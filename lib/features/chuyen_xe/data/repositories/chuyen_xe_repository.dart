// lib/features/chuyen_xe/data/repositories/chuyen_xe_repository.dart
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_client.dart';
import '../models/chuyen_xe_model.dart';
import '../models/kiem_ke_model.dart';

class ChuyenXeRepository {
  /// Lấy danh sách phụ xe
  Future<List<Map<String, dynamic>>> searchPhuXeAPI(String keyword) async {

    try {
      // 1. Đổi endpoint từ '/api/chuyen-xe' sang endpoint quản lý nhân viên
      final res = await ApiClient.instance.dio.get(
        '/api/nhan-vien', // Thay đổi đường dẫn này cho khớp với Backend
        queryParameters: {
          'keyword': keyword,     // Tham số tìm kiếm theo tên hoặc mã
          'chucVu': 'Phụ xe',     // Backend filter: x.ChucVu.TenChucVu.Contains(chucVu)
          'page': 1,
          'pageSize': 20,         // Chỉ nên lấy top kết quả để UI không bị giật
        },
      );

      // 2. Parse dữ liệu trả về
      final data = res.data;

      // Thường backend .NET sẽ bọc array trong một object (ví dụ: data['items'] hoặc data['data'])
      // Nếu BE trả thẳng mảng JSON thì nó sẽ rơi vào trường hợp 'data as List'
      final list = (data is Map ? (data['items'] ?? data['data']) : data) as List? ?? [];

      // 3. Ép kiểu về List<Map<String, dynamic>> để dùng chung với pattern của UI hiện tại
      return list.map((e) => e as Map<String, dynamic>).toList();
    } on DioException {
      rethrow;
    } catch (_) {
      rethrow;
    }
  }

  /// Lấy danh sách chuyến xe của lái xe theo nhanVienId, hỗ trợ lọc trạng thái, khoảng ngày, xe và phân trang.
  Future<List<ChuyenXeModel>> getList({
    required int nhanVienId,
    int? xeId,
    String? trangThai,
    DateTime? tuNgay,
    DateTime? denNgay,
    int page = 1,
    int pageSize = 50,
  }) async {
    debugPrint('[ChuyenXe] getList() nhanVienId=$nhanVienId xeId=$xeId trangThai=$trangThai tuNgay=$tuNgay denNgay=$denNgay');
    try {
      final res = await ApiClient.instance.dio.get(
        '/api/chuyen-xe',
        queryParameters: {
          'nhanVienId': nhanVienId,
          if (xeId    != null) 'xeId':     xeId,
          if (trangThai != null) 'trangThai': trangThai,
          if (tuNgay  != null) 'tuNgay':  tuNgay.toIso8601String(),
          if (denNgay != null) 'denNgay': denNgay.toIso8601String(),
          'page': page,
          'pageSize': pageSize,
        },
      );
      debugPrint('[ChuyenXe] response status=${res.statusCode} data=${res.data.runtimeType}');
      final data = res.data;
      final list = (data is Map ? data['items'] : data) as List? ?? [];
      debugPrint('[ChuyenXe] parsed ${list.length} items');
      return list
          .map((e) => ChuyenXeModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      debugPrint('[ChuyenXe] DioException: ${e.type} | status=${e.response?.statusCode} | message=${e.message}');
      debugPrint('[ChuyenXe] response body: ${e.response?.data}');
      rethrow;
    } catch (e) {
      debugPrint('[ChuyenXe] ERROR: $e');
      rethrow;
    }
  }

  /// Lấy danh sách chuyến xe theo trạng thái, không giới hạn lái xe — dùng cho
  /// màn hình kế toán lập kiểm kê (không truyền nhanVienId, backend trả tất cả).
  Future<List<ChuyenXeModel>> getListByTrangThai({
    required String trangThai,
    int page = 1,
    int pageSize = 100,
  }) async {
    try {
      final res = await ApiClient.instance.dio.get(
        '/api/chuyen-xe',
        queryParameters: {
          'trangThai': trangThai,
          'page': page,
          'pageSize': pageSize,
        },
      );
      final data = res.data;
      final list = (data is Map ? data['items'] : data) as List? ?? [];
      return list
          .map((e) => ChuyenXeModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      debugPrint('[ChuyenXe] DioException getListByTrangThai: ${e.type} | status=${e.response?.statusCode} | message=${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[ChuyenXe] ERROR getListByTrangThai: $e');
      rethrow;
    }
  }

  /// Lấy danh sách chuyến xe không giới hạn lái xe, lọc theo khoảng ngày — dùng cho màn Tổng quan.
  Future<List<ChuyenXeModel>> getListAll({
    DateTime? tuNgay,
    DateTime? denNgay,
    int page = 1,
    int pageSize = 100,
  }) async {
    try {
      final res = await ApiClient.instance.dio.get(
        '/api/chuyen-xe',
        queryParameters: {
          if (tuNgay  != null) 'tuNgay':  tuNgay.toIso8601String(),
          if (denNgay != null) 'denNgay': denNgay.toIso8601String(),
          'page': page,
          'pageSize': pageSize,
        },
      );
      final data = res.data;
      final list = (data is Map ? data['items'] : data) as List? ?? [];
      return list.map((e) => ChuyenXeModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      debugPrint('[ChuyenXe] DioException getListAll: ${e.type} | status=${e.response?.statusCode} | message=${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[ChuyenXe] ERROR getListAll: $e');
      rethrow;
    }
  }

  /// Lấy chi tiết chuyến xe theo ID kèm danh sách hàng hóa và ảnh đã upload.
  Future<ChuyenXeModel> getById(int id) async {
    debugPrint('[ChuyenXe] GET ${AppConstants.resolvedApiUrl}/api/chuyen-xe/$id');
    try{
      final res = await ApiClient.instance.dio.get('/api/chuyen-xe/$id');
      return ChuyenXeModel.fromJson(res.data as Map<String, dynamic>);
    }
    on DioException catch (e)
    {
      debugPrint('[ChuyenXe] DioException getById: ${e.type} | status=${e.response?.statusCode} | message=${e.message}');
      debugPrint('[ChuyenXe] response body: ${e.response?.data}');
      rethrow;
    }
    catch (e) {
      debugPrint('[ChuyenXe] ERROR getById: $e');
      rethrow;
    }
  }

  /// Kiểm tra chuyến xe đang thực hiện hôm nay của lái xe.
  /// Trả null nếu chưa có (HTTP 204).
  Future<ChuyenXeModel?> getActiveTripToday(int nhanVienId) async {
    try {
      final res = await ApiClient.instance.dio.get(
        '/api/chuyen-xe/active-today',
        queryParameters: {'nhanVienId': nhanVienId},
      );
      if (res.statusCode == 204 || res.data == null) return null;
      return ChuyenXeModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 204) return null;
      rethrow;
    }
  }

  /// Tạo chuyến xe mới từ mobile (loai='mobile').
  Future<ChuyenXeModel> createTrip({
    required DateTime ngayXuat,
    required int xeId,
    required int nhanVienId,
    int? phuXeId,
  }) async {
    final res = await ApiClient.instance.dio.post('/api/chuyen-xe', data: {
      'ngayXuat': ngayXuat.toIso8601String(),
      'xeId': xeId,
      'nhanVienId': nhanVienId,
      if (phuXeId != null) 'phuXeId': phuXeId,
      'loai': 'mobile',
      'trangThai': 'dang-giao',
      'isActive': true,
      'chiTiet': [],
    });
    return ChuyenXeModel.fromJson(res.data as Map<String, dynamic>);
  }

  /// Lấy danh sách bán hàng lái xe đã nhập cho chuyến xe.
  Future<List<BanHangKhachHangModel>> getBanHang(int chuyenXeId) async {
    final res = await ApiClient.instance.dio
        .get('/api/chuyen-xe/$chuyenXeId/ban-hang');
    final list = res.data as List? ?? [];
    return list
        .map((e) => BanHangKhachHangModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Lưu entry bán hàng lên server (không kiểm tra tồn kho ở đây).
  Future<BanHangKhachHangModel> createBanHang(
      int chuyenXeId, Map<String, dynamic> data) async {
    final res = await ApiClient.instance.dio
        .post('/api/chuyen-xe/$chuyenXeId/ban-hang', data: data);
    return BanHangKhachHangModel.fromJson(res.data as Map<String, dynamic>);
  }

  /// Sửa entry bán hàng.
  Future<BanHangKhachHangModel> updateBanHang(
      int chuyenXeId, int banHangId, Map<String, dynamic> data) async {
    final res = await ApiClient.instance.dio
        .put('/api/chuyen-xe/$chuyenXeId/ban-hang/$banHangId', data: data);
    return BanHangKhachHangModel.fromJson(res.data as Map<String, dynamic>);
  }

  /// Xóa entry bán hàng.
  Future<void> deleteBanHang(int chuyenXeId, int banHangId) async {
    await ApiClient.instance.dio
        .post('/api/chuyen-xe/$chuyenXeId/ban-hang/$banHangId/delete');
  }

  /// Xóa 1 dòng mua gas dư.
  Future<void> deleteBanHangGasDu(int chuyenXeId, int gasDuId) async {
    await ApiClient.instance.dio
        .post('/api/chuyen-xe/$chuyenXeId/ban-hang-gas-du/$gasDuId/delete');
  }

  /// Xóa chuyến xe (chỉ dùng khi chuyến chưa kết thúc / kỳ chưa chốt).
  Future<void> deleteTrip(int chuyenXeId) async {
    await ApiClient.instance.dio.post('/api/chuyen-xe/$chuyenXeId/delete');
  }

  /// Mobile: lái xe kết thúc chuyến — đổi trangThai sang hoan-thanh.
  Future<void> ketThucMobile(int chuyenXeId) async {
    await ApiClient.instance.dio
        .post('/api/chuyen-xe/$chuyenXeId/ket-thuc-mobile');
  }

  /// Ke toan phe duyet chuyen xe — tao KetThucChuyenXe record voi so lieu quyet toan.
  /// Goi cung endpoint voi web (POST /api/chuyen-xe/{id}/ket-thuc).
  Future<void> pheduyet(int chuyenXeId, Map<String, dynamic> body) async {
    await ApiClient.instance.dio
        .post('/api/chuyen-xe/$chuyenXeId/ket-thuc', data: body);
  }

  /// Nhập đầy đủ thông tin bán hàng 1 khách hàng: sản phẩm + gas dư + thanh toán.
  /// Nhập bán hàng khách hàng — trả xacNhanId (xác nhận khách hàng được tạo tự động)
  Future<int> nhapKhachHang(int chuyenXeId, Map<String, dynamic> body) async {
    final token = await const FlutterSecureStorage().read(key: 'jwt_token');
    debugPrint('[NHAP_KH] POST ${ApiClient.instance.dio.options.baseUrl}/api/chuyen-xe/$chuyenXeId/nhap-khach-hang');
    debugPrint('[NHAP_KH] token: ${token != null ? '${token.substring(0, 20)}...(len=${token.length})' : 'NULL'}');
    debugPrint('[NHAP_KH] body: ${const JsonEncoder.withIndent('  ').convert(body)}');
    final res = await ApiClient.instance.dio
        .post('/api/chuyen-xe/$chuyenXeId/nhap-khach-hang', data: body);
    return res.data['xacNhanId'] as int? ?? 0;
  }

  /// Nén ảnh xuống ≤ 1MB bằng cách giảm dần quality (85 → 20, bước 10).
  Future<XFile> _compressToUnder1MB(XFile photo) async {
    const maxBytes = 1 * 1024 * 1024;
    if (await photo.length() <= maxBytes) return photo;

    final tmpDir = Directory.systemTemp;
    var quality = 85;
    XFile? result;

    while (quality >= 20) {
      final outPath =
          '${tmpDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      result = await FlutterImageCompress.compressAndGetFile(
        photo.path,
        outPath,
        quality: quality,
        format: CompressFormat.jpeg,
      );
      if (result != null && await result.length() <= maxBytes) return result;
      quality -= 10;
    }

    return result ?? photo;
  }

  /// Upload ảnh giao hàng cho chuyến xe. Tự động nén xuống ≤ 1MB trước khi gửi.
  Future<String> uploadPhoto(int chuyenXeId, XFile photo) async {
    final compressed = await _compressToUnder1MB(photo);
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        compressed.path,
        filename: compressed.name,
      ),
    });
    final res = await ApiClient.instance.dio.post(
      '/api/chuyen-xe/$chuyenXeId/photos',
      data: formData,
    );
    return res.data['url'] as String;
  }

  /// Lấy kiểm kê xuất hàng của chuyến xe. Trả null nếu chưa lập (HTTP 204).
  Future<KiemKeChuyenXeModel?> getKiemKe(int chuyenXeId) async {
    try {
      final res = await ApiClient.instance.dio.get('/api/chuyen-xe/$chuyenXeId/kiem-ke');
      if (res.statusCode == 204 || res.data == null) return null;
      return KiemKeChuyenXeModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 204) return null;
      rethrow;
    }
  }

  /// Lập mới hoặc thay thế toàn bộ chi tiết kiểm kê xuất hàng của chuyến xe.
  Future<KiemKeChuyenXeModel> upsertKiemKe(
    int chuyenXeId, {
    String? ghiChu,
    required List<Map<String, dynamic>> chiTiet,
  }) async {
    final res = await ApiClient.instance.dio.put(
      '/api/chuyen-xe/$chuyenXeId/kiem-ke',
      data: {
        'ghiChu': ghiChu,
        'chiTiet': chiTiet,
      },
    );
    return KiemKeChuyenXeModel.fromJson(res.data as Map<String, dynamic>);
  }

  /// Xóa toàn bộ biên bản kiểm kê xuất hàng của chuyến xe (kế toán lập sai, muốn làm lại).
  Future<void> deleteKiemKe(int chuyenXeId) async {
    await ApiClient.instance.dio.post('/api/chuyen-xe/$chuyenXeId/kiem-ke/delete');
  }

  /// Upload xác nhận khách hàng (ảnh biên lai ký tay hoặc chữ ký trên app)
  Future<String> uploadXacNhan(
    int xacNhanId, {
    required File file,
    required String loaiXacNhan,  // 'anh' | 'ky'
  }) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        filename: file.uri.pathSegments.last,
      ),
      'loaiXacNhan': loaiXacNhan,
    });
    final res = await ApiClient.instance.dio.post(
      '/api/xac-nhan-khach-hang/$xacNhanId/upload',
      data: formData,
    );
    return res.data['url'] as String;
  }

  /// Get-or-create xác nhận khách hàng — dùng khi lái xe muốn xác nhận sau hoặc lại lỡ bỏ qua
  Future<int> getOrCreateXacNhan(int chuyenXeId, int khachHangId) async {
    final res = await ApiClient.instance.dio.post(
      '/api/xac-nhan-khach-hang/chuyen-xe/$chuyenXeId/khach-hang/$khachHangId',
    );
    return res.data['xacNhanId'] as int;
  }
}
