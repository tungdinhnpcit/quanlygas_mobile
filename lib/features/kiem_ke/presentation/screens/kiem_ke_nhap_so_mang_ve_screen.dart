// lib/features/kiem_ke/presentation/screens/kiem_ke_nhap_so_mang_ve_screen.dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../chuyen_xe/data/models/kiem_ke_model.dart';
import '../../../chuyen_xe/data/repositories/chuyen_xe_repository.dart';

/// Kế toán nhập số bình còn lại + số vỏ mang về cho từng mặt hàng của phiếu kiểm kê
/// (nhóm theo hãng), lưu ngay vào phiếu, rồi chọn chuyến để đối chiếu.
/// Route ở root navigator → tự có Scaffold + AppBar (mobile_screen_navigation.md).
class KiemKeNhapSoMangVeScreen extends StatefulWidget {
  const KiemKeNhapSoMangVeScreen({super.key, required this.kiemKeId, this.ngay});

  final int kiemKeId;
  // Ngày (từ danh sách) truyền tiếp sang màn chọn chuyến
  final DateTime? ngay;

  @override
  State<KiemKeNhapSoMangVeScreen> createState() => _KiemKeNhapSoMangVeScreenState();
}

/// Một dòng nhập: chi tiết mặt hàng + 2 controller số mang về.
class _Row {
  final KiemKeChiTietModel ct;
  final TextEditingController binhCtrl;
  final TextEditingController voCtrl;

  _Row(this.ct)
      : binhCtrl = TextEditingController(
            text: ct.soBinhConLai != null ? '${ct.soBinhConLai}' : ''),
        voCtrl = TextEditingController(
            text: ct.soVoMangVe != null ? '${ct.soVoMangVe}' : '');

  void dispose() {
    binhCtrl.dispose();
    voCtrl.dispose();
  }
}

class _KiemKeNhapSoMangVeScreenState extends State<KiemKeNhapSoMangVeScreen> {
  final _repo = ChuyenXeRepository();

  bool _loading = true;
  bool _saving = false;
  String? _error;
  List<_Row> _rows = [];

  static const _teal = Color(0xFF00897B);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final r in _rows) {
      r.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final phieu = await _repo.getPhieuKiemKeById(widget.kiemKeId);
      if (!mounted) return;
      for (final r in _rows) {
        r.dispose();
      }
      setState(() {
        _rows = phieu.chiTiet.map((ct) => _Row(ct)).toList();
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

  List<Map<String, dynamic>> _buildChiTiet() => _rows
      .map((r) => {
            'id': r.ct.id,
            'soBinhConLai': int.tryParse(r.binhCtrl.text.trim()) ?? 0,
            'soVoMangVe': int.tryParse(r.voCtrl.text.trim()) ?? 0,
          })
      .toList();

  Future<bool> _luu({bool silent = false}) async {
    setState(() => _saving = true);
    try {
      await _repo.updateSoMangVe(widget.kiemKeId, _buildChiTiet());
      if (!mounted) return true;
      if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã lưu số mang về'), backgroundColor: Colors.green),
        );
      }
      return true;
    } catch (e) {
      if (!mounted) return false;
      final msg = e is DioException
          ? (e.response?.data is Map ? e.response?.data['message'] as String? : null) ??
              e.message ??
              e.toString()
          : e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red),
      );
      return false;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _chonChuyen() async {
    // Lưu trước rồi mới sang màn chọn chuyến để đối chiếu
    final ok = await _luu(silent: true);
    if (!ok || !mounted) return;
    context.push(AppRoutes.kiemKeChonChuyen(widget.kiemKeId), extra: widget.ngay);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhập số mang về'),
        leading: BackButton(onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(AppRoutes.kiemKeList);
          }
        }),
      ),
      body: _buildBody(),
      bottomNavigationBar: _rows.isEmpty ? null : _buildBottomBar(),
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
              Text(_error!, textAlign: TextAlign.center,
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
    if (_rows.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Phiếu này chưa có mặt hàng nào.',
              textAlign: TextAlign.center, style: TextStyle(color: Colors.black45)),
        ),
      );
    }

    // Nhóm dòng theo hãng (tenNhaCungCap), giữ thứ tự xuất hiện
    final groups = <String, List<_Row>>{};
    for (final r in _rows) {
      final hang = r.ct.tenNhaCungCap?.trim().isNotEmpty == true
          ? r.ct.tenNhaCungCap!
          : 'Không xác định hãng';
      groups.putIfAbsent(hang, () => []).add(r);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      children: [
        for (final entry in groups.entries) ...[
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 8),
            child: Row(
              children: [
                const Icon(Icons.factory_outlined, size: 16, color: _teal),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(entry.key,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: _teal)),
                ),
              ],
            ),
          ),
          ...entry.value.map(_rowCard),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _rowCard(_Row r) {
    final ct = r.ct;
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(ct.matHangLabel.isEmpty ? 'Mặt hàng #${ct.matHangId}' : ct.matHangLabel,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 2),
            Text('Xuất: ${ct.soBinhXuat} bình • ${ct.soVoXuat} vỏ',
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _numField('Số bình còn lại', r.binhCtrl)),
                const SizedBox(width: 10),
                Expanded(child: _numField('Số vỏ mang về', r.voCtrl)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _numField(String label, TextEditingController ctrl) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      ),
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _saving ? null : () => _luu(),
                icon: const Icon(Icons.save_outlined),
                label: const Text('Lưu'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  foregroundColor: _teal,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _chonChuyen,
                icon: _saving
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.local_shipping_outlined),
                label: const Text('Chọn chuyến để đối chiếu'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _teal,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
