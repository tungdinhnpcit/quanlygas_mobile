// lib/features/nhan_vien/data/repositories/nhan_vien_repository.dart
import '../../../../core/network/api_client.dart';
import '../models/nhan_vien_model.dart';

class NhanVienRepository {
  Future<List<NhanVienModel>> getPaged({
    int page = 1,
    int pageSize = 50,
    String? search,
    String? chucVu,
  }) async {
    final params = <String, dynamic>{'page': page, 'pageSize': pageSize};
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (chucVu != null && chucVu.isNotEmpty) params['chucVu'] = chucVu;
    final res = await ApiClient.instance.dio.get('/api/nhan-vien', queryParameters: params);
    final data = res.data;
    final list = data is Map && data['items'] is List
        ? data['items'] as List
        : data is List ? data : [];
    return list.map((e) => NhanVienModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<NhanVienModel> getById(int id) async {
    final res = await ApiClient.instance.dio.get('/api/nhan-vien/$id');
    return NhanVienModel.fromJson(res.data as Map<String, dynamic>);
  }
}
