import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../providers/settings_provider.dart';

import '../models/volume_model.dart';
import '../services/docker_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/safe_input_dialog.dart';

class VolumeListView extends ConsumerStatefulWidget {
  final String serverId;

  const VolumeListView({super.key, required this.serverId});

  @override
  ConsumerState<VolumeListView> createState() => _VolumeListViewState();
}

class _VolumeListViewState extends ConsumerState<VolumeListView> {
  List<VolumeModel> _volumes = [];
  bool _loading = true;
  String? _error;

  final Set<String> _busyNames = {};

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh({bool force = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final raw = await DockerRepository.instance.listVolumes(
        widget.serverId,
        forceRefresh: force,
      );

      if (!mounted) return;

      setState(() {
        _volumes = raw.map((m) => VolumeModel.fromDockerJson(m)).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = AppLocalizations.of(context).failedLoadVolumes('$e');
        _loading = false;
      });
    }
  }

  Future<void> _showCreateDialog() async {
    final l10n = AppLocalizations.of(context);
    final name = await showSafeInputDialog(
      context: context,
      title: l10n.createVolume,
      actionLabel: l10n.create,
      cancelLabel: l10n.cancel,
      hint: 'volume_name',
      icon: Icons.storage_outlined,
    );

    if (name == null || name.isEmpty) return;
    if (!mounted) return;

    try {
      await DockerRepository.instance.createVolume(widget.serverId, name);
      await _refresh(force: true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).failedCreateVolume('$e'),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _confirmRemove(VolumeModel volume) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.border),
        ),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        title: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                Icons.delete_outline_rounded,
                color: AppColors.danger,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                AppLocalizations.of(context).deleteVolumeTitle,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Text(
            AppLocalizations.of(context).deleteVolumeBody(volume.name),
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13.5,
              height: 1.5,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context).delete),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _busyNames.add(volume.name);
    });

    try {
      await DockerRepository.instance.removeVolume(
        widget.serverId,
        volume.name,
      );

      await _refresh(force: true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).failedDelete('$e')),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _busyNames.remove(volume.name);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch settingsProvider murni buat trigger rebuild pas tema ganti -
    // AppColors itu static getter, gak otomatis ke-notify Flutter,
    // jadi butuh dependency Riverpod eksplisit ini biar widget yang
    // 'kept-alive' (IndexedStack dkk) ikut refresh tanpa reset navigasi.
    ref.watch(settingsProvider);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context).volumesTitle,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      AppLocalizations.of(context).volumesSubtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              if (!_loading)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDarkAlt,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    '${_volumes.length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),

              _HeaderButton(
                icon: Icons.add_rounded,
                tooltip: AppLocalizations.of(context).createVolume,
                onPressed: _showCreateDialog,
                accent: true,
              ),

              const SizedBox(width: 7),

              _HeaderButton(
                icon: Icons.refresh_rounded,
                tooltip: AppLocalizations.of(context).refresh,
                onPressed: _loading ? null : () => _refresh(force: true),
              ),
            ],
          ),
        ),

        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildBody() {
    if (_loading && _volumes.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(strokeWidth: 2.5),
            SizedBox(height: 14),
            Text(
              AppLocalizations.of(context).loadingVolumes,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: .10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  size: 29,
                  color: AppColors.danger,
                ),
              ),
              const SizedBox(height: 15),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.danger,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: () => _refresh(force: true),
                icon: const Icon(Icons.refresh_rounded, size: 17),
                label: Text(AppLocalizations.of(context).tryAgain),
              ),
            ],
          ),
        ),
      );
    }

    if (_volumes.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: AppColors.surfaceDarkAlt,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                Icons.storage_outlined,
                size: 32,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).noVolumesFound,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 5),
            Text(
              AppLocalizations.of(context).createVolumeHint,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _refresh(force: true),
      color: AppColors.accent,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
        itemCount: _volumes.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final volume = _volumes[index];

          final busy = _busyNames.contains(volume.name);

          return _VolumeCard(
            volume: volume,
            busy: busy,
            onDelete: () => _confirmRemove(volume),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Volume Card
// ─────────────────────────────────────────────

class _VolumeCard extends StatelessWidget {
  final VolumeModel volume;
  final bool busy;
  final VoidCallback onDelete;

  const _VolumeCard({
    required this.volume,
    required this.busy,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.storage_rounded,
                  size: 22,
                  color: AppColors.accent,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      volume.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Docker Volume',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              if (busy)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                IconButton(
                  tooltip: AppLocalizations.of(context).delete,
                  onPressed: onDelete,
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    size: 20,
                    color: AppColors.danger,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.danger.withValues(alpha: .08),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 14),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceDarkAlt,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _VolumeInfo(
                    label: AppLocalizations.of(context).driver,
                    value: volume.driver,
                  ),
                ),
                Container(width: 1, height: 30, color: AppColors.border),
                const SizedBox(width: 16),
                Expanded(
                  child: _VolumeInfo(
                    label: AppLocalizations.of(context).scope,
                    value: volume.scope,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Volume Info
// ─────────────────────────────────────────────

class _VolumeInfo extends StatelessWidget {
  final String label;
  final String value;

  const _VolumeInfo({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            letterSpacing: .7,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Header Button
// ─────────────────────────────────────────────

class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool accent;

  const _HeaderButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        style: IconButton.styleFrom(
          backgroundColor: accent ? AppColors.accent : AppColors.surfaceDarkAlt,
          foregroundColor: accent ? Colors.white : AppColors.textPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
        ),
      ),
    );
  }
}
