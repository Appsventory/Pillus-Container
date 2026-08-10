import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/docker_repository.dart';
import '../theme/app_theme.dart';

class ContainerInspectScreen extends StatefulWidget {
  final String serverId;
  final String containerId;
  final String containerName;

  const ContainerInspectScreen({
    super.key,
    required this.serverId,
    required this.containerId,
    required this.containerName,
  });

  @override
  State<ContainerInspectScreen> createState() => _ContainerInspectScreenState();
}

class _ContainerInspectScreenState extends State<ContainerInspectScreen> {
  Map<String, dynamic>? _data;
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
      final data = await DockerRepository.instance.inspectContainer(
        widget.serverId,
        widget.containerId,
      );
      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = AppLocalizations.of(context).failedLoadDetails('$e');
        _loading = false;
      });
    }
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
            : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    final d = _data!;
    // PENTING: key di sini ('Config', 'State', dst) itu nama field dari
    // JSON API Docker asli - FIXED, bukan teks UI, jadi JANGAN pernah
    // pakai getter l10n buat baca key JSON (bakal selalu miss di bahasa
    // selain yang translasinya kebetulan sama kayak Docker punya).
    final config = (d['Config'] as Map?) ?? {};
    final state = (d['State'] as Map?) ?? {};
    final hostConfig = (d['HostConfig'] as Map?) ?? {};
    final networkSettings = (d['NetworkSettings'] as Map?) ?? {};
    final mounts = (d['Mounts'] as List?) ?? [];
    final env = (config['Env'] as List?) ?? [];
    final ports = (networkSettings['Ports'] as Map?) ?? {};

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _section(AppLocalizations.of(context).general, [
          _row('ID', (d['Id'] as String? ?? '').substring(0, 12)),
          _row(
            AppLocalizations.of(context).image,
            config['Image']?.toString() ?? '-',
          ),
          _row(
            AppLocalizations.of(context).created,
            d['Created']?.toString() ?? '-',
          ),
          _row(
            AppLocalizations.of(context).status,
            state['Status']?.toString() ?? '-',
          ),
          _row(
            AppLocalizations.of(context).startedAt,
            state['StartedAt']?.toString() ?? '-',
          ),
          _row(
            AppLocalizations.of(context).restartCount,
            d['RestartCount']?.toString() ?? '0',
          ),
        ]),
        _section(AppLocalizations.of(context).configuration, [
          _row(
            AppLocalizations.of(context).command,
            (config['Cmd'] as List?)?.join(' ') ?? '-',
          ),
          _row(
            AppLocalizations.of(context).entrypoint,
            (config['Entrypoint'] as List?)?.join(' ') ?? '-',
          ),
          _row(
            AppLocalizations.of(context).workingDir,
            config['WorkingDir']?.toString() ?? '-',
          ),
          _row(
            AppLocalizations.of(context).restartPolicy,
            hostConfig['RestartPolicy']?['Name']?.toString() ?? '-',
          ),
          _row(
            AppLocalizations.of(context).networkMode,
            hostConfig['NetworkMode']?.toString() ?? '-',
          ),
        ]),
        if (ports.isNotEmpty)
          _section(
            AppLocalizations.of(context).ports,
            ports.entries.map((e) {
              final bindings = (e.value as List?) ?? [];
              final text = bindings.isEmpty
                  ? AppLocalizations.of(context).notPublished
                  : bindings
                        .map((b) => '${b['HostIp']}:${b['HostPort']}')
                        .join(', ');
              return _row(e.key.toString(), text);
            }).toList(),
          ),
        if (mounts.isNotEmpty)
          _section(
            AppLocalizations.of(context).mounts,
            mounts.map((m) {
              final src = m['Source']?.toString() ?? '-';
              final dst = m['Destination']?.toString() ?? '-';
              return _row(dst, src);
            }).toList(),
          ),
        if (env.isNotEmpty)
          _section(
            AppLocalizations.of(context).envVars,
            env.map((e) => _row('', e.toString())).toList(),
          ),
      ],
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(children: children),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label.isNotEmpty)
            SizedBox(
              width: 110,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          Expanded(
            child: SelectableText(
              value,
              style: TextStyle(fontSize: 12.5, fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }
}
