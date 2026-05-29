// lib/features/auth/data/biometric_service.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();
  final _storage = const FlutterSecureStorage();

  static const _keyEnabled  = 'biometric_enabled';
  static const _keyUsername = 'saved_username';

  Future<bool> isAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      if (!canCheck) return false;
      final biometrics = await _auth.getAvailableBiometrics();
      return biometrics.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Xác thực vân tay để đăng nhập Gas Manager',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  Future<bool> isBiometricEnabled() async {
    final val = await _storage.read(key: _keyEnabled);
    return val == 'true';
  }

  Future<void> enableBiometric() async {
    await _storage.write(key: _keyEnabled, value: 'true');
  }

  Future<void> disableBiometric() async {
    await _storage.delete(key: _keyEnabled);
    await _storage.delete(key: _keyUsername);
  }

  Future<String?> getSavedUsername() async {
    return _storage.read(key: _keyUsername);
  }

  Future<void> saveUsername(String username) async {
    await _storage.write(key: _keyUsername, value: username);
  }
}
