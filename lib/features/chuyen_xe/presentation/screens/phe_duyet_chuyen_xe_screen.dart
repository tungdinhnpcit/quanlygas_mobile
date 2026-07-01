// lib/features/chuyen_xe/presentation/screens/phe_duyet_chuyen_xe_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../data/models/chuyen_xe_model.dart';
import '../../data/repositories/chuyen_xe_repository.dart';
import '../providers/chuyen_xe_provider.dart';

// Man hinh phe duyet chuyen xe danh cho ke toan/quan ly sau khi lai xe da ket thuc tren mobile.
// Ke toan nhap so lieu quyet toan roi goi API POST /api/chuyen-xe/{id}/ket-thuc.
class PheDuyetChuyenXeScreen extends ConsumerStatefulWidget {
  final int chuyenXeId;
  const PheDuyetChuyenXeScreen({super.key, required this.chuyenXeId});

  @override
  ConsumerState<PheDuyetChuyenXeScreen> createState() => _PheDuyetChuyenXeScreenState();
}

class _PheDuyetChuyenXeScreenState extends ConsumerState<PheDuyetChuyenXeScreen> {
  final _repo = ChuyenXeRepository();
  final _fmt = NumberFormat('#,##0', 'vi_VN');

  // Controllers thanh toan
  final _tienMatCtrl = TextEditingController();
  final _tienCKCtrl  = TextEditingController();
  final _ghiChuCtrl  = TextEditingController();

  // Danh sach no cu khach hang can tra
  final List<_TraNoCuRow> _traNoCuRows = [];

  bool _saving = false;

  @override
  void dispose() {
    _tienMatCtrl.dispose();
    _tienCKCtrl.dispose();
    _ghiChuCtrl.dispose();
    for (final r in _traNoCuRows) r.dispose();
    super.dispose();
  }

  double _parseNum(String s) =>
      double.tryParse(s.replaceAll('.', '').replaceAll(',', '')) ?? 0;

  // Xu ly onChange input so tien: strip ky tu la, reformat theo phan nghin
  void _handleNumInput(TextEditingController ctrl, String raw) {
    final digits = raw.replaceAll(RegExp(r'[^\d]'), '');
    final num = int.tryParse(digits) ?? 0;
    final formatted = num > 0 ? _fmt.format(num) : '';
    ctrl.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
    setState(() {});
  }

  // Goi API phe duyet voi so lieu ke toan nhap
  Future<void> _submit(ChuyenXeModel cx) async {
    setState(() => _saving = true);
    try {
      // Xay dung request body tuong tu web settle dialog
      final chiTiet = cx.banHang
          .where((b) => b.thanhTien > 0)
          .map((b) => {
                'khachHangId': b.khachHangId,
                'matHangId': b.matHangId,
                'soLuong': b.soLuong,
                'donGia': b.donGia,
                'soVoBan': b.soVoBan,
                'soVoThu': b.soVoThu,
              })
          .toList();

      final traNoCu = _traNoCuRows
          .where((r) => r.khachHangId != null && _parseNum(r.soTienCtrl.text) > 0)
          .map((r) => {
                'khachHangId': r.khachHangId,
                'soTien': _parseNum(r.soTienCtrl.text),
              })
          .toList();

      final body = {
        'chiTiet': chiTiet,
        'voThu': <Map>[],  // Vo thu duoc tinh tu banHang
        'gasDu': <Map>[],
        'traNoCu': traNoCu,
        'tongTienMat': _parseNum(_tienMatCtrl.text),
        'tongTienCK': _parseNum(_tienCKCtrl.text),
        'ghiChu': _ghiChuCtrl.text.trim().isEmpty ? null : _ghiChuCtrl.text.trim(),
      };

      await _repo.pheduyet(widget.chuyenXeId, body);
      ref.invalidate(chuyenXeDetailProvider(widget.chuyenXeId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✓ Phê duyệt thành công'), backgroundColor: Colors.green),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(chuyenXeDetailProvider(widget.chuyenXeId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Phê duyệt chuyến xe'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
        data: (cx) => _buildContent(cx),
      ),
    );
  }

  Widget _buildContent(ChuyenXeModel cx) {
    final tongTienBanHang = cx.banHang.fold<double>(0, (s, b) => s + b.thanhTien);
    final tongVoThu = cx.banHang.fold<int>(0, (s, b) => s + b.soVoThu);
    final tienMat = _parseNum(_tienMatCtrl.text);
    final tienCK  = _parseNum(_tienCKCtrl.text);
    final conLai  = tongTienBanHang - tienMat - tienCK;

    // Tim tai khoan CK tu row dau tien co tienCK > 0 va co ten tai khoan
    final rowCoTaiKhoan = cx.banHang
        .where((b) => b.tienCK > 0 && b.tenTaiKhoanCK != null)
        .fold<BanHangKhachHangModel?>(null, (acc, b) => acc ?? b);

    // Lay danh sach khach hang tu banHang de chon khi nhap no cu
    final khachHangs = cx.banHang.map((b) => {'id': b.khachHangId, 'ten': b.tenKhachHang ?? 'KH#${b.khachHangId}'})
        .fold<Map<int, String>>({}, (map, kh) {
          final id = kh['id'] as int;
          if (!map.containsKey(id)) map[id] = kh['ten'] as String;
          return map;
        });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Tom tat chuyen xe ---
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${cx.maChuyenXe} — ${cx.bienSoXe ?? ''}',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  Text('Tổng tiền bán hàng: ${_fmt.format(tongTienBanHang.toInt())} đ',
                      style: TextStyle(color: Colors.teal.shade700, fontWeight: FontWeight.w600)),
                  if (tongVoThu > 0)
                    Text('Tổng vỏ thu: $tongVoThu vỏ', style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // --- Thu tien ---
          const Text('Thu tiền', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 8),
          _NumField(
            label: 'Tiền mặt (đ)',
            ctrl: _tienMatCtrl,
            onChanged: (v) => _handleNumInput(_tienMatCtrl, v),
          ),
          const SizedBox(height: 8),
          _NumField(
            label: 'Tiền chuyển khoản (đ)',
            ctrl: _tienCKCtrl,
            onChanged: (v) => _handleNumInput(_tienCKCtrl, v),
          ),
          if (rowCoTaiKhoan != null)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4, bottom: 4),
              child: Text(
                'Tài khoản nhận: ${rowCoTaiKhoan.tenTaiKhoanCK}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
              ),
            ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Còn lại (nợ):', style: TextStyle(fontWeight: FontWeight.w600)),
              Text(
                '${_fmt.format(conLai.toInt())} đ',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: conLai > 0 ? Colors.red.shade700 : Colors.green.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // --- No cu khach hang tra ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Nợ cũ thu', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              TextButton.icon(
                onPressed: () => setState(() => _traNoCuRows.add(_TraNoCuRow())),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Thêm dòng'),
              ),
            ],
          ),
          ..._traNoCuRows.asMap().entries.map((e) => _buildTraNoCuRow(e.key, e.value, khachHangs)),
          const SizedBox(height: 16),

          // --- Ghi chu ---
          const Text('Ghi chú', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 8),
          TextField(
            controller: _ghiChuCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: 'Ghi chú thêm...',
              border: OutlineInputBorder(),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
          ),
          const SizedBox(height: 24),

          // --- Nut phe duyet ---
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : () => _submit(cx),
              icon: _saving
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.verified_outlined),
              label: const Text('Xác nhận phê duyệt'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTraNoCuRow(int idx, _TraNoCuRow row, Map<int, String> khachHangs) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<int>(
              value: row.khachHangId,
              hint: const Text('Khách hàng'),
              isDense: true,
              decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
              items: khachHangs.entries
                  .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, overflow: TextOverflow.ellipsis)))
                  .toList(),
              onChanged: (v) => setState(() => row.khachHangId = v),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextField(
              controller: row.soTienCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Số tiền',
                border: OutlineInputBorder(),
                isDense: true,
                suffixText: 'đ',
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => setState(() {}),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
            onPressed: () => setState(() {
              _traNoCuRows[idx].dispose();
              _traNoCuRows.removeAt(idx);
            }),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

// Widget input so tien co dinh dang phan nghin
class _NumField extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final ValueChanged<String> onChanged;
  const _NumField({required this.label, required this.ctrl, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      ),
      onChanged: onChanged,
    );
  }
}

// State cho 1 dong no cu khach hang
class _TraNoCuRow {
  int? khachHangId;
  final soTienCtrl = TextEditingController();
  void dispose() => soTienCtrl.dispose();
}
