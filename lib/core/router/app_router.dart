// lib/core/router/app_router.dart
import 'package:flutter/cupertino.dart' show CupertinoPage;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/data/auth_repository.dart';
import '../network/api_client.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/chuyen_xe/presentation/screens/chuyen_xe_detail_screen.dart';
import '../../features/chuyen_xe/presentation/screens/chuyen_xe_list_screen.dart';
import '../../features/lich_tuan/presentation/screens/lich_tuan_screen.dart';
import '../../features/thong_bao/presentation/screens/thong_bao_detail_screen.dart';
import '../../features/thong_bao/presentation/screens/thong_bao_list_screen.dart';
import '../../features/nhan_vien/presentation/screens/nhan_vien_list_screen.dart';
import '../../features/nhan_vien/presentation/screens/nhan_vien_detail_screen.dart';
import '../../features/xe/presentation/screens/xe_list_screen.dart';
import '../../features/xe/presentation/screens/xe_detail_screen.dart';
import '../../features/mat_hang/presentation/screens/mat_hang_list_screen.dart';
import '../../features/mat_hang/presentation/screens/mat_hang_detail_screen.dart';
import '../../features/nha_cung_cap/presentation/screens/nha_cung_cap_list_screen.dart';
import '../../features/nha_cung_cap/presentation/screens/nha_cung_cap_detail_screen.dart';
import '../../features/khach_hang/presentation/screens/khach_hang_list_screen.dart';
import '../../features/khach_hang/presentation/screens/khach_hang_detail_screen.dart';
import '../../features/tong_quan/presentation/screens/tong_quan_screen.dart';
import '../../features/cai_dat/presentation/screens/cai_dat_screen.dart';
import '../../features/cai_dat/presentation/screens/thong_tin_tai_khoan_screen.dart';
import '../../features/cai_dat/presentation/screens/doi_mat_khau_screen.dart';
import '../services/notification_service.dart';
import 'app_routes.dart';

final _rootNavigatorKey  = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();
final _storage           = const FlutterSecureStorage();

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.home,
    redirect: (context, state) async {
      final token   = await _storage.read(key: 'jwt_token');
      final isLogin = state.matchedLocation == AppRoutes.login;
      if (token == null && !isLogin) return AppRoutes.login;
      if (token != null && isLogin)  return AppRoutes.home;
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const LoginScreen(),
      ),
      // Detail routes tại root navigator — full-screen, hỗ trợ swipe-back và nút back vật lý
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/chuyen-xe/:id',
        pageBuilder: (_, state) => CupertinoPage(
          key: state.pageKey,
          child: ChuyenXeDetailScreen(chuyenXeId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/thong-bao/:id',
        pageBuilder: (_, state) => CupertinoPage(
          key: state.pageKey,
          child: ThongBaoDetailScreen(thongBaoId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/nhan-vien/:id',
        pageBuilder: (_, state) => CupertinoPage(
          key: state.pageKey,
          child: NhanVienDetailScreen(nhanVienId: int.parse(state.pathParameters['id']!)),
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/xe/:id',
        pageBuilder: (_, state) => CupertinoPage(
          key: state.pageKey,
          child: XeDetailScreen(xeId: int.parse(state.pathParameters['id']!)),
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/mat-hang/:id',
        pageBuilder: (_, state) => CupertinoPage(
          key: state.pageKey,
          child: MatHangDetailScreen(matHangId: int.parse(state.pathParameters['id']!)),
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/nha-cung-cap/:id',
        pageBuilder: (_, state) => CupertinoPage(
          key: state.pageKey,
          child: NhaCungCapDetailScreen(nhaCungCapId: int.parse(state.pathParameters['id']!)),
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/khach-hang/:id',
        pageBuilder: (_, state) => CupertinoPage(
          key: state.pageKey,
          child: KhachHangDetailScreen(id: int.parse(state.pathParameters['id']!)),
        ),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (_, __, child) => _MainShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (_, __) => const HomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.chuyenXeList,
            builder: (_, __) => const ChuyenXeListScreen(),
          ),
          GoRoute(
            path: AppRoutes.thongBaoList,
            builder: (_, __) => const ThongBaoListScreen(),
          ),
          GoRoute(
            path: AppRoutes.nhanVienList,
            builder: (_, __) => const NhanVienListScreen(),
          ),
          GoRoute(
            path: AppRoutes.xeList,
            builder: (_, __) => const XeListScreen(),
          ),
          GoRoute(
            path: AppRoutes.matHangList,
            builder: (_, __) => const MatHangListScreen(),
          ),
          GoRoute(
            path: AppRoutes.nhaCungCapList,
            builder: (_, __) => const NhaCungCapListScreen(),
          ),
          GoRoute(
            path: AppRoutes.khachHangList,
            builder: (_, __) => const KhachHangListScreen(),
          ),
          GoRoute(
            path: AppRoutes.tongQuan,
            builder: (_, __) => const TongQuanScreen(),
          ),
          GoRoute(
            path: AppRoutes.lichTuan,
            builder: (_, __) => const LichTuanScreen(),
          ),
          GoRoute(
            path: AppRoutes.caiDat,
            builder: (_, __) => const CaiDatScreen(),
          ),
          GoRoute(
            path: AppRoutes.thongTinTaiKhoan,
            builder: (_, __) => const ThongTinTaiKhoanScreen(),
          ),
          GoRoute(
            path: AppRoutes.doiMatKhau,
            builder: (_, __) => const DoiMatKhauScreen(),
          ),
        ],
      ),
    ],
  );

  NotificationService.setNavigateCallback((route) => router.go(route));
  ApiClient.setNavigateToLogin((route) => router.go(route));

  return router;
});

// ------------------------------------------------------------------
// _MainShell — bottom nav 3 tab cố định
// ------------------------------------------------------------------

class _MainShell extends ConsumerStatefulWidget {
  const _MainShell({required this.child});
  final Widget child;

  @override
  ConsumerState<_MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<_MainShell> {
  int _currentIndex = 0;

  static const _tabs = [
    _TabDef(
      route:        AppRoutes.home,
      icon:         Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      label:        'Trang chủ',
    ),
    _TabDef(
      route:        AppRoutes.thongBaoList,
      icon:         Icons.notifications_outlined,
      selectedIcon: Icons.notifications_rounded,
      label:        'Thông báo',
    ),
    _TabDef(
      route:        AppRoutes.caiDat,
      icon:         Icons.settings_outlined,
      selectedIcon: Icons.settings_rounded,
      label:        'Cài đặt',
    ),
  ];

  static const _tabTitles = ['Trang chủ', 'Thông báo', 'Cài đặt'];

  // Tiêu đề cho các route chức năng (không phải 3 tab cố định)
  static const _featureTitles = {
    AppRoutes.chuyenXeList:     'Chuyến xe',
    AppRoutes.nhanVienList:     'Nhân viên',
    AppRoutes.xeList:           'Xe',
    AppRoutes.matHangList:      'Mặt hàng',
    AppRoutes.nhaCungCapList:   'Nhà cung cấp',
    AppRoutes.khachHangList:    'Khách hàng',
    AppRoutes.tongQuan:         'Tổng quan',
    AppRoutes.lichTuan:         'Lịch tuần',
    AppRoutes.thongTinTaiKhoan: 'Thông tin tài khoản',
    AppRoutes.doiMatKhau:       'Đổi mật khẩu',
  };

  void _onTabTapped(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
    context.go(_tabs[index].route);
  }

  Future<void> _logout() async {
    await AuthRepository().logout();
    if (mounted) context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final location    = GoRouterState.of(context).uri.path;
    final isTabRoute  = location == AppRoutes.home ||
        _tabs.any((t) => t.route == location);
    final title       = _featureTitles[location] ?? _tabTitles[_currentIndex];

    void goBack() {
      if (context.canPop()) context.pop();
      else context.go(AppRoutes.home);
    }

    return GestureDetector(
      // Vuốt phải để quay lại — chỉ hoạt động trên màn hình chức năng
      onHorizontalDragEnd: (details) {
        if (!isTabRoute && (details.primaryVelocity ?? 0) > 300) { goBack(); }
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: isTabRoute
              ? null
              : IconButton(
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'Quay lại',
                  onPressed: goBack,
                ),
          title: Text(title),
          actions: [
            if (isTabRoute)
              IconButton(
                icon: const Icon(Icons.logout),
                tooltip: 'Đăng xuất',
                onPressed: _logout,
              ),
          ],
        ),
        body: widget.child,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: _onTabTapped,
          destinations: _tabs
              .map((t) => NavigationDestination(
                    icon:         Icon(t.icon),
                    selectedIcon: Icon(t.selectedIcon),
                    label:        t.label,
                  ))
              .toList(),
        ),
      ),
    );
  }
}

class _TabDef {
  final String route;
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const _TabDef({
    required this.route,
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}
