// lib/features/thong_bao/presentation/providers/thong_bao_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/thong_bao_model.dart';
import '../../data/repositories/thong_bao_repository.dart';

final thongBaoRepositoryProvider = Provider<ThongBaoRepository>(
  (_) => ThongBaoRepository(),
);

/// Lazy load — không gọi API trong constructor, screen tự gọi load() với recipientId trong initState.
class ThongBaoListNotifier extends StateNotifier<AsyncValue<List<ThongBaoModel>>> {
  final ThongBaoRepository _repo;
  String _recipientId = '0';

  ThongBaoListNotifier(this._repo) : super(const AsyncValue.data([]));

  /// Tải lịch sử thông báo. Lần đầu phải truyền recipientId (userId dạng string).
  Future<void> load({String? recipientId}) async {
    if (recipientId != null) _recipientId = recipientId;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.getHistory(_recipientId));
  }
}

final thongBaoListProvider =
    StateNotifierProvider.autoDispose<ThongBaoListNotifier, AsyncValue<List<ThongBaoModel>>>(
  (ref) => ThongBaoListNotifier(ref.watch(thongBaoRepositoryProvider)),
);
