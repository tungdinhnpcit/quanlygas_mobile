// lib/features/tong_quan/presentation/providers/tong_quan_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/tong_quan_model.dart';
import '../../data/repositories/tong_quan_repository.dart';

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
  DateTime _tuNgay;
  DateTime _denNgay;

  TongQuanNotifier(this._repo)
      : _tuNgay  = DateTime.now().subtract(const Duration(days: 30)),
        _denNgay = DateTime.now(),
        super(const AsyncValue.loading()) {
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
