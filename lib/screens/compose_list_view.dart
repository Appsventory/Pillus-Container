import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../providers/settings_provider.dart';
import '../models/compose_stack_model.dart';
import '../services/docker_repository.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';
import 'compose_edit_screen.dart';

class ComposeListView extends ConsumerStatefulWidget {
  final String serverId;
  final void Function(String path) onOpenFileLocation;

  const ComposeListView({
    super.key,
    required this.serverId,
    required this.onOpenFileLocation,
  });

  @override
  ConsumerState<ComposeListView> createState() => _ComposeListViewState();
}

class _ComposeListViewState extends ConsumerState<ComposeListView> {
  List<ComposeStackModel> _stacks = [];
  bool _loading = true;
  String? _error;
  final Set<String> _busyNames = {};

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final raw = await DockerRepository.instance.listComposeStacks(
        widget.serverId,
      );
      if (!mounted) return;
      setState(() {
        _stacks = raw.map((m) => ComposeStackModel.fromDockerJson(m)).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = AppLocalizations.of(context).failedLoadStacks('$e');
        _loading = false;
      });
    }
  }

  Future<void> _runAction(String name, Future<void> Function() action) async {
    setState(() => _busyNames.add(name));
    try {
      await action();
      await _refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).failed('$e'))),
        );
      }
    } finally {
      if (mounted) setState(() => _busyNames.remove(name));
    }
  }

  Future<void> _confirmDown(ComposeStackModel s) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: AppColors.border),
        ),
        title: Text(AppLocalizations.of(context).stopStackTitle),
        content: Text(
          AppLocalizations.of(context).stopStackBody(s.name),
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context).down),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _runAction(
        s.name,
        () => DockerRepository.instance.composeDown(
          widget.serverId,
          s.primaryConfigFile,
        ),
      );
    }
  }

  Future<void> _showLogs(ComposeStackModel s) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollCtrl) => _ComposeLogsSheet(
          serverId: widget.serverId,
          stack: s,
          scrollController: scrollCtrl,
        ),
      ),
    );
  }

  void _editComposeFile(ComposeStackModel s) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ComposeEditScreen(
          serverId: widget.serverId,
          configFile: s.primaryConfigFile,
        ),
      ),
    );
  }

  void _openFileLocation(ComposeStackModel s) {
    final file = s.primaryConfigFile;
    final lastSlash = file.lastIndexOf('/');
    final dir = lastSlash > 0 ? file.substring(0, lastSlash) : '/';
    widget.onOpenFileLocation(dir);
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
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
          child: Row(
            children: [
              Text(
                AppLocalizations.of(context).composeStacks,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 20),
                onPressed: _loading ? null : _refresh,
              ),
            ],
          ),
        ),
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildBody() {
    if (_loading && _stacks.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _error!,
            style: TextStyle(color: AppColors.danger, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (_stacks.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context).noComposeStacks,
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        itemCount: _stacks.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final s = _stacks[i];
          final busy = _busyNames.contains(s.name);
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: s.isRunning
                              ? AppColors.success
                              : AppColors.textSecondary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          s.name,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (busy)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_vert_rounded,
                          size: 20,
                          color: AppColors.textSecondary,
                        ),
                        color: AppColors.surfaceDarkAlt,
                        onSelected: (v) {
                          switch (v) {
                            case 'edit':
                              _editComposeFile(s);
                            case 'location':
                              _openFileLocation(s);
                            case 'logs':
                              _showLogs(s);
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: Text(
                              AppLocalizations.of(context).editContents,
                            ),
                          ),
                          PopupMenuItem(
                            value: 'location',
                            child: Text(
                              AppLocalizations.of(context).openFileLocation,
                            ),
                          ),
                          PopupMenuItem(
                            value: 'logs',
                            child: Text(AppLocalizations.of(context).logs),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    s.status,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    s.primaryConfigFile,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontFamily: 'monospace',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 4,
                    children: [
                      _actionBtn(
                        Icons.play_arrow_rounded,
                        'Up',
                        busy
                            ? null
                            : () => _runAction(
                                s.name,
                                () => DockerRepository.instance.composeUp(
                                  widget.serverId,
                                  s.primaryConfigFile,
                                ),
                              ),
                      ),
                      _actionBtn(
                        Icons.refresh_rounded,
                        AppLocalizations.of(context).restart,
                        busy
                            ? null
                            : () => _runAction(
                                s.name,
                                () => DockerRepository.instance.composeRestart(
                                  widget.serverId,
                                  s.primaryConfigFile,
                                ),
                              ),
                      ),
                      _actionBtn(
                        Icons.download_rounded,
                        AppLocalizations.of(context).pull,
                        busy
                            ? null
                            : () => _runAction(
                                s.name,
                                () => DockerRepository.instance.composePull(
                                  widget.serverId,
                                  s.primaryConfigFile,
                                ),
                              ),
                      ),
                      _actionBtn(
                        Icons.stop_circle_outlined,
                        AppLocalizations.of(context).down,
                        busy ? null : () => _confirmDown(s),
                        color: AppColors.danger,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _actionBtn(
    IconData icon,
    String label,
    VoidCallback? onTap, {
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color ?? AppColors.textPrimary),
            SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                color: color ?? AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComposeLogsSheet extends StatefulWidget {
  final String serverId;
  final ComposeStackModel stack;
  final ScrollController scrollController;

  const _ComposeLogsSheet({
    required this.serverId,
    required this.stack,
    required this.scrollController,
  });

  @override
  State<_ComposeLogsSheet> createState() => _ComposeLogsSheetState();
}

class _ComposeLogsSheetState extends State<_ComposeLogsSheet> {
  String _logs = '';
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final logs = await DockerRepository.instance.composeLogs(
        widget.serverId,
        widget.stack.primaryConfigFile,
        tailLines: SettingsService.instance.current.logTailLines,
      );
      if (!mounted) return;
      setState(() {
        _logs = logs.isEmpty
            ? AppLocalizations.of(context).logsEmptyShort
            : logs;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = AppLocalizations.of(context).failedLoadLogs('$e');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  AppLocalizations.of(context).logsFor(widget.stack.name),
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 20),
                onPressed: _loading ? null : _load,
              ),
            ],
          ),
          Divider(color: AppColors.border),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
                    child: Text(
                      _error!,
                      style: TextStyle(color: AppColors.danger),
                    ),
                  )
                : Container(
                    width: double.infinity,
                    color: AppColors.surfaceDarkAlt,
                    child: SingleChildScrollView(
                      controller: widget.scrollController,
                      padding: const EdgeInsets.all(12),
                      child: SelectableText(
                        _logs,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11.5,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
