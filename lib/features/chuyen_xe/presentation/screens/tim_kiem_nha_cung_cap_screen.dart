// lib/features/chuyen_xe/presentation/screens/tim_kiem_nha_cung_cap_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/database/local_database.dart';
import '../../../../core/utils/vietnamese_text.dart';

/// Màn hình tìm kiếm Nhà cung cấp — load toàn bộ danh sách từ cache local khi
/// mở, filter local khi gõ (hỗ trợ gõ không dấu). Trả Map NCC đã chọn qua
/// context.pop().
class TimKiemNhaCungCapScreen extends StatefulWidget {
  const TimKiemNhaCungCapScreen({super.key});

  @override
  State<TimKiemNhaCungCapScreen> createState() => _TimKiemNhaCungCapScreenState();
}

class _TimKiemNhaCungCapScreenState extends State<TimKiemNhaCungCapScreen> {
  final _db = LocalDatabase.instance;
  final _searchCtrl = TextEditingController();

  List<Map<String, dynamic>> _all = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
    _searchCtrl.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    final ncc = await _db.getNhaCungCapList();
    if (!mounted) return;
    setState(() {
      _all = ncc;
      _filtered = ncc;
      _loading = false;
    });
  }

  void _onSearch() {
    final q = removeDiacritics(_searchCtrl.text.trim());
    setState(() {
      if (q.isEmpty) {
        _filtered = _all;
      } else {
        _filtered = _all.where((ncc) {
          final ma = removeDiacritics(ncc['ma_ncc'] as String? ?? '');
          final ten = removeDiacritics(ncc['ten_ncc'] as String? ?? '');
          return ma.contains(q) || ten.contains(q);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chọn Hãng SX'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: TextField(
              controller: _searchCtrl,
              autofocus: false,
              decoration: InputDecoration(
                hintText: 'Tìm theo mã hoặc tên nhà cung cấp...',
                prefixIcon: const Icon(Icons.search, size: 20),
                border: const OutlineInputBorder(),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => _searchCtrl.clear(),
                      )
                    : null,
              ),
            ),
          ),
          if (!_loading)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 4),
              child: Row(children: [
                Text(
                  '${_filtered.length} nhà cung cấp',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ]),
            ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.local_shipping_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 8),
            Text(
              _searchCtrl.text.isEmpty
                  ? 'Chưa có nhà cung cấp nào'
                  : 'Không tìm thấy "${_searchCtrl.text}"',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: _filtered.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 56),
      itemBuilder: (_, i) {
        final ncc = _filtered[i];
        final ma = ncc['ma_ncc'] as String? ?? '';
        final ten = ncc['ten_ncc'] as String? ?? '';
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: const Color(0xFF00897B).withValues(alpha: 0.12),
            child: Text(
              ten.isNotEmpty ? ten[0].toUpperCase() : '?',
              style: const TextStyle(
                  color: Color(0xFF00897B), fontWeight: FontWeight.bold),
            ),
          ),
          title: Text('$ma - $ten',
              style: const TextStyle(fontWeight: FontWeight.w600)),
          trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          onTap: () => context.pop(ncc),
        );
      },
    );
  }
}
