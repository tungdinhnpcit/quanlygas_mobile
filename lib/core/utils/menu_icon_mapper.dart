// lib/core/utils/menu_icon_mapper.dart
import 'package:flutter/material.dart';

IconData mapMenuIcon(String menuCode) {
  return switch (menuCode.toUpperCase()) {
    'DASHBOARD'                    => Icons.dashboard_rounded,
    'CHUYEN_XE'   || 'CHUYENXE'   => Icons.local_shipping_rounded,
    'BAT_DAU_CHUYEN' || 'BATDAUCHUYEN' => Icons.play_circle_rounded,
    'NHAP_HANG'   || 'NHAPHANG'    => Icons.move_to_inbox_rounded,
    'TON_KHO'     || 'TONKHO'      => Icons.warehouse_rounded,
    'BAO_CAO'     || 'BAOCAO'      => Icons.bar_chart_rounded,
    'KHACH_HANG'  || 'KHACHHANG'   => Icons.people_rounded,
    'MAT_HANG'    || 'MATHANG'     => Icons.inventory_2_rounded,
    'NHAN_VIEN'   || 'NHANVIEN'    => Icons.badge_rounded,
    'XE'                           => Icons.directions_car_rounded,
    'NHA_CUNG_CAP'|| 'NHACUNGCAP'  => Icons.business_rounded,
    'TAI_KHOAN_CT'|| 'TAIKHOANCT'  => Icons.account_balance_rounded,
    'DONG_TIEN'   || 'DONGTIEN'    => Icons.currency_exchange_rounded,
    'THONG_BAO'   || 'THONGBAO'    => Icons.notifications_rounded,
    'DON_HANG'    || 'DONHANG'     => Icons.shopping_cart_rounded,
    'QUAN_LY'     || 'QUANLY'      => Icons.manage_accounts_rounded,
    'LICH_TUAN'   || 'LICHTUAN'    => Icons.calendar_today_rounded,
    'SAN_PHAM'    || 'SANPHAM'     => Icons.inventory_2_rounded,
    'KHO'                          => Icons.warehouse_rounded,
    'CONG_NO'     || 'CONGNO'      => Icons.account_balance_wallet_rounded,
    'THANH_TOAN'  || 'THANHTOAN'   => Icons.payment_rounded,
    // Hệ thống
    'HT_TAIKHOAN'                  => Icons.manage_accounts_rounded,
    'HT_NHOMQUYEN'                 => Icons.shield_rounded,
    'HT_PHANQUYEN'                 => Icons.security_rounded,
    'HT_CHUCNANG' || 'HT_MENU'    => Icons.menu_book_rounded,
    'THAN_SO_HOC'                  => Icons.auto_awesome_rounded,
    _                              => Icons.apps_rounded,
  };
}

const List<Color> kMenuCardColors = [
  Color(0xFF1565C0), // blue 800
  Color(0xFF00695C), // teal 800
  Color(0xFF4527A0), // deep purple 800
  Color(0xFF558B2F), // light green 800
  Color(0xFFAD1457), // pink 800
  Color(0xFF00838F), // cyan 800
  Color(0xFFE65100), // deep orange 800
  Color(0xFF283593), // indigo 800
  Color(0xFF6A1B9A), // purple 800
  Color(0xFF2E7D32), // green 800
];

Color menuCardColor(int index) => kMenuCardColors[index % kMenuCardColors.length];
