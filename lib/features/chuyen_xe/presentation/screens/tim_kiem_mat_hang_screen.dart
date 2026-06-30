// lib/features/chuyen_xe/presentation/screens/tim_kiem_mat_hang_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/database/local_database.dart';
import '../../../../core/utils/vietnamese_text.dart';

/// Màn hình tìm kiếm mặt hàng — load toàn bộ danh sách từ cache local khi mở,
/// filter local khi gõ (hỗ trợ gõ không dấu). Trả Map mặt hàng đã chọn qua
/// context.pop(). Nếu truyền [nhaCungCapId], chỉ hiện mặt hàng thuộc hãng đó
/// (cascade từ màn chọn Hãng SX) — mặc định null thì không lọc.
class TimKiemMatHangScreen extends StatefulWidget {
  const TimKiemMatHangScreen({super.key, this.nhaCungCapId});

  final int? nhaCungCapId;

  @override
  State<TimKiemMatHangScreen> createState() => _TimKiemMatHangScreenState();
}

class _TimKiemMatHangScreenState extends State<TimKiemMatHangScreen> {
  final _db = LocalDatabase.instance;
  final _searchCtrl = TextEditingController();

  List<Map<String, dynamic>> _nhaCCList = [];
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
    var mh = await _db.getMatHangList();
    final ncc = await _db.getNhaCungCapList();
    if (widget.nhaCungCapId != null) {
      mh = mh.where((m) => m['nha_cung_cap_id'] == widget.nhaCungCapId).toList();
    }
    if (!mounted) return;
    setState(() {
      _nhaCCList = ncc;
      _all = mh;
      _filtered = mh;
      _loading = false;
    });
  }

  /// Mã NCC tương ứng mặt hàng — join thủ công vì cache_mat_hang
  /// chỉ lưu ten_nha_cc, không lưu ma_ncc.
  String _maNcc(Map<String, dynamic> mh) {
    final nccId = mh['nha_cung_cap_id'] as int?;
    if (nccId == null) return '';
    return _nhaCCList.firstWhere(
      (n) => n['server_id'] == nccId,
      orElse: () => {},
    )['ma_ncc'] as String? ?? '';
  }

  void _onSearch() {
    final q = removeDiacritics(_searchCtrl.text.trim());
    setState(() {
      if (q.isEmpty) {
        _filtered = _all;
      } else {
        _filtered = _all.where((mh) {
          final ma = removeDiacritics(mh['ma_mat_hang'] as String? ?? '');
          final ten = removeDiacritics(mh['ten_mat_hang'] as String? ?? '');
          final tenNcc = removeDiacritics(mh['ten_nha_cc'] as String? ?? '');
          return ma.contains(q) || ten.contains(q) || tenNcc.contains(q);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chọn mặt hàng'),
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
                hintText: 'Tìm theo mã hoặc tên mặt hàng...',
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
                  '${_filtered.length} mặt hàng',
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
            const Icon(Icons.inventory_2_outlined,
                size: 48, color: Colors.grey),
            const SizedBox(height: 8),
            Text(
              _searchCtrl.text.isEmpty
                  ? 'Chưa có mặt hàng nào'
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
        final mh = _filtered[i];
        final ma = mh['ma_mat_hang'] as String? ?? '';
        final ten = mh['ten_mat_hang'] as String? ?? '';
        final dvt = mh['don_vi_tinh'] as String? ?? '';
        final maNcc = _maNcc(mh);
        final tenNcc = mh['ten_nha_cc'] as String? ?? '';
        final ncc = [maNcc, tenNcc].where((s) => s.isNotEmpty).join(' - ');
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
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (dvt.isNotEmpty)
                Text('ĐVT: $dvt',
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              if (ncc.isNotEmpty)
                Text('NCC: $ncc',
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          isThreeLine: dvt.isNotEmpty && ncc.isNotEmpty,
          trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          onTap: () => context.pop(mh),
        );
      },
    );
  }
}
