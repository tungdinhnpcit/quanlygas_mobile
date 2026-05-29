// lib/features/cai_dat/presentation/screens/thong_tin_tai_khoan_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/user_info_provider.dart';

/// Màn hình Thông tin tài khoản — hiển thị thông tin user đang đăng nhập.
class ThongTinTaiKhoanScreen extends ConsumerWidget {
  const ThongTinTaiKhoanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userInfoProvider);

    return userAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Lỗi: $e')),
      data: (user) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: CircleAvatar(
              radius: 40,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _InfoCard(children: [
            _InfoRow(label: 'Họ và tên',       value: user.fullName),
            _InfoRow(label: 'Tên đăng nhập',   value: user.username),
            _InfoRow(label: 'Vai trò',          value: _roleLabel(user.roleCode)),
          ]),
        ],
      ),
    );
  }

  String _roleLabel(String roleCode) {
    return switch (roleCode) {
      'admin'     => 'Quản trị hệ thống',
      'giam-doc'  => 'Giám đốc',
      'ke-toan'   => 'Kế toán',
      'lai-xe'    => 'Lái xe',
      'quan-ly'   => 'Quản lý',
      _           => roleCode,
    };
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(children: children),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.grey[600])),
          ),
          Expanded(
            child: Text(value.isNotEmpty ? value : '—',
                style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
