import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'l10n/app_localizations.dart';
import 'providers/settings_provider.dart';
import 'screens/dashboard_screen.dart';
import 'services/settings_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SettingsService.instance.load();
  runApp(const ProviderScope(child: DockerManagerApp()));
}

class DockerManagerApp extends ConsumerWidget {
  const DockerManagerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    // Sinkronkan AppColors SEBELUM MaterialApp build child tree,
    // supaya ganti tema langsung terasa tanpa keluar Settings.
    final platformBrightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    AppColors.sync(settings.themeMode, platformBrightness);

    return MaterialApp(
      title: 'Docker Manager',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: settings.flutterThemeMode,
      locale: settings.localeOrNull,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      localeResolutionCallback: (locale, supported) {
        if (settings.language != 'auto') {
          return settings.localeOrNull ?? const Locale('en');
        }
        if (locale != null) {
          for (final s in supported) {
            if (s.languageCode == locale.languageCode) return s;
          }
        }
        return const Locale('en');
      },
      builder: (context, child) {
        // Pastikan tetap sinkron dengan Theme yang aktif.
        AppColors.sync(settings.themeMode, Theme.of(context).brightness);
        return child ?? const SizedBox.shrink();
      },
      home: DashboardScreen(),
    );
  }
}
