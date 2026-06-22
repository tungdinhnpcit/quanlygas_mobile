// lib/features/tong_quan/presentation/screens/dai_ly_chua_mua_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/models/tong_quan_model.dart';
import '../providers/tong_quan_provider.dart';

final _date = DateFormat('dd/MM/yyyy');

class DaiLyChuaMuaScreen extends ConsumerWidget {
  const DaiLyChuaMuaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(khachHangChuaMuaProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(khachHangChuaMuaProvider),
      child: listAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ListView(
          children: [
            const SizedBox(height: 120),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                  const SizedBox(height: 12),
                  Text(e.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
        data: (list) {
          if (list.isEmpty) {
            return ListView(
              children: const [
                SizedBox(height: 120),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.store_outlined, size: 56, color: Colors.grey),
                      SizedBox(height: 12),
                      Text('Tất cả đại lý đều mua hàng gần đây',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _DaiLyChuaMuaCard(item: list[i]),
          );
        },
      ),
    );
  }
}

class _DaiLyChuaMuaCard extends StatelessWidget {
  final KhachHangChuaMuaModel item;
  const _DaiLyChuaMuaCard({required this.item});

  // Màu badge theo số ngày chưa mua
  Color _badgeColor() {
    final n = item.soNgayChuaMua;
    if (n == null) return Colors.grey;
    if (n > 30) return const Color(0xFFE53935);   // đỏ
    if (n > 15) return const Color(0xFFF57C00);   // cam
    return const Color(0xFF00897B);                // xanh
  }

  Future<void> _goiDienThoai() async {
    final sdt = item.soDienThoai;
    if (sdt == null || sdt.isEmpty) return;
    final uri = Uri.parse('tel:$sdt');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _chiDuong() async {
    final lat = item.latitude;
    final lng = item.longitude;
    final dia = item.diaChi;

    Uri uri;
    if (lat != null && lng != null) {
      uri = Platform.isIOS
          ? Uri.parse('maps://?daddr=$lat,$lng')
          : Uri.parse('geo:$lat,$lng?q=$lat,$lng');
    } else if (dia != null && dia.isNotEmpty) {
      final q = Uri.encodeComponent(dia);
      uri = Uri.parse('https://www.google.com/maps/search/?q=$q');
    } else {
      return;
    }

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (lat != null && lng != null) {
        final fallback = Uri.parse(
            'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
        await launchUrl(fallback, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final badgeColor = _badgeColor();
    final soNgay     = item.soNgayChuaMua;
    final hasPhone   = item.soDienThoai != null && item.soDienThoai!.isNotEmpty;
    final hasMap     = (item.latitude != null && item.longitude != null) ||
                       (item.diaChi != null && item.diaChi!.isNotEmpty);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: tên + badge ngày
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.tenKhachHang,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    soNgay != null ? '$soNgay ngày' : 'Chưa mua',
                    style: TextStyle(
                        fontSize: 11,
                        color: badgeColor,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Địa chỉ
            if (item.diaChi != null && item.diaChi!.isNotEmpty)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      item.diaChi!,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            // SĐT
            if (hasPhone) ...[
              const SizedBox(height: 3),
              Row(
                children: [
                  const Icon(Icons.phone_outlined, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(item.soDienThoai!,
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ],
            // Ngày mua cuối
            if (item.ngayMuaCuoiCung != null) ...[
              const SizedBox(height: 3),
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Mua lần cuối: ${_date.format(item.ngayMuaCuoiCung!.toLocal())}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
            // Action buttons
            if (hasPhone || hasMap) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  if (hasPhone)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _goiDienThoai,
                        icon: const Icon(Icons.phone, size: 16),
                        label: const Text('Gọi', style: TextStyle(fontSize: 13)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF00897B),
                          side: const BorderSide(color: Color(0xFF00897B)),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ),
                  if (hasPhone && hasMap) const SizedBox(width: 8),
                  if (hasMap)
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _chiDuong,
                        icon: const Icon(Icons.directions, size: 16),
                        label: const Text('Chỉ đường', style: TextStyle(fontSize: 13)),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF00897B),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
