import 'package:pillus/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/server_model.dart';
import '../providers/server_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/fingerprint_dialog.dart';
import '../widgets/responsive.dart';
import '../widgets/server_card.dart';
import 'add_server_screen.dart';
import 'server_shell_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Trigger rebuild pas tema ganti (lihat catatan sama di server_shell_screen.dart).
    ref.watch(settingsProvider);
    final servers = ref.watch(serverListProvider);
    final columns = Responsive.gridColumns(context);
    final padding = Responsive.pagePadding(context);
    final onlineCount = servers.where((s) => s.status.name == 'online').length;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Dashboard',
          style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.3),
        ),
        centerTitle: false,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.add_rounded),
            tooltip: AppLocalizations.of(context).addServer,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddServerScreen()),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: servers.isEmpty
            ? _EmptyState(padding: padding)
            : RefreshIndicator(
                onRefresh: () => ref
                    .read(serverListProvider.notifier)
                    .checkAllReachability(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: padding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status summary
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceDark.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: onlineCount > 0
                                    ? AppColors.success
                                    : AppColors.textSecondary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 10),
                            Text(
                              AppLocalizations.of(
                                context,
                              ).serversOnline(onlineCount, servers.length),
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),

                      // Server grid
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: servers.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          mainAxisExtent: 320,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemBuilder: (context, i) {
                          final s = servers[i];
                          return ServerCard(
                            server: s,
                            onTap: () => s.status == ServerStatus.online
                                ? _openContainers(context, s)
                                : _connectAndEnter(context, ref, s),
                            onEdit: () => _editServer(context, s),
                            onReconnect: () => _reconnect(context, ref, s.id),
                            onDelete: () => _confirmDelete(context, ref, s),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        elevation: 3,
        child: const Icon(Icons.settings),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          );
        },
      ),
    );
  }

  void _openContainers(BuildContext context, ServerModel server) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ServerShellScreen(serverId: server.id, serverName: server.name),
      ),
    );
  }

  void _editServer(BuildContext context, ServerModel server) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddServerScreen(editingServer: server)),
    );
  }

  /// Tap 1x: kalau belum connect, connect dulu - begitu berhasil LANGSUNG
  /// masuk ke ServerShellScreen (gak perlu tap lagi). Kalau gagal, tetap
  /// di dashboard, card bakal nunjukin status error kayak biasa.
  Future<void> _connectAndEnter(
    BuildContext context,
    WidgetRef ref,
    ServerModel server,
  ) async {
    await _reconnect(context, ref, server.id);
    if (!context.mounted) return;

    final updated = ref
        .read(serverListProvider)
        .where((s) => s.id == server.id)
        .firstOrNull;
    if (updated?.status == ServerStatus.online) {
      _openContainers(context, updated!);
    }
  }

  Future<void> _reconnect(BuildContext context, WidgetRef ref, String id) {
    return ref
        .read(serverListProvider.notifier)
        .connectServer(
          id,
          onFingerprintPrompt:
              ({
                required host,
                required keyType,
                required fingerprint,
                required changed,
              }) {
                return showFingerprintDialog(
                  context,
                  host: host,
                  keyType: keyType,
                  fingerprint: fingerprint,
                  changed: changed,
                );
              },
        );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    ServerModel server,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.border),
        ),
        title: Text(
          AppLocalizations.of(context).deleteServerTitle,
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        content: Text(
          AppLocalizations.of(context).deleteServerBody(server.name),
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13.5,
            height: 1.45,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context).delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(serverListProvider.notifier).removeServer(server.id);
    }
  }
}

class _EmptyState extends StatelessWidget {
  final EdgeInsets padding;

  const _EmptyState({required this.padding});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
              ),
              child: Icon(
                Icons.dns_rounded,
                size: 40,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 24),
            Text(
              AppLocalizations.of(context).noServersTitle,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context).noServersBody,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddServerScreen()),
              ),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: Text(AppLocalizations.of(context).addServer),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//  Navigator.push(
//       context,
//       MaterialPageRoute(builder: (_) => const SettingsScreen()),
//     );
