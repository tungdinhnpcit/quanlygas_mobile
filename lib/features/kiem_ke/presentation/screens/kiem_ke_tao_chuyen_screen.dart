// lib/features/kiem_ke/presentation/screens/kiem_ke_tao_chuyen_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/database/local_database.dart';
import '../../../../core/router/app_routes.dart';
import '../../../chuyen_xe/data/repositories/chuyen_xe_repository.dart';

/// Màn hình riêng cho kế toán: tạo chuyến xe mới (Ngày xuất / Xe / Lái xe /
/// Phụ xe) ngay từ luồng Kiểm kê — tạo xong vào thẳng màn nhập kiểm kê của
/// chuyến vừa tạo, không đi qua luồng "Bắt đầu bán hàng" của lái xe.
class KiemKeTaoChuyenScreen extends StatefulWidget {
  const KiemKeTaoChuyenScreen({super.key});

  @override
  State<KiemKeTaoChuyenScreen> createState() => _KiemKeTaoChuyenScreenState();
}

class _KiemKeTaoChuyenScreenState extends State<KiemKeTaoChuyenScreen> {
  final _db = LocalDatabase.instance;
  final _repo = ChuyenXeRepository();

  List<Map<String, dynamic>> _xeList = [];
  List<Map<String, dynamic>> _nhanVienList = [];
  List<Map<String, dynamic>> _phuXeList = [];

  DateTime _selectedDate = DateTime.now();
  int? _selectedXeId;
  int? _selectedNhanVienId;
  String _nhanVienText = '';
  int? _selectedPhuXeId;
  String _phuXeText = '';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadCaches();
  }

  Future<void> _loadCaches() async {
    final xe = await _db.getXeList();
    final nv = await _db.getNhanVienList();
    if (mounted) {
      setState(() {
        _xeList = xe;
        _nhanVienList = nv;
      });
    }
    // Phụ xe lấy từ API (lọc theo chức vụ "Phụ xe" ở backend) — giống tim_kiem_phu_xe_screen.dart,
    // KHÔNG dùng cache local vì cache_nhan_vien chỉ lưu lái xe (is_lai_xe = 1).
    try {
      final px = await _repo.searchPhuXeAPI('');
      if (mounted) {
        setState(() {
          _phuXeList = px
              .map((e) => {
                    'server_id': e['id'],
                    'ho_ten': e['hoTen'],
                    'ma_nhan_vien': e['maNhanVien'],
                  })
              .toList();
        });
      }
    } catch (_) {
      // Giữ _phuXeList rỗng nếu lỗi mạng — field sẽ hiện thông báo chưa có dữ liệu
    }
  }

  Future<void> _pickDate() async {
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Row(
                  children: [
                    const Text('Chọn ngày xuất',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              CalendarDatePicker(
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 30)),
                onDateChanged: (picked) {
                  setState(() => _selectedDate = picked);
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submit() async {
    if (_selectedXeId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Vui lòng chọn xe')));
      return;
    }
    if (_selectedNhanVienId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Vui lòng chọn lái xe')));
      return;
    }

    setState(() => _saving = true);
    try {
      final trip = await _repo.createTrip(
        ngayXuat: _selectedDate,
        xeId: _selectedXeId!,
        nhanVienId: _selectedNhanVienId!,
        phuXeId: _selectedPhuXeId,
      );
      if (mounted) {
        context.pushReplacement(AppRoutes.kiemKeNhap(trip.id));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tạo chuyến: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _autocompleteField({
    required String label,
    required String hintText,
    required String currentText,
    required List<Map<String, dynamic>> options,
    required ValueChanged<Map<String, dynamic>> onSelected,
    VoidCallback? onClear,
    String emptyMessage = 'Chưa có dữ liệu nhân viên — vui lòng đồng bộ dữ liệu trước',
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 8),
        options.isEmpty
            ? Text(emptyMessage, style: const TextStyle(color: Colors.orange))
            : Autocomplete<Map<String, dynamic>>(
                initialValue: TextEditingValue(text: currentText),
                optionsBuilder: (textValue) {
                  if (textValue.text.isEmpty) return options;
                  final q = textValue.text.toLowerCase();
                  return options.where((nv) =>
                      (nv['ho_ten'] as String).toLowerCase().contains(q) ||
                      (nv['ma_nhan_vien'] as String).toLowerCase().contains(q));
                },
                displayStringForOption: (nv) => '${nv['ho_ten']} (${nv['ma_nhan_vien']})',
                onSelected: onSelected,
                fieldViewBuilder: (ctx, ctrl, fn, onSubmit) => TextFormField(
                  controller: ctrl,
                  focusNode: fn,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    hintText: hintText,
                    suffixIcon: onClear != null && ctrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              ctrl.clear();
                              onClear();
                            },
                          )
                        : null,
                  ),
                ),
              ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('dd/MM/yyyy').format(_selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo chuyến xe'),
        leading: BackButton(onPressed: () {
          if (context.canPop()) context.pop();
          else context.go(AppRoutes.kiemKeList);
        }),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(8),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Ngày xuất',
                                style: Theme.of(context).textTheme.labelMedium),
                            const SizedBox(height: 4),
                            Text(
                              dateLabel,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.calendar_today, color: Color(0xFF00897B), size: 20),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Chọn xe *', style: Theme.of(context).textTheme.labelMedium),
                    const SizedBox(height: 8),
                    _xeList.isEmpty
                        ? const Text('Đang tải danh sách xe...',
                            style: TextStyle(color: Colors.grey))
                        : DropdownButtonFormField<int>(
                            isExpanded: true,
                            value: _selectedXeId,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding:
                                  EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            hint: const Text('Chọn xe'),
                            items: _xeList
                                .map((xe) => DropdownMenuItem<int>(
                                      value: xe['server_id'] as int,
                                      child: Text(xe['bien_so_xe'] as String),
                                    ))
                                .toList(),
                            onChanged: (val) => setState(() => _selectedXeId = val),
                          ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _autocompleteField(
                  label: 'Lái xe *',
                  hintText: 'Tìm theo tên hoặc mã NV',
                  currentText: _nhanVienText,
                  options: _nhanVienList,
                  onSelected: (nv) => setState(() {
                    _selectedNhanVienId = nv['server_id'] as int;
                    _nhanVienText = '${nv['ho_ten']} (${nv['ma_nhan_vien']})';
                  }),
                ),
              ),
            ),
            const SizedBox(height: 12),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _autocompleteField(
                  label: 'Phụ xe (tuỳ chọn)',
                  hintText: 'Tìm theo tên hoặc mã NV',
                  currentText: _phuXeText,
                  options: _phuXeList,
                  emptyMessage: 'Chưa có nhân viên phụ xe nào',
                  onSelected: (nv) => setState(() {
                    _selectedPhuXeId = nv['server_id'] as int;
                    _phuXeText = '${nv['ho_ten']} (${nv['ma_nhan_vien']})';
                  }),
                  onClear: () => setState(() {
                    _selectedPhuXeId = null;
                    _phuXeText = '';
                  }),
                ),
              ),
            ),
            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: _saving ? null : _submit,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.add_circle_outline),
              label: Text(_saving ? 'Đang tạo...' : 'Tạo chuyến xe'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00897B),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
