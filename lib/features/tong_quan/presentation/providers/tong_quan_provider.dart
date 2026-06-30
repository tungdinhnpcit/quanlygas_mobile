// lib/features/tong_quan/presentation/providers/tong_quan_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/tong_quan_model.dart';
import '../../data/repositories/tong_quan_repository.dart';
import '../../../chuyen_xe/data/models/chuyen_xe_model.dart';
import '../../../chuyen_xe/data/repositories/chuyen_xe_repository.dart';

final tongQuanRepositoryProvider = Provider<TongQuanRepository>(
  (_) => TongQuanRepository(),
);

// ── Dashboard mới ────────────────────────────────────────────────────────────

class TongQuanDateRange {
  final DateTime tuNgay;
  final DateTime denNgay;
  const TongQuanDateRange(this.tuNgay, this.denNgay);
}

class TongQuanNotifier extends StateNotifier<AsyncValue<TongQuanDashboard>> {
  final TongQuanRepository _repo;
  late DateTime _tuNgay;
  late DateTime _denNgay;

  TongQuanNotifier(this._repo) : super(const AsyncValue.loading()) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    _tuNgay  = today;
    _denNgay = today;
    _load();
  }

  DateTime get tuNgay  => _tuNgay;
  DateTime get denNgay => _denNgay;

  Future<void> _load() async {
    state = const AsyncValue.loading();
    try {
      final data = await _repo.getTongQuan(_tuNgay, _denNgay);
      state = AsyncValue.data(data);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void setDateRange(DateTime tuNgay, DateTime denNgay) {
    _tuNgay  = tuNgay;
    _denNgay = denNgay;
    _load();
  }

  void refresh() => _load();
}

final tongQuanDashboardProvider =
    StateNotifierProvider.autoDispose<TongQuanNotifier, AsyncValue<TongQuanDashboard>>(
  (ref) => TongQuanNotifier(ref.read(tongQuanRepositoryProvider)),
);

/// Chi tiết bán hàng cho 1 đại lý — FutureProvider.family.autoDispose
/// arg = (khachHangId, tuNgay, denNgay)
final daiLyBanHangProvider = FutureProvider.autoDispose
    .family<List<DaiLyBanHangModel>, (int, DateTime, DateTime)>((ref, args) {
  final (khachHangId, tuNgay, denNgay) = args;
  return ref.read(tongQuanRepositoryProvider).getDaiLyBanHang(khachHangId, tuNgay, denNgay);
});

/// Danh sách khách hàng lâu chưa mua
final khachHangChuaMuaProvider =
    FutureProvider.autoDispose<List<KhachHangChuaMuaModel>>((ref) {
  return ref.read(tongQuanRepositoryProvider).getKhachHangChuaMua();
});

/// Danh sách chuyến xe không giới hạn lái xe, lọc theo khoảng ngày — dùng cho màn Tổng quan
final thongKeChuyenXeProvider = FutureProvider.autoDispose
    .family<List<ChuyenXeModel>, (DateTime, DateTime)>((ref, args) {
  final (tuNgay, denNgay) = args;
  return ChuyenXeRepository().getListAll(tuNgay: tuNgay, denNgay: denNgay, pageSize: 100);
});
