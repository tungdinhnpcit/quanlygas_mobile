// lib/features/xe/presentation/providers/xe_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/xe_model.dart';
import '../../data/repositories/xe_repository.dart';

final xeRepositoryProvider = Provider<XeRepository>((_) => XeRepository());

/// Lazy load — không gọi API trong constructor, screen tự gọi load() trong initState.
class XeListNotifier extends StateNotifier<AsyncValue<List<XeModel>>> {
  final XeRepository _repo;
  XeListNotifier(this._repo) : super(const AsyncValue.data([]));

  Future<void> load({String? search}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.getPaged(search: search));
  }
}

final xeListProvider =
    StateNotifierProvider.autoDispose<XeListNotifier, AsyncValue<List<XeModel>>>(
  (ref) => XeListNotifier(ref.watch(xeRepositoryProvider)),
);

final xeDetailProvider = FutureProvider.family<XeModel, int>((ref, id) {
  return ref.watch(xeRepositoryProvider).getById(id);
});
