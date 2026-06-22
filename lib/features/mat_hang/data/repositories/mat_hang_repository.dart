// lib/features/mat_hang/data/repositories/mat_hang_repository.dart
import '../../../../core/network/api_client.dart';
import '../models/mat_hang_model.dart';

class MatHangRepository {
  Future<List<MatHangModel>> getPaged({int page = 1, int pageSize = 50, String? search}) async {
    final params = <String, dynamic>{'page': page, 'pageSize': pageSize};
    if (search != null && search.isNotEmpty) params['search'] = search;
    final res = await ApiClient.instance.dio.get('/api/mat-hang', queryParameters: params);
    final data = res.data;
    final list = data is Map && data['items'] is List
        ? data['items'] as List
        : data is List ? data : [];
    return list.map((e) => MatHangModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<MatHangModel> getById(int id) async {
    final res = await ApiClient.instance.dio.get('/api/mat-hang/$id');
    return MatHangModel.fromJson(res.data as Map<String, dynamic>);
  }
}
