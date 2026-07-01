// lib/features/kiem_ke/presentation/screens/kiem_ke_nhap_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/database/local_database.dart';
import '../../../../core/router/app_routes.dart';
import '../../../chuyen_xe/data/models/chuyen_xe_model.dart';
import '../../../chuyen_xe/data/models/kiem_ke_model.dart';
import '../../../chuyen_xe/data/repositories/chuyen_xe_repository.dart';

/// Một dòng nhập kiểm kê: Nhà cung cấp (cascade) → Mặt hàng → Số bình/vỏ xuất.
class _KiemKeRow {
  int nhaCungCapId;
  int matHangId;
  String soBinhXuat;
  String soVoXuat;

  _KiemKeRow({
    this.nhaCungCapId = 0,
    this.matHangId = 0,
    this.soBinhXuat = '',
    this.soVoXuat = '',
  });
}

/// Màn hình kế toán nhập kiểm kê xuất hàng cho 1 chuyến xe — route ở root
/// navigator nên tự có Scaffold + AppBar riêng (theo mobile_screen_navigation.md).
class KiemKeNhapScreen extends StatefulWidget {
  const KiemKeNhapScreen({super.key, required this.chuyenXeId});

  final int chuyenXeId;

  @override
  State<KiemKeNhapScreen> createState() => _KiemKeNhapScreenState();
}

class _KiemKeNhapScreenState extends State<KiemKeNhapScreen> {
  final _repo = ChuyenXeRepository();
  final _db = LocalDatabase.instance;

  bool _loading = true;
  bool _saving = false;
  String? _error;

  ChuyenXeModel? _chuyenXe;
  List<Map<String, dynamic>> _nhaCCList = [];
  List<Map<String, dynamic>> _matHangList = [];
  final List<_KiemKeRow> _rows = [];
  final _ghiChuCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _ghiChuCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _repo.getById(widget.chuyenXeId),
        _db.getNhaCungCapList(),
        _db.getMatHangList(),
        _repo.getKiemKe(widget.chuyenXeId),
      ]);

      final cx       = results[0] as ChuyenXeModel;
      final nccList  = results[1] as List<Map<String, dynamic>>;
      final mhList   = results[2] as List<Map<String, dynamic>>;
      final kiemKe   = results[3] as KiemKeChuyenXeModel?;

      if (!mounted) return;
      setState(() {
        _chuyenXe    = cx;
        _nhaCCList   = nccList;
        _matHangList = mhList;
        _rows.clear();
        if (kiemKe != null && kiemKe.chiTiet.isNotEmpty) {
          _ghiChuCtrl.text = kiemKe.ghiChu ?? '';
          for (final ct in kiemKe.chiTiet) {
            _rows.add(_KiemKeRow(
              nhaCungCapId: ct.nhaCungCapId ?? 0,
              matHangId:    ct.matHangId,
              soBinhXuat:   ct.soBinhXuat > 0 ? '${ct.soBinhXuat}' : '',
              soVoXuat:     ct.soVoXuat > 0 ? '${ct.soVoXuat}' : '',
            ));
          }
        } else {
          _rows.add(_KiemKeRow());
        }
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

  void _addRow() => setState(() => _rows.add(_KiemKeRow()));

  void _removeRow(int index) => setState(() => _rows.removeAt(index));

  Future<void> _save() async {
    final chiTiet = <Map<String, dynamic>>[];
    for (final r in _rows) {
      final soBinh = int.tryParse(r.soBinhXuat) ?? 0;
      final soVo   = int.tryParse(r.soVoXuat) ?? 0;
      if (r.matHangId <= 0 || (soBinh <= 0 && soVo <= 0)) continue;
      chiTiet.add({
        'nhaCungCapId': r.nhaCungCapId > 0 ? r.nhaCungCapId : null,
        'matHangId':    r.matHangId,
        'soBinhXuat':   soBinh,
        'soVoXuat':     soVo,
      });
    }

    if (chiTiet.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập ít nhất 1 dòng hợp lệ (chọn mặt hàng + số bình/vỏ)')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await _repo.upsertKiemKe(
        widget.chuyenXeId,
        ghiChu: _ghiChuCtrl.text.trim().isEmpty ? null : _ghiChuCtrl.text.trim(),
        chiTiet: chiTiet,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lưu kiểm kê thành công'), backgroundColor: Colors.green),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Xóa toàn bộ biên bản kiểm kê của chuyến xe sau khi người dùng xác nhận.
  Future<void> _deleteKiemKe() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xóa kiểm kê?'),
        content: const Text('Xóa toàn bộ biên bản kiểm kê này? Không thể hoàn tác.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    setState(() => _saving = true);
    try {
      await _repo.deleteKiemKe(widget.chuyenXeId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa kiểm kê'), backgroundColor: Colors.orange),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kiểm kê xuất hàng'),
        leading: BackButton(onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(AppRoutes.kiemKeList);
          }
        }),
        actions: [
          if (!_loading && _error == null) ...[
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'Xóa kiểm kê',
              onPressed: _saving ? null : _deleteKiemKe,
            ),
            TextButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Lưu', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ],
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
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

    final cx = _chuyenXe!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        // Header thông tin chuyến — readonly
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cx.maChuyenXe,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 8),
                if (cx.bienSoXe != null)
                  _InfoLine(icon: Icons.directions_car, label: 'Biển số xe', value: cx.bienSoXe!),
                if (cx.tenNhanVien != null)
                  _InfoLine(icon: Icons.person_outline, label: 'Lái xe', value: cx.tenNhanVien!),
                if (cx.tenPhuXe != null)
                  _InfoLine(icon: Icons.person_outline, label: 'Phụ xe', value: cx.tenPhuXe!),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        const Text('Chi tiết xuất hàng',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),

        ..._rows.asMap().entries.map((e) => _RowEditor(
              key: ValueKey(e.key),
              row: e.value,
              nhaCCList: _nhaCCList,
              matHangList: _matHangList,
              onChanged: () => setState(() {}),
              onRemove: _rows.length > 1 ? () => _removeRow(e.key) : null,
            )),

        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _addRow,
          icon: const Icon(Icons.add),
          label: const Text('Thêm dòng'),
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(44)),
        ),

        const SizedBox(height: 16),
        TextField(
          controller: _ghiChuCtrl,
          decoration: const InputDecoration(
            labelText: 'Ghi chú',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          maxLines: 2,
        ),

        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.save_outlined),
            label: const Text('Lưu kiểm kê'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00897B),
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoLine({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontSize: 13, color: Colors.grey)),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

/// Editor cho 1 dòng kiểm kê: dropdown NCC (cascade) → dropdown Mặt hàng → 2 ô số.
class _RowEditor extends StatelessWidget {
  final _KiemKeRow row;
  final List<Map<String, dynamic>> nhaCCList;
  final List<Map<String, dynamic>> matHangList;
  final VoidCallback onChanged;
  final VoidCallback? onRemove;

  const _RowEditor({
    super.key,
    required this.row,
    required this.nhaCCList,
    required this.matHangList,
    required this.onChanged,
    this.onRemove,
  });

  /// Tra cứu "mã - tên" của Hãng SX/Mặt hàng đang chọn để hiển thị trên field.
  String? _labelFor(List<Map<String, dynamic>> list, int id, String maKey, String tenKey) {
    if (id <= 0) return null;
    final item = list.firstWhere((e) => e['server_id'] == id, orElse: () => {});
    if (item.isEmpty) return null;
    return '${item[maKey] ?? ''} - ${item[tenKey] ?? ''}';
  }

  Future<void> _pickNhaCungCap(BuildContext context) async {
    final ncc = await context.push<Map<String, dynamic>>(AppRoutes.timKiemNhaCungCap);
    if (ncc != null) {
      row.nhaCungCapId = ncc['server_id'] as int;
      row.matHangId = 0; // reset cascade — mặt hàng phải chọn lại theo hãng mới
      onChanged();
    }
  }

  Future<void> _pickMatHang(BuildContext context) async {
    final mh = await context.push<Map<String, dynamic>>(
      AppRoutes.timKiemMatHang,
      extra: row.nhaCungCapId > 0 ? {'nhaCungCapId': row.nhaCungCapId} : null,
    );
    if (mh != null) {
      row.matHangId = mh['server_id'] as int;
      onChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final nhaCCLabel = _labelFor(nhaCCList, row.nhaCungCapId, 'ma_ncc', 'ten_ncc');
    final matHangLabel = _labelFor(matHangList, row.matHangId, 'ma_mat_hang', 'ten_mat_hang');

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _pickNhaCungCap(context),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Hãng SX',
                        border: OutlineInputBorder(),
                        isDense: true,
                        suffixIcon: Icon(Icons.search, size: 18),
                      ),
                      child: Text(
                        nhaCCLabel ?? 'Chọn hãng SX',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: nhaCCLabel == null ? Colors.grey : null,
                        ),
                      ),
                    ),
                  ),
                ),
                if (onRemove != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: onRemove,
                    tooltip: 'Xoá dòng',
                  ),
              ],
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _pickMatHang(context),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Mặt hàng',
                  border: OutlineInputBorder(),
                  isDense: true,
                  suffixIcon: Icon(Icons.search, size: 18),
                ),
                child: Text(
                  matHangLabel ?? 'Chọn mặt hàng',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: matHangLabel == null ? Colors.grey : null,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: row.soBinhXuat,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Số bình xuất',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (v) {
                      row.soBinhXuat = v;
                      onChanged();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: row.soVoXuat,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Số vỏ xuất',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (v) {
                      row.soVoXuat = v;
                      onChanged();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
