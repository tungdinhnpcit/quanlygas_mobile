// lib/features/thong_bao/presentation/providers/thong_bao_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/user_info_provider.dart';
import '../../../../core/services/background_polling_service.dart';
import '../../data/models/thong_bao_model.dart';
import '../../data/repositories/thong_bao_repository.dart';

final thongBaoRepositoryProvider = Provider<ThongBaoRepository>(
  (_) => ThongBaoRepository(),
);

/// State danh sách thông báo có phân trang.
class ThongBaoPageState {
  final List<ThongBaoModel> items;
  final bool isLoading;      // đang tải trang đầu
  final bool isLoadingMore;  // đang tải thêm
  final bool hasMore;
  final Object? error;

  const ThongBaoPageState({
    this.items = const [],
    this.isLoading = true,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
  });

  ThongBaoPageState copyWith({
    List<ThongBaoModel>? items,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    Object? error,
    bool clearError = false,
  }) =>
      ThongBaoPageState(
        items: items ?? this.items,
        isLoading: isLoading ?? this.isLoading,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        hasMore: hasMore ?? this.hasMore,
        error: clearError ? null : (error ?? this.error),
      );
}

class ThongBaoListNotifier extends StateNotifier<ThongBaoPageState> {
  final ThongBaoRepository _repo;
  final Ref _ref;
  final bool? _daDoc;   // null=tất cả, false=chưa đọc, true=đã đọc
  int _userId = 0;
  int _page = 1;
  static const int _pageSize = 20;

  ThongBaoListNotifier(this._repo, this._ref, this._daDoc) : super(const ThongBaoPageState());

  /// Tải trang đầu (reset). Truyền userId lần đầu.
  Future<void> loadFirst(int userId) async {
    _userId = userId;
    if (_userId <= 0) return;
    _page = 1;
    state = const ThongBaoPageState(isLoading: true);
    try {
      final res = await _repo.getListPaged(_userId, page: _page, pageSize: _pageSize, daDoc: _daDoc);
      if (!mounted) return;
      state = ThongBaoPageState(
        items: res.items,
        isLoading: false,
        hasMore: res.items.length < res.total,
      );
    } catch (e) {
      if (!mounted) return;
      state = ThongBaoPageState(isLoading: false, hasMore: false, error: e);
    }
  }

  Future<void> refresh() => loadFirst(_userId);

  /// Tải thêm trang kế tiếp (infinite scroll).
  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.isLoading) return;
    state = state.copyWith(isLoadingMore: true);
    _page += 1;
    try {
      final res = await _repo.getListPaged(_userId, page: _page, pageSize: _pageSize, daDoc: _daDoc);
      if (!mounted) return;
      final merged = [...state.items, ...res.items];
      state = state.copyWith(
        items: merged,
        isLoadingMore: false,
        hasMore: merged.length < res.total,
      );
    } catch (_) {
      _page -= 1; // rollback để thử lại lần sau
      if (!mounted) return;
      state = state.copyWith(isLoadingMore: false);
    }
  }

  /// Đánh dấu đã đọc — optimistic local + gọi API + đồng bộ các tab khác + badge.
  Future<void> markAsRead(int id) async {
    // Cập nhật local: nếu đang ở tab "Chưa đọc" thì bỏ item khỏi list, ngược lại set daDoc
    final updated = _daDoc == false
        ? state.items.where((t) => t.id != id).toList()
        : state.items.map((t) => t.id == id ? t.copyWith(daDoc: true) : t).toList();
    state = state.copyWith(items: updated);
    try {
      await _repo.markAsRead(id);
    } catch (_) {}
    if (!mounted) return;
    _ref.invalidate(soChuaDocProvider);
    _invalidateOtherTabs();
  }

  /// Đánh dấu tất cả đã đọc.
  Future<void> markAllAsRead(int userId) async {
    try {
      await _repo.markAllAsRead(userId);
      if (!mounted) return;
      _ref.invalidate(soChuaDocProvider);
      await BackgroundPollingService.updateLastKnownCount(0);
    } catch (_) {}
    if (!mounted) return;
    // Cập nhật state tại chỗ cho cả 3 tab — không invalidate vì tab đang hiển thị
    // sẽ bị dispose/tạo lại với isLoading=true mà không có ai gọi loadFirst() lại,
    // khiến loading treo vô thời hạn (autoDispose family không tự refetch).
    for (final f in <bool?>[null, false, true]) {
      _ref.read(thongBaoListProvider(f).notifier)._applyAllRead();
    }
  }

  /// Áp dụng "đã đọc tất cả" lên state của instance này.
  void _applyAllRead() {
    if (!mounted) return;
    if (_daDoc == false) {
      // Tab "Chưa đọc": mọi item giờ đã đọc → không còn thuộc tab này
      state = state.copyWith(items: const []);
    } else {
      state = state.copyWith(
        items: state.items.map((t) => t.copyWith(daDoc: true)).toList(),
      );
    }
  }

  // Reset các instance family khác (giữ tab hiện tại đã cập nhật optimistic)
  void _invalidateOtherTabs() {
    for (final f in <bool?>[null, false, true]) {
      if (f != _daDoc) _ref.invalidate(thongBaoListProvider(f));
    }
  }
}

/// Family theo bộ lọc: null=Tất cả, false=Chưa đọc, true=Đã đọc.
final thongBaoListProvider = StateNotifierProvider.autoDispose
    .family<ThongBaoListNotifier, ThongBaoPageState, bool?>(
  (ref, daDoc) => ThongBaoListNotifier(ref.watch(thongBaoRepositoryProvider), ref, daDoc),
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
