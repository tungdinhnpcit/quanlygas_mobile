// lib/features/home/presentation/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/user_info_provider.dart';
import '../../../../features/menu/providers/menu_provider.dart';
import '../widgets/menu_grid_item.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menusAsync   = ref.watch(menuProvider);
    final userAsync    = ref.watch(userInfoProvider);
    final colorScheme  = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(menuProvider);
        ref.invalidate(userInfoProvider);
      },
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _GreetingCard(userAsync: userAsync),
          ),
          menusAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: colorScheme.error),
                    const SizedBox(height: 12),
                    Text('Không tải được menu', style: TextStyle(color: colorScheme.error)),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => ref.invalidate(menuProvider),
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            ),
            data: (menus) {
              if (menus.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.apps, size: 56, color: Colors.white24),
                        SizedBox(height: 12),
                        Text('Không có chức năng nào', style: TextStyle(color: Colors.white38)),
                      ],
                    ),
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.05,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final menu = menus[index];
                      return MenuGridItem(
                        menu: menu,
                        index: index,
                        onTap: () => context.go(menu.mobileRoute!),
                      );
                    },
                    childCount: menus.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _GreetingCard extends StatelessWidget {
  final AsyncValue userAsync;
  const _GreetingCard({required this.userAsync});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Chào buổi sáng';
    if (h < 18) return 'Chào buổi chiều';
    return 'Chào buổi tối';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF00695C), Color(0xFF00897B)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00897B).withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: userAsync.when(
        loading: () => const SizedBox(
          height: 52,
          child: Center(child: CircularProgressIndicator(color: Colors.white54, strokeWidth: 2)),
        ),
        error: (_, __) => _buildContent('', ''),
        data: (info) => _buildContent(info.fullName, info.roleCode),
      ),
    );
  }

  Widget _buildContent(String fullName, String roleCode) {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.person_rounded, color: Colors.white, size: 28),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _greeting(),
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 2),
              Text(
                fullName.isNotEmpty ? fullName : 'Người dùng',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (roleCode.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              roleCode,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
      ],
    );
  }
}
