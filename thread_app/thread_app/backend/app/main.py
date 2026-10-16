import shutil, sqlite3, time
from pathlib import Path
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from .color import hex_to_lab, snap, contrast_warning

DB = Path('workshop.db'); BACKUPS = Path('backups'); BACKUPS.mkdir(exist_ok=True)
SCHEMA = Path(__file__).parents[2] / 'docs/schema.sql'
app = FastAPI(title='Thread Recommender API')

def db():
    c = sqlite3.connect(DB); c.row_factory = sqlite3.Row; return c

def init():
    c = db()
    if not c.execute("SELECT name FROM sqlite_master WHERE name='threads'").fetchone():
        c.executescript(SCHEMA.read_text()); c.commit()
    c.close()
init()

class Thread(BaseModel):
    code: str; name: str; hex: str; sample_hex: str
    type: str = 'normal'; cost_per_1000_stitches: float = 0
    in_stock: bool = True; stock_qty: float = 0; low_stock_at: float = 0

COLS = 'code,name,hex,sample_hex,type,cost_per_1000_stitches,in_stock,stock_qty,low_stock_at,lab_l,lab_a,lab_b'
def _vals(t):
    L, a, b = hex_to_lab(t.sample_hex)
    return (t.code, t.name, t.hex, t.sample_hex, t.type, t.cost_per_1000_stitches, int(t.in_stock), t.stock_qty, t.low_stock_at, L, a, b)

@app.get('/threads')
def list_threads(in_stock: bool | None = None):
    c = db()
    rows = c.execute('SELECT * FROM threads' + (' WHERE in_stock=?' if in_stock is not None else ''),
                     (int(in_stock),) if in_stock is not None else ()).fetchall()
    return [dict(r) for r in rows]

@app.post('/threads')
def add_thread(t: Thread):
    c = db()
    try:
        cur = c.execute(f'INSERT INTO threads({COLS}) VALUES({",".join("?"*12)})', _vals(t)); c.commit()
    except sqlite3.IntegrityError: raise HTTPException(409, 'duplicate thread code')
    return {'id': cur.lastrowid}

@app.put('/threads/{tid}')
def edit_thread(tid: int, t: Thread):
    c = db(); sets = ','.join(f'{k}=?' for k in COLS.split(','))
    c.execute(f'UPDATE threads SET {sets} WHERE id=?', _vals(t) + (tid,)); c.commit()
    return {'ok': True}

@app.post('/threads/{tid}/stock')
def set_stock(tid: int, in_stock: bool):
    c = db(); c.execute('UPDATE threads SET in_stock=? WHERE id=?', (int(in_stock), tid)); c.commit()
    return {'ok': True}

@app.get('/threads/low-stock')
def low_stock():
    return [dict(r) for r in db().execute('SELECT * FROM threads WHERE low_stock_at>0 AND stock_qty<=low_stock_at')]

class Match(BaseModel):
    hex: str; type: str | None = None; fabric_hex: str | None = None

@app.post('/match')
def match(m: Match):
    threads = [dict(r) for r in db().execute('SELECT * FROM threads')]
    try: res = snap(m.hex, threads, m.type)
    except LookupError as e: raise HTTPException(404, str(e))
    if m.fabric_hex: res['contrast'] = contrast_warning(res['thread']['sample_hex'], m.fabric_hex)
    return res

@app.post('/backup')
def backup():
    p = BACKUPS / f"workshop-{time.strftime('%Y%m%d-%H%M%S')}.db"
    src = db(); dst = sqlite3.connect(p); src.backup(dst); dst.close()
    return {'path': str(p), 'size': p.stat().st_size}

@app.get('/backups')
def backups(): return sorted(x.name for x in BACKUPS.glob('*.db'))

@app.post('/restore/{name}')
def restore(name: str):
    p = BACKUPS / Path(name).name
    if not p.exists(): raise HTTPException(404, 'backup not found')
    shutil.copy(DB, BACKUPS / f'pre-restore-{int(time.time())}.db'); shutil.copy(p, DB)
    return {'restored': p.name}
