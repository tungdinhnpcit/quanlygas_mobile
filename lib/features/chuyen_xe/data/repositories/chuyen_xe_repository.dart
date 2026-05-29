// lib/features/chuyen_xe/data/repositories/chuyen_xe_repository.dart
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

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
    final res = await ApiClient.instance.dio.get('/api/chuyen-xe/$id');
    return ChuyenXeModel.fromJson(res.data as Map<String, dynamic>);
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
