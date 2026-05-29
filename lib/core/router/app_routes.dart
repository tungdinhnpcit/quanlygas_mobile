// lib/core/router/app_routes.dart
class AppRoutes {
  static const String login          = '/login';
  static const String home           = '/';
  static const String chuyenXeList   = '/chuyen-xe';
  static const String thongBaoList   = '/thong-bao';
  static const String lichTuan       = '/lich-tuan';
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

  static const String caiDat             = '/cai-dat';
  static const String thongTinTaiKhoan   = '/thong-tin-tai-khoan';
  static const String doiMatKhau         = '/doi-mat-khau';
}
