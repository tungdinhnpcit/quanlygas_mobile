// lib/features/cai_dat/presentation/screens/cai_dat_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../features/auth/data/auth_repository.dart';
import '../../../../features/menu/providers/menu_provider.dart';
import '../../../../core/providers/user_info_provider.dart';
import '../../../../features/thong_bao/presentation/providers/thong_bao_provider.dart';

/// Màn hình Cài đặt — danh sách các chức năng cài đặt tài khoản.
class CaiDatScreen extends ConsumerWidget {
  const CaiDatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      children: [
        const SizedBox(height: 8),
        _SettingTile(
          icon: Icons.person_outline,
          title: 'Thông tin tài khoản',
          subtitle: 'Xem thông tin cá nhân',
          onTap: () => context.push(AppRoutes.thongTinTaiKhoan),
        ),
        const Divider(height: 1, indent: 56),
        _SettingTile(
          icon: Icons.lock_outline,
          title: 'Đổi mật khẩu',
          subtitle: 'Thay đổi mật khẩu đăng nhập',
          onTap: () => context.push(AppRoutes.doiMatKhau),
        ),
        const Divider(height: 1, indent: 56),
        _SettingTile(
          icon: Icons.logout,
          title: 'Đăng xuất',
          subtitle: 'Thoát khỏi tài khoản',
          iconColor: Theme.of(context).colorScheme.error,
          titleColor: Theme.of(context).colorScheme.error,
          onTap: () => _logout(context, ref),
        ),
      ],
    );
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await AuthRepository().logout();
    ref.invalidate(menuProvider);
    ref.invalidate(userInfoProvider);
    ref.invalidate(soChuaDocProvider);
    if (context.mounted) context.go(AppRoutes.login);
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? titleColor;

  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    final defaultColor = Theme.of(context).colorScheme.primary;
    return ListTile(
      leading: Icon(icon, color: iconColor ?? defaultColor),
      title: Text(title, style: TextStyle(color: titleColor)),
      subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
