// lib/features/auth/presentation/screens/login_screen_v3.dart
//
// Giao diện theo Figma "Login Screens for Mobile App Design"
// (https://www.figma.com/design/Gtq8hIplGuhzOjJiQKI9tr/...?node-id=253-2491)
// Đã nối logic đăng nhập thật (username/password + vân tay) — lấy từ login_screen.dart.

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/user_info_provider.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../features/menu/providers/menu_provider.dart';
import '../../../../features/thong_bao/presentation/providers/thong_bao_provider.dart';
import '../../data/auth_repository.dart';
import '../../data/biometric_service.dart';

class LoginScreenV3 extends ConsumerStatefulWidget {
  const LoginScreenV3({super.key});

  @override
  ConsumerState<LoginScreenV3> createState() => _LoginScreenV3State();
}

class _LoginScreenV3State extends ConsumerState<LoginScreenV3> {
  static const _coral = Color(0xFFFF6482);
  static const _coralDark = Color(0xFFFF3D68);

  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _obscure = true;
  bool _loading = false;
  bool _biometricAvailable = false;
  bool _biometricReady = false;
  String? _error;

  final _repo = AuthRepository();
  final _biometric = BiometricService();

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      _usernameCtrl.text = 'admin';
      _passwordCtrl.text = 'diepSam@2026##';
    }
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    final available = await _biometric.isAvailable();
    if (!available) return;

    final enabled = await _biometric.isBiometricEnabled();
    final hasToken = await _repo.isLoggedIn();
    setState(() {
      _biometricAvailable = true;
      _biometricReady = enabled && hasToken;
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
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await _repo.login(
        _usernameCtrl.text.trim(),
        _passwordCtrl.text,
      );
      if (!mounted) return;

      final available = await _biometric.isAvailable();
      final enabled = await _biometric.isBiometricEnabled();
      if (available && !enabled) {
        await _showEnableBiometricSheet(response.username);
      } else {
        await _biometric.saveUsername(response.username);
      }

      if (mounted) {
        ref.invalidate(menuProvider);
        ref.invalidate(userInfoProvider);
        ref.invalidate(soChuaDocProvider);
        context.go(AppRoutes.home);
      }
    } catch (e) {
      String msg;
      if (e is DioException) {
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.connectionError) {
          msg = 'Không kết nối được đến máy chủ (${e.requestOptions.baseUrl})';
        } else if (e.response?.statusCode == 401 ||
            e.response?.statusCode == 400) {
          msg = 'Sai tên đăng nhập hoặc mật khẩu';
        } else {
          msg = 'Lỗi: ${e.message ?? e.type.name}';
        }
      } else {
        msg = 'Lỗi: $e';
      }
      setState(() => _error = msg);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loginWithBiometric() async {
    if (!_biometricReady) {
      setState(
        () => _error =
            'Vui lòng đăng nhập bằng mật khẩu trước để kích hoạt vân tay',
      );
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final ok = await _biometric.authenticate();
      if (!ok) {
        setState(() {
          _error = 'Xác thực vân tay thất bại';
          _loading = false;
        });
        return;
      }

      final storage = await _repo.getStoredRefreshToken();
      if (storage == null) {
        await _biometric.disableBiometric();
        setState(() {
          _biometricReady = false;
          _error = 'Phiên đăng nhập hết hạn, vui lòng nhập mật khẩu';
          _loading = false;
        });
        return;
      }

      await _repo.refresh(storage);
      if (mounted) {
        ref.invalidate(menuProvider);
        ref.invalidate(userInfoProvider);
        ref.invalidate(soChuaDocProvider);
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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.fingerprint, size: 56, color: _coral),
            const SizedBox(height: 12),
            const Text(
              'Bật đăng nhập bằng vân tay?',
              style: TextStyle(
                color: Color(0xFF1D2226),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Lần sau bạn có thể đăng nhập nhanh mà không cần nhập mật khẩu.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF8E8E93), fontSize: 14),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF8E8E93),
                      side: const BorderSide(color: Color(0xFFE5E5EA)),
                    ),
                    child: const Text('Để sau'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: FilledButton.styleFrom(backgroundColor: _coralDark),
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
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Nền gradient luôn phủ kín toàn bộ màn hình, không phụ thuộc chiều cao nội dung
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1E9E8E),
                    Color(0xFFFF7A30),
                    Color(0xFFFFC93C),
                  ],
                  stops: [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(32, 24, 32, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome 🖖',
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            height: 1.1,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Đăng nhập để quản lý chuyến xe và bán hàng của bạn',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.bottomCenter,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(32, 28, 32, 40),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(32),
                                topRight: Radius.circular(32),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0x1A000000),
                                  blurRadius: 24,
                                  offset: Offset(0, -8),
                                ),
                              ],
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const _TabItem(
                                    label: 'Đăng nhập',
                                    selected: true,
                                  ),
                                  const SizedBox(height: 22),
                                  _InputField(
                                    hint: 'Tên đăng nhập',
                                    controller: _usernameCtrl,
                                    textInputAction: TextInputAction.next,
                                    validator: (v) =>
                                        (v == null || v.trim().isEmpty)
                                        ? 'Vui lòng nhập tên đăng nhập'
                                        : null,
                                  ),
                                  const SizedBox(height: 16),
                                  _InputField(
                                    hint: 'Mật khẩu',
                                    controller: _passwordCtrl,
                                    obscure: _obscure,
                                    textInputAction: TextInputAction.done,
                                    onSubmitted: (_) => _submit(),
                                    validator: (v) => (v == null || v.isEmpty)
                                        ? 'Vui lòng nhập mật khẩu'
                                        : null,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscure
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        size: 22,
                                        color: const Color(0xFF8E8E93),
                                      ),
                                      onPressed: () =>
                                          setState(() => _obscure = !_obscure),
                                    ),
                                  ),
                                  if (_error != null) ...[
                                    const SizedBox(height: 14),
                                    _ErrorText(message: _error!),
                                  ],
                                  if (_biometricAvailable) ...[
                                    const SizedBox(height: 18),
                                    GestureDetector(
                                      onTap: _loading
                                          ? null
                                          : _loginWithBiometric,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: const [
                                          Icon(
                                            Icons.fingerprint,
                                            size: 22,
                                            color: _coralDark,
                                          ),
                                          SizedBox(width: 6),
                                          Text(
                                            'Đăng nhập bằng vân tay',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: _coralDark,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 6),
                                ],
                              ),
                            ),
                          ),
                          // Nút submit hình tròn, đè lên cạnh dưới của card
                          Positioned(
                            bottom: -27,
                            child: GestureDetector(
                              onTap: _loading ? null : _submit,
                              child: Container(
                                width: 54,
                                height: 54,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [_coral, _coralDark],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _coral.withValues(alpha: 0.5),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: _loading
                                    ? const Padding(
                                        padding: EdgeInsets.all(14),
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.arrow_forward,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 48),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 32),
                        child: Center(
                          child: Text(
                            'v1.0.0',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final String label;
  final bool selected;

  const _TabItem({required this.label, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: selected ? const Color(0xFF1D2226) : const Color(0xFF8E8E93),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 2,
          width: 49,
          color: selected ? const Color(0xFFFF3D68) : Colors.transparent,
        ),
      ],
    );
  }
}

class _InputField extends StatelessWidget {
  final String hint;
  final TextEditingController controller;
  final bool obscure;
  final Widget? suffixIcon;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final String? Function(String?)? validator;

  const _InputField({
    required this.hint,
    required this.controller,
    this.obscure = false,
    this.suffixIcon,
    this.textInputAction,
    this.onSubmitted,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E5EA)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        textInputAction: textInputAction,
        onFieldSubmitted: onSubmitted,
        validator: validator,
        style: const TextStyle(fontSize: 16, color: Color(0xFF1C1C1E)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 16, color: Color(0xFF8E8E93)),
          border: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 21,
            vertical: 14,
          ),
          suffixIcon: suffixIcon,
          errorStyle: const TextStyle(height: 0, fontSize: 0),
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
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
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
