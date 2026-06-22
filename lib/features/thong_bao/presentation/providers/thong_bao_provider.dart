// lib/features/thong_bao/presentation/providers/thong_bao_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/user_info_provider.dart';
import '../../../../core/services/background_polling_service.dart';
import '../../data/models/thong_bao_model.dart';
import '../../data/repositories/thong_bao_repository.dart';

final thongBaoRepositoryProvider = Provider<ThongBaoRepository>(
  (_) => ThongBaoRepository(),
);

class ThongBaoListNotifier extends StateNotifier<AsyncValue<List<ThongBaoModel>>> {
  final ThongBaoRepository _repo;
  final Ref _ref;
  int _userId = 0;

  ThongBaoListNotifier(this._repo, this._ref) : super(const AsyncValue.data([]));

  /// Tải danh sách thông báo. Lần đầu phải truyền userId.
  /// Chưa đọc được sắp xếp lên đầu, trong từng nhóm mới nhất trước.
  Future<void> load({int? userId}) async {
    if (userId != null) _userId = userId;
    if (_userId <= 0) return;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final items = await _repo.getList(_userId);
      items.sort((a, b) {
        if (a.daDoc != b.daDoc) return a.daDoc ? 1 : -1;
        return b.createdAt.compareTo(a.createdAt);
      });
      return items;
    });
  }

  /// Đánh dấu đã đọc — cập nhật state local ngay, gọi API nền.
  Future<void> markAsRead(int id) async {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncValue.data(
      current.map((t) => t.id == id ? t.copyWith(daDoc: true) : t).toList(),
    );
    try { await _repo.markAsRead(id); } catch (_) {}
  }

  /// Đánh dấu tất cả thông báo chưa đọc là đã đọc
  Future<void> markAllAsRead() async {
    final current = state.valueOrNull;
    if (current == null) return;
    // Optimistic update: đánh dấu tất cả là đã đọc trong state local
    state = AsyncValue.data(
      current.map((t) => t.copyWith(daDoc: true)).toList(),
    );
    try {
      await _repo.markAllAsRead(_userId);
      // Invalidate badge count
      _ref.invalidate(soChuaDocProvider);
      // Cập nhật baseline polling để tránh re-notification
      await BackgroundPollingService.updateLastKnownCount(0);
    } catch (_) {}
  }
}

final thongBaoListProvider =
    StateNotifierProvider.autoDispose<ThongBaoListNotifier, AsyncValue<List<ThongBaoModel>>>(
  (ref) => ThongBaoListNotifier(ref.watch(thongBaoRepositoryProvider), ref),
);

/// Chi tiết thông báo — FutureProvider.family, không phụ thuộc list cache.
/// Quan trọng: hoạt động khi app cold-start từ notification tap.
final thongBaoDetailProvider =
    FutureProvider.autoDispose.family<ThongBaoModel, int>((ref, id) {
  return ref.watch(thongBaoRepositoryProvider).getById(id);
});

/// Đếm số chưa đọc — dùng cho badge trên bottom nav.
final soChuaDocProvider = FutureProvider.autoDispose<int>((ref) async {
  final userInfo = await ref.watch(userInfoProvider.future);
  if (userInfo.userId <= 0) return 0;
  final count = await ref.watch(thongBaoRepositoryProvider).getSoChuaDoc(userInfo.userId);
  // Cập nhật baseline polling mỗi khi refresh badge
  await BackgroundPollingService.updateLastKnownCount(count);
  return count;
});
