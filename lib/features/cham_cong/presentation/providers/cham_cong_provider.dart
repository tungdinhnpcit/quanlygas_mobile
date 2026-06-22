// lib/features/cham_cong/presentation/providers/cham_cong_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/cham_cong_model.dart';
import '../../data/repositories/cham_cong_repository.dart';

// StateNotifier — quản lý state danh sách chấm công
class ChamCongNotifier extends StateNotifier<AsyncValue<List<ChamCongModel>>> {
  final ChamCongRepository _repo;

  int _nhanVienId = 0;
  int _thang = 0;
  int _nam = 0;

  ChamCongNotifier(this._repo) : super(const AsyncValue.data([])) {
    final now = DateTime.now();
    _thang = now.month;
    _nam = now.year;
  }

  // Load danh sách chấm công — guard: không gọi nếu nhanVienId == 0
  Future<void> load({int? nhanVienId, int? thang, int? nam}) async {
    if (nhanVienId != null) _nhanVienId = nhanVienId;
    if (thang != null) _thang = thang;
    if (nam != null) _nam = nam;

    // Guard: không load nếu chưa xác định được nhân viên
    if (_nhanVienId <= 0) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repo.getThang(thang: _thang, nam: _nam, nhanVienId: _nhanVienId),
    );
  }

  // Cập nhật tháng/năm rồi reload
  void setThang(int thang, int nam) {
    _thang = thang;
    _nam = nam;
    if (_nhanVienId > 0) load();
  }

  // Reset filter
  void clearFilter() {
    _nhanVienId = 0;
    state = const AsyncValue.data([]);
  }
}

final chamCongRepositoryProvider2 = Provider<ChamCongRepository>((ref) {
  return ref.watch(chamCongRepositoryProvider);
});

final chamCongProvider = StateNotifierProvider.autoDispose<
    ChamCongNotifier,
    AsyncValue<List<ChamCongModel>>>((ref) {
  final repo = ref.watch(chamCongRepositoryProvider);
  return ChamCongNotifier(repo);
});
