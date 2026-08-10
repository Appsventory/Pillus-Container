import 'package:flutter/material.dart';

/// Preferensi aplikasi yang disimpan secara persisten.
class AppSettings {
  /// system | light | dark
  final String themeMode;

  /// auto | id | en | zh | ja
  final String language;

  /// Path binary docker di remote server, default "docker".
  final String dockerCliPath;

  /// Jumlah baris log default: 100 | 500 | 1000
  final int logTailLines;

  const AppSettings({
    this.themeMode = 'dark',
    this.language = 'auto',
    this.dockerCliPath = 'docker',
    this.logTailLines = 500,
  });

  AppSettings copyWith({
    String? themeMode,
    String? language,
    String? dockerCliPath,
    int? logTailLines,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      dockerCliPath: dockerCliPath ?? this.dockerCliPath,
      logTailLines: logTailLines ?? this.logTailLines,
    );
  }

  Map<String, dynamic> toJson() => {
        'themeMode': themeMode,
        'language': language,
        'dockerCliPath': dockerCliPath,
        'logTailLines': logTailLines,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final lines = json['logTailLines'];
    int parsedLines = 500;
    if (lines is int) {
      parsedLines = lines;
    } else if (lines is num) {
      parsedLines = lines.toInt();
    }
    if (parsedLines != 100 && parsedLines != 500 && parsedLines != 1000) {
      parsedLines = 500;
    }

    final theme = (json['themeMode'] as String?) ?? 'dark';
    final lang = (json['language'] as String?) ?? 'auto';
    final path = (json['dockerCliPath'] as String?)?.trim();

    return AppSettings(
      themeMode: const {'system', 'light', 'dark'}.contains(theme)
          ? theme
          : 'dark',
      language: const {'auto', 'id', 'en', 'zh', 'ja'}.contains(lang)
          ? lang
          : 'auto',
      dockerCliPath: (path == null || path.isEmpty) ? 'docker' : path,
      logTailLines: parsedLines,
    );
  }

  ThemeMode get flutterThemeMode {
    switch (themeMode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  /// Locale efektif. null = ikuti sistem (MaterialApp akan resolve).
  Locale? get localeOrNull {
    switch (language) {
      case 'id':
        return const Locale('id');
      case 'en':
        return const Locale('en');
      case 'zh':
        return const Locale('zh');
      case 'ja':
        return const Locale('ja');
      default:
        return null; // auto
    }
  }
}
