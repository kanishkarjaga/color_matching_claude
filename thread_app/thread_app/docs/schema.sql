-- SQLite schema (app) — mirrored by backend. Phase 1 uses threads/settings/backups.
PRAGMA foreign_keys=ON;
CREATE TABLE settings(key TEXT PRIMARY KEY, value TEXT);  -- needle_count=12, machine_format=DST, lang=en
CREATE TABLE users(id INTEGER PRIMARY KEY, name TEXT, role TEXT CHECK(role IN('owner','designer','operator')), pin_hash TEXT);
CREATE TABLE threads(
  id INTEGER PRIMARY KEY, code TEXT UNIQUE NOT NULL, name TEXT NOT NULL,
  hex TEXT NOT NULL,            -- printed spool color
  sample_hex TEXT NOT NULL,     -- measured stitched-sample color (used for matching)
  type TEXT CHECK(type IN('normal','zari')) DEFAULT 'normal',
  cost_per_1000_stitches REAL DEFAULT 0, in_stock INTEGER DEFAULT 1,
  stock_qty REAL DEFAULT 0, low_stock_at REAL DEFAULT 0, used_total REAL DEFAULT 0,
  lab_l REAL, lab_a REAL, lab_b REAL);   -- cached from sample_hex
CREATE TABLE thread_usage(id INTEGER PRIMARY KEY, thread_id INT REFERENCES threads(id), job_id INT, stitches INT, at TEXT);
CREATE TABLE designs(id INTEGER PRIMARY KEY, code TEXT UNIQUE, name TEXT, category TEXT, image_path TEXT, thumb_path TEXT, stitch_count INT);
CREATE TABLE design_layers(id INTEGER PRIMARY KEY, design_id INT REFERENCES designs(id), name TEXT, original_hex TEXT, mask_path TEXT, stitch_count INT, is_outline INT DEFAULT 0, sort_order INT);
CREATE TABLE rules(id INTEGER PRIMARY KEY, name TEXT, condition_json TEXT, action_json TEXT, weight REAL DEFAULT 1, active INT DEFAULT 1);
CREATE TABLE jobs(id INTEGER PRIMARY KEY, uuid TEXT UNIQUE, design_id INT, customer TEXT, event_date TEXT,
  fabric_type TEXT, fabric_hex TEXT, occasion TEXT, style TEXT, season TEXT, status TEXT, is_template INT DEFAULT 0,
  chosen_scheme_json TEXT, price REAL, minutes REAL, customer_choice TEXT, created_by INT, created_at TEXT);
CREATE TABLE job_layers(id INTEGER PRIMARY KEY, job_id INT REFERENCES jobs(id), layer_id INT, thread_id INT, needle_no INT, swapped INT DEFAULT 0);
CREATE TABLE feedback(id INTEGER PRIMARY KEY, job_id INT, choice TEXT CHECK(choice IN('like','reject')), at TEXT);
CREATE TABLE backups(id INTEGER PRIMARY KEY, path TEXT, created_at TEXT, size INT);
CREATE INDEX idx_designs_cat ON designs(category); CREATE INDEX idx_jobs_event ON jobs(design_id,event_date);
