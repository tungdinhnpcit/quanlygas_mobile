// lib/features/tong_quan/presentation/screens/tong_quan_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models/tong_quan_model.dart';
import '../providers/tong_quan_provider.dart';

final _vnd  = NumberFormat('#,###', 'vi_VN');
final _num  = NumberFormat('#,###');
final _date = DateFormat('dd/MM/yyyy');

class TongQuanScreen extends ConsumerStatefulWidget {
  const TongQuanScreen({super.key});

  @override
  ConsumerState<TongQuanScreen> createState() => _TongQuanScreenState();
}

class _TongQuanScreenState extends ConsumerState<TongQuanScreen> {
  late DateTime _tuNgay;
  late DateTime _denNgay;

  @override
  void initState() {
    super.initState();
    _denNgay = DateTime.now();
    _tuNgay  = _denNgay.subtract(const Duration(days: 30));
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? _tuNgay : _denNgay,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _tuNgay = picked;
        if (_tuNgay.isAfter(_denNgay)) _denNgay = _tuNgay;
      } else {
        _denNgay = picked;
        if (_denNgay.isBefore(_tuNgay)) _tuNgay = _denNgay;
      }
    });
    ref.read(tongQuanDashboardProvider.notifier).setDateRange(_tuNgay, _denNgay);
  }

  @override
  Widget build(BuildContext context) {
    final dataAsync = ref.watch(tongQuanDashboardProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.read(tongQuanDashboardProvider.notifier).refresh(),
      child: CustomScrollView(
        slivers: [
          // ── Bộ lọc ngày ────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  _DateButton(
                    label: 'Từ',
                    date: _tuNgay,
                    onTap: () => _pickDate(isFrom: true),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
                  ),
                  _DateButton(
                    label: 'Đến',
                    date: _denNgay,
                    onTap: () => _pickDate(isFrom: false),
                  ),
                  const Spacer(),
                  // Nút chọn nhanh 7 / 30 ngày
                  _QuickChip(
                    label: '7 ngày',
                    onTap: () {
                      setState(() {
                        _denNgay = DateTime.now();
                        _tuNgay  = _denNgay.subtract(const Duration(days: 7));
                      });
                      ref.read(tongQuanDashboardProvider.notifier)
                          .setDateRange(_tuNgay, _denNgay);
                    },
                  ),
                  const SizedBox(width: 6),
                  _QuickChip(
                    label: '30 ngày',
                    onTap: () {
                      setState(() {
                        _denNgay = DateTime.now();
                        _tuNgay  = _denNgay.subtract(const Duration(days: 30));
                      });
                      ref.read(tongQuanDashboardProvider.notifier)
                          .setDateRange(_tuNgay, _denNgay);
                    },
                  ),
                ],
              ),
            ),
          ),

          // ── Nội dung ──────────────────────────────────────────────────
          dataAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                    const SizedBox(height: 12),
                    Text('$e',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.redAccent)),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => ref.read(tongQuanDashboardProvider.notifier).refresh(),
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            ),
            data: (data) => SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _KpiGrid(data: data),
                  const SizedBox(height: 16),
                  _BinhBanSection(items: data.binhBanTheoMatHang),
                  const SizedBox(height: 16),
                  _DaiLySection(items: data.binhBanTheoDaiLy),
                  const SizedBox(height: 8),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Date button ──────────────────────────────────────────────────────────────

class _DateButton extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;
  const _DateButton({required this.label, required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.withValues(alpha: 0.35)),
          borderRadius: BorderRadius.circular(8),
          color: Colors.white,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$label: ',
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
            Text(_date.format(date),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _QuickChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      onPressed: onTap,
    );
  }
}

// ── KPI 2×2 grid ─────────────────────────────────────────────────────────────

class _KpiGrid extends StatelessWidget {
  final TongQuanDashboard data;
  const _KpiGrid({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                icon: Icons.attach_money_rounded,
                color: const Color(0xFF00897B),
                label: 'Doanh thu',
                value: '${_vnd.format(data.tongDoanhThu)} đ',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _KpiCard(
                icon: Icons.warning_amber_rounded,
                color: const Color(0xFFE65100),
                label: 'Nợ trong kỳ',
                value: '${_vnd.format(data.tongTienNo)} đ',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                icon: Icons.local_shipping_outlined,
                color: const Color(0xFF1976D2),
                label: 'Số chuyến',
                value: '${_num.format(data.soChuyenXe)} chuyến',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _KpiCard(
                icon: Icons.account_balance_wallet_outlined,
                color: const Color(0xFF7B1FA2),
                label: 'Tổng công nợ',
                value: '${_vnd.format(data.tongCongNoHienTai)} đ',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  const _KpiCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w800),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(color: color.withValues(alpha: 0.75), fontSize: 11)),
        ],
      ),
    );
  }
}

// ── Bình gas theo danh mục ───────────────────────────────────────────────────

class _BinhBanSection extends StatelessWidget {
  final List<BinhBanItem> items;
  const _BinhBanSection({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return _Section(
        title: 'Bình gas theo danh mục',
        icon: Icons.propane_tank_outlined,
        child: const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('Không có dữ liệu', style: TextStyle(color: Colors.grey)),
          ),
        ),
      );
    }
    final maxSl = items.map((e) => e.soLuong).fold(1, (a, b) => a > b ? a : b);
    return _Section(
      title: 'Bình gas theo danh mục',
      icon: Icons.propane_tank_outlined,
      child: Column(
        children: items.map((item) {
          final label = item.tenNhaCungCap != null
              ? '${item.tenMatHang} · ${item.tenNhaCungCap}'
              : item.tenMatHang;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(label,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_num.format(item.soLuong)} bình',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF00695C)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: maxSl > 0 ? item.soLuong / maxSl : 0,
                  backgroundColor: Colors.grey.withValues(alpha: 0.15),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00897B)),
                  borderRadius: BorderRadius.circular(4),
                  minHeight: 5,
                ),
                const SizedBox(height: 2),
                Text(
                  '${_vnd.format(item.thanhTien)} đ',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Doanh thu theo đại lý ────────────────────────────────────────────────────

class _DaiLySection extends StatelessWidget {
  final List<DaiLyItem> items;
  const _DaiLySection({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return _Section(
        title: 'Doanh thu theo đại lý',
        icon: Icons.store_outlined,
        child: const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('Không có dữ liệu', style: TextStyle(color: Colors.grey)),
          ),
        ),
      );
    }
    return _Section(
      title: 'Doanh thu theo đại lý',
      icon: Icons.store_outlined,
      child: Column(
        children: items.map((item) => _DaiLyRow(item: item)).toList(),
      ),
    );
  }
}

class _DaiLyRow extends StatelessWidget {
  final DaiLyItem item;
  const _DaiLyRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final soNgay   = item.soNgayChuaMua;
    // Cảnh báo nếu lâu hơn 30 ngày chưa mua
    final isWarning = soNgay != null && soNgay > 30;
    final dayColor  = isWarning ? const Color(0xFFE65100) : Colors.grey;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.tenKhachHang,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${_vnd.format(item.thanhTien)} đ',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF00695C)),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              Text(
                '${_num.format(item.soLuong)} bình',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
              if (item.tienNo > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE65100).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Nợ: ${_vnd.format(item.tienNo)} đ',
                    style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFFE65100),
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
              const Spacer(),
              if (soNgay != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.schedule, size: 12, color: dayColor),
                    const SizedBox(width: 2),
                    Text(
                      '$soNgay ngày',
                      style: TextStyle(fontSize: 11, color: dayColor,
                          fontWeight: isWarning ? FontWeight.w700 : FontWeight.normal),
                    ),
                    if (isWarning)
                      const Padding(
                        padding: EdgeInsets.only(left: 3),
                        child: Icon(Icons.warning_amber_rounded,
                            size: 13, color: Color(0xFFE65100)),
                      ),
                  ],
                )
              else
                const Text('Chưa mua',
                    style: TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
          const Divider(height: 14, thickness: 0.5),
        ],
      ),
    );
  }
}

// ── Section wrapper ──────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _Section({required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 18, color: const Color(0xFF00897B)),
            const SizedBox(width: 8),
            Text(title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
