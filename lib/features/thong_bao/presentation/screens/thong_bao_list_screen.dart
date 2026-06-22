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
    Future.microtask(() async {
      final userId = (await ref.read(userInfoProvider.future)).userId;
      ref.read(thongBaoListProvider.notifier).load(userId: userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(thongBaoListProvider);

    return RefreshIndicator(
      onRefresh: () async {
        final userId = ref.read(userInfoProvider).valueOrNull?.userId ?? 0;
        await ref.read(thongBaoListProvider.notifier).load(userId: userId);
        ref.invalidate(soChuaDocProvider);
      },
      child: listAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, _) => _ErrorView(
          message:  e.toString(),
          onRetry:  () {
            final userId = ref.read(userInfoProvider).valueOrNull?.userId ?? 0;
            ref.read(thongBaoListProvider.notifier).load(userId: userId);
          },
        ),
        data: (list) {
          if (list.isEmpty) {
            return ListView(children: const [
              SizedBox(height: 160),
              Center(
                child: Column(children: [
                  Icon(Icons.notifications_none, size: 64, color: Colors.white24),
                  SizedBox(height: 16),
                  Text('Chưa có thông báo nào',
                      style: TextStyle(color: Colors.white38, fontSize: 16)),
                ]),
              ),
            ]);
          }
          final hasUnread = list.any((t) => !t.daDoc);
          return Column(
            children: [
              if (hasUnread)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    icon: const Icon(Icons.done_all, size: 18),
                    label: const Text('Đọc tất cả'),
                    onPressed: () => ref
                        .read(thongBaoListProvider.notifier)
                        .markAllAsRead(),
                  ),
                ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) => _ThongBaoCard(item: list[i]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ThongBaoCard extends ConsumerWidget {
  final ThongBaoModel item;
  const _ThongBaoCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt = DateFormat('dd/MM/yyyy HH:mm');

    return Card(
      elevation: item.daDoc ? 1 : 3,
      color: item.daDoc ? Colors.white : const Color(0xFFE0F2F1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: item.daDoc
            ? BorderSide.none
            : const BorderSide(color: Color(0xFF00897B), width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          if (!item.daDoc) {
            ref.read(thongBaoListProvider.notifier).markAsRead(item.id);
            ref.invalidate(soChuaDocProvider);
          }
          context.push(AppRoutes.thongBaoDetail(item.id.toString()));
        },
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
                child: Icon(item.icon, color: const Color(0xFF00897B), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Text(
                          item.tieuDe,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: item.daDoc ? FontWeight.w500 : FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (!item.daDoc)
                        Container(
                          width: 8, height: 8,
                          margin: const EdgeInsets.only(left: 6),
                          decoration: const BoxDecoration(
                            color: Color(0xFF00897B), shape: BoxShape.circle,
                          ),
                        ),
                    ]),
                    const SizedBox(height: 4),
                    Text(
                      item.noiDung,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00897B).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          item.loaiLabel,
                          style: const TextStyle(
                              color: Color(0xFF00897B), fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        fmt.format(item.createdAt.toLocal()),
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ]),
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
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
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
          ]),
        ),
      );
}
