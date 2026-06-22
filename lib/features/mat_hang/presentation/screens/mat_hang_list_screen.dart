// lib/features/mat_hang/presentation/screens/mat_hang_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/app_routes.dart';
import '../providers/mat_hang_provider.dart';

class MatHangListScreen extends ConsumerStatefulWidget {
  const MatHangListScreen({super.key});

  @override
  ConsumerState<MatHangListScreen> createState() => _MatHangListScreenState();
}

class _MatHangListScreenState extends ConsumerState<MatHangListScreen> {
  final _searchCtrl = TextEditingController();
  final _fmt = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(matHangListProvider.notifier).load());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(matHangListProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Tìm mã, tên mặt hàng...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchCtrl.clear();
                        ref.read(matHangListProvider.notifier).load();
                        setState(() {});
                      },
                    )
                  : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              isDense: true,
            ),
            onSubmitted: (_) =>
                ref.read(matHangListProvider.notifier).load(search: _searchCtrl.text.trim()),
            onChanged: (_) => setState(() {}),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () =>
                ref.read(matHangListProvider.notifier).load(search: _searchCtrl.text.trim()),
            child: listAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text(e.toString())),
              data: (list) {
                if (list.isEmpty) {
                  return ListView(children: const [
                    SizedBox(height: 120),
                    Center(child: Column(children: [
                      Icon(Icons.inventory_2_outlined, size: 64, color: Colors.white24),
                      SizedBox(height: 12),
                      Text('Không có mặt hàng nào', style: TextStyle(color: Colors.white38)),
                    ])),
                  ]);
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) {
                    final mh = list[i];
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => ctx.push(AppRoutes.matHangDetail(mh.id)),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00897B).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.inventory_2_rounded,
                                    color: Color(0xFF00897B), size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(mh.maMatHang,
                                        style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                    Text(mh.tenMatHang,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600, fontSize: 14)),
                                    const SizedBox(height: 4),
                                    Row(children: [
                                      Text(_fmt.format(mh.giaBan),
                                          style: const TextStyle(
                                              color: Color(0xFF00897B),
                                              fontWeight: FontWeight.w600)),
                                      if (mh.donViTinh != null) ...[
                                        const Text(' / ',
                                            style: TextStyle(color: Colors.grey)),
                                        Text(mh.donViTinh!,
                                            style: const TextStyle(
                                                fontSize: 12, color: Colors.grey)),
                                      ],
                                    ]),
                                  ],
                                ),
                              ),
                              if (!mh.isActive)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text('Ngừng KD',
                                      style: TextStyle(color: Colors.red, fontSize: 10)),
                                ),
                              const SizedBox(width: 4),
                              const Icon(Icons.chevron_right, color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
