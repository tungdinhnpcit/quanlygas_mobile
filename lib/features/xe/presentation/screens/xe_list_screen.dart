// lib/features/xe/presentation/screens/xe_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../providers/xe_provider.dart';

class XeListScreen extends ConsumerStatefulWidget {
  const XeListScreen({super.key});

  @override
  ConsumerState<XeListScreen> createState() => _XeListScreenState();
}

class _XeListScreenState extends ConsumerState<XeListScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(xeListProvider.notifier).load());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Color _trangThaiColor(String tt) => switch (tt.toLowerCase()) {
        'active'      => const Color(0xFF10B981),
        'maintenance' => const Color(0xFFF59E0B),
        'inactive'    => const Color(0xFFEF4444),
        _             => Colors.grey,
      };

  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(xeListProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Tìm biển số, loại xe...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchCtrl.clear();
                        ref.read(xeListProvider.notifier).load();
                        setState(() {});
                      },
                    )
                  : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              isDense: true,
            ),
            onSubmitted: (_) =>
                ref.read(xeListProvider.notifier).load(search: _searchCtrl.text.trim()),
            onChanged: (_) => setState(() {}),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () =>
                ref.read(xeListProvider.notifier).load(search: _searchCtrl.text.trim()),
            child: listAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text(e.toString())),
              data: (list) {
                if (list.isEmpty) {
                  return ListView(children: const [
                    SizedBox(height: 120),
                    Center(child: Column(children: [
                      Icon(Icons.directions_car_outlined, size: 64, color: Colors.white24),
                      SizedBox(height: 12),
                      Text('Không có xe nào', style: TextStyle(color: Colors.white38)),
                    ])),
                  ]);
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) {
                    final xe   = list[i];
                    final tColor = _trangThaiColor(xe.trangThai);
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => ctx.push(AppRoutes.xeDetail(xe.id)),
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
                                child: const Icon(Icons.local_shipping_rounded,
                                    color: Color(0xFF00897B), size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(children: [
                                      Text(xe.bienSoXe,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w700, fontSize: 15)),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: tColor.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(xe.trangThaiLabel,
                                            style: TextStyle(
                                                color: tColor, fontSize: 10,
                                                fontWeight: FontWeight.w600)),
                                      ),
                                    ]),
                                    const SizedBox(height: 2),
                                    Text(xe.loaiXe,
                                        style: const TextStyle(fontSize: 13, color: Colors.grey)),
                                    if (xe.namSanXuat != null)
                                      Text('Năm ${xe.namSanXuat}',
                                          style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                  ],
                                ),
                              ),
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
