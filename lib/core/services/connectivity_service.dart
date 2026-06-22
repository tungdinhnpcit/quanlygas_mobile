// lib/core/services/connectivity_service.dart
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static final ConnectivityService instance = ConnectivityService._();
  ConnectivityService._();

  final _connectivity = Connectivity();
  final _controller = StreamController<bool>.broadcast();

  bool _isOnline = true;
  bool get isOnline => _isOnline;
  Stream<bool> get onChanged => _controller.stream;

  StreamSubscription? _sub;

  Future<void> initialize() async {
    final results = await _connectivity.checkConnectivity();
    _isOnline = _isConnected(results);

    _sub = _connectivity.onConnectivityChanged.listen((results) {
      final nowOnline = _isConnected(results);
      if (nowOnline != _isOnline) {
        _isOnline = nowOnline;
        _controller.add(_isOnline);
      }
    });
  }

  Future<bool> checkOnline() async {
    final results = await _connectivity.checkConnectivity();
    _isOnline = _isConnected(results);
    return _isOnline;
  }

  bool _isConnected(List<ConnectivityResult> results) =>
      results.isNotEmpty && results.any((r) => r != ConnectivityResult.none);

  void dispose() {
    _sub?.cancel();
    _controller.close();
  }
}
