// lib/features/nha_cung_cap/presentation/providers/nha_cung_cap_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/nha_cung_cap_model.dart';
import '../../data/repositories/nha_cung_cap_repository.dart';

final nhaCungCapRepositoryProvider = Provider<NhaCungCapRepository>((_) => NhaCungCapRepository());

/// Lazy load — không gọi API trong constructor, screen tự gọi load() trong initState.
class NhaCungCapListNotifier extends StateNotifier<AsyncValue<List<NhaCungCapModel>>> {
  final NhaCungCapRepository _repo;
  NhaCungCapListNotifier(this._repo) : super(const AsyncValue.data([]));

  Future<void> load({String? search}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.getPaged(search: search));
  }
}

final nhaCungCapListProvider =
    StateNotifierProvider.autoDispose<NhaCungCapListNotifier, AsyncValue<List<NhaCungCapModel>>>(
  (ref) => NhaCungCapListNotifier(ref.watch(nhaCungCapRepositoryProvider)),
);

final nhaCungCapDetailProvider = FutureProvider.family<NhaCungCapModel, int>((ref, id) {
  return ref.watch(nhaCungCapRepositoryProvider).getById(id);
});
