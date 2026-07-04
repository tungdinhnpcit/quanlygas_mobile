// lib/core/widgets/app_bottom_nav_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../router/app_routes.dart';
import '../../features/thong_bao/presentation/providers/thong_bao_provider.dart';

/// Bottom navigation bar dùng chung cho các màn hình root navigator (ngoài ShellRoute).
/// Hiển thị 3 tab: Trang chủ / Thông báo / Cài đặt, giống _MainShell.
/// Không highlight tab nào (indicatorColor transparent) vì đây là sub-screens.
class AppBottomNavBar extends ConsumerWidget {
  /// Guard tùy chọn — gọi trước khi điều hướng khỏi màn hiện tại.
  /// Trả về false để hủy điều hướng (ví dụ user chọn "Ở lại" khi có dữ liệu chưa lưu).
  final Future<bool> Function()? confirmBeforeLeave;

  const AppBottomNavBar({super.key, this.confirmBeforeLeave});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(soChuaDocProvider).valueOrNull ?? 0;
    return NavigationBar(
      selectedIndex: 0,
      indicatorColor: Colors.transparent,
      onDestinationSelected: (i) async {
        if (confirmBeforeLeave != null && !await confirmBeforeLeave!()) return;
        if (!context.mounted) return;
        switch (i) {
          case 0:
            context.go(AppRoutes.home);
          case 1:
            context.go(AppRoutes.thongBaoList);
          case 2:
            context.go(AppRoutes.caiDat);
        }
      },
      destinations: [
        const NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: 'Trang chủ',
        ),
        NavigationDestination(
          icon: unread > 0
              ? Badge(
                  label: Text('$unread'),
                  child: const Icon(Icons.notifications_outlined),
                )
              : const Icon(Icons.notifications_outlined),
          selectedIcon: const Icon(Icons.notifications_rounded),
          label: 'Thông báo',
        ),
        const NavigationDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings_rounded),
          label: 'Cài đặt',
        ),
      ],
    );
  }
}
