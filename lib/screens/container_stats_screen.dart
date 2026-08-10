import 'dart:async';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/container_stats_model.dart';
import '../services/docker_repository.dart';
import '../theme/app_theme.dart';

class ContainerStatsScreen extends StatefulWidget {
  final String serverId;
  final String containerId;
  final String containerName;

  const ContainerStatsScreen({
    super.key,
    required this.serverId,
    required this.containerId,
    required this.containerName,
  });

  @override
  State<ContainerStatsScreen> createState() => _ContainerStatsScreenState();
}

class _ContainerStatsScreenState extends State<ContainerStatsScreen> {
  StreamSubscription<Map<String, ContainerStatsModel>>? _sub;
  ContainerStatsModel? _stats;
  String? _error;

  @override
  void initState() {
    super.initState();
    _sub = DockerRepository.instance
        .watchStats(widget.serverId)
        .listen(
          (map) {
            // Docker ps ID / stats ID sama-sama short-id (12 char) jadi cocok.
            final s =
                map[widget.containerId] ??
                map.values
                    .where((v) => widget.containerId.startsWith(v.id))
                    .firstOrNull;
            if (mounted && s != null) setState(() => _stats = s);
          },
          onError: (e) {
            if (mounted) setState(() => _error = AppLocalizations.of(context).failedLoadStats('$e'));
          },
        );
  }

  @override
  void dispose() {
    // Cuma stop listen; stream `docker stats` di repository otomatis
    // berhenti sendiri kalau ini listener terakhir yang nonton.
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).statsTitle(widget.containerName),
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: _error != null
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
            : _stats == null
            ? Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 14),
                      Text(
                        AppLocalizations.of(context).waitingStats,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _usageCard(AppLocalizations.of(context).cpu, _stats!.cpuPercent, _stats!.cpuValue),
                  SizedBox(height: 14),
                  _usageCard(
                    AppLocalizations.of(context).memory,
                    _stats!.memPercent,
                    _stats!.memValue,
                    subtitle: _stats!.memUsage,
                  ),
                  const SizedBox(height: 14),
                  _infoCard(AppLocalizations.of(context).networkIo, _stats!.netIO),
                  const SizedBox(height: 14),
                  _infoCard(AppLocalizations.of(context).blockIo, _stats!.blockIO),
                  const SizedBox(height: 14),
                  _infoCard(AppLocalizations.of(context).pids, _stats!.pids),
                  const SizedBox(height: 20),
                  Text(
                    AppLocalizations.of(context).statsLiveHint,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _usageCard(
    String label,
    String percentText,
    double value, {
    String? subtitle,
  }) {
    Color color = AppColors.success;
    if (value > 85) {
      color = AppColors.danger;
    } else if (value > 60) {
      color = AppColors.warning;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  percentText,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (value.clamp(0, 100)) / 100,
                minHeight: 8,
                backgroundColor: AppColors.surfaceDarkAlt,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
            if (subtitle != null) ...[
              SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoCard(String label, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              value,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
