import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/ghi_chu_model.dart';
import '../../data/repositories/ghi_chu_repository.dart';

final ghiChuRepositoryProvider =
Provider<GhiChuRepository>((_) => GhiChuRepository());

class GhiChuListNotifier extends StateNotifier<AsyncValue<List<GhiChuModel>>> {
  final GhiChuRepository _repo;
  GhiChuListNotifier(this._repo) : super(const AsyncValue.data([]));

  Future<void> load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.getAll());
  }

  Future<void> save(GhiChuModel m) async {
    await _repo.save(m);
    await load();
  }

  Future<void> remove(int id) async {
    await _repo.delete(id);
    await load();
  }
}

final ghiChuListProvider = StateNotifierProvider.autoDispose<GhiChuListNotifier,
    AsyncValue<List<GhiChuModel>>>(
      (ref) => GhiChuListNotifier(ref.watch(ghiChuRepositoryProvider)),
);