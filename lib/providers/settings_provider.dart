import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_settings.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';

final settingsProvider =
    NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    final initial = SettingsService.instance.current;
    final platform =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    AppColors.sync(initial.themeMode, platform);
    Future.microtask(_load);
    return initial;
  }

  Future<void> _load() async {
    final loaded = await SettingsService.instance.load();
    final platform =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    AppColors.sync(loaded.themeMode, platform);
    state = loaded;
  }

  Future<void> setThemeMode(String mode) async {
    final next = state.copyWith(themeMode: mode);
    final platform =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    // Update warna SEBELUM notify listeners → UI langsung refresh.
    AppColors.sync(next.themeMode, platform);
    state = next;
    await SettingsService.instance.save(next);
  }

  Future<void> setLanguage(String language) async {
    final next = state.copyWith(language: language);
    state = next;
    await SettingsService.instance.save(next);
  }

  Future<void> setDockerCliPath(String path) async {
    final trimmed = path.trim().isEmpty ? 'docker' : path.trim();
    final next = state.copyWith(dockerCliPath: trimmed);
    state = next;
    await SettingsService.instance.save(next);
  }

  Future<void> setLogTailLines(int lines) async {
    final next = state.copyWith(logTailLines: lines);
    state = next;
    await SettingsService.instance.save(next);
  }
}
