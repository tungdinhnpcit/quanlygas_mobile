class CongNoChuyenXeModel {
  final int chuyenXeId;
  final String maChuyenXe;
  final String ngayXuat;
  final double soTienNo;
  final double daTra;
  final double conNo;

  CongNoChuyenXeModel.fromJson(Map<String, dynamic> j)
      : chuyenXeId = j['chuyenXeId'],
        maChuyenXe = j['maChuyenXe'] ?? '',
        ngayXuat   = j['ngayXuat'] ?? '',
        soTienNo   = (j['soTienNo'] as num).toDouble(),
        daTra      = (j['daTra'] as num).toDouble(),
        conNo      = (j['conNo'] as num).toDouble();
}

// Một khoản nợ còn lại (khách + chuyến + số nợ) — dùng cho màn chọn thu nợ cũ
class DuNoItemModel {
  final int khachHangId;
  final String? maKhachHang;
  final String tenKhachHang;
  final String? diaChi;
  final int chuyenXeId;
  final String maChuyenXe;
  final String ngayXuat;
  final double soTienNo;
  final double daTra;
  final double conNo;

  DuNoItemModel.fromJson(Map<String, dynamic> j)
      : khachHangId  = j['khachHangId'],
        maKhachHang  = j['maKhachHang'],
        tenKhachHang = j['tenKhachHang'] ?? '',
        diaChi       = j['diaChi'],
        chuyenXeId   = j['chuyenXeId'],
        maChuyenXe   = j['maChuyenXe'] ?? '',
        ngayXuat     = j['ngayXuat'] ?? '',
        soTienNo     = (j['soTienNo'] as num).toDouble(),
        daTra        = (j['daTra'] as num).toDouble(),
        conNo        = (j['conNo'] as num).toDouble();
}
