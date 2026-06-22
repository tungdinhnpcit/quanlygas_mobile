// lib/features/nhan_vien/presentation/screens/nhan_vien_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../data/models/nhan_vien_model.dart';
import '../providers/nhan_vien_provider.dart';

class NhanVienListScreen extends ConsumerStatefulWidget {
  const NhanVienListScreen({super.key});

  @override
  ConsumerState<NhanVienListScreen> createState() => _NhanVienListScreenState();
}

class _NhanVienListScreenState extends ConsumerState<NhanVienListScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(nhanVienListProvider.notifier).load());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _search() {
    ref.read(nhanVienListProvider.notifier).load(search: _searchCtrl.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(nhanVienListProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Tìm theo mã, tên, chức vụ...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchCtrl.clear();
                        ref.read(nhanVienListProvider.notifier).load();
                      },
                    )
                  : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              isDense: true,
            ),
            onSubmitted: (_) => _search(),
            onChanged: (_) => setState(() {}),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => ref.read(nhanVienListProvider.notifier).load(search: _searchCtrl.text.trim()),
            child: listAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                    const SizedBox(height: 12),
                    Text(e.toString(), textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => ref.read(nhanVienListProvider.notifier).load(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
              data: (list) {
                if (list.isEmpty) {
                  return ListView(children: const [
                    SizedBox(height: 120),
                    Center(child: Column(children: [
                      Icon(Icons.people_outline, size: 64, color: Colors.white24),
                      SizedBox(height: 12),
                      Text('Không có nhân viên nào', style: TextStyle(color: Colors.white38)),
                    ])),
                  ]);
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) => _NhanVienCard(
                    item: list[i],
                    onTap: () => ctx.push(AppRoutes.nhanVienDetail(list[i].id)),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _NhanVienCard extends StatelessWidget {
  final NhanVienModel item;
  final VoidCallback onTap;
  const _NhanVienCard({required this.item, required this.onTap});

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
                  item.hoTen.isNotEmpty ? item.hoTen[0].toUpperCase() : 'N',
                  style: const TextStyle(
                      color: Color(0xFF00897B), fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(item.maNhanVien,
                          style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(width: 8),
                      if (!item.isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('Nghỉ việc',
                              style: TextStyle(color: Colors.red, fontSize: 10)),
                        ),
                    ]),
                    const SizedBox(height: 2),
                    Text(item.hoTen,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    if (item.chucVu != null) ...[
                      const SizedBox(height: 2),
                      Text(item.chucVu!,
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
