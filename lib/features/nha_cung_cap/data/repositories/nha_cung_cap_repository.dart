// lib/features/nha_cung_cap/data/repositories/nha_cung_cap_repository.dart
import '../../../../core/network/api_client.dart';
import '../models/nha_cung_cap_model.dart';

class NhaCungCapRepository {
  Future<List<NhaCungCapModel>> getPaged({int page = 1, int pageSize = 50, String? search}) async {
    final params = <String, dynamic>{'page': page, 'pageSize': pageSize};
    if (search != null && search.isNotEmpty) params['search'] = search;
    final res = await ApiClient.instance.dio.get('/api/nha-cung-cap', queryParameters: params);
    final data = res.data;
    final list = data is Map && data['items'] is List
        ? data['items'] as List
        : data is List ? data : [];
    return list.map((e) => NhaCungCapModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<NhaCungCapModel> getById(int id) async {
    final res = await ApiClient.instance.dio.get('/api/nha-cung-cap/$id');
    return NhaCungCapModel.fromJson(res.data as Map<String, dynamic>);
  }
}
