// lib/features/chuyen_xe/presentation/screens/tim_kiem_phu_xe_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories/chuyen_xe_repository.dart';

/// Màn hình tìm kiếm phụ xe — load toàn bộ danh sách khi mở,
/// filter local khi gõ. Trả Map nhân viên đã chọn qua context.pop().
class TimKiemPhuXeScreen extends StatefulWidget {
  const TimKiemPhuXeScreen({super.key});

  @override
  State<TimKiemPhuXeScreen> createState() => _TimKiemPhuXeScreenState();
}

class _TimKiemPhuXeScreenState extends State<TimKiemPhuXeScreen> {
  final _repo = ChuyenXeRepository();
  final _searchCtrl = TextEditingController();

  List<Map<String, dynamic>> _all = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;
  String? _error;

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

  /// Load toàn bộ phụ xe bằng cách gửi keyword rỗng
  Future<void> _loadAll() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await _repo.searchPhuXeAPI('');
      if (mounted) {
        setState(() {
          _all = res;
          _filtered = res;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  void _onSearch() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filtered = _all;
      } else {
        _filtered = _all.where((px) {
          final ten = (px['hoTen'] as String? ?? '').toLowerCase();
          final ma  = (px['maNhanVien']  as String? ?? '').toLowerCase();
          return ten.contains(q) || ma.contains(q);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chọn phụ xe'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: Column(
        children: [
          // ── Search box ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: TextField(
              controller: _searchCtrl,
              autofocus: false,
              decoration: InputDecoration(
                hintText: 'Tìm theo tên hoặc mã nhân viên...',
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

          // ── Đếm kết quả ────────────────────────────────────────────────
          if (!_loading && _error == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 4),
              child: Row(children: [
                Text(
                  '${_filtered.length} nhân viên',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ]),
            ),

          // ── Nội dung ────────────────────────────────────────────────────
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 8),
            const Text('Không tải được danh sách',
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _loadAll,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_off_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 8),
            Text(
              _searchCtrl.text.isEmpty
                  ? 'Chưa có nhân viên phụ xe nào'
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
        final px  = _filtered[i];
        final ten = px['hoTen'] as String? ?? '';
        final ma  = px['maNhanVien']  as String?;
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: const Color(0xFF00897B).withValues(alpha: 0.12),
            child: Text(
              ten.isNotEmpty ? ten[0].toUpperCase() : '?',
              style: const TextStyle(
                  color: Color(0xFF00897B), fontWeight: FontWeight.bold),
            ),
          ),
          title: Text(ten,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: ma != null
              ? Text(ma,
                  style: const TextStyle(fontSize: 12, color: Colors.grey))
              : null,
          trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          onTap: () => context.pop(px),
        );
      },
    );
  }
}
