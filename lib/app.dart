// lib/app.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/app_scale.dart';

class QuanLyGasApp extends ConsumerStatefulWidget {
  const QuanLyGasApp({super.key});

  @override
  ConsumerState<QuanLyGasApp> createState() => _QuanLyGasAppState();
}

class _QuanLyGasAppState extends ConsumerState<QuanLyGasApp> {
  @override
  void initState() {
    super.initState();
    NotificationService.initialize();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'QuanLyGas',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(scale: 1.0),
      builder: (context, child) {
        final scale = AppScale.factor(context);
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
          ),
          child: Theme(
            data: AppTheme.build(scale: scale),
            child: child!,
          ),
        );
      },
      routerConfig: router,
      locale: const Locale('vi'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('vi'),
        Locale('en'),
      ],
    );
  }
}
