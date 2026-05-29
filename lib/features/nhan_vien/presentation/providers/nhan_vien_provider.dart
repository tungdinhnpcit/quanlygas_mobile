// lib/features/nhan_vien/presentation/providers/nhan_vien_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/nhan_vien_model.dart';
import '../../data/repositories/nhan_vien_repository.dart';

final nhanVienRepositoryProvider = Provider<NhanVienRepository>((_) => NhanVienRepository());

/// Lazy load — không gọi API trong constructor, screen tự gọi load() trong initState.
class NhanVienListNotifier extends StateNotifier<AsyncValue<List<NhanVienModel>>> {
  final NhanVienRepository _repo;
  NhanVienListNotifier(this._repo) : super(const AsyncValue.data([]));

  Future<void> load({String? search}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.getPaged(search: search));
  }
}

final nhanVienListProvider =
    StateNotifierProvider.autoDispose<NhanVienListNotifier, AsyncValue<List<NhanVienModel>>>(
  (ref) => NhanVienListNotifier(ref.watch(nhanVienRepositoryProvider)),
);

final nhanVienDetailProvider = FutureProvider.family<NhanVienModel, int>((ref, id) {
  return ref.watch(nhanVienRepositoryProvider).getById(id);
});
