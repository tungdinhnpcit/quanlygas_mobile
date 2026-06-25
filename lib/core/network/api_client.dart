// lib/core/network/api_client.dart
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

const _wafSignatures = [
  'The requested URL was rejected',
  'Please consult with your administrator',
  'Your support ID is',
];

bool _isF5WafBlock(dynamic data) {
  if (data is! String) return false;
  return _wafSignatures.any((sig) => data.contains(sig));
}

String _extractSupportId(String body) {
  final match = RegExp(r'Your support ID is[:\s]+(\d+)', caseSensitive: false).firstMatch(body);
  return match != null ? match.group(1)! : '';
}

DioException _wafException(RequestOptions opts, String body) {
  final supportId = _extractSupportId(body);
  final msg = supportId.isNotEmpty
      ? 'Yêu cầu bị tường lửa (F5 WAF) chặn. Mã hỗ trợ: $supportId'
      : 'Yêu cầu bị tường lửa (F5 WAF) chặn. Vui lòng liên hệ quản trị viên.';
  return DioException(
    requestOptions: opts,
    type: DioExceptionType.badResponse,
    message: msg,
  );
}

class ApiClient {
  static ApiClient? _instance;
  late final Dio _dio;
  final _storage = const FlutterSecureStorage();

  // Callback được set bởi app_router khi cần navigate về login
  static void Function(String route)? _navigateToLogin;
  static void setNavigateToLogin(void Function(String) cb) => _navigateToLogin = cb;

  ApiClient._() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.resolvedApiUrl,
      connectTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'jwt_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onResponse: (response, handler) {
        // Phát hiện F5 WAF trả về HTML với status 200
        if (_isF5WafBlock(response.data)) {
          handler.reject(_wafException(response.requestOptions, response.data as String));
          return;
        }
        handler.next(response);
      },
      onError: (error, handler) async {
        // Phát hiện F5 WAF trả về HTML kèm status lỗi (403, v.v.)
        final responseData = error.response?.data;
        if (_isF5WafBlock(responseData)) {
          handler.next(_wafException(error.requestOptions, responseData as String));
          return;
        }

        if (error.response?.statusCode == 401) {
          final refreshed = await _tryRefresh();
          if (refreshed) {
            // Retry với token mới
            final token = await _storage.read(key: 'jwt_token');
            final opts = error.requestOptions
              ..headers['Authorization'] = 'Bearer $token';
            try {
              final resp = await _dio.fetch(opts);
              handler.resolve(resp);
              return;
            } catch (_) {}
          }
          // Refresh thất bại → xóa session + về login
          await _storage.deleteAll();
          _navigateToLogin?.call('/login');
        }
        handler.next(error);
      },
    ));
  }

  static ApiClient get instance => _instance ??= ApiClient._();

  Dio get dio => _dio;

  Future<bool> _tryRefresh() async {
    final refreshToken = await _storage.read(key: 'refresh_token');
    if (refreshToken == null) return false;
    try {
      final resp = await Dio(BaseOptions(baseUrl: AppConstants.resolvedApiUrl))
          .post('/api/auth/refresh', data: {'refreshToken': refreshToken});
      final data = resp.data as Map<String, dynamic>;
      await _storage.write(key: 'jwt_token',     value: data['accessToken'] as String);
      await _storage.write(key: 'refresh_token', value: data['refreshToken'] as String);
      if (data['menus'] != null) {
        await _storage.write(key: 'user_menus', value: jsonEncode(data['menus']));
      }
      if (data['rights'] != null) {
        await _storage.write(key: 'user_rights', value: jsonEncode(data['rights']));
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}
