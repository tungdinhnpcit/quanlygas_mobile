// lib/features/auth/presentation/screens/login_screen_v2.dart
//
// Bản dựng UI tĩnh theo Figma "Login Version 8"
// (https://www.figma.com/design/sPfkkZFvWlC4liGBDAnlJL/...?node-id=71-9021)
// Chưa nối logic đăng nhập — chỉ để review giao diện trước khi quyết định
// có thay thế login_screen.dart hiện tại hay không.

import 'dart:ui';

import 'package:flutter/material.dart';

class LoginScreenV2 extends StatefulWidget {
  const LoginScreenV2({super.key});

  @override
  State<LoginScreenV2> createState() => _LoginScreenV2State();
}

class _LoginScreenV2State extends State<LoginScreenV2> {
  static const _black = Color(0xFF1A1C1E);
  static const _grey = Color(0xFF6C7278);
  static const _stroke = Color(0xFFEDF1F3);
  static const _blue = Color(0xFF4D81E7);
  static const _buttonBlue = Color(0xFF1D61E7);

  bool _obscure = true;
  bool _rememberMe = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _stroke,
      body: Stack(
        children: [
          // Blur gradient blob góc trên-trái
          Positioned(
            left: -180,
            top: -260,
            child: Transform.rotate(
              angle: 0.335, // ~19.2deg
              child: Container(
                width: 480,
                height: 480,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _buttonBlue.withValues(alpha: 0.35),
                      _stroke.withValues(alpha: 0.0),
                    ],
                  ),
                ),
                child: ClipOval(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  Column(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _buttonBlue,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.shield_outlined, color: Colors.white, size: 26),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Sign in to your Account',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _black,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Enter your email and password to log in',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: _grey, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  _InputField(hint: 'Loisbecket@gmail.com'),
                  const SizedBox(height: 12),
                  _InputField(
                    hint: '•••••••',
                    obscure: _obscure,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 18,
                        color: _grey,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: Checkbox(
                              value: _rememberMe,
                              onChanged: (v) => setState(() => _rememberMe = v ?? false),
                              activeColor: _buttonBlue,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text('Remember me', style: TextStyle(fontSize: 13, color: _grey, fontWeight: FontWeight.w500)),
                        ],
                      ),
                      const Text(
                        'Forgot Password ?',
                        style: TextStyle(fontSize: 13, color: _blue, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Nút Log In
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _buttonBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Log In', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      const Expanded(child: Divider(color: _stroke, thickness: 1)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('Or', style: TextStyle(fontSize: 13, color: _grey)),
                      ),
                      const Expanded(child: Divider(color: _stroke, thickness: 1)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _SocialButton(
                    icon: const _GoogleIcon(),
                    label: 'Continue with Google',
                    onTap: () {},
                  ),
                  const SizedBox(height: 8),
                  _SocialButton(
                    icon: const _FacebookIcon(),
                    label: 'Continue with Facebook',
                    onTap: () {},
                  ),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account? ", style: TextStyle(fontSize: 13, color: _grey, fontWeight: FontWeight.w500)),
                      GestureDetector(
                        onTap: () {},
                        child: const Text('Sign Up', style: TextStyle(fontSize: 13, color: _blue, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final String hint;
  final bool obscure;
  final Widget? suffixIcon;

  const _InputField({required this.hint, this.obscure = false, this.suffixIcon});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEDF1F3)),
        boxShadow: const [
          BoxShadow(color: Color(0x3DE4E5E7), blurRadius: 2, offset: Offset(0, 1)),
        ],
      ),
      child: TextField(
        obscureText: obscure,
        style: const TextStyle(fontSize: 14, color: Color(0xFF1A1C1E)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 14, color: Color(0xFFACB5BB)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final Widget icon;
  final String label;
  final VoidCallback onTap;

  const _SocialButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFFEFF0F6)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1C1E))),
          ],
        ),
      ),
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 18,
      height: 18,
      child: Icon(Icons.g_mobiledata, size: 22, color: Color(0xFF4285F4)),
    );
  }
}

class _FacebookIcon extends StatelessWidget {
  const _FacebookIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: const BoxDecoration(color: Color(0xFF1877F2), shape: BoxShape.circle),
      child: const Icon(Icons.facebook, size: 14, color: Colors.white),
    );
  }
}
