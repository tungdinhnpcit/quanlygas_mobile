// lib/features/than_so_hoc/presentation/screens/than_so_hoc_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/numerology/calculate.dart';
import '../../../../core/utils/numerology/types.dart';
import '../../../../core/utils/vietnamese_text.dart';
import '../widgets/results_view.dart';

/// Man hinh Than so hoc: nhap ho ten + ngay sinh, tinh toan va hien thi
/// toan bo chi so than so hoc. Tinh toan hoan toan phia client, khong goi
/// API (xem Plans/than-so-hoc.md).
class ThanSoHocScreen extends StatefulWidget {
  const ThanSoHocScreen({super.key});

  @override
  State<ThanSoHocScreen> createState() => _ThanSoHocScreenState();
}

class _ThanSoHocScreenState extends State<ThanSoHocScreen> {
  final _formKey = GlobalKey<FormState>();
  final _hoTenCtrl = TextEditingController();

  DateTime? _ngaySinh;
  DateTime _ngayLapLaSo = DateTime.now();

  NumerologyResult? _result;
  DateTime? _resultBirthDate;

  @override
  void dispose() {
    _hoTenCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickNgaySinh() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _ngaySinh ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _ngaySinh = picked);
  }

  Future<void> _pickNgayLapLaSo() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _ngayLapLaSo,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _ngayLapLaSo = picked);
  }

  void _tinh() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_ngaySinh == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ngày sinh')),
      );
      return;
    }

    final input = NumerologyInput(
      fullName: _hoTenCtrl.text.trim(),
      birthDate: _ngaySinh!,
      chartDate: _ngayLapLaSo,
    );
    final result = calculateNumerology(
      input,
      removeDiacritics: (s) => removeDiacritics(s).toUpperCase(),
    );
    setState(() {
      _result = result;
      _resultBirthDate = _ngaySinh;
    });
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _hoTenCtrl,
              decoration: const InputDecoration(
                labelText: 'Họ và tên đầy đủ *',
                border: OutlineInputBorder(),
                hintText: 'VD: Nguyễn Thị Hằng',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Vui lòng nhập họ tên' : null,
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickNgaySinh,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Ngày sinh *',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today_outlined),
                ),
                child: Text(
                  _ngaySinh != null ? dateFormat.format(_ngaySinh!) : 'Chọn ngày sinh',
                  style: TextStyle(color: _ngaySinh == null ? Colors.grey : null),
                ),
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickNgayLapLaSo,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Ngày lập lá số',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.event_outlined),
                  helperText: 'Dùng để tính Năm/Tháng/Ngày cá nhân, mặc định là hôm nay',
                ),
                child: Text(dateFormat.format(_ngayLapLaSo)),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _tinh,
              icon: const Icon(Icons.auto_awesome_rounded),
              label: const Text('Tính chỉ số thần số học'),
            ),
            if (_result != null) ...[
              const Divider(height: 32),
              NumerologyResultsView(
                result: _result!,
                rawBirthDay: _resultBirthDate!.day,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
