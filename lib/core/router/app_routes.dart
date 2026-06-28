// lib/core/router/app_routes.dart
class AppRoutes {
  static const String login          = '/login';
  static const String home           = '/';
  static const String chuyenXeList   = '/chuyen-xe';
  static const String thongBaoList   = '/thong-bao';
  static const String lichTuan       = '/lich-tuan';
  static const String chamCong       = '/cham-cong';
  static const String nhanVienList   = '/nhan-vien';
  static const String xeList         = '/xe';
  static const String matHangList    = '/mat-hang';
  static const String nhaCungCapList = '/nha-cung-cap';

  static String chuyenXeDetail(String id)   => '/chuyen-xe/$id';
  static String thongBaoDetail(String id)   => '/thong-bao/$id';
  static String nhanVienDetail(int id)      => '/nhan-vien/$id';
  static String xeDetail(int id)            => '/xe/$id';
  static String matHangDetail(int id)       => '/mat-hang/$id';
  static String nhaCungCapDetail(int id)    => '/nha-cung-cap/$id';

  static const String khachHangList        = '/khach-hang';
  static String khachHangDetail(int id)    => '/khach-hang/$id';

  static const String tongQuan             = '/tong-quan';

  static const String daiLyChuaMua        = '/dai-ly-chua-mua';
  static String daiLyChiTiet(
    String id, {
    DateTime? tuNgay,
    DateTime? denNgay,
  }) {
    final q = <String, String>{};
    if (tuNgay != null) q['tuNgay'] = tuNgay.toIso8601String().substring(0, 10);
    if (denNgay != null) q['denNgay'] = denNgay.toIso8601String().substring(0, 10);
    final qs = q.isEmpty ? '' : '?${q.entries.map((e) => '${e.key}=${e.value}').join('&')}';
    return '/dai-ly-chi-tiet/$id$qs';
  }

  static const String caiDat             = '/cai-dat';
  static const String thongTinTaiKhoan   = '/thong-tin-tai-khoan';
  static const String doiMatKhau         = '/doi-mat-khau';

  // Mobile driver — nhập bán hàng
  static const String batDauChuyen       = '/bat-dau-chuyen';
  static const String banHangTheoNgay    = '/ban-hang/theo-ngay';
  static String nhapBanHang(int chuyenXeId) => '/ban-hang/$chuyenXeId/nhap';
  static const String taoKhachHang       = '/khach-hang/tao-moi';
  static const String timKiemKhachHang   = '/tim-kiem-khach-hang';
  static const String timKiemPhuXe       = '/tim-kiem-phu-xe';
  static const String dongBo             = '/cai-dat/dong-bo';
}
