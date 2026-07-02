// lib/features/thong_bao/presentation/screens/thong_bao_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/providers/user_info_provider.dart';
import '../../data/models/thong_bao_model.dart';
import '../providers/thong_bao_provider.dart';

const _teal = Color(0xFF00897B);

class ThongBaoListScreen extends ConsumerStatefulWidget {
  const ThongBaoListScreen({super.key});

  @override
  ConsumerState<ThongBaoListScreen> createState() => _ThongBaoListScreenState();
}

class _ThongBaoListScreenState extends ConsumerState<ThongBaoListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final soChuaDoc = ref.watch(soChuaDocProvider).valueOrNull ?? 0;

    return Column(
      children: [
        Material(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Row(
            children: [
              Expanded(
                child: TabBar(
                  controller: _tab,
                  labelColor: _teal,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: _teal,
                  labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  tabs: [
                    const Tab(text: 'Tất cả'),
                    Tab(text: soChuaDoc > 0 ? 'Chưa đọc ($soChuaDoc)' : 'Chưa đọc'),
                    const Tab(text: 'Đã đọc'),
                  ],
                ),
              ),
              if (soChuaDoc > 0)
                TextButton.icon(
                  icon: const Icon(Icons.done_all, size: 18),
                  label: const Text('Đọc tất cả'),
                  onPressed: () async {
                    final userId = ref.read(userInfoProvider).valueOrNull?.userId ?? 0;
                    if (userId > 0) {
                      await ref.read(thongBaoListProvider(false).notifier).markAllAsRead(userId);
                    }
                  },
                ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: const [
              _ThongBaoTabList(daDoc: null),
              _ThongBaoTabList(daDoc: false),
              _ThongBaoTabList(daDoc: true),
            ],
          ),
        ),
      ],
    );
  }
}

/// Danh sách 1 tab — infinite scroll + pull to refresh, giữ state khi chuyển tab.
class _ThongBaoTabList extends ConsumerStatefulWidget {
  final bool? daDoc;
  const _ThongBaoTabList({required this.daDoc});

  @override
  ConsumerState<_ThongBaoTabList> createState() => _ThongBaoTabListState();
}

class _ThongBaoTabListState extends ConsumerState<_ThongBaoTabList>
    with AutomaticKeepAliveClientMixin {
  final _scroll = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    Future.microtask(() async {
      final userId = (await ref.read(userInfoProvider.future)).userId;
      if (mounted) {
        ref.read(thongBaoListProvider(widget.daDoc).notifier).loadFirst(userId);
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 300) {
      ref.read(thongBaoListProvider(widget.daDoc).notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final state = ref.watch(thongBaoListProvider(widget.daDoc));

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.items.isEmpty) {
      return _ErrorView(
        message: state.error.toString(),
        onRetry: () => ref.read(thongBaoListProvider(widget.daDoc).notifier).refresh(),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(thongBaoListProvider(widget.daDoc).notifier).refresh();
        ref.invalidate(soChuaDocProvider);
      },
      child: state.items.isEmpty
          ? ListView(children: const [
              SizedBox(height: 140),
              Center(
                child: Column(children: [
                  Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Không có thông báo', style: TextStyle(color: Colors.grey, fontSize: 16)),
                ]),
              ),
            ])
          : ListView.separated(
              controller: _scroll,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: state.items.length + (state.hasMore ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                if (i >= state.items.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  );
                }
                return _ThongBaoCard(item: state.items[i], daDoc: widget.daDoc);
              },
            ),
    );
  }
}

class _ThongBaoCard extends ConsumerWidget {
  final ThongBaoModel item;
  final bool? daDoc; // filter của tab chứa card này — để gọi đúng notifier
  const _ThongBaoCard({required this.item, required this.daDoc});

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
            : const BorderSide(color: _teal, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          if (!item.daDoc) {
            ref.read(thongBaoListProvider(daDoc).notifier).markAsRead(item.id);
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
                  color: _teal.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(item.icon, color: _teal, size: 20),
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
                            color: _teal, shape: BoxShape.circle,
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
                          color: _teal.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          item.loaiLabel,
                          style: const TextStyle(
                              color: _teal, fontSize: 11, fontWeight: FontWeight.w600),
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
