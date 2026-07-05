// lib/features/kiem_ke/presentation/screens/kiem_ke_list_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/app_routes.dart';
import '../../../chuyen_xe/data/models/kiem_ke_model.dart';
import '../../../chuyen_xe/data/repositories/chuyen_xe_repository.dart';

/// Màn hình kế toán: danh sách phiếu kiểm kê độc lập (Luồng B) lọc theo ngày
/// lập, mặc định hôm nay. Bấm phiếu chưa gắn chuyến → chọn chuyến để liên kết;
/// bấm phiếu đã gắn chuyến → vào thẳng màn đối chiếu.
class KiemKeListScreen extends StatefulWidget {
  const KiemKeListScreen({super.key});

  @override
  State<KiemKeListScreen> createState() => _KiemKeListScreenState();
}

class _KiemKeListScreenState extends State<KiemKeListScreen> {
  final _repo = ChuyenXeRepository();
  bool _loading = true;
  String? _error;
  List<KiemKeChuyenXeModel> _items = [];

  DateTime _denNgay = DateTime.now();
  late DateTime _tuNgay = _denNgay;

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
      final items = await _repo.getPhieuKiemKeList(tuNgay: _tuNgay, denNgay: _denNgay);
      if (!mounted) return;
      setState(() {
        _items = items;
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

  void _onTapPhieu(KiemKeChuyenXeModel kk) {
    final chuyenXeId = kk.chuyenXeId;
    if (chuyenXeId != null) {
      context.push(AppRoutes.kiemKeDoiChieu(chuyenXeId));
    } else {
      context.push(AppRoutes.kiemKeChonChuyen(kk.id)).then((_) => _load());
    }
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
                  .push(AppRoutes.kiemKeDocLapNhap)
                  .then((_) => _load()),
              icon: const Icon(Icons.add),
              label: const Text('Tạo phiếu kiểm kê'),
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF00897B)),
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: _items.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 100),
                      Center(
                        child: Column(
                          children: [
                            Icon(Icons.fact_check_outlined, size: 64, color: Colors.black26),
                            SizedBox(height: 16),
                            Text('Không có phiếu kiểm kê nào trong khoảng ngày này',
                                style: TextStyle(color: Colors.black45, fontSize: 15)),
                          ],
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final kk = _items[i];
                      return _KiemKePhieuItem(item: kk, fmt: fmt, onTap: () => _onTapPhieu(kk));
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

class _KiemKePhieuItem extends StatelessWidget {
  final KiemKeChuyenXeModel item;
  final DateFormat fmt;
  final VoidCallback onTap;

  const _KiemKePhieuItem({required this.item, required this.fmt, required this.onTap});

  @override
  Widget build(BuildContext context) {
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
                child: const Icon(Icons.fact_check_outlined, color: Color(0xFF00897B), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Phiếu kiểm kê #${item.id}',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 2),
                    if (item.ngayLap != null)
                      Text(fmt.format(item.ngayLap!.toLocal()),
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                              fontSize: 13)),
                    if (item.maChuyenXe != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.local_shipping_outlined, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(item.maChuyenXe!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ],
                    if (item.ghiChu != null && item.ghiChu!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(item.ghiChu!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _Badge(
                    label: item.daGanChuyen ? 'Đã gắn chuyến' : 'Chưa gắn chuyến',
                    color: item.daGanChuyen ? Colors.green : Colors.orange,
                  ),
                  if (item.daChot) ...[
                    const SizedBox(height: 6),
                    const _Badge(label: 'Đã chốt', color: Colors.blue),
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

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
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
