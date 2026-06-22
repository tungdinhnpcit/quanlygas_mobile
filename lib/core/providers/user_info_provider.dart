// lib/core/providers/user_info_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class UserInfo {
  final String fullName;
  final String username;
  final String roleCode;
  final int userId;
  final int nhanVienId;
  final String? avatarUrl;

  const UserInfo({
    required this.fullName,
    required this.username,
    required this.roleCode,
    required this.userId,
    required this.nhanVienId,
    this.avatarUrl,
  });
}

final userInfoProvider = FutureProvider<UserInfo>((ref) async {
  const storage = FlutterSecureStorage();
  final fullName       = await storage.read(key: 'full_name') ?? '';
  final username       = await storage.read(key: 'username') ?? '';
  final roleCode       = await storage.read(key: 'role_code') ?? '';
  final userIdStr      = await storage.read(key: 'user_id') ?? '0';
  final nhanVienIdStr  = await storage.read(key: 'nhan_vien_id') ?? '0';
  final avatarUrl      = await storage.read(key: 'avatar_url');
  return UserInfo(
    fullName:    fullName,
    username:    username,
    roleCode:    roleCode,
    userId:      int.tryParse(userIdStr) ?? 0,
    nhanVienId:  int.tryParse(nhanVienIdStr) ?? 0,
    avatarUrl:   (avatarUrl != null && avatarUrl.isNotEmpty) ? avatarUrl : null,
  );
});
