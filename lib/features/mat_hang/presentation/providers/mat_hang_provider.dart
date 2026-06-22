// lib/features/mat_hang/presentation/providers/mat_hang_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/mat_hang_model.dart';
import '../../data/repositories/mat_hang_repository.dart';

final matHangRepositoryProvider = Provider<MatHangRepository>((_) => MatHangRepository());

/// Lazy load — không gọi API trong constructor, screen tự gọi load() trong initState.
class MatHangListNotifier extends StateNotifier<AsyncValue<List<MatHangModel>>> {
  final MatHangRepository _repo;
  MatHangListNotifier(this._repo) : super(const AsyncValue.data([]));

  Future<void> load({String? search}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.getPaged(search: search));
  }
}

final matHangListProvider =
    StateNotifierProvider.autoDispose<MatHangListNotifier, AsyncValue<List<MatHangModel>>>(
  (ref) => MatHangListNotifier(ref.watch(matHangRepositoryProvider)),
);

final matHangDetailProvider = FutureProvider.family<MatHangModel, int>((ref, id) {
  return ref.watch(matHangRepositoryProvider).getById(id);
});
