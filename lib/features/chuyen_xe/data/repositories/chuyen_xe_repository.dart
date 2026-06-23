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

class ChuyenXeRepository {
  /// Lấy danh sách chuyến xe của lái xe theo nhanVienId, hỗ trợ lọc trạng thái, khoảng ngày và phân trang.
  Future<List<ChuyenXeModel>> getList({
    required int nhanVienId,
    String? trangThai,
    DateTime? tuNgay,
    DateTime? denNgay,
    int page = 1,
    int pageSize = 50,
  }) async {
    debugPrint('[ChuyenXe] getList() nhanVienId=$nhanVienId trangThai=$trangThai tuNgay=$tuNgay denNgay=$denNgay');
    try {
      final res = await ApiClient.instance.dio.get(
        '/api/chuyen-xe',
        queryParameters: {
          'nhanVienId': nhanVienId,
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

  /// Lấy chi tiết chuyến xe theo ID kèm danh sách hàng hóa và ảnh đã upload.
  Future<ChuyenXeModel> getById(int id) async {
    debugPrint('[ChuyenXe] GET '+AppConstants.resolvedApiUrl+'/api/chuyen-xe/$id');
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
  }) async {
    final res = await ApiClient.instance.dio.post('/api/chuyen-xe', data: {
      'ngayXuat': ngayXuat.toIso8601String(),
      'xeId': xeId,
      'nhanVienId': nhanVienId,
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

  /// Mobile: lái xe kết thúc chuyến — đổi trangThai sang hoan-thanh.
  Future<void> ketThucMobile(int chuyenXeId) async {
    await ApiClient.instance.dio
        .post('/api/chuyen-xe/$chuyenXeId/ket-thuc-mobile');
  }

  /// Nhập đầy đủ thông tin bán hàng 1 khách hàng: sản phẩm + gas dư + thanh toán.
  Future<void> nhapKhachHang(int chuyenXeId, Map<String, dynamic> body) async {
    final token = await const FlutterSecureStorage().read(key: 'jwt_token');
    debugPrint('[NHAP_KH] POST ${ApiClient.instance.dio.options.baseUrl}/api/chuyen-xe/$chuyenXeId/nhap-khach-hang');
    debugPrint('[NHAP_KH] token: ${token != null ? '${token.substring(0, 20)}...(len=${token.length})' : 'NULL'}');
    debugPrint('[NHAP_KH] body: ${const JsonEncoder.withIndent('  ').convert(body)}');
    await ApiClient.instance.dio
        .post('/api/chuyen-xe/$chuyenXeId/nhap-khach-hang', data: body);
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
}
