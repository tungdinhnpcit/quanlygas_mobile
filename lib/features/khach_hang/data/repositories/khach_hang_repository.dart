// lib/features/khach_hang/data/repositories/khach_hang_repository.dart
import 'dart:io';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../models/khach_hang_model.dart';

class KhachHangRepository {
  /// Lấy danh sách khách hàng phân trang + tìm kiếm
  Future<({List<KhachHangModel> items, int totalCount})> getPaged({
    int page = 1,
    int pageSize = 50,
    String? search,
  }) async {
    final params = <String, dynamic>{'page': page, 'pageSize': pageSize};
    if (search != null && search.isNotEmpty) params['search'] = search;
    final res = await ApiClient.instance.dio.get('/api/khach-hang', queryParameters: params);
    final data = res.data;
    if (data is Map) {
      final items = (data['items'] as List? ?? [])
          .map((e) => KhachHangModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return (items: items, totalCount: data['totalCount'] as int? ?? items.length);
    }
    final items = (data as List)
        .map((e) => KhachHangModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return (items: items, totalCount: items.length);
  }

  /// Lấy chi tiết một khách hàng theo ID
  Future<KhachHangModel> getById(int id) async {
    final res = await ApiClient.instance.dio.get('/api/khach-hang/$id');
    return KhachHangModel.fromJson(res.data as Map<String, dynamic>);
  }

  /// Cập nhật tọa độ GPS của cửa hàng khách hàng
  Future<void> updateViTri(KhachHangModel kh, double lat, double lng) async {
    await ApiClient.instance.dio.put(
      '/api/khach-hang/${kh.id}',
      data: {
        'maKhachHang':  kh.maKhachHang,
        'tenKhachHang': kh.tenKhachHang,
        'diaChi':       kh.diaChi,
        'soDienThoai':  kh.soDienThoai,
        'email':        kh.email,
        'latitude':     lat,
        'longitude':    lng,
        'isActive':     kh.isActive,
      },
    );
  }

  /// Upload ảnh cửa hàng — multipart/form-data
  Future<String> uploadAnh(int id, File file) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        filename: file.path.split(Platform.pathSeparator).last,
      ),
    });
    final res = await ApiClient.instance.dio
        .post('/api/khach-hang/$id/upload-anh', data: formData);
    return (res.data as Map<String, dynamic>)['anhCuaHang'] as String;
  }
}
