// lib/features/cham_cong/presentation/screens/cham_cong_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/providers/user_info_provider.dart';
import '../../../nhan_vien/data/models/nhan_vien_model.dart';
import '../../../nhan_vien/presentation/providers/nhan_vien_provider.dart';
import '../../data/models/cham_cong_model.dart';
import '../providers/cham_cong_provider.dart';

class ChamCongScreen extends ConsumerStatefulWidget {
  const ChamCongScreen({super.key});

  @override
  ConsumerState<ChamCongScreen> createState() => _ChamCongScreenState();
}

class _ChamCongScreenState extends ConsumerState<ChamCongScreen> {
  bool _isAdmin = false;
  List<NhanVienModel> _laiXeList = [];
  int _selectedNhanVienId = 0;

  int _thang = 0;
  int _nam = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _init());
  }

  Future<void> _init() async {
    final userInfo = await ref.read(userInfoProvider.future);
    final isLaiXe = userInfo.roleCode == 'LaiXe';
    final now = DateTime.now();

    setState(() {
      _thang = now.month;
      _nam = now.year;
      _isAdmin = !isLaiXe;
    });

    if (isLaiXe) {
      final id = userInfo.nhanVienId;
      setState(() => _selectedNhanVienId = id);
      ref.read(chamCongProvider.notifier).load(
        nhanVienId: id,
        thang: _thang,
        nam: _nam,
      );
    } else {
      try {
        final repo = ref.read(nhanVienRepositoryProvider);
        final list = await repo.getPaged(pageSize: 200, chucVu: 'Lái xe');
        final filtered = list
            .where((nv) =>
                nv.chucVu != null &&
                nv.chucVu!.toLowerCase().contains('lái xe') &&
                nv.isActive)
            .toList();
        final laiXeList = filtered.isNotEmpty ? filtered : list;

        if (!mounted) return;
        setState(() {
          _laiXeList = laiXeList;
          if (laiXeList.isNotEmpty) {
            _selectedNhanVienId = laiXeList.first.id;
          }
        });
        if (laiXeList.isNotEmpty) {
          ref.read(chamCongProvider.notifier).load(
            nhanVienId: laiXeList.first.id,
            thang: _thang,
            nam: _nam,
          );
        }
      } catch (_) {}
    }
  }

  Future<void> _changeMonth(int delta) async {
    int newThang = _thang + delta;
    int newNam = _nam;

    if (newThang > 12) {
      newThang = 1;
      newNam++;
    } else if (newThang < 1) {
      newThang = 12;
      newNam--;
    }

    setState(() {
      _thang = newThang;
      _nam = newNam;
    });

    ref.read(chamCongProvider.notifier).setThang(newThang, newNam);
  }

  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(chamCongProvider);

    return Column(
      children: [
        // Dropdown chọn lái xe (chỉ admin)
        if (_isAdmin && _laiXeList.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_outline,
                      size: 20, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButton<int>(
                      value: _selectedNhanVienId == 0
                          ? null
                          : _selectedNhanVienId,
                      isExpanded: true,
                      underline: const SizedBox.shrink(),
                      hint: const Text('Chọn lái xe'),
                      items: _laiXeList.map((nv) {
                        return DropdownMenuItem<int>(
                          value: nv.id,
                          child: Text(
                            '${nv.hoTen}${nv.maNhanVien.isNotEmpty ? " (${nv.maNhanVien})" : ""}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (id) {
                        if (id == null) return;
                        setState(() => _selectedNhanVienId = id);
                        ref.read(chamCongProvider.notifier).load(
                          nhanVienId: id,
                          thang: _thang,
                          nam: _nam,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Header: tháng/năm
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => _changeMonth(-1),
              ),
              Text(
                'Tháng $_thang / $_nam',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => _changeMonth(1),
              ),
            ],
          ),
        ),

        // Danh sách chấm công
        Expanded(
          child: listAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(
              child: Text('Lỗi: $err'),
            ),
            data: (list) {
              if (list.isEmpty) {
                return const Center(child: Text('Không có dữ liệu'));
              }

              // Gom nhóm theo ngày
              final Map<DateTime, List<ChamCongModel>> groupedByDay = {};
              for (final cc in list) {
                final dayKey = DateTime(cc.ngay.year, cc.ngay.month, cc.ngay.day);
                groupedByDay.putIfAbsent(dayKey, () => []).add(cc);
              }

              final sortedDays = groupedByDay.keys.toList()..sort();

              return RefreshIndicator(
                onRefresh: () async {
                  await ref.read(chamCongProvider.notifier).load(
                    nhanVienId: _selectedNhanVienId,
                    thang: _thang,
                    nam: _nam,
                  );
                },
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: sortedDays.length + 1,
                  itemBuilder: (ctx, idx) {
                    // Footer: thống kê tổng ngày công
                    if (idx == sortedDays.length) {
                      final tongCong = list
                          .where((cc) => 'BH1H2'.contains(cc.kyHieu))
                          .length;
                      return Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tổng công: $tongCong ngày',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final day = sortedDays[idx];
                    final items = groupedByDay[day]!;

                    final fmtDay = DateFormat('dd EEEE', 'vi_VN').format(day);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              fmtDay,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: items.map((cc) {
                                final badge = _buildKyHieuBadge(cc.kyHieu);
                                return Chip(
                                  avatar: CircleAvatar(
                                    backgroundColor: badge.color,
                                    radius: 12,
                                    child: Text(
                                      cc.kyHieu,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  label: Text('${badge.label}: ${cc.buoi}'),
                                  backgroundColor: badge.color.withValues(alpha: 0.1),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  ({Color color, String label}) _buildKyHieuBadge(String kyHieu) {
    return switch (kyHieu) {
      'B' => (color: Colors.green, label: 'Đủ'),
      'H1' => (color: Colors.orange, label: 'Nửa ngày'),
      'H2' => (color: Colors.orange, label: 'Nửa ngày'),
      'V' => (color: Colors.amber, label: 'Phép'),
      'K' => (color: Colors.red, label: 'Không phép'),
      'O' => (color: Colors.grey, label: 'Overtime'),
      _ => (color: Colors.blueGrey, label: kyHieu),
    };
  }
}
