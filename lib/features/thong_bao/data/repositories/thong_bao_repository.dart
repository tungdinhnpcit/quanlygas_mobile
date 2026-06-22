// lib/features/thong_bao/data/repositories/thong_bao_repository.dart
import '../../../../core/network/api_client.dart';
import '../models/thong_bao_model.dart';

class ThongBaoRepository {
  /// Danh sách thông báo của user (mới nhất trước)
  Future<List<ThongBaoModel>> getList(int userId) async {
    final res = await ApiClient.instance.dio
        .get('/api/thong-bao', queryParameters: {'userId': userId, 'pageSize': 100});
    final data  = res.data;
    final items = data is Map ? (data['items'] as List? ?? []) : (data as List? ?? []);
    return items.map((e) => ThongBaoModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Chi tiết một thông báo — không phụ thuộc list cache (dùng khi mở từ notification tap)
  Future<ThongBaoModel> getById(int id) async {
    final res = await ApiClient.instance.dio.get('/api/thong-bao/$id');
    return ThongBaoModel.fromJson(res.data as Map<String, dynamic>);
  }

  /// Đánh dấu đã đọc
  Future<void> markAsRead(int id) async {
    await ApiClient.instance.dio.put('/api/thong-bao/$id/doc');
  }

  /// Đếm số chưa đọc (cho badge)
  Future<int> getSoChuaDoc(int userId) async {
    final res = await ApiClient.instance.dio
        .get('/api/thong-bao/so-chua-doc', queryParameters: {'userId': userId});
    final data = res.data;
    return (data is Map ? data['count'] as int? : null) ?? 0;
  }

  /// Đánh dấu tất cả thông báo chưa đọc là đã đọc
  Future<void> markAllAsRead(int userId) async {
    await ApiClient.instance.dio.put(
      '/api/thong-bao/doc-tat-ca',
      queryParameters: {'userId': userId},
    );
  }
}
