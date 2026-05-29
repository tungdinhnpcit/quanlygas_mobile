// lib/features/cai_dat/presentation/screens/cai_dat_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';

/// Màn hình Cài đặt — danh sách các chức năng cài đặt tài khoản.
class CaiDatScreen extends StatelessWidget {
  const CaiDatScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
      ],
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
