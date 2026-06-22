// lib/features/menu/providers/menu_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/data/auth_models.dart';

final _repo = AuthRepository();

/// Danh sách menu của user hiện tại (lọc theo platform mobile/both)
final menuProvider = FutureProvider<List<MenuInfo>>((ref) async {
  final all = await _repo.getSavedMenus();
  return all
      .where((m) => m.mobileRoute != null &&
          (m.platform == 'mobile' || m.platform == 'both'))
      .toList()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
});

/// Danh sách quyền của user hiện tại
final rightsProvider = FutureProvider<List<RightInfo>>((ref) async {
  return _repo.getSavedRights();
});

/// Check quyền theo right_code
final permissionProvider = Provider.family<bool, String>((ref, rightCode) {
  final rights = ref.watch(rightsProvider).valueOrNull ?? [];
  return rights.any((r) => r.rightCode == rightCode);
});
