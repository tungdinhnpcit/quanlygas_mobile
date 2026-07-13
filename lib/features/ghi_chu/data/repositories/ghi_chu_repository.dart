// lib/features/ghi_chu/data/repositories/ghi_chu_repository.dart
import '../../../../core/network/api_client.dart';
import '../models/ghi_chu_model.dart';

/// Gọi API backend cho ghi chú bảo mật — mã hoá mật khẩu thực hiện ở server,
/// client chỉ gửi/nhận plaintext qua HTTPS.
class GhiChuRepository {
  Future<List<GhiChuModel>> getAll() async {
    final res = await ApiClient.instance.dio.get('/api/ghi-chu-bao-mat');
    return (res.data as List)
        .map((e) => GhiChuModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> save(GhiChuModel m) async {
    final data = {
      'tieuDe': m.tieuDe.trim(),
      'taiKhoan': m.taiKhoan.trim(),
      'matKhau': m.matKhau,
      'ghiChu': m.ghiChu.trim(),
    };
    if (m.id == null) {
      await ApiClient.instance.dio.post('/api/ghi-chu-bao-mat', data: data);
    } else {
      await ApiClient.instance.dio.put('/api/ghi-chu-bao-mat/${m.id}', data: data);
    }
  }

  Future<void> delete(int id) =>
      ApiClient.instance.dio.post('/api/ghi-chu-bao-mat/$id/delete');
}
