import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/app_settings.dart';

class SettingsService {
  SettingsService._();
  static final instance = SettingsService._();

  final _storage = const FlutterSecureStorage();
  static const _key = 'app_settings_v1';

  /// Cache in-memory supaya DockerRepository bisa baca path secara sync.
  AppSettings _cached = const AppSettings();
  AppSettings get current => _cached;

  Future<AppSettings> load() async {
    try {
      final raw = await _storage.read(key: _key);
      if (raw == null || raw.isEmpty) {
        _cached = const AppSettings();
        return _cached;
      }
      final map = jsonDecode(raw) as Map<String, dynamic>;
      _cached = AppSettings.fromJson(map);
      return _cached;
    } catch (_) {
      _cached = const AppSettings();
      return _cached;
    }
  }

  Future<void> save(AppSettings settings) async {
    _cached = settings;
    await _storage.write(key: _key, value: jsonEncode(settings.toJson()));
  }
}
