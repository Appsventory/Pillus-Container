import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/docker_repository.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';

class ContainerLogsScreen extends StatefulWidget {
  final String serverId;
  final String containerId;
  final String containerName;

  const ContainerLogsScreen({
    super.key,
    required this.serverId,
    required this.containerId,
    required this.containerName,
  });

  @override
  State<ContainerLogsScreen> createState() => _ContainerLogsScreenState();
}

class _ContainerLogsScreenState extends State<ContainerLogsScreen> {
  String _logs = '';
  bool _loading = true;
  String? _error;
  late int _tailLines;
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _tailLines = SettingsService.instance.current.logTailLines;
    _load();
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final logs = await DockerRepository.instance.containerLogs(
        widget.serverId,
        widget.containerId,
        tailLines: _tailLines,
      );
      if (!mounted) return;
      setState(() {
        _logs = logs.isEmpty ? AppLocalizations.of(context).logsEmpty : logs;
        _loading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollCtrl.hasClients) {
          _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = AppLocalizations.of(context).failedLoadLogs('$e');
        _loading = false;
      });
    }
  }

  void _loadMore() {
    setState(() => _tailLines += 500);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.containerName,
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loading ? null : _load,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    _error!,
                    style: TextStyle(color: AppColors.danger),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : Column(
                children: [
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      color: AppColors.surfaceDarkAlt,
                      child: SingleChildScrollView(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.all(14),
                        child: SelectableText(
                          _logs,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: AppColors.textPrimary,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: AppColors.border)),
                    ),
                    child: Row(
                      children: [
                        Text(
                          AppLocalizations.of(context).showingLastLines(_tailLines),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: _loadMore,
                          child: Text(AppLocalizations.of(context).loadMore),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
