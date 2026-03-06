import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'core/localization/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'data/providers.dart';
import 'features/settings/settings_providers.dart';
import 'core/widgets/app_scaffold.dart';
import 'features/billing/billing_home_screen.dart';
import 'features/inventory/item_list_screen.dart';
import 'features/khata/customer_list_screen.dart';
import 'features/reports/reports_home_screen.dart';
import 'features/settings/settings_screen.dart';
import 'routing/app_router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
  }
  runApp(
    const ProviderScope(
      child: KiranaApp(),
    ),
  );
}

class KiranaApp extends ConsumerStatefulWidget {
  const KiranaApp({super.key});

  @override
  ConsumerState<KiranaApp> createState() => _KiranaAppState();
}

class _KiranaAppState extends ConsumerState<KiranaApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadLargeText());
  }

  Future<void> _loadLargeText() async {
    try {
      final repo = await ref.read(settingsRepositoryFutureProvider.future);
      final v = await repo.getBool('large_text');
      ref.read(largeTextProvider.notifier).state = v;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final largeText = ref.watch(largeTextProvider);

    return MaterialApp(
      title: AppStrings.appTitle,
      theme: AppTheme.lightTheme(largeText: largeText),
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: largeText ? const TextScaler.linear(1.2) : TextScaler.noScaling,
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const _MainShell(),
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}

class _MainShell extends ConsumerStatefulWidget {
  const _MainShell();

  @override
  ConsumerState<_MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<_MainShell> {
  int _currentIndex = 0;

  static const _screens = [
    BillingHomeScreen(),
    ItemListScreen(),
    CustomerListScreen(),
    ReportsHomeScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      currentIndex: _currentIndex,
      onDestinationSelected: (i) {
        setState(() => _currentIndex = i);
      },
      child: _screens[_currentIndex],
    );
  }
}
