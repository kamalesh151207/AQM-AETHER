// AQM AETHER — Main Entry Point
// Clean Modern Environmental Intelligence & Sensor Monitoring Platform

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'providers/device_provider.dart';
import 'providers/monitoring_provider.dart';
import 'providers/analytics_provider.dart';
import 'providers/settings_provider.dart';
import 'services/storage_service.dart';
import 'services/threshold/threshold_service.dart';
import 'screens/main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Force portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // System UI overlay style for modern light theme
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize storage & threshold engine
  final storageService = StorageService();
  await storageService.initialize();

  final thresholdService = ThresholdService();
  await thresholdService.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider(storageService)),
        ChangeNotifierProvider(create: (_) => MonitoringProvider(storageService)),
        ChangeNotifierProvider.value(value: thresholdService),
        ChangeNotifierProvider(
          create: (context) => DeviceProvider(
            context.read<MonitoringProvider>(),
          ),
        ),
        ChangeNotifierProxyProvider<MonitoringProvider, AnalyticsProvider>(
          create: (context) => AnalyticsProvider(context.read<MonitoringProvider>()),
          update: (context, monitoring, analytics) =>
              analytics!..updateFromMonitoring(monitoring),
        ),
      ],
      child: const AqmAetherApp(),
    ),
  );
}

class AqmAetherApp extends StatefulWidget {
  const AqmAetherApp({super.key});

  @override
  State<AqmAetherApp> createState() => _AqmAetherAppState();
}

class _AqmAetherAppState extends State<AqmAetherApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final deviceProvider = context.read<DeviceProvider>();
    if (state == AppLifecycleState.resumed) {
      deviceProvider.handleAppResume();
    } else if (state == AppLifecycleState.paused) {
      deviceProvider.handleAppPause();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return MaterialApp(
      title: 'AQM AETHER',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.darkTheme ? ThemeMode.dark : ThemeMode.light,
      home: const MainShell(),
    );
  }
}
