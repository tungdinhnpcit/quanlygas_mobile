// lib/features/chuyen_xe/presentation/screens/chuyen_xe_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../data/models/chuyen_xe_model.dart';
import '../providers/chuyen_xe_provider.dart';

// Formatter dùng chung trong file.
final _fmtCurrency =
    NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
final _fmtDate = DateFormat('dd/MM/yyyy HH:mm');
final _fmtDateOnly = DateFormat('dd/MM/yyyy');

class ChuyenXeDetailScreen extends ConsumerStatefulWidget {
  const ChuyenXeDetailScreen({super.key, required this.chuyenXeId});

  final String chuyenXeId;

  @override
  ConsumerState<ChuyenXeDetailScreen> createState() =>
      _ChuyenXeDetailScreenState();
}

class _ChuyenXeDetailScreenState extends ConsumerState<ChuyenXeDetailScreen>
    with SingleTickerProviderStateMixin {
  bool _uploading = false;
  late final TabController _tabController;

  // Danh sách tab: index cố định, hiển thị tất cả
  static const _tabs = [
    Tab(icon: Icon(Icons.list_alt_rounded, size: 20), text: 'Chi tiết'),
    Tab(icon: Icon(Icons.recycling_rounded, size: 20), text: 'Thu vỏ'),
    Tab(icon: Icon(Icons.payments_outlined, size: 20), text: 'Thu tiền'),
    Tab(icon: Icon(Icons.camera_alt_outlined, size: 20), text: 'Ảnh'),
    Tab(icon: Icon(Icons.local_gas_station_outlined, size: 20), text: 'Gas dư'),
    Tab(icon: Icon(Icons.receipt_long_outlined, size: 20), text: 'Thu nợ'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Hiện bottom sheet chọn nguồn ảnh (camera hoặc thư viện).
  Future<ImageSource?> _pickSource() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Chụp ảnh'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Chọn từ thư viện'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  /// Xử lý chọn ảnh và upload lên server, tự động nén xuống ≤ 1MB.
  Future<void> _handleUpload(ChuyenXeModel cx) async {
    final source = await _pickSource();
    if (source == null) return;

    final picker = ImagePicker();
    final photo = await picker.pickImage(source: source, imageQuality: 85);
    if (photo == null) return;

    setState(() => _uploading = true);
    try {
      final upload = ref.read(uploadPhotoProvider);
      await upload(cx.id, photo);
      final id = int.tryParse(widget.chuyenXeId) ?? 0;
      ref.invalidate(chuyenXeDetailProvider(id));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload thất bại: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final id = int.tryParse(widget.chuyenXeId) ?? 0;
    final detailAsync = ref.watch(chuyenXeDetailProvider(id));

    return Scaffold(
      appBar: AppBar(
        title: Text('Chuyến #${widget.chuyenXeId}'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: _tabs,
        ),
      ),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 56, color: Colors.redAccent),
              const SizedBox(height: 12),
              const Text('Không tải được thông tin'),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => ref.invalidate(chuyenXeDetailProvider(id)),
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
        data: (cx) => Stack(
          children: [
            TabBarView(
              controller: _tabController,
              children: [
                _TabChiTiet(cx: cx),
                _TabThuVo(cx: cx),
                _TabThuTien(cx: cx),
                _TabAnh(
                  cx: cx,
                  uploading: _uploading,
                  onUpload: () => _handleUpload(cx),
                ),
                _TabGasDu(cx: cx),
                _TabThuNo(cx: cx),
              ],
            ),
            // Header tóm tắt luôn hiển thị phía trên
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _HeaderBar(cx: cx),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header tóm tắt mã chuyến + trạng thái ──────────────────────────────────

class _HeaderBar extends StatelessWidget {
  final ChuyenXeModel cx;
  const _HeaderBar({required this.cx});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF00897B).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.local_shipping_rounded,
                color: Color(0xFF00897B), size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cx.maChuyenXe,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15),
                ),
                Text(
                  _fmtDateOnly.format(cx.ngayXuat.toLocal()),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          _StatusBadge(label: cx.trangThaiLabel, color: cx.trangThaiColor),
        ],
      ),
    );
  }
}

// ── Tab 1: Chi tiết hàng hóa ────────────────────────────────────────────────

class _TabChiTiet extends StatelessWidget {
  final ChuyenXeModel cx;
  const _TabChiTiet({required this.cx});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 80, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thông tin xe + ghi chú
          _SectionCard(
            title: 'Thông tin chuyến',
            child: Column(
              children: [
                if (cx.bienSoXe != null)
                  _InfoRow(
                      icon: Icons.directions_car,
                      label: 'Biển số xe',
                      value: cx.bienSoXe!),
                if (cx.bienSoXe != null) const SizedBox(height: 8),
                if (cx.tenNhanVien != null)
                  _InfoRow(
                      icon: Icons.person_outline,
                      label: 'Lái xe',
                      value: cx.tenNhanVien!),
                if (cx.tenNhanVien != null) const SizedBox(height: 8),
                _InfoRow(
                    icon: Icons.calendar_today,
                    label: 'Ngày xuất',
                    value: _fmtDateOnly.format(cx.ngayXuat.toLocal())),
                if (cx.ghiChu != null && cx.ghiChu!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _InfoRow(
                      icon: Icons.note_outlined,
                      label: 'Ghi chú',
                      value: cx.ghiChu!),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Danh sách hàng hóa
          if (cx.chiTiet.isEmpty)
            _EmptyState(
                icon: Icons.inventory_2_outlined,
                label: 'Chưa có hàng hóa trong chuyến')
          else ...[
            _SectionLabel(
                '${cx.chiTiet.length} cửa hàng trong chuyến'),
            const SizedBox(height: 8),
            ...cx.chiTiet.asMap().entries.map((e) {
              final i  = e.key;
              final ct = e.value;
              return _ChiTietCard(index: i, item: ct);
            }),
          ],
          const SizedBox(height: 16),

          // Tổng tiền thu
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF00695C),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tổng tiền thu',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
                Text(
                  _fmtCurrency.format(cx.tongTienThu),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Card một cửa hàng trong chuyến.
class _ChiTietCard extends StatelessWidget {
  final int index;
  final ChuyenXeChiTietModel item;
  const _ChiTietCard({required this.index, required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor:
                      const Color(0xFF00897B).withValues(alpha: 0.15),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                        color: Color(0xFF00897B),
                        fontSize: 12,
                        fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.tenKhachHang ?? 'Khách hàng #${item.khachHangId}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ),
                Text(
                  _fmtCurrency.format(item.thanhTien),
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF00897B),
                      fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _DataChip(
                      label: 'Mặt hàng',
                      value: item.tenMatHang ??
                          'ID ${item.matHangId}'),
                ),
                _DataChip(
                    label: 'SL',
                    value: '${item.soLuong} bình'),
                const SizedBox(width: 8),
                _DataChip(
                    label: 'Đ/bình',
                    value: _fmtCurrency.format(item.donGia)),
              ],
            ),
            if (item.soVoBan > 0 || item.soVoThu > 0) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  _DataChip(
                      label: 'Vỏ bán',
                      value: '${item.soVoBan}',
                      color: Colors.blue),
                  const SizedBox(width: 8),
                  _DataChip(
                      label: 'Vỏ thu',
                      value: '${item.soVoThu}',
                      color: Colors.teal),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Tab 2: Thu vỏ bình ────────────────────────────────────────────────────

class _TabThuVo extends StatelessWidget {
  final ChuyenXeModel cx;
  const _TabThuVo({required this.cx});

  @override
  Widget build(BuildContext context) {
    final voThu = cx.ketThuc?.voThu ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 80, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (cx.ketThuc == null)
            _EmptyState(
                icon: Icons.recycling_rounded,
                label: 'Chuyến chưa kết thúc')
          else if (voThu.isEmpty)
            _EmptyState(
                icon: Icons.recycling_rounded,
                label: 'Không có dữ liệu thu vỏ')
          else ...[
            _SummaryRow(
                label: 'Tổng vỏ thu',
                value: '${cx.ketThuc!.soVoThuThucTe} bình',
                valueColor: Colors.teal),
            const SizedBox(height: 12),
            _SectionLabel('Chi tiết theo hãng'),
            const SizedBox(height: 8),
            ...voThu.map((v) => _VoThuCard(item: v)),
          ],
        ],
      ),
    );
  }
}

// Card một dòng thu vỏ.
class _VoThuCard extends StatelessWidget {
  final VoThuChiTietModel item;
  const _VoThuCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.teal.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.recycling_rounded,
              color: Colors.teal, size: 22),
        ),
        title: Text(
          item.tenMatHang ?? 'Mặt hàng #${item.matHangId}',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          item.tenNhaCungCap ?? 'Không xác định hãng',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${item.soVo} vỏ',
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Colors.teal),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tab 3: Thu tiền ─────────────────────────────────────────────────────────

class _TabThuTien extends StatelessWidget {
  final ChuyenXeModel cx;
  const _TabThuTien({required this.cx});

  @override
  Widget build(BuildContext context) {
    final kt = cx.ketThuc;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 80, 16, 24),
      child: kt == null
          ? _EmptyState(
              icon: Icons.payments_outlined,
              label: 'Chuyến chưa kết thúc')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (kt.ngayKetThuc != null) ...[
                  _InfoChip(
                      icon: Icons.check_circle_outline,
                      label: 'Kết thúc lúc',
                      value: _fmtDate.format(kt.ngayKetThuc!.toLocal()),
                      color: Colors.green),
                  const SizedBox(height: 12),
                ],

                // Tổng tiền nộp
                _SectionCard(
                  title: 'Tiền nộp',
                  child: Column(
                    children: [
                      _InfoRow(
                          icon: Icons.money,
                          label: 'Tiền mặt',
                          value: _fmtCurrency.format(kt.tienMat)),
                      const SizedBox(height: 8),
                      _InfoRow(
                          icon: Icons.account_balance_outlined,
                          label: 'Chuyển khoản',
                          value: _fmtCurrency.format(kt.tienCK)),
                      const Divider(height: 20),
                      _InfoRow(
                          icon: Icons.summarize_outlined,
                          label: 'Tổng nộp',
                          value: _fmtCurrency.format(kt.tongTienNop),
                          bold: true,
                          valueColor: const Color(0xFF00897B)),
                      if (kt.soTienNo > 0) ...[
                        const SizedBox(height: 8),
                        _InfoRow(
                            icon: Icons.warning_amber_outlined,
                            label: 'Còn nợ',
                            value: _fmtCurrency.format(kt.soTienNo),
                            bold: true,
                            valueColor: Colors.red),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Vỏ bình
                _SectionCard(
                  title: 'Vỏ bình',
                  child: Column(
                    children: [
                      _InfoRow(
                          icon: Icons.recycling_rounded,
                          label: 'Vỏ thu thực tế',
                          value: '${kt.soVoThuThucTe} bình'),
                      if (kt.soVoMua > 0) ...[
                        const SizedBox(height: 8),
                        _InfoRow(
                            icon: Icons.add_shopping_cart_outlined,
                            label: 'Vỏ mua thêm',
                            value: '${kt.soVoMua} bình'),
                        const SizedBox(height: 8),
                        _InfoRow(
                            icon: Icons.payments_outlined,
                            label: 'Tiền ứng mua vỏ',
                            value: _fmtCurrency.format(kt.tienUngMuaVo)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Các khoản trả lại
                if (kt.tongTienTraGasDu > 0 || kt.tongThuNoCu > 0)
                  _SectionCard(
                    title: 'Các khoản khác',
                    child: Column(
                      children: [
                        if (kt.tongTienTraGasDu > 0)
                          _InfoRow(
                              icon: Icons.local_gas_station_outlined,
                              label: 'Tiền trả gas dư',
                              value: _fmtCurrency.format(kt.tongTienTraGasDu),
                              valueColor: Colors.orange),
                        if (kt.tongTienTraGasDu > 0 && kt.tongThuNoCu > 0)
                          const SizedBox(height: 8),
                        if (kt.tongThuNoCu > 0)
                          _InfoRow(
                              icon: Icons.receipt_long_outlined,
                              label: 'Thu nợ cũ',
                              value: _fmtCurrency.format(kt.tongThuNoCu),
                              valueColor: Colors.purple),
                      ],
                    ),
                  ),

                if (kt.ghiChu != null && kt.ghiChu!.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _SectionCard(
                    title: 'Ghi chú',
                    child: Text(kt.ghiChu!,
                        style: const TextStyle(fontSize: 13)),
                  ),
                ],
              ],
            ),
    );
  }
}

// ── Tab 4: Ảnh xác nhận ─────────────────────────────────────────────────────

class _TabAnh extends StatelessWidget {
  final ChuyenXeModel cx;
  final bool uploading;
  final VoidCallback onUpload;

  const _TabAnh({
    required this.cx,
    required this.uploading,
    required this.onUpload,
  });

  /// Mở dialog xem ảnh toàn màn hình, cho phép swipe và pinch-to-zoom.
  static void _showFullScreen(BuildContext context, String baseUrl,
      List<AnhChuyenXeModel> anhs, int initialIndex) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => _FullScreenGallery(
        baseUrl: baseUrl,
        anhs: anhs,
        initialIndex: initialIndex,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final baseUrl =
        AppConstants.baseApiUrl.replaceFirst(RegExp(r'/apimanager$'), '');
    final canUpload = !uploading;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 80, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress badge
          Row(
            children: [
              _SectionLabel('Ảnh xác nhận giao hàng'),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: cx.anh.length >= 2
                      ? Colors.green.withValues(alpha: 0.12)
                      : Colors.orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${cx.anh.length}/2',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: cx.anh.length >= 2 ? Colors.green : Colors.orange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Ảnh grid hoặc empty state
          if (cx.anh.isEmpty)
            _EmptyState(
                icon: Icons.camera_alt_outlined,
                label: 'Chưa có ảnh. Nhấn nút bên dưới để upload.')
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: cx.anh.length,
              itemBuilder: (_, i) {
                final anh = cx.anh[i];
                return GestureDetector(
                  onTap: () => _showFullScreen(context, baseUrl, cx.anh, i),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          '$baseUrl${anh.url}',
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.broken_image,
                                color: Colors.grey),
                          ),
                        ),
                      ),
                      // Overlay zoom hint góc trên phải
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.zoom_in_rounded,
                              color: Colors.white, size: 14),
                        ),
                      ),
                      Positioned(
                        bottom: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _fmtDate.format(anh.uploadedAt.toLocal()),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

          if (cx.anh.length >= 2) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.check_circle,
                    size: 16, color: Colors.green.shade600),
                const SizedBox(width: 6),
                Text(
                  'Đã đủ 2 ảnh xác nhận',
                  style:
                      TextStyle(color: Colors.green.shade600, fontSize: 13),
                ),
              ],
            ),
          ],

          // Nút upload
          if (cx.anh.length < 2) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: canUpload ? onUpload : null,
                icon: uploading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.add_a_photo),
                label: Text(uploading ? 'Đang upload...' : 'Upload ảnh'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: uploading ? Colors.grey : null,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Tab 5: Mua gas dư từ khách hàng ─────────────────────────────────────────

class _TabGasDu extends StatelessWidget {
  final ChuyenXeModel cx;
  const _TabGasDu({required this.cx});

  @override
  Widget build(BuildContext context) {
    final gasDu = cx.ketThuc?.gasDu ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 80, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (cx.ketThuc == null)
            _EmptyState(
                icon: Icons.local_gas_station_outlined,
                label: 'Chuyến chưa kết thúc')
          else if (gasDu.isEmpty)
            _EmptyState(
                icon: Icons.local_gas_station_outlined,
                label: 'Không có mua gas dư trong chuyến này')
          else ...[
            _SummaryRow(
                label: 'Tổng tiền trả KH',
                value: _fmtCurrency
                    .format(cx.ketThuc!.tongTienTraGasDu),
                valueColor: Colors.orange),
            const SizedBox(height: 12),
            _SectionLabel('Chi tiết gas dư'),
            const SizedBox(height: 8),
            ...gasDu.map((g) => _GasDuCard(item: g)),
          ],
        ],
      ),
    );
  }
}

// Card một dòng gas dư.
class _GasDuCard extends StatelessWidget {
  final GasDuChiTietModel item;
  const _GasDuCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.store_outlined,
                    size: 18, color: Color(0xFF00897B)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.tenKhachHang ?? 'Khách hàng #${item.khachHangId}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ),
                Text(
                  _fmtCurrency.format(item.thanhTien),
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Colors.orange),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _DataChip(
                      label: 'Mặt hàng',
                      value: item.tenMatHang ?? 'ID ${item.matHangId}'),
                ),
                _DataChip(
                    label: 'Số kg',
                    value: '${item.soKg} kg'),
                const SizedBox(width: 8),
                _DataChip(
                    label: 'Đ/kg',
                    value: _fmtCurrency.format(item.donGia)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tab 6: Thu nợ cũ ─────────────────────────────────────────────────────────

class _TabThuNo extends StatelessWidget {
  final ChuyenXeModel cx;
  const _TabThuNo({required this.cx});

  @override
  Widget build(BuildContext context) {
    final traNoCu = cx.ketThuc?.traNoCu ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 80, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (cx.ketThuc == null)
            _EmptyState(
                icon: Icons.receipt_long_outlined,
                label: 'Chuyến chưa kết thúc')
          else if (traNoCu.isEmpty)
            _EmptyState(
                icon: Icons.receipt_long_outlined,
                label: 'Không có thu nợ cũ trong chuyến này')
          else ...[
            _SummaryRow(
                label: 'Tổng thu nợ',
                value:
                    _fmtCurrency.format(cx.ketThuc!.tongThuNoCu),
                valueColor: Colors.purple),
            const SizedBox(height: 12),
            _SectionLabel('Chi tiết thu nợ cũ'),
            const SizedBox(height: 8),
            ...traNoCu.map((n) => _TraNoCuCard(item: n)),
          ],
        ],
      ),
    );
  }
}

// Card một dòng thu nợ.
class _TraNoCuCard extends StatelessWidget {
  final TraNoCuModel item;
  const _TraNoCuCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.purple.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.receipt_long_outlined,
              color: Colors.purple, size: 22),
        ),
        title: Text(
          item.tenKhachHang ?? 'Khách hàng #${item.khachHangId}',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: item.ghiChu != null && item.ghiChu!.isNotEmpty
            ? Text(item.ghiChu!,
                style: const TextStyle(fontSize: 12, color: Colors.grey))
            : null,
        trailing: Text(
          _fmtCurrency.format(item.soTien),
          style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: Colors.purple),
        ),
      ),
    );
  }
}

// ── Fullscreen gallery ─────────────────────────────────────────────────────

/// Widget xem ảnh toàn màn hình: swipe ngang giữa các ảnh, pinch-to-zoom, timestamp.
class _FullScreenGallery extends StatefulWidget {
  final String baseUrl;
  final List<AnhChuyenXeModel> anhs;
  final int initialIndex;

  const _FullScreenGallery({
    required this.baseUrl,
    required this.anhs,
    required this.initialIndex,
  });

  @override
  State<_FullScreenGallery> createState() => _FullScreenGalleryState();
}

class _FullScreenGalleryState extends State<_FullScreenGallery> {
  late final PageController _pageCtrl;
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _pageCtrl = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: Stack(
        children: [
          // PageView cho phép swipe ngang giữa các ảnh
          PageView.builder(
            controller: _pageCtrl,
            itemCount: widget.anhs.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (_, i) {
              final anh = widget.anhs[i];
              return InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Center(
                  child: Image.network(
                    '${widget.baseUrl}${anh.url}',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.broken_image,
                      color: Colors.white54,
                      size: 64,
                    ),
                  ),
                ),
              );
            },
          ),

          // Nút đóng góc trên phải
          Positioned(
            top: 40,
            right: 16,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),

          // Indicator X/N + timestamp — góc dưới giữa
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Column(
                children: [
                  Text(
                    '${_current + 1} / ${widget.anhs.length}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _fmtDate.format(widget.anhs[_current].uploadedAt.toLocal()),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared widgets ─────────────────────────────────────────────────────────

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
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

/// Card bao quanh một nhóm thông tin với tiêu đề.
class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

/// Tiêu đề section nhỏ.
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey));
  }
}

/// Hàng tóm tắt nổi bật (label — value).
class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _SummaryRow(
      {required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: (valueColor ?? const Color(0xFF00897B)).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 14)),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: valueColor ?? const Color(0xFF00897B))),
        ],
      ),
    );
  }
}

/// Hàng thông tin với icon — label: value.
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.bold = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 17, color: Colors.grey),
        const SizedBox(width: 8),
        Text('$label:',
            style: const TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              fontSize: 13,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }
}

/// Chip thông tin nhỏ trong card chi tiết.
class _DataChip extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _DataChip({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? const Color(0xFF00897B);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  color: c.withValues(alpha: 0.7))),
          Text(value,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: c)),
        ],
      ),
    );
  }
}

/// Chip thông tin với icon + label + value theo hàng ngang.
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _InfoChip(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text('$label: ',
              style: TextStyle(fontSize: 12, color: color)),
          Text(value,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color)),
        ],
      ),
    );
  }
}

/// Trạng thái rỗng (empty state) cho các tab không có dữ liệu.
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String label;
  const _EmptyState({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 56, color: Colors.black26),
            const SizedBox(height: 14),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black45, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
