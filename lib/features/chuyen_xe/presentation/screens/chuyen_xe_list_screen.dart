// lib/features/chuyen_xe/presentation/screens/chuyen_xe_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/providers/user_info_provider.dart';
import '../../../../core/router/app_routes.dart';
import '../../../nhan_vien/data/models/nhan_vien_model.dart';
import '../../../nhan_vien/presentation/providers/nhan_vien_provider.dart';
import '../../data/models/chuyen_xe_model.dart';
import '../providers/chuyen_xe_provider.dart';

class ChuyenXeListScreen extends ConsumerStatefulWidget {
  const ChuyenXeListScreen({super.key});

  @override
  ConsumerState<ChuyenXeListScreen> createState() => _ChuyenXeListScreenState();
}

class _ChuyenXeListScreenState extends ConsumerState<ChuyenXeListScreen> {
  String?   _selectedStatus;
  DateTime? _tuNgay;
  DateTime? _denNgay;

  // Quản lý theo lái xe (chỉ dùng cho admin/quanly/ketoan)
  bool _isAdmin = false;
  List<NhanVienModel> _laiXeList = [];
  int _selectedNhanVienId = 0;

  static const _statuses = [
    (null,         'Tất cả',     Color(0xFF9E9E9E)),
    ('cho-xuat',   'Chờ xuất',   Color(0xFFF59E0B)),
    ('dang-giao',  'Đang giao',  Color(0xFF3B82F6)),
    ('hoan-thanh', 'Hoàn thành', Color(0xFF10B981)),
    ('huy',        'Huỷ',        Color(0xFFEF4444)),
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _init());
  }

  /// Khởi tạo: phân nhánh theo role — lái xe load ngay, admin/kế toán/quản lý tải danh sách lái xe.
  Future<void> _init() async {
    // Await để đảm bảo userInfoProvider đã đọc xong từ secure storage
    final userInfo = await ref.read(userInfoProvider.future);
    final role = userInfo.roleCode;
    final isLaiXe = role == 'LaiXe';

    setState(() => _isAdmin = !isLaiXe);

    if (isLaiXe) {
      final id = userInfo.nhanVienId;
      setState(() => _selectedNhanVienId = id);
      ref.read(chuyenXeListProvider.notifier).load(nhanVienId: id);
    } else {
      // Tải danh sách lái xe từ API, filter client-side theo chức vụ
      try {
        final repo = ref.read(nhanVienRepositoryProvider);
        final list = await repo.getPaged(pageSize: 200, chucVu: 'Lái xe');
        // Lọc client-side đề phòng backend chưa hỗ trợ param chucVu
        final filtered = list.where((nv) =>
          nv.chucVu != null &&
          nv.chucVu!.toLowerCase().contains('lái xe') &&
          nv.isActive,
        ).toList();
        final laiXeList = filtered.isNotEmpty ? filtered : list;

        if (!mounted) return;
        setState(() {
          _laiXeList = laiXeList;
          if (laiXeList.isNotEmpty) {
            _selectedNhanVienId = laiXeList.first.id;
          }
        });
        if (laiXeList.isNotEmpty) {
          ref.read(chuyenXeListProvider.notifier)
              .load(nhanVienId: laiXeList.first.id);
        }
      } catch (_) {
        // Lỗi tải lái xe — bỏ qua, list chuyến xe sẽ trống
      }
    }
  }

  void _applyFilter() {
    ref.read(chuyenXeListProvider.notifier).setFilter(
      trangThai: _selectedStatus,
      tuNgay:    _tuNgay,
      denNgay:   _denNgay,
    );
  }

  Future<void> _pickDate({required bool isTuNgay}) async {
    final initial = (isTuNgay ? _tuNgay : _denNgay) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked == null) return;
    setState(() {
      if (isTuNgay) {
        _tuNgay = picked;
        if (_denNgay != null && _denNgay!.isBefore(picked)) _denNgay = null;
      } else {
        _denNgay = picked;
        if (_tuNgay != null && _tuNgay!.isAfter(picked)) _tuNgay = null;
      }
    });
    _applyFilter();
  }

  void _clearDateFilter() {
    setState(() {
      _tuNgay  = null;
      _denNgay = null;
    });
    _applyFilter();
  }

  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(chuyenXeListProvider);
    final fmtDate   = DateFormat('dd/MM/yy');
    final hasDateFilter = _tuNgay != null || _denNgay != null;

    return Column(
      children: [
            // ─── Dropdown chọn lái xe (chỉ hiển thị cho admin/quanly/ketoan) ─
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
                            ref
                                .read(chuyenXeListProvider.notifier)
                                .load(nhanVienId: id);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ─── Filter Bar: khoảng ngày ───────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                children: [
                  Expanded(
                    child: _DateButton(
                      label: _tuNgay != null
                          ? fmtDate.format(_tuNgay!)
                          : 'Từ ngày',
                      hasValue: _tuNgay != null,
                      onTap: () => _pickDate(isTuNgay: true),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
                  ),
                  Expanded(
                    child: _DateButton(
                      label: _denNgay != null
                          ? fmtDate.format(_denNgay!)
                          : 'Đến ngày',
                      hasValue: _denNgay != null,
                      onTap: () => _pickDate(isTuNgay: false),
                    ),
                  ),
                  if (hasDateFilter) ...[
                    const SizedBox(width: 6),
                    IconButton(
                      onPressed: _clearDateFilter,
                      icon: const Icon(Icons.close, size: 18),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.red.shade50,
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.all(6),
                        minimumSize: const Size(32, 32),
                      ),
                      tooltip: 'Xoá filter ngày',
                    ),
                  ],
                ],
              ),
            ),

            // ─── Status Chips: scroll ngang ────────────────────────────
            SizedBox(
              height: 46,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                itemCount: _statuses.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final (code, label, color) = _statuses[i];
                  final selected = _selectedStatus == code;
                  return FilterChip(
                    label: Text(label),
                    selected: selected,
                    onSelected: (_) {
                      setState(() => _selectedStatus = code);
                      _applyFilter();
                    },
                    selectedColor: color.withValues(alpha: 0.2),
                    checkmarkColor: color,
                    labelStyle: TextStyle(
                      color: selected ? color : Colors.grey.shade700,
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.normal,
                      fontSize: 13,
                    ),
                    side: BorderSide(
                      color: selected
                          ? color.withValues(alpha: 0.6)
                          : Colors.grey.shade300,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  );
                },
              ),
            ),

            const Divider(height: 1),

            // ─── Danh sách chuyến xe ───────────────────────────────────
            Expanded(
              child: RefreshIndicator(
                onRefresh: () =>
                    ref.read(chuyenXeListProvider.notifier).load(),
                child: listAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => _ErrorView(
                    message: e.toString(),
                    onRetry: () =>
                        ref.read(chuyenXeListProvider.notifier).load(),
                  ),
                  data: (list) {
                    if (list.isEmpty) {
                      return ListView(
                        children: [
                          const SizedBox(height: 100),
                          Center(
                            child: Column(
                              children: [
                                const Icon(Icons.local_shipping_outlined,
                                    size: 64, color: Colors.black26),
                                const SizedBox(height: 16),
                                Text(
                                  _isAdmin && _selectedNhanVienId == 0
                                      ? 'Chọn lái xe để xem chuyến xe'
                                      : _selectedStatus != null || hasDateFilter
                                          ? 'Không có chuyến xe phù hợp bộ lọc'
                                          : 'Chưa có chuyến xe nào',
                                  style: const TextStyle(
                                      color: Colors.black45, fontSize: 15),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      itemCount: list.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, i) => _ChuyenXeCard(
                        item: list[i],
                        showDriver: _isAdmin,
                        onTap: () => context.push(
                            AppRoutes.chuyenXeDetail(list[i].id.toString())),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
    );
  }
}

// Nút chọn ngày với style nhất quán.
class _DateButton extends StatelessWidget {
  final String label;
  final bool hasValue;
  final VoidCallback onTap;

  const _DateButton({
    required this.label,
    required this.hasValue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(
        Icons.calendar_today_outlined,
        size: 15,
        color: hasValue
            ? Theme.of(context).colorScheme.primary
            : Colors.grey,
      ),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          color: hasValue
              ? Theme.of(context).colorScheme.primary
              : Colors.grey,
        ),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        side: BorderSide(
          color: hasValue
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.6)
              : Colors.grey.shade300,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

// Card hiển thị thông tin tóm tắt một chuyến xe.
class _ChuyenXeCard extends StatelessWidget {
  final ChuyenXeModel item;
  final bool showDriver;
  final VoidCallback onTap;
  const _ChuyenXeCard({
    required this.item,
    required this.showDriver,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fmt         = DateFormat('dd/MM/yyyy');
    final fmtCurrency = NumberFormat.currency(
        locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
    final statusColor = item.trangThaiColor;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: icon + mã chuyến + badge trạng thái
              Row(
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
                        Text(
                          item.maChuyenXe,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          fmt.format(item.ngayXuat.toLocal()),
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StatusBadge(label: item.trangThaiLabel, color: statusColor),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),
              // Footer: số cửa hàng + biển số + (tên lái xe nếu admin) + tổng tiền
              Row(
                children: [
                  const Icon(Icons.inventory_2_outlined,
                      size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text('${item.chiTiet.length} cửa hàng',
                      style:
                          const TextStyle(fontSize: 13, color: Colors.grey)),
                  if (showDriver && item.tenNhanVien != null) ...[
                    const SizedBox(width: 10),
                    const Icon(Icons.person_outline,
                        size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        item.tenNhanVien!,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ),
                  ] else if (!showDriver && item.bienSoXe != null) ...[
                    const SizedBox(width: 12),
                    const Icon(Icons.directions_car_outlined,
                        size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(item.bienSoXe!,
                        style: const TextStyle(
                            fontSize: 13, color: Colors.grey)),
                  ],
                  const Spacer(),
                  Text(
                    fmtCurrency.format(item.tongTienThu),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF00897B),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Badge nhỏ hiển thị trạng thái với màu viền.
class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// Màn hình lỗi với nút thử lại.
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56, color: Colors.redAccent),
            const SizedBox(height: 16),
            const Text('Không tải được dữ liệu',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}
