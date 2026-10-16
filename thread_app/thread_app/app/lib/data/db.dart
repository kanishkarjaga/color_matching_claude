import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'thread.dart';

class AppDb {
  static Database? _db;
  static Future<Database> get() async => _db ??= await openDatabase(
    p.join(await getDatabasesPath(), 'workshop.db'), version: 1,
    onCreate: (db, _) async {
      await db.execute('CREATE TABLE settings(key TEXT PRIMARY KEY, value TEXT)');
      await db.execute('''CREATE TABLE threads(id INTEGER PRIMARY KEY, code TEXT UNIQUE NOT NULL, name TEXT NOT NULL,
        hex TEXT NOT NULL, sample_hex TEXT NOT NULL, type TEXT DEFAULT 'normal', cost_per_1000_stitches REAL DEFAULT 0,
        in_stock INTEGER DEFAULT 1, stock_qty REAL DEFAULT 0, low_stock_at REAL DEFAULT 0, used_total REAL DEFAULT 0,
        lab_l REAL, lab_a REAL, lab_b REAL)''');
      await db.execute('CREATE TABLE thread_usage(id INTEGER PRIMARY KEY, thread_id INT, job_id INT, stitches INT, at TEXT)');
      await db.insert('settings', {'key': 'needle_count', 'value': '12'});
    });

  static Future<List<Thread>> threads() async => (await (await get()).query('threads', orderBy: 'name')).map(Thread.fromMap).toList();
  static Future<void> save(Thread t) async => (await get()).insert('threads', t.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  static Future<void> setStock(int id, bool v) async => (await get()).update('threads', {'in_stock': v ? 1 : 0}, where: 'id=?', whereArgs: [id]);
  static Future<List<Thread>> lowStock() async => (await (await get()).rawQuery(
    'SELECT * FROM threads WHERE low_stock_at>0 AND stock_qty<=low_stock_at')).map(Thread.fromMap).toList();

  /// Daily auto-backup: call on app start; keeps last 14 copies.
  static Future<void> autoBackup() async {
    await get();
    final dir = Directory(p.join((await getApplicationDocumentsDirectory()).path, 'backups'))..createSync(recursive: true);
    final day = DateTime.now().toIso8601String().substring(0, 10);
    final f = File(p.join(dir.path, 'workshop-$day.db'));
    if (!f.existsSync()) await File(p.join(await getDatabasesPath(), 'workshop.db')).copy(f.path);
    final all = dir.listSync().whereType<File>().toList()..sort((a, b) => a.path.compareTo(b.path));
    for (final old in all.take((all.length - 14).clamp(0, all.length))) { old.deleteSync(); }
  }
  static Future<List<File>> backups() async {
    final dir = Directory(p.join((await getApplicationDocumentsDirectory()).path, 'backups'));
    return dir.existsSync() ? (dir.listSync().whereType<File>().toList()..sort((a, b) => b.path.compareTo(a.path))) : [];
  }
  /// One-tap restore: close DB, overwrite file, reopen.
  static Future<void> restore(File backup) async {
    await _db?.close(); _db = null;
    await backup.copy(p.join(await getDatabasesPath(), 'workshop.db'));
    await get();
  }
}
