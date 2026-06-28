// lib/features/khach_hang/presentation/providers/khach_hang_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/khach_hang_model.dart';
import '../../data/repositories/khach_hang_repository.dart';

final khachHangRepositoryProvider =
    Provider<KhachHangRepository>((_) => KhachHangRepository());

/// Lazy load — không gọi API trong constructor, screen tự gọi load() trong initState.
class KhachHangListNotifier extends StateNotifier<AsyncValue<List<KhachHangModel>>> {
  final KhachHangRepository _repo;
  KhachHangListNotifier(this._repo) : super(const AsyncValue.data([]));

  Future<void> load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.getAll());
  }
}

final khachHangListProvider = StateNotifierProvider.autoDispose<KhachHangListNotifier,
    AsyncValue<List<KhachHangModel>>>(
  (ref) => KhachHangListNotifier(ref.watch(khachHangRepositoryProvider)),
);

final khachHangDetailProvider =
    FutureProvider.family<KhachHangModel, int>((ref, id) {
  return ref.watch(khachHangRepositoryProvider).getById(id);
});
