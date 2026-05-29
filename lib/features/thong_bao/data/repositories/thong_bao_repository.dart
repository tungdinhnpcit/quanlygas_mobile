// lib/features/thong_bao/data/repositories/thong_bao_repository.dart
import '../../../../core/network/api_client.dart';
import '../models/thong_bao_model.dart';

class ThongBaoRepository {
  Future<List<ThongBaoModel>> getHistory(String recipientId) async {
    final res = await ApiClient.instance.dio
        .get('/api/notifications/history/$recipientId');
    final data = res.data;
    final list = data is List
        ? data
        : (data is Map && data['data'] is List)
            ? data['data'] as List
            : (data is Map && data['notifications'] is List)
                ? data['notifications'] as List
                : [];
    return list
        .map((e) => ThongBaoModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
