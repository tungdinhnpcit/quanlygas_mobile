// lib/core/providers/sync_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/connectivity_service.dart';
import '../services/sync_service.dart';
import '../database/local_database.dart';

// Trạng thái online/offline của thiết bị
final isOnlineProvider = StreamProvider<bool>((ref) {
  return ConnectivityService.instance.onChanged;
});

// Số lượng bản ghi chưa đồng bộ (dùng cho badge DongBoScreen)
final pendingCountProvider = FutureProvider<int>((ref) async {
  return LocalDatabase.instance.getPendingCount();
});

// State của tiến trình đồng bộ
class SyncNotifier extends StateNotifier<AsyncValue<SyncUploadResult?>> {
  SyncNotifier() : super(const AsyncValue.data(null));

  Future<SyncUploadResult> uploadPending() async {
    state = const AsyncValue.loading();
    try {
      final result = await SyncService.instance.uploadPendingData();
      state = AsyncValue.data(result);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<SyncResult> syncCatalog() async {
    return SyncService.instance.syncCatalog();
  }
}

final syncNotifierProvider =
    StateNotifierProvider<SyncNotifier, AsyncValue<SyncUploadResult?>>(
  (ref) => SyncNotifier(),
);
