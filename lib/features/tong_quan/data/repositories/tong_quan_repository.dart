// lib/features/tong_quan/data/repositories/tong_quan_repository.dart
import '../../../../core/network/api_client.dart';
import '../models/tong_quan_model.dart';

class TongQuanRepository {
  Future<DoanhThuResult> getDoanhThu(DateTime tuNgay, DateTime denNgay) async {
    final res = await ApiClient.instance.dio.get(
      '/api/bao-cao/doanh-thu',
      queryParameters: {
        'tuNgay': tuNgay.toIso8601String(),
        'denNgay': denNgay.toIso8601String(),
      },
    );
    return DoanhThuResult.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<TonKhoItem>> getTonKho() async {
    final res = await ApiClient.instance.dio.get('/api/bao-cao/ton-kho');
    final data = res.data;
    final list = (data is Map ? data['items'] : data) as List? ?? [];
    return list.map((e) => TonKhoItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<NhapXuatItem>> getNhapXuat(DateTime tuNgay, DateTime denNgay) async {
    final res = await ApiClient.instance.dio.get(
      '/api/bao-cao/nhap-xuat',
      queryParameters: {
        'tuNgay': tuNgay.toIso8601String(),
        'denNgay': denNgay.toIso8601String(),
      },
    );
    final data = res.data;
    final list = (data is Map ? data['items'] : data) as List? ?? [];
    return list.map((e) => NhapXuatItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<TongQuanDashboard> getTongQuan(DateTime tuNgay, DateTime denNgay) async {
    final res = await ApiClient.instance.dio.get(
      '/api/bao-cao/tong-quan',
      queryParameters: {
        'tuNgay': tuNgay.toIso8601String(),
        'denNgay': denNgay.toIso8601String(),
      },
    );
    return TongQuanDashboard.fromJson(res.data as Map<String, dynamic>);
  }

  /// Lấy chi tiết bán hàng cho 1 khách hàng trong khoảng ngày
  Future<List<DaiLyBanHangModel>> getDaiLyBanHang(
      int khachHangId, DateTime tuNgay, DateTime denNgay) async {
    final res = await ApiClient.instance.dio.get(
      '/api/bao-cao/dai-ly/$khachHangId/ban-hang',
      queryParameters: {
        'tuNgay':  tuNgay.toIso8601String(),
        'denNgay': denNgay.toIso8601String(),
      },
    );
    final list = res.data as List? ?? [];
    return list
        .map((e) => DaiLyBanHangModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Lấy danh sách khách hàng active lâu chưa mua, sắp xếp theo số ngày giảm dần
  Future<List<KhachHangChuaMuaModel>> getKhachHangChuaMua() async {
    final res = await ApiClient.instance.dio.get('/api/bao-cao/khach-hang-chua-mua');
    final list = res.data as List? ?? [];
    return list
        .map((e) => KhachHangChuaMuaModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
