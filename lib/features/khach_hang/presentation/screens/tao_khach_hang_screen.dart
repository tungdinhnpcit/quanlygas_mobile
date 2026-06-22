// lib/features/khach_hang/presentation/screens/tao_khach_hang_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/database/local_database.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/connectivity_service.dart';

class TaoKhachHangScreen extends ConsumerStatefulWidget {
  const TaoKhachHangScreen({super.key});

  @override
  ConsumerState<TaoKhachHangScreen> createState() =>
      _TaoKhachHangScreenState();
}

class _TaoKhachHangScreenState extends ConsumerState<TaoKhachHangScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tenCtrl = TextEditingController();
  final _diaChiCtrl = TextEditingController();
  final _sdtCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _tenCtrl.dispose();
    _diaChiCtrl.dispose();
    _sdtCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    try {
      final online = await ConnectivityService.instance.checkOnline();
      final data = {
        'tenKhachHang': _tenCtrl.text.trim(),
        'diaChi': _diaChiCtrl.text.trim().isEmpty ? null : _diaChiCtrl.text.trim(),
        'soDienThoai': _sdtCtrl.text.trim().isEmpty ? null : _sdtCtrl.text.trim(),
        'email': _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        'isActive': true,
      };

      if (online) {
        final res = await ApiClient.instance.dio.post('/khach-hang', data: data);
        final serverId = res.data['id'] as int;
        // Cache vào SQLite
        await LocalDatabase.instance.upsertKhachHangList([{
          'server_id': serverId,
          'ten_khach_hang': data['tenKhachHang'],
          'dia_chi': data['diaChi'],
          'so_dien_thoai': data['soDienThoai'],
          'email': data['email'],
          'is_active': 1,
          'is_offline_created': 0,
          'is_synced': 1,
          'created_at': DateTime.now().toIso8601String(),
        }]);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã tạo khách hàng'), backgroundColor: Colors.green));
          context.pop();
        }
      } else {
        // Lưu offline
        await LocalDatabase.instance.insertKhachHangOffline({
          'ten_khach_hang': data['tenKhachHang'],
          'dia_chi': data['diaChi'],
          'so_dien_thoai': data['soDienThoai'],
          'email': data['email'],
          'is_active': 1,
          'is_offline_created': 1,
          'is_synced': 0,
          'created_at': DateTime.now().toIso8601String(),
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã lưu offline. Sẽ đồng bộ khi có mạng.')));
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _tenCtrl,
              decoration: const InputDecoration(
                labelText: 'Tên khách hàng *',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Vui lòng nhập tên' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _diaChiCtrl,
              decoration: const InputDecoration(
                labelText: 'Địa chỉ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _sdtCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Số điện thoại',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.save_rounded),
              label: Text(_saving ? 'Đang lưu...' : 'Lưu'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00897B),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(46),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
