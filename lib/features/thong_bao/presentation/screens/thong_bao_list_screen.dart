// lib/features/thong_bao/presentation/screens/thong_bao_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/providers/user_info_provider.dart';
import '../../data/models/thong_bao_model.dart';
import '../providers/thong_bao_provider.dart';

class ThongBaoListScreen extends ConsumerStatefulWidget {
  const ThongBaoListScreen({super.key});

  @override
  ConsumerState<ThongBaoListScreen> createState() => _ThongBaoListScreenState();
}

class _ThongBaoListScreenState extends ConsumerState<ThongBaoListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final userId = ref.read(userInfoProvider).valueOrNull?.userId.toString() ?? '0';
      ref.read(thongBaoListProvider.notifier).load(recipientId: userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(thongBaoListProvider);

    return RefreshIndicator(
      onRefresh: () => ref.read(thongBaoListProvider.notifier).load(),
      child: listAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorView(
          message: e.toString(),
          onRetry: () => ref.read(thongBaoListProvider.notifier).load(),
        ),
        data: (list) {
          if (list.isEmpty) {
            return ListView(
              children: const [
                SizedBox(height: 160),
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.notifications_none, size: 64, color: Colors.white24),
                      SizedBox(height: 16),
                      Text('Chưa có thông báo nào',
                          style: TextStyle(color: Colors.white38, fontSize: 16)),
                    ],
                  ),
                ),
              ],
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) => _ThongBaoCard(
              item: list[i],
              onTap: () => context.push(AppRoutes.thongBaoDetail(list[i].id)),
            ),
          );
        },
      ),
    );
  }
}

class _ThongBaoCard extends StatelessWidget {
  final ThongBaoModel item;
  final VoidCallback onTap;
  const _ThongBaoCard({required this.item, required this.onTap});

  IconData _typeIcon(String type) => switch (type.toLowerCase()) {
        'email' => Icons.email_outlined,
        'sms'   => Icons.sms_outlined,
        'push'  => Icons.notifications_outlined,
        'web'   => Icons.web_outlined,
        _       => Icons.notifications_outlined,
      };

  Color _statusColor(String status) => switch (status.toLowerCase()) {
        'sent'    => const Color(0xFF10B981),
        'pending' => const Color(0xFFF59E0B),
        'failed'  => const Color(0xFFEF4444),
        _         => Colors.grey,
      };

  @override
  Widget build(BuildContext context) {
    final fmt         = DateFormat('dd/MM/yyyy HH:mm');
    final statusColor = _statusColor(item.status);

    return Card(
      elevation: item.isRead ? 1 : 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: item.isRead
            ? BorderSide.none
            : const BorderSide(color: Color(0xFF00897B), width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF00897B).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_typeIcon(item.type),
                    color: const Color(0xFF00897B), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.subject,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: item.isRead
                                  ? FontWeight.w500
                                  : FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (!item.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(left: 6),
                            decoration: const BoxDecoration(
                              color: Color(0xFF00897B),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            item.statusLabel,
                            style: TextStyle(
                                color: statusColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          item.typeLabel,
                          style: const TextStyle(
                              fontSize: 11, color: Colors.grey),
                        ),
                        const Spacer(),
                        Text(
                          fmt.format(item.createdAt.toLocal()),
                          style: const TextStyle(
                              fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56, color: Colors.redAccent),
            const SizedBox(height: 16),
            const Text('Không tải được thông báo',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}
