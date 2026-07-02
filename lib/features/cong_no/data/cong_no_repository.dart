import 'package:dio/dio.dart';
import 'package:quan_ly_gas_app/core/network/api_client.dart';
import 'cong_no_model.dart';

class CongNoRepository {
  final Dio _dio = ApiClient.instance.dio;

  Future<List<CongNoChuyenXeModel>> getDuNo(int khachHangId) async {
    final res = await _dio.get('/api/cong-no/du-no', queryParameters: {'khachHangId': khachHangId});
    return (res.data as List).map((e) => CongNoChuyenXeModel.fromJson(e)).toList();
  }

  // Lấy tất cả khoản nợ còn lại của mọi khách (cho màn chọn thu nợ cũ)
  Future<List<DuNoItemModel>> getDuNoTatCa({int? excludeChuyenXeId}) async {
    final res = await _dio.get('/api/cong-no/du-no-tat-ca', queryParameters: {
      if (excludeChuyenXeId != null) 'excludeChuyenXeId': excludeChuyenXeId,
    });
    return (res.data as List).map((e) => DuNoItemModel.fromJson(e)).toList();
  }

  Future<CongNoChuyenXeModel> traNo({
    required int khachHangId,
    required int chuyenXeId,
    required double soTienTra,
    required String hinhThuc,
    int? taiKhoanId,
    String? ghiChu,
  }) async {
    final res = await _dio.post('/api/cong-no/tra-no', data: {
      'khachHangId': khachHangId,
      'chuyenXeId':  chuyenXeId,
      'soTienTra':   soTienTra,
      'hinhThuc':    hinhThuc,
      if (taiKhoanId != null) 'taiKhoanId': taiKhoanId,
      if (ghiChu != null) 'ghiChu': ghiChu,
    });
    return CongNoChuyenXeModel.fromJson(res.data);
  }

  Future<List<Map<String, dynamic>>> getTaiKhoanNganHang() async {
    final res = await _dio.get('/api/tai-khoan');
    final List data = res.data is List ? res.data : (res.data['items'] ?? []);
    return data
        .where((tk) => tk['loai'] == 'ngan-hang' && tk['isActive'] == true)
        .map<Map<String, dynamic>>((tk) => {
          'id': tk['id'],
          'tenTaiKhoan': tk['tenTaiKhoan'],
        })
        .toList();
  }

}
