// lib/features/auth/presentation/screens/login_screen.dart
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/user_info_provider.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../features/menu/providers/menu_provider.dart';
import '../../data/auth_repository.dart';
import '../../data/biometric_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey      = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _obscure             = true;
  bool _loading             = false;
  bool _biometricAvailable  = false; // device hỗ trợ biometric (hiển thị button)
  bool _biometricReady      = false; // đã enable + có session (login được ngay)
  String? _error;

  final _repo      = AuthRepository();
  final _biometric = BiometricService();

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      _usernameCtrl.text = 'admin';
      _passwordCtrl.text = '123456';
    }
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    final available = await _biometric.isAvailable();
    if (!available) return;

    final enabled  = await _biometric.isBiometricEnabled();
    final hasToken = await _repo.isLoggedIn();
    setState(() {
      _biometricAvailable = true;
      _biometricReady     = enabled && hasToken;
    });
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      final response = await _repo.login(
        _usernameCtrl.text.trim(),
        _passwordCtrl.text,
      );
      if (!mounted) return;

      final available = await _biometric.isAvailable();
      final enabled   = await _biometric.isBiometricEnabled();
      if (available && !enabled) {
        await _showEnableBiometricSheet(response.username);
      } else {    
        await _biometric.saveUsername(response.username);
      }

      if (mounted) {
        ref.invalidate(menuProvider);
        ref.invalidate(userInfoProvider);
        context.go(AppRoutes.home);
      }
    } catch (_) {
      setState(() => _error = 'Sai tên đăng nhập hoặc mật khẩu');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loginWithBiometric() async {
    if (!_biometricReady) {
      setState(() => _error = 'Vui lòng đăng nhập bằng mật khẩu trước để kích hoạt vân tay');
      return;
    }

    setState(() { _loading = true; _error = null; });
    try {
      final ok = await _biometric.authenticate();
      if (!ok) {
        setState(() { _error = 'Xác thực vân tay thất bại'; _loading = false; });
        return;
      }

      final storage = await _repo.getStoredRefreshToken();
      if (storage == null) {
        await _biometric.disableBiometric();
        setState(() { _biometricReady = false; _error = 'Phiên đăng nhập hết hạn, vui lòng nhập mật khẩu'; _loading = false; });
        return;
      }

      await _repo.refresh(storage);
      if (mounted) {
        ref.invalidate(menuProvider);
        ref.invalidate(userInfoProvider);
        context.go(AppRoutes.home);
      }
    } catch (_) {
      await _biometric.disableBiometric();
      setState(() {
        _biometricReady = false;
        _error = 'Phiên đăng nhập hết hạn, vui lòng nhập mật khẩu';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showEnableBiometricSheet(String username) async {
    if (!mounted) return;
    final enable = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: const Color(0xFF1A3A4A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.fingerprint, size: 56, color: Color(0xFF00897B)),
            const SizedBox(height: 12),
            const Text(
              'Bật đăng nhập bằng vân tay?',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Lần sau bạn có thể đăng nhập nhanh mà không cần nhập mật khẩu.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white60, fontSize: 14),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white60,
                      side: const BorderSide(color: Colors.white24),
                    ),
                    child: const Text('Để sau'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF00897B),
                    ),
                    child: const Text('Bật'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    if (enable == true) {
      await _biometric.enableBiometric();
      await _biometric.saveUsername(username);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          _Background(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _Header(),
                    const SizedBox(height: 36),
                    _Card(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _UsernameField(controller: _usernameCtrl),
                            const SizedBox(height: 16),
                            _PasswordField(
                              controller: _passwordCtrl,
                              obscure: _obscure,
                              onToggle: () => setState(() => _obscure = !_obscure),
                              onSubmit: (_) => _submit(),
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: 10),
                              _ErrorText(message: _error!),
                            ],
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: _LoginButton(loading: _loading, onTap: _submit),
                                ),
                                if (_biometricAvailable) ...[
                                  const SizedBox(width: 12),
                                  _BiometricIconButton(
                                    loading: _loading,
                                    onTap: _loginWithBiometric,
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'v1.0.0',
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
//  Sub-widgets
// ──────────────────────────────────────────────

class _Background extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D1B2A), Color(0xFF1A3A4A), Color(0xFF0D2233)],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        Icon(Icons.local_fire_department_rounded, size: 64, color: Color(0xFF00BCD4)),
        SizedBox(height: 10),
        Text(
          'GAS MANAGER',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: 3,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Quản lý phân phối khí gas',
          style: TextStyle(color: Colors.white54, fontSize: 14),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _UsernameField extends StatelessWidget {
  final TextEditingController controller;
  const _UsernameField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      textInputAction: TextInputAction.next,
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration(
        label: 'Tên đăng nhập',
        icon: Icons.person_outline_rounded,
      ),
      validator: (v) =>
          (v == null || v.trim().isEmpty) ? 'Vui lòng nhập tên đăng nhập' : null,
    );
  }
}

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggle;
  final ValueChanged<String> onSubmit;

  const _PasswordField({
    required this.controller,
    required this.obscure,
    required this.onToggle,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: onSubmit,
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration(
        label: 'Mật khẩu',
        icon: Icons.lock_outline_rounded,
      ).copyWith(
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: Colors.white54,
          ),
          onPressed: onToggle,
        ),
      ),
      validator: (v) =>
          (v == null || v.isEmpty) ? 'Vui lòng nhập mật khẩu' : null,
    );
  }
}

class _LoginButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onTap;
  const _LoginButton({required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: FilledButton(
        onPressed: loading ? null : onTap,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF00897B),
          disabledBackgroundColor: const Color(0xFF00897B).withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: loading
            ? const SizedBox(
                height: 22, width: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
              )
            : const Text(
                'ĐĂNG NHẬP',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 1.5),
              ),
      ),
    );
  }
}

/// Nút vân tay hình vuông 50×50 đặt cạnh nút đăng nhập chính
class _BiometricIconButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onTap;
  const _BiometricIconButton({required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 50,
      height: 50,
      child: Tooltip(
        message: 'Đăng nhập bằng vân tay',
        child: OutlinedButton(
          onPressed: loading ? null : onTap,
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.zero,
            side: const BorderSide(color: Color(0xFF00BCD4), width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Icon(Icons.fingerprint, size: 26, color: Color(0xFF00BCD4)),
        ),
      ),
    );
  }
}

class _ErrorText extends StatelessWidget {
  final String message;
  const _ErrorText({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.redAccent, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

InputDecoration _inputDecoration({required String label, required IconData icon}) {
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: Colors.white54),
    prefixIcon: Icon(icon, color: Colors.white54),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.white24),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF00897B), width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.redAccent),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
    ),
    filled: true,
    fillColor: Colors.white.withValues(alpha: 0.06),
  );
}
