// lib/features/xe/data/repositories/xe_repository.dart
import '../../../../core/network/api_client.dart';
import '../models/xe_model.dart';

class XeRepository {
  Future<List<XeModel>> getPaged({int page = 1, int pageSize = 50, String? search}) async {
    final params = <String, dynamic>{'page': page, 'pageSize': pageSize};
    if (search != null && search.isNotEmpty) params['search'] = search;
    final res = await ApiClient.instance.dio.get('/api/xe', queryParameters: params);
    final data = res.data;
    final list = data is Map && data['items'] is List
        ? data['items'] as List
        : data is List ? data : [];
    return list.map((e) => XeModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<XeModel> getById(int id) async {
    final res = await ApiClient.instance.dio.get('/api/xe/$id');
    return XeModel.fromJson(res.data as Map<String, dynamic>);
  }
}
