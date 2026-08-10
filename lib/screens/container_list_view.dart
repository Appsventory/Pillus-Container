import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../providers/settings_provider.dart';

import '../models/container_model.dart';
import '../services/docker_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/safe_input_dialog.dart';
import 'container_inspect_screen.dart';
import 'container_logs_screen.dart';
import 'container_exec_screen.dart';
import 'container_stats_screen.dart';
import 'create_container_sheet.dart';

class ContainerListView extends ConsumerStatefulWidget {
  final String serverId;
  final VoidCallback? onCreatePressed;

  /// Dipanggil dari menu "Buka Lokasi File" di Compose. Parent (ServerShell)
  /// yang handle: tutup halaman Compose, pindah ke tab Files, lalu navigate
  /// ke path yang diminta.
  final void Function(String path)? onOpenFileLocation;

  const ContainerListView({
    super.key,
    required this.serverId,
    this.onCreatePressed,
    this.onOpenFileLocation,
  });

  @override
  ConsumerState<ContainerListView> createState() => _ContainerListViewState();
}

class _ContainerListViewState extends ConsumerState<ContainerListView> {
  List<ContainerModel> _containers = [];
  bool _loading = true;
  String? _error;

  final Set<String> _busyIds = {};

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
      final list = await DockerRepository.instance.listContainers(
        widget.serverId,
        forceRefresh: force,
      );

      if (!mounted) return;

      setState(() {
        _containers = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = AppLocalizations.of(context).failedLoadContainers('$e');
        _loading = false;
      });
    }
  }

  Future<void> _runAction(String containerId, Future Function() action) async {
    setState(() {
      _busyIds.add(containerId);
    });

    try {
      await action();
      await _refresh(force: true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).failed('$e')),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _busyIds.remove(containerId);
        });
      }
    }
  }

  Future<void> _confirmRemove(ContainerModel container) async {
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
                AppLocalizations.of(context).deleteContainerTitle,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: Text(
          AppLocalizations.of(context).deleteContainerBody(container.name),
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13.5,
            height: 1.5,
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

    await _runAction(
      container.id,
      () => DockerRepository.instance.removeContainer(
        widget.serverId,
        container.id,
        force: container.isRunning,
      ),
    );
  }

  Future<void> _renameContainer(ContainerModel container) async {
    final l10n = AppLocalizations.of(context);
    final newName = await showSafeInputDialog(
      context: context,
      title: l10n.renameContainer,
      actionLabel: l10n.rename,
      cancelLabel: l10n.cancel,
      hint: l10n.containerName,
      initialValue: container.name,
      icon: Icons.edit_outlined,
    );

    if (newName == null || newName.isEmpty || newName == container.name) return;
    if (!mounted) return;

    await _runAction(
      container.id,
      () => DockerRepository.instance.renameContainer(
        widget.serverId,
        container.id,
        newName,
      ),
    );
  }

  void _openLogs(ContainerModel container) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ContainerLogsScreen(
          serverId: widget.serverId,
          containerId: container.id,
          containerName: container.name,
        ),
      ),
    );
  }

  void _openInspect(ContainerModel container) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ContainerInspectScreen(
          serverId: widget.serverId,
          containerId: container.id,
          containerName: container.name,
        ),
      ),
    );
  }

  void _openExec(ContainerModel container) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ContainerExecScreen(
          serverId: widget.serverId,
          containerId: container.id,
          containerName: container.name,
        ),
      ),
    );
  }

  void _openStats(ContainerModel container) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ContainerStatsScreen(
          serverId: widget.serverId,
          containerId: container.id,
          containerName: container.name,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch settingsProvider murni buat trigger rebuild pas tema ganti -
    // AppColors itu static getter, gak otomatis ke-notify Flutter,
    // jadi butuh dependency Riverpod eksplisit ini biar widget yang
    // 'kept-alive' (IndexedStack dkk) ikut refresh tanpa reset navigasi.
    ref.watch(settingsProvider);
    return Stack(
      children: [
        Column(
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
                          AppLocalizations.of(context).containersTitle,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          AppLocalizations.of(context).containersSubtitle,
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
                        '${_containers.length}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),

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
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            onPressed: _loading ? null : _showCreateContainer,
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.white,
            elevation: 3,
            icon: const Icon(Icons.add_rounded, size: 20),
            label: Text(
              AppLocalizations.of(context).createContainer,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showCreateContainer() async {
    final req = await showCreateContainerSheet(
      context: context,
      serverId: widget.serverId,
    );
    if (req == null || !mounted) return;

    try {
      await DockerRepository.instance.createContainer(
        widget.serverId,
        image: req.image,
        name: req.name,
        network: req.network,
        restartPolicy: req.restartPolicy,
        ports: req.ports,
        env: req.env,
        volumes: req.volumes,
        command: req.command,
        autoRemove: req.autoRemove,
        privileged: req.privileged,
      );
      await _refresh(force: true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).failedCreateContainer('$e'),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildBody() {
    if (_loading && _containers.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(strokeWidth: 2.5),
            SizedBox(height: 14),
            Text(
              AppLocalizations.of(context).loadingContainers,
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

    if (_containers.isEmpty) {
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
                Icons.view_in_ar_outlined,
                size: 32,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).noContainersFound,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 5),
            Text(
              AppLocalizations.of(context).createContainerHint,
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
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
        itemCount: _containers.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final container = _containers[index];

          return _ContainerCard(
            container: container,
            busy: _busyIds.contains(container.id),
            onStart: () => _runAction(
              container.id,
              () => DockerRepository.instance.startContainer(
                widget.serverId,
                container.id,
              ),
            ),
            onStop: () => _runAction(
              container.id,
              () => DockerRepository.instance.stopContainer(
                widget.serverId,
                container.id,
              ),
            ),
            onRestart: () => _runAction(
              container.id,
              () => DockerRepository.instance.restartContainer(
                widget.serverId,
                container.id,
              ),
            ),
            onRemove: () => _confirmRemove(container),
            onLogs: () => _openLogs(container),
            onInspect: () => _openInspect(container),
            onExec: () => _openExec(container),
            onStats: () => _openStats(container),
            onRename: () => _renameContainer(container),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Container Card
// ─────────────────────────────────────────────

class _ContainerCard extends StatelessWidget {
  final ContainerModel container;
  final bool busy;

  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onRestart;
  final VoidCallback onRemove;
  final VoidCallback onLogs;
  final VoidCallback onInspect;
  final VoidCallback onExec;
  final VoidCallback onStats;
  final VoidCallback onRename;

  const _ContainerCard({
    required this.container,
    required this.busy,
    required this.onStart,
    required this.onStop,
    required this.onRestart,
    required this.onRemove,
    required this.onLogs,
    required this.onInspect,
    required this.onExec,
    required this.onStats,
    required this.onRename,
  });

  Color get _stateColor {
    switch (container.state) {
      case ContainerState.running:
        return AppColors.success;
      case ContainerState.paused:
      case ContainerState.restarting:
        return AppColors.warning;
      case ContainerState.created:
        return AppColors.accent;
      case ContainerState.exited:
      case ContainerState.unknown:
        return AppColors.textSecondary;
    }
  }

  String get _stateLabel {
    switch (container.state) {
      case ContainerState.running:
        return 'Running';
      case ContainerState.paused:
        return 'Paused';
      case ContainerState.restarting:
        return 'Restarting';
      case ContainerState.exited:
        return 'Exited';
      case ContainerState.created:
        return 'Created';
      case ContainerState.unknown:
        return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceDark,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: _stateColor.withValues(alpha: .10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.view_in_ar_rounded,
                      size: 21,
                      color: _stateColor,
                    ),
                  ),

                  SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          container.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 5),
                        _StatusBadge(label: _stateLabel, color: _stateColor),
                      ],
                    ),
                  ),

                  if (busy)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    _ContainerMenu(
                      onLogs: onLogs,
                      onInspect: onInspect,
                      onExec: onExec,
                      onStats: onStats,
                      onRename: onRename,
                      onRemove: onRemove,
                    ),
                ],
              ),

              const SizedBox(height: 14),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDarkAlt,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'IMAGE',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: .7,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      container.image,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
                    ),
                  ],
                ),
              ),

              if (container.status.isNotEmpty) ...[
                const SizedBox(height: 9),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 14,
                      color: _stateColor,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        container.status,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: _stateColor,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              if (container.ports.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lan_outlined,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        container.ports,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: container.isRunning
                        ? _ActionButton(
                            icon: Icons.stop_rounded,
                            label: AppLocalizations.of(context).stop,
                            onPressed: busy ? null : onStop,
                            danger: true,
                          )
                        : _ActionButton(
                            icon: Icons.play_arrow_rounded,
                            label: AppLocalizations.of(context).start,
                            onPressed: busy ? null : onStart,
                            primary: true,
                          ),
                  ),

                  if (container.isRunning) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.refresh_rounded,
                        label: AppLocalizations.of(context).restart,
                        onPressed: busy ? null : onRestart,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Status Badge
// ─────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .11),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Container Menu
// ─────────────────────────────────────────────

class _ContainerMenu extends StatelessWidget {
  final VoidCallback onLogs;
  final VoidCallback onInspect;
  final VoidCallback onExec;
  final VoidCallback onStats;
  final VoidCallback onRename;
  final VoidCallback onRemove;

  const _ContainerMenu({
    required this.onLogs,
    required this.onInspect,
    required this.onExec,
    required this.onStats,
    required this.onRename,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert_rounded,
        size: 20,
        color: AppColors.textSecondary,
      ),
      color: AppColors.surfaceDarkAlt,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(13),
        side: BorderSide(color: AppColors.border),
      ),
      onSelected: (value) {
        switch (value) {
          case 'logs':
            onLogs();
            break;
          case 'inspect':
            onInspect();
            break;
          case 'exec':
            onExec();
            break;
          case 'stats':
            onStats();
            break;
          case 'rename':
            onRename();
            break;
          case 'remove':
            onRemove();
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'logs',
          child: _MenuItem(
            icon: Icons.article_outlined,
            label: AppLocalizations.of(context).logs,
          ),
        ),
        PopupMenuItem(
          value: 'inspect',
          child: _MenuItem(
            icon: Icons.info_outline_rounded,
            label: AppLocalizations.of(context).inspect,
          ),
        ),
        PopupMenuItem(
          value: 'exec',
          child: _MenuItem(
            icon: Icons.terminal_rounded,
            label: AppLocalizations.of(context).execTerminal,
          ),
        ),
        PopupMenuItem(
          value: 'stats',
          child: _MenuItem(
            icon: Icons.bar_chart_rounded,
            label: AppLocalizations.of(context).liveStats,
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'rename',
          child: _MenuItem(
            icon: Icons.edit_outlined,
            label: AppLocalizations.of(context).rename,
          ),
        ),
        PopupMenuItem(
          value: 'remove',
          child: _MenuItem(
            icon: Icons.delete_outline_rounded,
            label: AppLocalizations.of(context).delete,
            color: AppColors.danger,
          ),
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _MenuItem({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color ?? AppColors.textSecondary),
        SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(fontSize: 13, color: color ?? AppColors.textPrimary),
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

  const _HeaderButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        style: IconButton.styleFrom(
          backgroundColor: AppColors.surfaceDarkAlt,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Action Button
// ─────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool danger;
  final bool primary;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.danger = false,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color foreground;
    final Color background;

    if (danger) {
      foreground = AppColors.danger;
      background = AppColors.danger.withValues(alpha: .10);
    } else if (primary) {
      foreground = AppColors.accent;
      background = AppColors.accent.withValues(alpha: .12);
    } else {
      foreground = AppColors.textPrimary;
      background = AppColors.surfaceDarkAlt;
    }

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(11),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: onPressed == null ? AppColors.textSecondary : foreground,
              ),
              SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: onPressed == null
                      ? AppColors.textSecondary
                      : foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
