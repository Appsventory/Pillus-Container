import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/server_model.dart';
import '../theme/app_theme.dart';

class ServerCard extends StatelessWidget {
  final ServerModel server;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onReconnect;
  final VoidCallback? onDelete;

  const ServerCard({
    super.key,
    required this.server,
    this.onTap,
    this.onEdit,
    this.onReconnect,
    this.onDelete,
  });

  bool get _hasCachedStats => server.lastConnected != null;

  Color get _statusColor {
    switch (server.status) {
      case ServerStatus.online:
        return AppColors.success;
      case ServerStatus.connecting:
        return AppColors.warning;
      case ServerStatus.error:
        return AppColors.danger;
      case ServerStatus.offline:
        // Bukan sesi SSH aktif, tapi masih bisa tau host-nya nyala/enggak
        // dari quick-check (TCP connect), tanpa login penuh.
        if (server.reachable == true) return AppColors.accent;
        if (server.reachable == false) return AppColors.textSecondary;
        return AppColors.textSecondary; // belum sempat dicek
    }
  }

  String get _statusLabel {
    switch (server.status) {
      case ServerStatus.online:
        return 'Online';
      case ServerStatus.connecting:
        return 'Connecting';
      case ServerStatus.error:
        return 'Error';
      case ServerStatus.offline:
        if (server.reachable == true) return 'Reachable';
        if (server.reachable == false) return 'Unreachable';
        return 'Checking...';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      server.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    _statusLabel,
                    style: TextStyle(fontSize: 12, color: _statusColor),
                  ),
                  if (onEdit != null ||
                      onReconnect != null ||
                      onDelete != null) ...[
                    const SizedBox(width: 4),
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert_rounded,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                      padding: EdgeInsets.zero,
                      color: AppColors.surfaceDarkAlt,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: AppColors.border),
                      ),
                      onSelected: (v) {
                        switch (v) {
                          case 'edit':
                            onEdit?.call();
                          case 'reconnect':
                            onReconnect?.call();
                          case 'delete':
                            onDelete?.call();
                        }
                      },
                      itemBuilder: (context) => [
                        if (onEdit != null)
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.edit_outlined,
                                  size: 18,
                                  color: AppColors.textSecondary,
                                ),
                                SizedBox(width: 10),
                                Text(AppLocalizations.of(context).editServer),
                              ],
                            ),
                          ),
                        if (onReconnect != null)
                          PopupMenuItem(
                            value: 'reconnect',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.refresh_rounded,
                                  size: 18,
                                  color: AppColors.textSecondary,
                                ),
                                SizedBox(width: 10),
                                Text(AppLocalizations.of(context).reconnect),
                              ],
                            ),
                          ),
                        if (onDelete != null)
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete_outline_rounded,
                                  size: 18,
                                  color: AppColors.danger,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  AppLocalizations.of(context).delete,
                                  style: TextStyle(color: AppColors.danger),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
              SizedBox(height: 4),
              Text(
                '${server.username}@${server.host}:${server.port}',
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 14),
              if (_hasCachedStats) ...[
                _infoRow(
                  AppLocalizations.of(context).osLabel,
                  server.osInfo ?? '-',
                ),
                _infoRow(
                  AppLocalizations.of(context).dockerLabel,
                  server.dockerVersion ?? '-',
                ),
                _infoRow(
                  AppLocalizations.of(context).container,
                  AppLocalizations.of(context).containersRunning(
                    server.containerRunning ?? 0,
                    server.containerTotal ?? 0,
                  ),
                ),
                _infoRow(
                  AppLocalizations.of(context).imagesTitle,
                  '${server.imageCount ?? 0}',
                ),
                const SizedBox(height: 10),
                _usageBar(
                  AppLocalizations.of(context).cpu,
                  server.cpuUsagePercent,
                ),
                _usageBar(
                  AppLocalizations.of(context).ram,
                  server.ramUsagePercent,
                ),
                _usageBar(
                  AppLocalizations.of(context).disk,
                  server.diskUsagePercent,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      server.status == ServerStatus.online
                          ? Icons.bolt_rounded
                          : Icons.history_rounded,
                      size: 12,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        server.status == ServerStatus.online
                            ? '${AppLocalizations.of(context).live} · ${server.latencyMs ?? '-'} ms'
                            : AppLocalizations.of(context).lastData(
                                _relativeTime(context, server.lastConnected!),
                              ),
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ] else
                Text(
                  AppLocalizations.of(context).neverConnected,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _usageBar(String label, double? percent) {
    final p = (percent ?? 0).clamp(0, 100) / 100;
    Color color = AppColors.success;
    if (p > 0.85) {
      color = AppColors.danger;
    } else if (p > 0.6) {
      color = AppColors.warning;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 49,
            child: Text(
              label,
              style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: p.toDouble(),
                minHeight: 6,
                backgroundColor: AppColors.surfaceDarkAlt,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 34,
            child: Text(
              '${(percent ?? 0).toStringAsFixed(0)}%',
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 11.5),
            ),
          ),
        ],
      ),
    );
  }

  String _relativeTime(BuildContext context, DateTime dt) {
    final l10n = AppLocalizations.of(context);
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return l10n.justNow;
    if (diff.inMinutes < 60) return l10n.minutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return l10n.hoursAgo(diff.inHours);
    return l10n.daysAgo(diff.inDays);
  }
}
