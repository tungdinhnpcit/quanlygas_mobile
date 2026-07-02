// lib/features/chuyen_xe/presentation/screens/chon_no_cu_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../cong_no/data/cong_no_model.dart';
import '../../../cong_no/data/cong_no_repository.dart';

/// Màn chọn khoản nợ cũ để thu — liệt kê mọi khoản nợ còn lại (khách + chuyến + số nợ),
/// tìm theo tên khách. Trả về DuNoItemModel đã chọn qua context.pop().
class ChonNoCuScreen extends StatefulWidget {
  final int? excludeChuyenXeId; // loại chuyến đang phê duyệt khỏi danh sách nợ cũ
  const ChonNoCuScreen({super.key, this.excludeChuyenXeId});

  @override
  State<ChonNoCuScreen> createState() => _ChonNoCuScreenState();
}

class _ChonNoCuScreenState extends State<ChonNoCuScreen> {
  final _repo = CongNoRepository();
  final _searchCtrl = TextEditingController();
  final _fmt = NumberFormat('#,##0', 'vi_VN');

  List<DuNoItemModel> _all = [];
  List<DuNoItemModel> _filtered = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final list = await _repo.getDuNoTatCa(excludeChuyenXeId: widget.excludeChuyenXeId);
      if (!mounted) return;
      setState(() {
        _all = list;
        _filtered = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _onSearch() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filtered = _all;
      } else {
        _filtered = _all.where((d) {
          final ten = d.tenKhachHang.toLowerCase();
          final ma  = (d.maKhachHang ?? '').toLowerCase();
          final dc  = (d.diaChi ?? '').toLowerCase();
          final mcx = d.maChuyenXe.toLowerCase();
          return ten.contains(q) || ma.contains(q) || dc.contains(q) || mcx.contains(q);
        }).toList();
      }
    });
  }

  String _fmtNgay(String iso) {
    final d = DateTime.tryParse(iso);
    return d != null ? DateFormat('dd/MM/yyyy').format(d) : iso;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chọn khoản nợ cũ'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: TextField(
              controller: _searchCtrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Tìm theo tên khách, mã, địa chỉ...',
                prefixIcon: const Icon(Icons.search, size: 20),
                border: const OutlineInputBorder(),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () => _searchCtrl.clear())
                    : null,
              ),
            ),
          ),
          if (!_loading && _error == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 4),
              child: Row(
                children: [
                  Text('${_filtered.length} khoản nợ',
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_error != null)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Lỗi tải dữ liệu: $_error',
                      textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
                ),
              ),
            )
          else if (_filtered.isEmpty)
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_outline, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('Không có khoản nợ nào', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                itemCount: _filtered.length,
                separatorBuilder: (_, __) => const Divider(height: 1, indent: 56),
                itemBuilder: (_, i) => _buildItem(_filtered[i]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildItem(DuNoItemModel d) {
    return InkWell(
      onTap: () => context.pop(d),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFFE65100).withValues(alpha: 0.12),
              child: Text(
                d.tenKhachHang.isNotEmpty ? d.tenKhachHang[0].toUpperCase() : '?',
                style: const TextStyle(color: Color(0xFFE65100), fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${d.maKhachHang != null ? "${d.maKhachHang} - " : ""}${d.tenKhachHang}',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  if (d.diaChi != null && d.diaChi!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(d.diaChi!,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.local_shipping_outlined, size: 13, color: Colors.grey.shade700),
                      const SizedBox(width: 4),
                      Text('${d.maChuyenXe} • ${_fmtNgay(d.ngayXuat)}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('Còn nợ', style: TextStyle(fontSize: 10, color: Colors.grey)),
                Text('${_fmt.format(d.conNo.toInt())} đ',
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFFE65100))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
