// lib/core/services/sync_service.dart
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/local_database.dart';
import '../network/api_client.dart';

class SyncResult {
  final int matHangMoi;
  final int nhaCCMoi;
  final int khachHangMoi;
  final int xeMoi;
  final int nhanVienMoi;
  final int taiKhoanMoi;
  int get totalSynced => matHangMoi + nhaCCMoi + khachHangMoi + xeMoi + nhanVienMoi;
  bool get hasNewItems => totalSynced > 0;
  String get summary {
    final parts = <String>[];
    if (matHangMoi > 0) parts.add('$matHangMoi mặt hàng mới');
    if (nhaCCMoi > 0) parts.add('$nhaCCMoi nhà CC mới');
    if (khachHangMoi > 0) parts.add('$khachHangMoi khách hàng mới');
    if (xeMoi > 0) parts.add('$xeMoi xe mới');
    if (nhanVienMoi > 0) parts.add('$nhanVienMoi nhân viên mới');
    return parts.isEmpty ? 'Catalog đã cập nhật' : 'Cập nhật: ${parts.join(', ')}';
  }

  const SyncResult({
    this.matHangMoi = 0,
    this.nhaCCMoi = 0,
    this.khachHangMoi = 0,
    this.xeMoi = 0,
    this.nhanVienMoi = 0,
    this.taiKhoanMoi = 0,
  });
}

class SyncUploadResult {
  final int khCount;
  final int cxCount;
  final int bhCount;
  final List<String> errors;
  bool get hasErrors => errors.isNotEmpty;

  const SyncUploadResult({
    this.khCount = 0,
    this.cxCount = 0,
    this.bhCount = 0,
    this.errors = const [],
  });
}

class SyncService {
  static final SyncService instance = SyncService._();
  SyncService._();

  final _db = LocalDatabase.instance;
  Dio get _dio => ApiClient.instance.dio;

  static const _syncDateKey = 'last_catalog_sync_date';

  // ── Catalog sync ────────────────────────────────────────────────────────

  Future<bool> shouldSyncToday() async {
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getString(_syncDateKey) ?? '';
    final today = DateTime.now().toIso8601String().substring(0, 10);
    return last != today;
  }

  Future<void> markSyncedToday() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await prefs.setString(_syncDateKey, today);
  }

  /// Kéo catalog từ server về SQLite. Trả về số lượng bản ghi mới/cập nhật.
  Future<SyncResult> syncCatalog() async {
    int matHangMoi = 0, nhaCCMoi = 0, khachHangMoi = 0, xeMoi = 0, nhanVienMoi = 0, taiKhoanMoi = 0;
    debugPrint('[SYNC] Bắt đầu sync catalog, baseUrl=${ApiClient.instance.dio.options.baseUrl}');

    try {
      // Mặt hàng
      final mhRes = await _dio.get('/api/mat-hang',
          queryParameters: {'pageSize': 500, 'isActive': true});
      debugPrint('[SYNC] mat-hang: ${(mhRes.data['items'] as List?)?.length ?? 0} items');
      final mhItems = (mhRes.data['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      if (mhItems.isNotEmpty) {
        final existingMh = await _db.getMatHangList();
        final existingIds = existingMh.map((e) => e['server_id']).toSet();
        matHangMoi = mhItems.where((e) => !existingIds.contains(e['id'])).length;
        await _db.upsertMatHangList(mhItems.map((e) => {
          'server_id': e['id'],
          'ma_mat_hang': e['maMatHang'] ?? '',
          'ten_mat_hang': e['tenMatHang'] ?? '',
          'don_vi_tinh': e['donViTinh'],
          'nha_cung_cap_id': e['nhaCungCapId'],
          'ten_nha_cc': e['tenNhaCungCap'],
          'don_gia': (e['donGia'] ?? 0).toDouble(),
          'is_active': (e['isActive'] == true) ? 1 : 0,
        }).toList());
      }
    } catch (e) { debugPrint('[SYNC] LỖI mat-hang: $e'); }

    try {
      // Nhà cung cấp
      final nccRes = await _dio.get('/api/nha-cung-cap/all');
      debugPrint('[SYNC] nha-cung-cap: ${(nccRes.data as List?)?.length ?? 0} items');
      final nccItems = (nccRes.data as List?)?.cast<Map<String, dynamic>>() ?? [];
      if (nccItems.isNotEmpty) {
        final existingNcc = await _db.getNhaCungCapList();
        final existingIds = existingNcc.map((e) => e['server_id']).toSet();
        nhaCCMoi = nccItems.where((e) => !existingIds.contains(e['id'])).length;
        await _db.upsertNhaCungCapList(nccItems.map((e) => {
          'server_id': e['id'],
          'ma_ncc': e['maNCC'] ?? '',
          'ten_ncc': e['tenNCC'] ?? '',
          'is_active': 1,
        }).toList());
      }
    } catch (e) { debugPrint('[SYNC] LỖI nha-cung-cap: $e'); }

    try {
      // Khách hàng
      final khRes = await _dio.get('/api/khach-hang',
          queryParameters: {'pageSize': 1000, 'isActive': true});
      final khItems = (khRes.data['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      debugPrint('[SYNC] khach-hang: ${khItems.length} items');
      if (khItems.isNotEmpty) {
        final existingKh = await _db.getKhachHangList();
        final existingIds = existingKh
            .where((e) => e['server_id'] != null)
            .map((e) => e['server_id'])
            .toSet();
        khachHangMoi = khItems.where((e) => !existingIds.contains(e['id'])).length;
        await _db.upsertKhachHangList(khItems.map((e) => {
          'server_id': e['id'],
          'ma_khach_hang': e['maKhachHang'],
          'ten_khach_hang': e['tenKhachHang'] ?? '',
          'dia_chi': e['diaChi'],
          'so_dien_thoai': e['soDienThoai'],
          'email': e['email'],
          'latitude': e['latitude'],
          'longitude': e['longitude'],
          'is_active': (e['isActive'] == true) ? 1 : 0,
          'is_offline_created': 0,
          'is_synced': 1,
        }).toList());
      }
    } catch (e) { debugPrint('[SYNC] LỖI khach-hang: $e'); }

    try {
      // Xe
      final xeRes = await _dio.get('/api/xe', queryParameters: {'isActive': true});
      final xeItems = (xeRes.data['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      debugPrint('[SYNC] xe: ${xeItems.length} items');
      if (xeItems.isNotEmpty) {
        final existingXe = await _db.getXeList();
        final existingIds = existingXe.map((e) => e['server_id']).toSet();
        xeMoi = xeItems.where((e) => !existingIds.contains(e['id'])).length;
        await _db.upsertXeList(xeItems.map((e) => {
          'server_id': e['id'],
          'bien_so_xe': e['bienSoXe'] ?? '',
          'loai_xe': e['loaiXe'],
          'is_active': (e['isActive'] == true) ? 1 : 0,
        }).toList());
      }
    } catch (e) { debugPrint('[SYNC] LỖI xe: $e'); }

    try {
      // Nhân viên (lái xe)
      final nvRes = await _dio.get('/api/nhan-vien/lai-xe');
      final nvItems = (nvRes.data as List?)?.cast<Map<String, dynamic>>() ?? [];
      debugPrint('[SYNC] nhan-vien: ${nvItems.length} items');
      if (nvItems.isNotEmpty) {
        // Xóa cache cũ để tránh data stale (is_lai_xe=0 từ version cũ)
        await _db.clearNhanVienCache();
        nhanVienMoi = nvItems.length;
        await _db.upsertNhanVienList(nvItems.map((e) => {
          'server_id':    e['id'],
          'ma_nhan_vien': e['maNhanVien'] ?? '',
          'ho_ten':       e['hoTen'] ?? '',
          'ten_chuc_vu':  null,
          'is_lai_xe':    1, // endpoint /lai-xe chỉ trả lái xe, luôn = 1
          'is_active':    1,
        }).toList());
      }
    } catch (e) { debugPrint('[SYNC] LỖI nhan-vien: $e'); }

    try {
      // Tài khoản công ty (dùng cho dropdown chuyển khoản)
      final tkRes = await _dio.get('/api/tai-khoan');
      final tkItems = (tkRes.data as List?)?.cast<Map<String, dynamic>>() ?? [];
      debugPrint('[SYNC] tai-khoan: ${tkItems.length} items');
      if (tkItems.isNotEmpty) {
        taiKhoanMoi = tkItems.length;
        await _db.upsertTaiKhoanList(tkItems.map((e) => {
          'server_id':     e['id'],
          'ma_tai_khoan':  e['maTaiKhoan'] ?? '',
          'ten_tai_khoan': e['tenTaiKhoan'] ?? '',
          'loai':          e['loai'] ?? '',
          'so_tai_khoan':  e['soTaiKhoan'],
          'ngan_hang':     e['nganHang'],
          'is_active':     (e['isActive'] == true) ? 1 : 0,
        }).toList());
      }
    } catch (e) { debugPrint('[SYNC] LỖI tai-khoan: $e'); }

    return SyncResult(
      matHangMoi: matHangMoi,
      nhaCCMoi: nhaCCMoi,
      khachHangMoi: khachHangMoi,
      xeMoi: xeMoi,
      nhanVienMoi: nhanVienMoi,
      taiKhoanMoi: taiKhoanMoi,
    );
  }

  // ── Upload dữ liệu offline ────────────────────────────────────────────────

  /// Đồng bộ tất cả dữ liệu offline lên server theo thứ tự: KH → CX → BH.
  Future<SyncUploadResult> uploadPendingData() async {
    int khCount = 0, cxCount = 0, bhCount = 0;
    final errors = <String>[];

    // 1. Sync khách hàng tạo offline
    final pendingKh = await _db.getPendingKhachHang();
    for (final kh in pendingKh) {
      try {
        final res = await _dio.post('/api/khach-hang', data: {
          'tenKhachHang': kh['ten_khach_hang'],
          'diaChi': kh['dia_chi'],
          'soDienThoai': kh['so_dien_thoai'],
          'email': kh['email'],
          'latitude': kh['latitude'],
          'longitude': kh['longitude'],
          'isActive': true,
        });
        await _db.markKhachHangSynced(kh['local_id'] as int, res.data['id'] as int);
        khCount++;
      } catch (e) {
        errors.add('Khách hàng ${kh['ten_khach_hang']}: $e');
      }
    }

    // 2. Sync chuyến xe tạo offline
    final pendingCx = await _db.getPendingChuyenXe();
    for (final cx in pendingCx) {
      try {
        final res = await _dio.post('/api/chuyen-xe', data: {
          'ngayXuat': cx['ngay_xuat'],
          'xeId': cx['xe_id'],
          'nhanVienId': cx['nhan_vien_id'],
          'loai': 'mobile',
          'trangThai': 'dang-giao',
          'isActive': true,
          'chiTiet': [],
        });
        await _db.markChuyenXeSynced(
          cx['local_id'] as int,
          res.data['id'] as int,
          res.data['maChuyenXe'] as String,
        );
        cxCount++;
      } catch (e) {
        errors.add('Chuyến xe ${cx['ngay_xuat']}: $e');
      }
    }

    // 3. Sync bán hàng offline
    final pendingBh = await _db.getPendingBanHang();
    for (final bh in pendingBh) {
      try {
        // Resolve server_id chuyến xe (nếu tạo offline, lấy server_id sau khi sync bước 2)
        int? chuyenXeServerId = bh['chuyen_xe_server_id'] as int?;
        if (chuyenXeServerId == null && bh['chuyen_xe_local_id'] != null) {
          final d = await _db.db;
          final rows = await d.query('chuyen_xe_offline',
              where: 'local_id = ?',
              whereArgs: [bh['chuyen_xe_local_id']]);
          if (rows.isNotEmpty) chuyenXeServerId = rows.first['server_id'] as int?;
        }
        if (chuyenXeServerId == null) {
          errors.add('Bán hàng local_id=${bh['local_id']}: chuyến xe chưa đồng bộ');
          continue;
        }

        // Resolve server_id khách hàng
        int? khachHangServerId = bh['khach_hang_server_id'] as int?;
        if (khachHangServerId == null && bh['khach_hang_local_id'] != null) {
          final d = await _db.db;
          final rows = await d.query('khach_hang_local',
              where: 'local_id = ?',
              whereArgs: [bh['khach_hang_local_id']]);
          if (rows.isNotEmpty) khachHangServerId = rows.first['server_id'] as int?;
        }
        if (khachHangServerId == null) {
          errors.add('Bán hàng local_id=${bh['local_id']}: khách hàng chưa đồng bộ');
          continue;
        }

        await _dio.post('/api/chuyen-xe/$chuyenXeServerId/ban-hang', data: {
          'khachHangId': khachHangServerId,
          'matHangId': bh['mat_hang_id'],
          'soLuong': bh['so_luong'],
          'donGia': bh['don_gia'],
          'soVoBan': bh['so_vo_ban'],
          'soVoThu': bh['so_vo_thu'],
          'ghiChu': bh['ghi_chu'],
        });
        await _db.markBanHangSynced(bh['local_id'] as int);
        bhCount++;
      } catch (e) {
        await _db.markBanHangSyncError(bh['local_id'] as int, e.toString());
        errors.add('Bán hàng local_id=${bh['local_id']}: $e');
      }
    }

    return SyncUploadResult(
        khCount: khCount, cxCount: cxCount, bhCount: bhCount, errors: errors);
  }
}
