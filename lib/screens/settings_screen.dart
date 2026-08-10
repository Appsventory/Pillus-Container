import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../providers/settings_provider.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _dockerPathCtrl;
  bool _pathDirty = false;

  @override
  void initState() {
    super.initState();
    _dockerPathCtrl = TextEditingController(
      text: SettingsService.instance.current.dockerCliPath,
    );
  }

  @override
  void dispose() {
    _dockerPathCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveDockerPath() async {
    await ref
        .read(settingsProvider.notifier)
        .setDockerCliPath(_dockerPathCtrl.text);
    if (!mounted) return;
    setState(() => _pathDirty = false);
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.saved),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context);

    // Pastikan warna selalu sinkron saat build (ganti tema langsung terlihat).
    AppColors.sync(
      settings.themeMode,
      MediaQuery.platformBrightnessOf(context),
    );

    if (!_pathDirty && _dockerPathCtrl.text != settings.dockerCliPath) {
      _dockerPathCtrl.text = settings.dockerCliPath;
    }

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        backgroundColor: AppColors.surfaceDark,
        foregroundColor: AppColors.textPrimary,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.settings,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 17,
                letterSpacing: -0.3,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              l10n.settingsSubtitle,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _SectionHeader(title: l10n.appearance),
          const SizedBox(height: 8),
          _SettingsCard(
            children: [
              _SettingLabel(l10n.theme),
              const SizedBox(height: 10),
              _SegmentedChoices(
                value: settings.themeMode,
                options: [
                  _Choice('system', l10n.themeSystem, Icons.brightness_auto_rounded),
                  _Choice('light', l10n.themeLight, Icons.light_mode_rounded),
                  _Choice('dark', l10n.themeDark, Icons.dark_mode_rounded),
                ],
                onChanged: (v) async {
                  await ref.read(settingsProvider.notifier).setThemeMode(v);
                  if (mounted) setState(() {});
                },
              ),
              const SizedBox(height: 20),
              _SettingLabel(l10n.language),
              const SizedBox(height: 10),
              _SegmentedChoices(
                value: settings.language,
                options: [
                  _Choice('auto', l10n.langAuto, Icons.translate_rounded),
                  _Choice('id', l10n.langId, Icons.flag_rounded),
                  _Choice('en', l10n.langEn, Icons.flag_rounded),
                  _Choice('zh', l10n.langZh, Icons.flag_rounded),
                  _Choice('ja', l10n.langJa, Icons.flag_rounded),
                ],
                onChanged: (v) =>
                    ref.read(settingsProvider.notifier).setLanguage(v),
                wrap: true,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SectionHeader(title: l10n.dockerConfig),
          const SizedBox(height: 8),
          _SettingsCard(
            children: [
              _SettingLabel(l10n.dockerCliPath),
              const SizedBox(height: 6),
              Text(
                l10n.dockerCliPathHint,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _dockerPathCtrl,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.surfaceDarkAlt,
                        hintText: 'docker',
                        hintStyle: TextStyle(color: AppColors.textSecondary),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppColors.accent,
                            width: 1.5,
                          ),
                        ),
                      ),
                      onChanged: (_) {
                        if (!_pathDirty) setState(() => _pathDirty = true);
                      },
                      onSubmitted: (_) => _saveDockerPath(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _pathDirty ? _saveDockerPath : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Icon(Icons.check_rounded, size: 20),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () async {
                    _dockerPathCtrl.text = 'docker';
                    await ref
                        .read(settingsProvider.notifier)
                        .setDockerCliPath('docker');
                    setState(() => _pathDirty = false);
                  },
                  child: Text(l10n.resetDefault),
                ),
              ),
              const SizedBox(height: 8),
              Divider(color: AppColors.border),
              const SizedBox(height: 12),
              _SettingLabel(l10n.logLines),
              const SizedBox(height: 6),
              Text(
                l10n.logLinesDesc,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 12),
              _SegmentedChoices(
                value: settings.logTailLines.toString(),
                options: [
                  _Choice('100', l10n.lines100, Icons.short_text_rounded),
                  _Choice('500', l10n.lines500, Icons.notes_rounded),
                  _Choice('1000', l10n.lines1000, Icons.subject_rounded),
                ],
                onChanged: (v) => ref
                    .read(settingsProvider.notifier)
                    .setLogTailLines(int.parse(v)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 2),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.9,
          color: AppColors.textSecondary.withValues(alpha: 0.85),
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _SettingLabel extends StatelessWidget {
  final String text;
  const _SettingLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _Choice {
  final String value;
  final String label;
  final IconData icon;
  const _Choice(this.value, this.label, this.icon);
}

class _SegmentedChoices extends StatelessWidget {
  final String value;
  final List<_Choice> options;
  final ValueChanged<String> onChanged;
  final bool wrap;

  const _SegmentedChoices({
    required this.value,
    required this.options,
    required this.onChanged,
    this.wrap = false,
  });

  @override
  Widget build(BuildContext context) {
    final chips = options.map((o) {
      final selected = o.value == value;
      return Padding(
        padding: const EdgeInsets.only(right: 8, bottom: 8),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onChanged(o.value),
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.accent.withValues(alpha: 0.14)
                    : AppColors.surfaceDarkAlt,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? AppColors.accent : AppColors.border,
                  width: selected ? 1.4 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    o.icon,
                    size: 16,
                    color: selected
                        ? AppColors.accent
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    o.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.w500,
                      color: selected
                          ? AppColors.accent
                          : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }).toList();

    if (wrap) {
      return Wrap(children: chips);
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: chips),
    );
  }
}
