// lib/features/lich_tuan/presentation/providers/lich_tuan_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/lich_tuan_remote_datasource.dart';
import '../../domain/entities/lich_tuan_entity.dart';

final lichTuanDatasourceProvider = Provider<LichTuanRemoteDatasource>(
  (ref) => LichTuanRemoteDatasource(),
);

/// Lazy load — không gọi API trong constructor, screen tự gọi loadCurrentMonth() trong initState.
class LichTuanNotifier extends StateNotifier<AsyncValue<List<LichTuanEntity>>> {
  LichTuanNotifier(this._datasource) : super(const AsyncValue.data([]));

  final LichTuanRemoteDatasource _datasource;
  late DateTime _start;
  late DateTime _end;

  /// Khởi tạo khoảng tháng hiện tại và fetch dữ liệu.
  void loadCurrentMonth() {
    final now = DateTime.now();
    _start = DateTime(now.year, now.month, 1);
    _end = DateTime(now.year, now.month + 1, 0);
    fetch(start: _start, end: _end);
  }

  Future<void> fetch({required DateTime start, required DateTime end}) async {
    _start = start;
    _end = end;
    state = const AsyncValue.loading();
    try {
      final models = await _datasource.fetchLichTuan(start: start, end: end);
      final entities = models.map((m) => m.toEntity()).toList()
        ..sort((a, b) => a.ngayGioBDBase.compareTo(b.ngayGioBDBase));
      state = AsyncValue.data(entities);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() => fetch(start: _start, end: _end);
}

final lichTuanProvider =
    StateNotifierProvider.autoDispose<LichTuanNotifier, AsyncValue<List<LichTuanEntity>>>(
  (ref) => LichTuanNotifier(ref.watch(lichTuanDatasourceProvider)),
);

/// Grouped by date (yyyy-MM-dd key) for the screen
final lichTuanGroupedProvider =
    Provider<AsyncValue<Map<DateTime, List<LichTuanEntity>>>>((ref) {
  return ref.watch(lichTuanProvider).whenData((list) {
    final map = <DateTime, List<LichTuanEntity>>{};
    for (final item in list) {
      final dateKey = DateTime(
        item.ngayGioBDBase.year,
        item.ngayGioBDBase.month,
        item.ngayGioBDBase.day,
      );
      map.putIfAbsent(dateKey, () => []).add(item);
    }
    return map;
  });
});
