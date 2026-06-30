// lib/core/router/app_router.dart
import 'package:flutter/cupertino.dart' show CupertinoPage;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemUiOverlayStyle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';

import '../network/api_client.dart';
import '../../features/auth/presentation/screens/login_screen_v3.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/chuyen_xe/presentation/screens/chuyen_xe_detail_screen.dart';
import '../../features/chuyen_xe/presentation/screens/chuyen_xe_list_screen.dart';
import '../../features/lich_tuan/presentation/screens/lich_tuan_screen.dart';
import '../../features/thong_bao/presentation/screens/thong_bao_detail_screen.dart';
import '../../features/thong_bao/presentation/screens/thong_bao_list_screen.dart';
import '../../features/cham_cong/presentation/screens/cham_cong_screen.dart';
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
import '../../features/tong_quan/presentation/screens/dai_ly_chi_tiet_screen.dart';
import '../../features/tong_quan/presentation/screens/dai_ly_chua_mua_screen.dart';
import '../../features/cai_dat/presentation/screens/cai_dat_screen.dart';
import '../../features/cai_dat/presentation/screens/thong_tin_tai_khoan_screen.dart';
import '../../features/cai_dat/presentation/screens/doi_mat_khau_screen.dart';
import '../../features/cai_dat/presentation/screens/dong_bo_screen.dart';
import '../../features/chuyen_xe/presentation/screens/bat_dau_chuyen_screen.dart';
import '../../features/chuyen_xe/presentation/screens/tim_kiem_khach_hang_screen.dart';
import '../../features/chuyen_xe/presentation/screens/tim_kiem_phu_xe_screen.dart';
import '../../features/chuyen_xe/presentation/screens/tim_kiem_mat_hang_screen.dart';
import '../../features/chuyen_xe/presentation/screens/tim_kiem_nha_cung_cap_screen.dart';
import '../../features/chuyen_xe/presentation/screens/chuyen_xe_theo_ngay_screen.dart';
import '../../features/chuyen_xe/presentation/screens/nhap_ban_hang_screen.dart';
import '../../features/chuyen_xe/presentation/screens/sua_ban_hang_khach_hang_screen.dart';
import '../../features/chuyen_xe/data/models/chuyen_xe_model.dart';
import '../../features/khach_hang/presentation/screens/tao_khach_hang_screen.dart';
import '../../features/kiem_ke/presentation/screens/kiem_ke_list_screen.dart';
import '../../features/kiem_ke/presentation/screens/kiem_ke_nhap_screen.dart';
import '../../features/kiem_ke/presentation/screens/kiem_ke_tao_chuyen_screen.dart';
import '../../features/thong_bao/presentation/providers/thong_bao_provider.dart';
import '../database/local_database.dart';
import '../providers/sync_provider.dart';
import '../services/background_polling_service.dart';
import '../services/connectivity_service.dart';
import '../services/notification_service.dart';
import '../services/sync_service.dart';
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
        builder: (_, __) => const LoginScreenV3(),
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
        path: AppRoutes.taoKhachHang,
        pageBuilder: (_, state) => CupertinoPage(
          key: state.pageKey,
          child: const TaoKhachHangScreen(),
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.timKiemKhachHang,
        pageBuilder: (_, state) => CupertinoPage(
          key: state.pageKey,
          child: const TimKiemKhachHangScreen(),
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.timKiemPhuXe,
        pageBuilder: (_, state) => CupertinoPage(
          key: state.pageKey,
          child: const TimKiemPhuXeScreen(),
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.timKiemMatHang,
        pageBuilder: (_, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return CupertinoPage(
            key: state.pageKey,
            child: TimKiemMatHangScreen(
              nhaCungCapId: extra?['nhaCungCapId'] as int?,
            ),
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.timKiemNhaCungCap,
        pageBuilder: (_, state) => CupertinoPage(
          key: state.pageKey,
          child: const TimKiemNhaCungCapScreen(),
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
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.batDauChuyen,
        pageBuilder: (_, state) => CupertinoPage(
          key: state.pageKey,
          child: const BatDauChuyenScreen(),
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.banHangTheoNgay,
        pageBuilder: (_, state) => CupertinoPage(
          key: state.pageKey,
          child: ChuyenXeTheoNgayScreen(
              args: state.extra as ChuyenXeTheoNgayArgs),
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/ban-hang/:id/nhap',
        pageBuilder: (_, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return CupertinoPage(
            key: state.pageKey,
            child: NhapBanHangScreen(
              chuyenXeServerId: int.tryParse(state.pathParameters['id']!),
              phuXeId: extra?['phuXeId'] as int?,
            ),
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/ban-hang/offline/:localId/nhap',
        pageBuilder: (_, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return CupertinoPage(
            key: state.pageKey,
            child: NhapBanHangScreen(
              chuyenXeLocalId: int.tryParse(state.pathParameters['localId']!),
              phuXeId: extra?['phuXeId'] as int?,
            ),
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/ban-hang/:chuyenXeId/khach-hang/:khachHangId/sua',
        pageBuilder: (_, state) {
          final cxId  = int.tryParse(state.pathParameters['chuyenXeId']  ?? '') ?? 0;
          final khId  = int.tryParse(state.pathParameters['khachHangId'] ?? '') ?? 0;
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final rows  = (extra['rows'] as List?)
              ?.map((e) => e as BanHangKhachHangModel).toList() ?? [];
          return CupertinoPage(
            key: state.pageKey,
            child: SuaBanHangKhachHangScreen(
              chuyenXeId: cxId,
              khachHangId: khId,
              rows: rows,
              canEdit: cxId > 0,
            ),
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.kiemKeTaoChuyen,
        pageBuilder: (_, state) => CupertinoPage(
          key: state.pageKey,
          child: const KiemKeTaoChuyenScreen(),
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/kiem-ke/:chuyenXeId/nhap',
        pageBuilder: (_, state) => CupertinoPage(
          key: state.pageKey,
          child: KiemKeNhapScreen(
            chuyenXeId: int.parse(state.pathParameters['chuyenXeId']!),
          ),
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/dai-ly-chi-tiet/:id',
        pageBuilder: (_, state) => CupertinoPage(
          key: state.pageKey,
          child: DaiLyChiTietScreen(
            khachHangId: int.parse(state.pathParameters['id']!),
            tuNgay: state.uri.queryParameters['tuNgay'] != null
                ? DateTime.tryParse(state.uri.queryParameters['tuNgay']!)
                : null,
            denNgay: state.uri.queryParameters['denNgay'] != null
                ? DateTime.tryParse(state.uri.queryParameters['denNgay']!)
                : null,
          ),
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
            path: AppRoutes.daiLyChuaMua,
            builder: (_, __) => const DaiLyChuaMuaScreen(),
          ),
          GoRoute(
            path: AppRoutes.lichTuan,
            builder: (_, __) => const LichTuanScreen(),
          ),
          GoRoute(
            path: AppRoutes.chamCong,
            builder: (_, __) => const ChamCongScreen(),
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
          GoRoute(
            path: AppRoutes.dongBo,
            builder: (_, __) => const DongBoScreen(),
          ),
          GoRoute(
            path: AppRoutes.kiemKeList,
            builder: (_, __) => const KiemKeListScreen(),
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
  bool _syncChecked = false;

  @override
  void initState() {
    super.initState();
    _runDailySyncIfNeeded();
    _listenConnectivity();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runPostLoginTasks());
  }

  Future<void> _runDailySyncIfNeeded() async {
    if (_syncChecked) return;
    _syncChecked = true;
    try {
      final should = await SyncService.instance.shouldSyncToday();
      if (!should) return;
      final online = await ConnectivityService.instance.checkOnline();
      if (!online) return;
      final result = await SyncService.instance.syncCatalog();
      // Chỉ đánh dấu đã sync khi có ít nhất 1 loại dữ liệu được tải về thành công
      if (result.totalSynced > 0) {
        await SyncService.instance.markSyncedToday();
      }
      if (result.hasNewItems && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result.summary),
          duration: const Duration(seconds: 4),
        ));
      }
    } catch (_) {}
  }

  void _listenConnectivity() {
    ConnectivityService.instance.onChanged.listen((online) async {
      if (!online || !mounted) return;
      final pending = await LocalDatabase.instance.getPendingCount();
      if (pending > 0 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Có $pending bản ghi chưa đồng bộ.'),
          action: SnackBarAction(
            label: 'Đồng bộ',
            onPressed: () =>
                ref.read(syncNotifierProvider.notifier).uploadPending(),
          ),
          duration: const Duration(seconds: 6),
        ));
      }
    });
  }

  /// Chạy background sau khi shell mount lần đầu:
  /// đăng ký FCM, đăng ký background polling, kiểm tra thông báo chưa đọc.
  Future<void> _runPostLoginTasks() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'jwt_token');
    if (token == null || !mounted) return;  // Chưa login → bỏ qua

    // 1. Đăng ký FCM token với backend
    try {
      final fcmToken = await NotificationService.getFcmToken();
      if (fcmToken != null) {
        await ApiClient.instance.dio.put(
          '/api/auth/device-token',
          data: {'fcmToken': fcmToken},
        );
        debugPrint('[POST-LOGIN] FCM token registered');
      }
      // Tự động re-register khi FCM token thay đổi
      NotificationService.onTokenRefresh.listen((newToken) async {
        try {
          await ApiClient.instance.dio.put('/api/auth/device-token',
              data: {'fcmToken': newToken});
          debugPrint('[POST-LOGIN] FCM token refreshed');
        } catch (e) {
          debugPrint('[POST-LOGIN] FCM token refresh failed: $e');
        }
      });
    } catch (e) {
      debugPrint('[POST-LOGIN] FCM registration failed: $e');
    }

    // 2. Đăng ký background polling (workmanager)
    try {
      await BackgroundPollingService.registerPeriodicTask();
      debugPrint('[POST-LOGIN] Background polling registered');
    } catch (e) {
      debugPrint('[POST-LOGIN] Background polling failed: $e');
    }

    // 3. Kiểm tra thông báo chưa đọc → hiển thị local notification nếu có mới
    try {
      final userIdStr = await storage.read(key: 'user_id');
      final userId = int.tryParse(userIdStr ?? '');
      if (userId == null || !mounted) return;

      final res = await ApiClient.instance.dio.get(
        '/api/thong-bao/so-chua-doc',
        queryParameters: {'userId': userId},
      );
      final count = (res.data as int?) ?? 0;
      if (count > 0) {
        final lastKnown = await BackgroundPollingService.getLastKnownCount();
        if (count > lastKnown) {
          await NotificationService.showSimpleNotification(
            title: 'Thông báo chưa đọc',
            body: 'Bạn có $count thông báo chưa đọc',
          );
          debugPrint('[POST-LOGIN] Notification shown: $count new messages');
        }
        await BackgroundPollingService.updateLastKnownCount(count);
      }
    } catch (e) {
      debugPrint('[POST-LOGIN] Notification check failed: $e');
    }
  }

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
    AppRoutes.daiLyChuaMua:     'Đại lý lâu chưa mua',
    AppRoutes.lichTuan:         'Lịch tuần',
    AppRoutes.chamCong:         'Chấm công',
    AppRoutes.thongTinTaiKhoan: 'Thông tin tài khoản',
    AppRoutes.doiMatKhau:       'Đổi mật khẩu',
    AppRoutes.dongBo:           'Đồng bộ dữ liệu',
    AppRoutes.kiemKeList:       'Kiểm kê chuyến xe',
  };

  String _resolveTitle(String location) {
    if (_featureTitles.containsKey(location)) return _featureTitles[location]!;
    return _tabTitles[_currentIndex];
  }

  void _onTabTapped(int index) {
    final location = GoRouterState.of(context).uri.path;
    if (index == _currentIndex && location == _tabs[index].route) return;
    setState(() => _currentIndex = index);
    context.go(_tabs[index].route);
  }

  @override
  Widget build(BuildContext context) {
    final location   = GoRouterState.of(context).uri.path;
    final isTabRoute = location == AppRoutes.home ||
        _tabs.any((t) => t.route == location);
    final isHome     = location == AppRoutes.home;
    final title      = _resolveTitle(location);

    void goBack() {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(AppRoutes.home);
      }
    }

    return GestureDetector(
      // Vuốt phải để quay lại — chỉ hoạt động trên màn hình chức năng
      onHorizontalDragEnd: (details) {
        if (!isTabRoute && (details.primaryVelocity ?? 0) > 300) {
          goBack();
        }
      },
      child: Scaffold(
        extendBodyBehindAppBar: isHome,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          // Home: trong suốt, không hiện title, icon trắng
          backgroundColor: isHome ? Colors.transparent : null,
          elevation: isHome ? 0 : null,
          scrolledUnderElevation: isHome ? 0 : null,
          foregroundColor: isHome ? Colors.white : null,
          systemOverlayStyle: isHome
              ? const SystemUiOverlayStyle(
                  statusBarColor: Colors.transparent,
                  statusBarIconBrightness: Brightness.light,
                  statusBarBrightness: Brightness.dark,
                )
              : null,
          leading: isTabRoute
              ? null
              : IconButton(
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'Quay lại',
                  onPressed: goBack,
                ),
          title: isHome ? null : Text(title),
        ),
        body: widget.child,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: _onTabTapped,
          destinations: [
            NavigationDestination(
              icon:         Icon(_tabs[0].icon),
              selectedIcon: Icon(_tabs[0].selectedIcon),
              label:        _tabs[0].label,
            ),
            NavigationDestination(
              icon:         _NotificationIcon(selectedIcon: _tabs[1].icon),
              selectedIcon: _NotificationIcon(selectedIcon: _tabs[1].selectedIcon),
              label:        _tabs[1].label,
            ),
            NavigationDestination(
              icon:         Icon(_tabs[2].icon),
              selectedIcon: Icon(_tabs[2].selectedIcon),
              label:        _tabs[2].label,
            ),
          ],
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

// ------------------------------------------------------------------
// _AppDrawer — side drawer 50% màn hình: user info + menu + logout
// ------------------------------------------------------------------

/// Icon tab Thông báo với Badge hiển thị số chưa đọc.
class _NotificationIcon extends ConsumerWidget {
  const _NotificationIcon({required this.selectedIcon});
  final IconData selectedIcon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(soChuaDocProvider).valueOrNull ?? 0;
    if (count == 0) return Icon(selectedIcon);
    return Badge(
      label: Text(count > 9 ? '9+' : '$count'),
      child: Icon(selectedIcon),
    );
  }
}
