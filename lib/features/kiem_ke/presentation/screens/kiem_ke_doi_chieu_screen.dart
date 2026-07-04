// lib/features/kiem_ke/presentation/screens/kiem_ke_doi_chieu_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../chuyen_xe/data/models/kiem_ke_doi_chieu_model.dart';
import '../../../chuyen_xe/data/repositories/chuyen_xe_repository.dart';

/// Màn đối chiếu số bình/vỏ mang về giữa số kế toán nhập và số suy ra từ bán hàng
/// của lái xe. Route ở root navigator nên tự có Scaffold + AppBar (theo
/// mobile_screen_navigation.md). Dòng chênh lệch được tô đỏ + banner cảnh báo.
class KiemKeDoiChieuScreen extends StatefulWidget {
  const KiemKeDoiChieuScreen({super.key, required this.chuyenXeId});

  final int chuyenXeId;

  @override
  State<KiemKeDoiChieuScreen> createState() => _KiemKeDoiChieuScreenState();
}

class _KiemKeDoiChieuScreenState extends State<KiemKeDoiChieuScreen> {
  final _repo = ChuyenXeRepository();
  bool _loading = true;
  String? _error;
  KiemKeDoiChieuModel? _data;

  static const _teal = Color(0xFF00897B);
  static const _red = Color(0xFFD32F2F);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _repo.getKiemKeDoiChieu(widget.chuyenXeId);
      if (!mounted) return;
      setState(() {
        _data = data;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đối chiếu kiểm kê'),
        leading: BackButton(onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(AppRoutes.kiemKeList);
          }
        }),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 56, color: Colors.redAccent),
              const SizedBox(height: 16),
              const Text('Không tải được dữ liệu',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    final data = _data;
    if (data == null || data.rows.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.fact_check_outlined, size: 64, color: Colors.black26),
              SizedBox(height: 16),
              Text('Chuyến này chưa lập kiểm kê,\nkhông có số liệu đối chiếu.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black45, fontSize: 15)),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          if (data.coChenhLech) _warningBanner(),
          const _SectionTitle('Chi tiết theo mặt hàng'),
          const SizedBox(height: 8),
          ...data.rows.map(_rowCard),
          if (data.voTheoNCC.isNotEmpty) ...[
            const SizedBox(height: 16),
            const _SectionTitle('Vỏ theo hãng'),
            const SizedBox(height: 8),
            ...data.voTheoNCC.map(_voNccCard),
          ],
        ],
      ),
    );
  }

  Widget _warningBanner() => Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _red.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _red.withValues(alpha: 0.4)),
        ),
        child: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: _red),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Có chênh lệch giữa số kế toán nhập và số suy ra từ bán hàng của lái xe — vui lòng kiểm tra.',
                style: TextStyle(color: _red, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );

  Widget _rowCard(KiemKeDoiChieuRow r) {
    final lech = r.coChenhLech;
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: lech ? const BorderSide(color: _red, width: 1) : BorderSide.none,
      ),
      color: lech ? _red.withValues(alpha: 0.04) : null,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(r.tenMatHang ?? 'Mặt hàng #${r.matHangId}',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            if (r.tenNhaCungCap != null) ...[
              const SizedBox(height: 2),
              Text(r.tenNhaCungCap!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
            const Divider(height: 18),
            _compareRow('Số bình mang về', r.soBinhKeToan, r.soBinhLaiXe, r.chenhLechBinh),
            const SizedBox(height: 6),
            _compareRow('Số vỏ mang về', r.soVoKeToan, r.soVoLaiXe, r.chenhLechVo),
          ],
        ),
      ),
    );
  }

  Widget _voNccCard(KiemKeDoiChieuVoNCC v) {
    final lech = v.chenhLech != 0;
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: lech ? const BorderSide(color: _red, width: 1) : BorderSide.none,
      ),
      color: lech ? _red.withValues(alpha: 0.04) : null,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(v.tenNhaCungCap ?? 'Không xác định',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const Divider(height: 18),
            _compareRow('Số vỏ mang về', v.soVoKeToan, v.soVoLaiXe, v.chenhLech),
          ],
        ),
      ),
    );
  }

  /// Một hàng so sánh: nhãn + KT (kế toán) + LX (lái xe) + chênh lệch.
  Widget _compareRow(String label, int? keToan, int laiXe, int chenhLech) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(label, style: const TextStyle(fontSize: 13, color: Colors.black87)),
        ),
        Expanded(flex: 2, child: _numCell('KT', keToan?.toString() ?? '—', _teal)),
        Expanded(flex: 2, child: _numCell('LX', '$laiXe', Colors.blueGrey)),
        Expanded(
          flex: 2,
          child: _numCell(
            'Δ',
            chenhLech > 0 ? '+$chenhLech' : '$chenhLech',
            chenhLech != 0 ? _red : Colors.grey,
            bold: chenhLech != 0,
          ),
        ),
      ],
    );
  }

  Widget _numCell(String cap, String value, Color color, {bool bold = false}) {
    return Column(
      children: [
        Text(cap, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
              fontSize: 15,
              color: color,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            )),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.black87));
}
