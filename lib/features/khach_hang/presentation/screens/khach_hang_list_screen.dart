// lib/features/khach_hang/presentation/screens/khach_hang_list_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/vietnamese_text.dart';
import '../../data/models/khach_hang_model.dart';
import '../providers/khach_hang_provider.dart';

class KhachHangListScreen extends ConsumerStatefulWidget {
  const KhachHangListScreen({super.key});

  @override
  ConsumerState<KhachHangListScreen> createState() => _KhachHangListScreenState();
}

class _KhachHangListScreenState extends ConsumerState<KhachHangListScreen> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  String _filterQuery = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(khachHangListProvider.notifier).load());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(khachHangListProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Tìm theo mã, tên, SĐT, địa chỉ...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _filterQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                isDense: true,
              ),
              onChanged: (text) {
                setState(() {});
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 1000), () {
                  setState(() => _filterQuery = removeDiacritics(text.trim()));
                });
              },
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref
                  .read(khachHangListProvider.notifier)
                  .load(),
              child: listAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                      const SizedBox(height: 12),
                      Text(e.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () => ref.read(khachHangListProvider.notifier).load(),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Thử lại'),
                      ),
                    ],
                  ),
                ),
                data: (list) {
                  final allItems = list;
                  final items = _filterQuery.isEmpty
                      ? allItems
                      : allItems.where((kh) {
                          final name = removeDiacritics(kh.tenKhachHang);
                          final ma = removeDiacritics(kh.maKhachHang);
                          final addr = removeDiacritics(kh.diaChi ?? '');
                          return name.contains(_filterQuery) ||
                              ma.contains(_filterQuery) ||
                              addr.contains(_filterQuery);
                        }).toList();

                  if (items.isEmpty) {
                    return ListView(children: const [
                      SizedBox(height: 120),
                      Center(
                        child: Column(children: [
                          Icon(Icons.people_outline, size: 64, color: Colors.white24),
                          SizedBox(height: 12),
                          Text('Không có khách hàng nào',
                              style: TextStyle(color: Colors.white38)),
                        ]),
                      ),
                    ]);
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) => _KhachHangCard(
                      item: items[i],
                      onTap: () => ctx.push(AppRoutes.khachHangDetail(items[i].id)),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push(AppRoutes.taoKhachHang);
          if (mounted) ref.read(khachHangListProvider.notifier).load();
        },
        icon: const Icon(Icons.add),
        label: const Text('Thêm khách hàng'),
        backgroundColor: const Color(0xFF00897B),
        foregroundColor: Colors.white,
      ),
    );
  }
}

class _KhachHangCard extends StatelessWidget {
  final KhachHangModel item;
  final VoidCallback onTap;
  const _KhachHangCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFF00897B).withValues(alpha: 0.15),
                child: Text(
                  item.tenKhachHang.isNotEmpty
                      ? item.tenKhachHang[0].toUpperCase()
                      : 'K',
                  style: const TextStyle(
                      color: Color(0xFF00897B),
                      fontWeight: FontWeight.bold,
                      fontSize: 18),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(item.maKhachHang,
                          style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(width: 6),
                      if (!item.isActive)
                        _Badge(label: 'Ngừng KD', color: Colors.red),
                      if (item.hasLocation) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.location_on, size: 14, color: Colors.green),
                      ],
                    ]),
                    const SizedBox(height: 2),
                    Text(item.tenKhachHang,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15)),
                    if (item.diaChi != null) ...[
                      const SizedBox(height: 2),
                      Text(item.diaChi!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                    if (item.soDienThoai != null) ...[
                      const SizedBox(height: 4),
                      Row(children: [
                        const Icon(Icons.phone_outlined, size: 13, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(item.soDienThoai!,
                            style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ]),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 10)),
    );
  }
}
