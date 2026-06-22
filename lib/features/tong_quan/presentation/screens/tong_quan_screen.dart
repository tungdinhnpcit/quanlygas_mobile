// lib/features/tong_quan/presentation/screens/tong_quan_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
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
    _tuNgay  = DateTime(_denNgay.year, _denNgay.month, 1);
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dòng 1: khoảng ngày
                  Row(
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
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Dòng 2: nút chọn nhanh (tránh overflow khi cùng hàng với DateButton)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
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
                  _DaiLySection(
                    items: data.binhBanTheoDaiLy,
                    tuNgay: _tuNgay,
                    denNgay: _denNgay,
                  ),
                  const SizedBox(height: 16),
                  const _ChuaMuaSection(),
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

// ── Doanh thu theo đại lý ────────────────────────────────────────────────────

class _DaiLySection extends StatelessWidget {
  final List<DaiLyItem> items;
  final DateTime? tuNgay;
  final DateTime? denNgay;
  const _DaiLySection({
    required this.items,
    this.tuNgay,
    this.denNgay,
  });

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
        children: items
            .map((item) => _DaiLyRow(
                  item: item,
                  tuNgay: tuNgay,
                  denNgay: denNgay,
                ))
            .toList(),
      ),
    );
  }
}

class _DaiLyRow extends StatelessWidget {
  final DaiLyItem item;
  final DateTime? tuNgay;
  final DateTime? denNgay;
  const _DaiLyRow({
    required this.item,
    this.tuNgay,
    this.denNgay,
  });

  @override
  Widget build(BuildContext context) {
    final soNgay   = item.soNgayChuaMua;
    // Cảnh báo nếu lâu hơn 30 ngày chưa mua
    final isWarning = soNgay != null && soNgay > 30;
    final dayColor  = isWarning ? const Color(0xFFE65100) : Colors.grey;

    return InkWell(
      onTap: () => context.push(
        AppRoutes.daiLyChiTiet(
          item.khachHangId.toString(),
          tuNgay: tuNgay,
          denNgay: denNgay,
        ),
      ),
      borderRadius: BorderRadius.circular(4),
      child: Padding(
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

// ── Khách hàng lâu chưa mua ──────────────────────────────────────────────────

// Hiển thị top 5 khách hàng lâu nhất chưa mua, link sang màn hình đầy đủ.
class _ChuaMuaSection extends ConsumerWidget {
  const _ChuaMuaSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(khachHangChuaMuaProvider);

    return _Section(
      title: 'Khách hàng lâu chưa mua',
      icon: Icons.warning_amber_outlined,
      child: dataAsync.when(
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        error: (e, _) => const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Text('Không tải được dữ liệu',
              style: TextStyle(color: Colors.grey)),
        ),
        data: (list) {
          if (list.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Tất cả khách hàng đều mua hàng gần đây',
                    style: TextStyle(color: Colors.grey)),
              ),
            );
          }
          final preview = list.take(5).toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...preview.map((item) => _ChuaMuaRow(item: item)),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.go(AppRoutes.daiLyChuaMua),
                  child: Text(
                    list.length > 5
                        ? 'Xem tất cả (${list.length})'
                        : 'Xem chi tiết',
                    style: const TextStyle(color: Color(0xFF00897B)),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// Row hiển thị 1 khách hàng: tên + địa chỉ + badge số ngày chưa mua
class _ChuaMuaRow extends StatelessWidget {
  final KhachHangChuaMuaModel item;
  const _ChuaMuaRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final days = item.soNgayChuaMua;
    final Color dayColor = days == null
        ? Colors.grey
        : days > 30
            ? const Color(0xFFE53935)
            : days > 15
                ? const Color(0xFFF57C00)
                : const Color(0xFF00897B);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.tenKhachHang,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (days != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: dayColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: dayColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    '$days ngày',
                    style: TextStyle(
                        fontSize: 11,
                        color: dayColor,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ],
          ),
          if (item.diaChi != null && item.diaChi!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                item.diaChi!,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          const Divider(height: 14, thickness: 0.5),
        ],
      ),
    );
  }
}
