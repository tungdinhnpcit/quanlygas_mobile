// lib/features/ghi_chu/presentation/screens/ghi_chu_list_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/vietnamese_text.dart';
import '../../data/models/ghi_chu_model.dart';
import '../providers/ghi_chu_provider.dart';

/// Màn danh sách "Ghi chú bảo mật" — tìm kiếm tiếng Việt không dấu theo
/// tiêu đề/tài khoản/ghi chú. Không hiển thị mật khẩu trong danh sách.
class GhiChuListScreen extends ConsumerStatefulWidget {
  const GhiChuListScreen({super.key});

  @override
  ConsumerState<GhiChuListScreen> createState() => _GhiChuListScreenState();
}

class _GhiChuListScreenState extends ConsumerState<GhiChuListScreen> {
  final _searchCtrl = TextEditingController();
  String _filterQuery = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(ghiChuListProvider.notifier).load());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 1000), () {
      setState(() => _filterQuery = removeDiacritics(value.trim()));
    });
  }

  List<GhiChuModel> _applyFilter(List<GhiChuModel> allItems) {
    if (_filterQuery.isEmpty) return allItems;
    return allItems.where((g) {
      final t = removeDiacritics(g.tieuDe);
      final a = removeDiacritics(g.taiKhoan);
      final c = removeDiacritics(g.ghiChu);
      return t.contains(_filterQuery) ||
          a.contains(_filterQuery) ||
          c.contains(_filterQuery);
    }).toList();
  }

  Future<void> _openForm([GhiChuModel? item]) async {
    await context.push(AppRoutes.ghiChuForm, extra: item);
    if (mounted) {
      await ref.read(ghiChuListProvider.notifier).load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ghiChuListProvider);

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Tìm theo tiêu đề, tài khoản, ghi chú...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                isDense: true,
              ),
            ),
          ),
          Expanded(
            child: state.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Lỗi tải dữ liệu: $e')),
              data: (allItems) {
                final items = _applyFilter(allItems);
                if (items.isEmpty) {
                  return const Center(
                    child: Text('Chưa có ghi chú nào'),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () => ref.read(ghiChuListProvider.notifier).load(),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 88),
                    itemCount: items.length,
                    itemBuilder: (context, i) {
                      final item = items[i];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.sticky_note_2_outlined),
                          ),
                          title: Text(
                            item.tieuDe,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: item.taiKhoan.isEmpty
                              ? null
                              : Text(item.taiKhoan),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _openForm(item),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Thêm ghi chú'),
      ),
    );
  }
}
