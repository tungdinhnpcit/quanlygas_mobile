// lib/core/database/local_database.dart
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class LocalDatabase {
  static final LocalDatabase instance = LocalDatabase._init();
  LocalDatabase._init();

  Database? _db;

  Future<Database> get db async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    return openDatabase(
      join(dir, 'gasmanager.db'),
      version: 4,
      onCreate: _create,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS cache_nhan_vien (
          server_id    INTEGER PRIMARY KEY,
          ma_nhan_vien TEXT NOT NULL,
          ho_ten       TEXT NOT NULL,
          ten_chuc_vu  TEXT,
          is_lai_xe    INTEGER DEFAULT 0,
          is_active    INTEGER DEFAULT 1
        )
      ''');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE ban_hang_offline ADD COLUMN tien_mat REAL NOT NULL DEFAULT 0');
      await db.execute('ALTER TABLE ban_hang_offline ADD COLUMN tien_ck  REAL NOT NULL DEFAULT 0');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS ban_hang_gas_du_local (
          local_id              INTEGER PRIMARY KEY AUTOINCREMENT,
          chuyen_xe_server_id   INTEGER,
          chuyen_xe_local_id    INTEGER,
          khach_hang_server_id  INTEGER,
          khach_hang_local_id   INTEGER,
          mat_hang_id           INTEGER NOT NULL,
          so_kg                 REAL NOT NULL DEFAULT 0,
          don_gia               REAL NOT NULL DEFAULT 0,
          thanh_tien            REAL NOT NULL DEFAULT 0,
          is_synced             INTEGER NOT NULL DEFAULT 0,
          created_at            TEXT
        )
      ''');
    }
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS cache_tai_khoan (
          server_id     INTEGER PRIMARY KEY,
          ma_tai_khoan  TEXT NOT NULL,
          ten_tai_khoan TEXT NOT NULL,
          loai          TEXT NOT NULL,
          so_tai_khoan  TEXT,
          ngan_hang     TEXT,
          is_active     INTEGER DEFAULT 1
        )
      ''');
      await db.execute(
        'ALTER TABLE ban_hang_offline ADD COLUMN tai_khoan_ck_id INTEGER NULL',
      );
    }
  }

  Future<void> _create(Database db, int version) async {
    await db.execute('''
      CREATE TABLE chuyen_xe_offline (
        local_id    INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id   INTEGER UNIQUE,
        ma_chuyen_xe TEXT,
        ngay_xuat   TEXT NOT NULL,
        xe_id       INTEGER NOT NULL,
        bien_so_xe  TEXT,
        nhan_vien_id INTEGER NOT NULL,
        trang_thai  TEXT NOT NULL DEFAULT 'dang-giao',
        loai        TEXT NOT NULL DEFAULT 'mobile',
        is_synced   INTEGER NOT NULL DEFAULT 0,
        created_at  TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE cache_mat_hang (
        server_id       INTEGER PRIMARY KEY,
        ma_mat_hang     TEXT NOT NULL,
        ten_mat_hang    TEXT NOT NULL,
        don_vi_tinh     TEXT,
        nha_cung_cap_id INTEGER,
        ten_nha_cc      TEXT,
        don_gia         REAL DEFAULT 0,
        is_active       INTEGER DEFAULT 1
      )
    ''');
    await db.execute('''
      CREATE TABLE cache_nha_cung_cap (
        server_id  INTEGER PRIMARY KEY,
        ma_ncc     TEXT NOT NULL,
        ten_ncc    TEXT NOT NULL,
        is_active  INTEGER DEFAULT 1
      )
    ''');
    await db.execute('''
      CREATE TABLE cache_xe (
        server_id   INTEGER PRIMARY KEY,
        bien_so_xe  TEXT NOT NULL,
        loai_xe     TEXT,
        is_active   INTEGER DEFAULT 1
      )
    ''');
    await db.execute('''
      CREATE TABLE cache_nhan_vien (
        server_id    INTEGER PRIMARY KEY,
        ma_nhan_vien TEXT NOT NULL,
        ho_ten       TEXT NOT NULL,
        ten_chuc_vu  TEXT,
        is_lai_xe    INTEGER DEFAULT 0,
        is_active    INTEGER DEFAULT 1
      )
    ''');
    await db.execute('''
      CREATE TABLE khach_hang_local (
        local_id            INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id           INTEGER UNIQUE,
        ma_khach_hang       TEXT,
        ten_khach_hang      TEXT NOT NULL,
        dia_chi             TEXT,
        so_dien_thoai       TEXT,
        email               TEXT,
        latitude            REAL,
        longitude           REAL,
        is_active           INTEGER DEFAULT 1,
        is_offline_created  INTEGER DEFAULT 0,
        is_synced           INTEGER DEFAULT 1,
        created_at          TEXT,
        updated_at          TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE ban_hang_offline (
        local_id              INTEGER PRIMARY KEY AUTOINCREMENT,
        chuyen_xe_server_id   INTEGER,
        chuyen_xe_local_id    INTEGER,
        khach_hang_server_id  INTEGER,
        khach_hang_local_id   INTEGER,
        mat_hang_id           INTEGER NOT NULL,
        so_luong              INTEGER NOT NULL DEFAULT 0,
        don_gia               REAL NOT NULL DEFAULT 0,
        thanh_tien            REAL NOT NULL DEFAULT 0,
        so_vo_ban             INTEGER DEFAULT 0,
        so_vo_thu             INTEGER DEFAULT 0,
        tien_mat              REAL NOT NULL DEFAULT 0,
        tien_ck               REAL NOT NULL DEFAULT 0,
        ghi_chu               TEXT,
        created_at            TEXT,
        is_synced             INTEGER NOT NULL DEFAULT 0,
        sync_error            TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE ban_hang_gas_du_local (
        local_id              INTEGER PRIMARY KEY AUTOINCREMENT,
        chuyen_xe_server_id   INTEGER,
        chuyen_xe_local_id    INTEGER,
        khach_hang_server_id  INTEGER,
        khach_hang_local_id   INTEGER,
        mat_hang_id           INTEGER NOT NULL,
        so_kg                 REAL NOT NULL DEFAULT 0,
        don_gia               REAL NOT NULL DEFAULT 0,
        thanh_tien            REAL NOT NULL DEFAULT 0,
        is_synced             INTEGER NOT NULL DEFAULT 0,
        created_at            TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE cache_tai_khoan (
        server_id     INTEGER PRIMARY KEY,
        ma_tai_khoan  TEXT NOT NULL,
        ten_tai_khoan TEXT NOT NULL,
        loai          TEXT NOT NULL,
        so_tai_khoan  TEXT,
        ngan_hang     TEXT,
        is_active     INTEGER DEFAULT 1
      )
    ''');
  }

  // ── Chuyến xe offline ─────────────────────────────────────────────────────

  Future<int> insertChuyenXeOffline(Map<String, dynamic> data) async {
    final d = await db;
    return d.insert('chuyen_xe_offline', data,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getActiveTripToday(
      int nhanVienId, String today) async {
    final d = await db;
    final rows = await d.query(
      'chuyen_xe_offline',
      where:
          "nhan_vien_id = ? AND ngay_xuat = ? AND trang_thai NOT IN ('hoan-thanh','huy')",
      whereArgs: [nhanVienId, today],
      orderBy: 'local_id DESC',
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  Future<void> markChuyenXeSynced(
      int localId, int serverId, String maCX) async {
    final d = await db;
    await d.update(
      'chuyen_xe_offline',
      {'server_id': serverId, 'ma_chuyen_xe': maCX, 'is_synced': 1},
      where: 'local_id = ?',
      whereArgs: [localId],
    );
  }

  Future<List<Map<String, dynamic>>> getPendingChuyenXe() async {
    final d = await db;
    return d.query('chuyen_xe_offline',
        where: 'is_synced = 0', orderBy: 'local_id ASC');
  }

  // ── Cache mặt hàng ────────────────────────────────────────────────────────

  Future<void> upsertMatHangList(List<Map<String, dynamic>> items) async {
    final d = await db;
    final batch = d.batch();
    for (final item in items) {
      batch.insert('cache_mat_hang', item,
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getMatHangList() async {
    final d = await db;
    return d.query('cache_mat_hang', where: 'is_active = 1');
  }

  // ── Cache nhà cung cấp ───────────────────────────────────────────────────

  Future<void> upsertNhaCungCapList(List<Map<String, dynamic>> items) async {
    final d = await db;
    final batch = d.batch();
    for (final item in items) {
      batch.insert('cache_nha_cung_cap', item,
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getNhaCungCapList() async {
    final d = await db;
    return d.query('cache_nha_cung_cap', where: 'is_active = 1');
  }

  // ── Cache xe ─────────────────────────────────────────────────────────────

  Future<void> upsertXeList(List<Map<String, dynamic>> items) async {
    final d = await db;
    final batch = d.batch();
    for (final item in items) {
      batch.insert('cache_xe', item,
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getXeList() async {
    final d = await db;
    return d.query('cache_xe', where: 'is_active = 1');
  }

  // ── Cache nhân viên (lái xe) ─────────────────────────────────────────────

  Future<void> upsertNhanVienList(List<Map<String, dynamic>> items) async {
    final d = await db;
    final batch = d.batch();
    for (final item in items) {
      batch.insert('cache_nhan_vien', item,
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getNhanVienList() async {
    final d = await db;
    return d.query('cache_nhan_vien',
        where: 'is_active = 1 AND is_lai_xe = 1',
        orderBy: 'ho_ten ASC');
  }

  Future<void> clearNhanVienCache() async {
    final d = await db;
    await d.delete('cache_nhan_vien');
  }

  // ── Cache tài khoản công ty ──────────────────────────────────────────────

  Future<void> upsertTaiKhoanList(List<Map<String, dynamic>> items) async {
    final d = await db;
    final batch = d.batch();
    for (final item in items) {
      batch.insert('cache_tai_khoan', item,
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  /// Trả tài khoản không phải tiền mặt (ngan-hang, ca-nhan) để dùng cho dropdown CK.
  Future<List<Map<String, dynamic>>> getTaiKhoanList() async {
    final d = await db;
    return d.query(
      'cache_tai_khoan',
      where: "is_active = 1 AND loai != 'tien-mat'",
      orderBy: 'ten_tai_khoan ASC',
    );
  }

  // ── Khách hàng ───────────────────────────────────────────────────────────

  Future<void> upsertKhachHangList(List<Map<String, dynamic>> items) async {
    final d = await db;
    final batch = d.batch();
    for (final item in items) {
      batch.insert('khach_hang_local', item,
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<int> insertKhachHangOffline(Map<String, dynamic> data) async {
    final d = await db;
    return d.insert('khach_hang_local', data);
  }

  Future<List<Map<String, dynamic>>> getKhachHangList({String? search}) async {
    final d = await db;
    if (search == null || search.isEmpty) {
      return d.query('khach_hang_local',
          where: 'is_active = 1', orderBy: 'ten_khach_hang ASC');
    }
    return d.query(
      'khach_hang_local',
      where: 'is_active = 1 AND ten_khach_hang LIKE ?',
      whereArgs: ['%$search%'],
      orderBy: 'ten_khach_hang ASC',
    );
  }

  Future<void> markKhachHangSynced(int localId, int serverId) async {
    final d = await db;
    await d.update(
      'khach_hang_local',
      {'server_id': serverId, 'is_synced': 1, 'is_offline_created': 0},
      where: 'local_id = ?',
      whereArgs: [localId],
    );
  }

  Future<List<Map<String, dynamic>>> getPendingKhachHang() async {
    final d = await db;
    return d.query('khach_hang_local', where: 'is_synced = 0');
  }

  // ── Bán hàng offline ─────────────────────────────────────────────────────

  Future<int> insertBanHangOffline(Map<String, dynamic> data) async {
    final d = await db;
    return d.insert('ban_hang_offline', data);
  }

  Future<List<Map<String, dynamic>>> getPendingBanHang() async {
    final d = await db;
    return d.query('ban_hang_offline',
        where: 'is_synced = 0', orderBy: 'local_id ASC');
  }

  Future<void> markBanHangSynced(int localId) async {
    final d = await db;
    await d.update('ban_hang_offline', {'is_synced': 1},
        where: 'local_id = ?', whereArgs: [localId]);
  }

  Future<void> markBanHangSyncError(int localId, String error) async {
    final d = await db;
    await d.update('ban_hang_offline', {'sync_error': error},
        where: 'local_id = ?', whereArgs: [localId]);
  }

  // ── Bán gas dư offline ────────────────────────────────────────────────────

  Future<int> insertBanHangGasDuLocal(Map<String, dynamic> data) async {
    final d = await db;
    return d.insert('ban_hang_gas_du_local', data);
  }

  Future<List<Map<String, dynamic>>> getPendingBanHangGasDu() async {
    final d = await db;
    return d.query('ban_hang_gas_du_local',
        where: 'is_synced = 0', orderBy: 'local_id ASC');
  }

  Future<void> markBanHangGasDuSynced(int localId) async {
    final d = await db;
    await d.update('ban_hang_gas_du_local', {'is_synced': 1},
        where: 'local_id = ?', whereArgs: [localId]);
  }

  Future<int> getPendingCount() async {
    final d = await db;
    final kh = Sqflite.firstIntValue(await d.rawQuery(
        'SELECT COUNT(*) FROM khach_hang_local WHERE is_synced = 0')) ?? 0;
    final cx = Sqflite.firstIntValue(await d.rawQuery(
        'SELECT COUNT(*) FROM chuyen_xe_offline WHERE is_synced = 0')) ?? 0;
    final bh = Sqflite.firstIntValue(await d.rawQuery(
        'SELECT COUNT(*) FROM ban_hang_offline WHERE is_synced = 0')) ?? 0;
    final gd = Sqflite.firstIntValue(await d.rawQuery(
        'SELECT COUNT(*) FROM ban_hang_gas_du_local WHERE is_synced = 0')) ?? 0;
    return kh + cx + bh + gd;
  }
}
