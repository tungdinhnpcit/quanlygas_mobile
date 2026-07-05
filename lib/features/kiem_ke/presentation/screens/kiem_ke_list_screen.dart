// lib/features/kiem_ke/presentation/screens/kiem_ke_list_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/app_routes.dart';
import '../../../chuyen_xe/data/models/chuyen_xe_model.dart';
import '../../../chuyen_xe/data/repositories/chuyen_xe_repository.dart';

/// Màn hình kế toán: danh sách chuyến xe trạng thái "Chờ xuất"/"Đang giao" để
/// lập (hoặc sửa) kiểm kê xuất hàng. Mỗi item hiện badge "Đã lập"/"Chưa lập".
class KiemKeListScreen extends StatefulWidget {
  const KiemKeListScreen({super.key});

  @override
  State<KiemKeListScreen> createState() => _KiemKeListScreenState();
}

class _KiemKeListScreenState extends State<KiemKeListScreen> {
  final _repo = ChuyenXeRepository();
  bool _loading = true;
  String? _error;
  // Chuyến do lái xe tự lập trên mobile (trạng thái hoàn thành)
  List<ChuyenXeModel> _itemsLaiXe = [];
  // Chuyến do kế toán tạo qua màn "Tạo chuyến xe" (chờ xuất/đang giao)
  List<ChuyenXeModel> _itemsKeToan = [];
  // chuyenXeId -> đã lập kiểm kê hay chưa
  final Map<int, bool> _daLapMap = {};

  DateTime _denNgay = DateTime.now();
  late DateTime _tuNgay = _denNgay.subtract(const Duration(days: 30));

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
      final results = await Future.wait([
        _repo.getListByTrangThai(trangThai: 'cho-xuat', tuNgay: _tuNgay, denNgay: _denNgay),
        _repo.getListByTrangThai(trangThai: 'dang-giao', tuNgay: _tuNgay, denNgay: _denNgay),
        _repo.getListByTrangThai(trangThai: 'hoan-thanh', tuNgay: _tuNgay, denNgay: _denNgay),
      ]);
      final itemsKeToan = [...results[0], ...results[1]]
        ..sort((a, b) => b.ngayXuat.compareTo(a.ngayXuat));
      final itemsLaiXe = [...results[2]]
        ..sort((a, b) => b.ngayXuat.compareTo(a.ngayXuat));

      if (!mounted) return;
      setState(() {
        _itemsKeToan = itemsKeToan;
        _itemsLaiXe = itemsLaiXe;
        _loading = false;
      });

      // N+1: kiểm tra trạng thái lập kiểm kê cho từng chuyến — danh sách thường ngắn.
      for (final cx in [...itemsKeToan, ...itemsLaiXe]) {
        _repo.getKiemKe(cx.id).then((kk) {
          if (!mounted) return;
          setState(() => _daLapMap[cx.id] = kk != null && kk.chiTiet.isNotEmpty);
        }).catchError((_) {
          if (!mounted) return;
          setState(() => _daLapMap[cx.id] = false);
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _pickDate({required bool isTuNgay}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isTuNgay ? _tuNgay : _denNgay,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    setState(() {
      if (isTuNgay) {
        _tuNgay = picked;
        if (_tuNgay.isAfter(_denNgay)) _denNgay = _tuNgay;
      } else {
        _denNgay = picked;
        if (_denNgay.isBefore(_tuNgay)) _tuNgay = _denNgay;
      }
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
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
              const Text('Không tải được dữ liệu',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
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

    final fmt = DateFormat('dd/MM/yyyy');
    final isEmpty = _itemsLaiXe.isEmpty && _itemsKeToan.isEmpty;

    // Danh sách phẳng: String = header section, ChuyenXeModel = item chuyến xe.
    final rows = <Object>[
      if (_itemsLaiXe.isNotEmpty) ...[
        'Chuyến do lái xe lập',
        ..._itemsLaiXe,
      ],
      if (_itemsKeToan.isNotEmpty) ...[
        'Chuyến kế toán tạo',
        ..._itemsKeToan,
      ],
    ];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: _DateButton(
                  label: 'Từ ngày',
                  date: _tuNgay,
                  fmt: fmt,
                  onTap: () => _pickDate(isTuNgay: true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DateButton(
                  label: 'Đến ngày',
                  date: _denNgay,
                  fmt: fmt,
                  onTap: () => _pickDate(isTuNgay: false),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => context
                  .push(AppRoutes.kiemKeTaoChuyen)
                  .then((_) => _load()),
              icon: const Icon(Icons.add),
              label: const Text('Tạo chuyến xe'),
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF00897B)),
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 100),
                      Center(
                        child: Column(
                          children: [
                            Icon(Icons.fact_check_outlined, size: 64, color: Colors.black26),
                            SizedBox(height: 16),
                            Text('Không có chuyến xe nào cần lập kiểm kê',
                                style: TextStyle(color: Colors.black45, fontSize: 15)),
                          ],
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: rows.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final row = rows[i];
                      if (row is String) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 4, bottom: 2),
                          child: Text(row,
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w700, color: Colors.grey)),
                        );
                      }
                      final cx = row as ChuyenXeModel;
                      return _KiemKeListItem(
                        item: cx,
                        daLap: _daLapMap[cx.id],
                        onTap: () => context.push(AppRoutes.kiemKeNhap(cx.id)).then((_) => _load()),
                        onDoiChieu: () => context.push(AppRoutes.kiemKeDoiChieu(cx.id)),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

class _DateButton extends StatelessWidget {
  final String label;
  final DateTime date;
  final DateFormat fmt;
  final VoidCallback onTap;

  const _DateButton({
    required this.label,
    required this.date,
    required this.fmt,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_today, size: 14, color: Color(0xFF00897B)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                fmt.format(date),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KiemKeListItem extends StatelessWidget {
  final ChuyenXeModel item;
  final bool? daLap; // null = đang tải trạng thái
  final VoidCallback onTap;
  final VoidCallback onDoiChieu;

  const _KiemKeListItem({
    required this.item,
    required this.daLap,
    required this.onTap,
    required this.onDoiChieu,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy');

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00897B).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.local_shipping_rounded,
                    color: Color(0xFF00897B), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.maChuyenXe,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(fmt.format(item.ngayXuat.toLocal()),
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            fontSize: 13)),
                    if (item.bienSoXe != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.directions_car_outlined, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(item.bienSoXe!,
                              style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ],
                    if (item.tenNhanVien != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(item.tenNhanVien!,
                              style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ],
                    if (item.tenPhuXe != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text('Phụ xe: ${item.tenPhuXe!}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _DaLapBadge(daLap: daLap),
                  if (daLap == true) ...[
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: onDoiChieu,
                      borderRadius: BorderRadius.circular(20),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.compare_arrows, size: 14, color: Color(0xFF00897B)),
                            SizedBox(width: 3),
                            Text('Đối chiếu',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF00897B),
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DaLapBadge extends StatelessWidget {
  final bool? daLap;
  const _DaLapBadge({required this.daLap});

  @override
  Widget build(BuildContext context) {
    if (daLap == null) {
      return const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    final color = daLap! ? Colors.green : Colors.orange;
    final label = daLap! ? 'Đã lập' : 'Chưa lập';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label,
          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
