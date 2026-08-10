import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../providers/settings_provider.dart';
import '../models/network_model.dart';
import '../models/container_model.dart';
import '../services/docker_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/safe_input_dialog.dart';

class NetworkListView extends ConsumerStatefulWidget {
  final String serverId;

  const NetworkListView({super.key, required this.serverId});

  @override
  ConsumerState<NetworkListView> createState() => _NetworkListViewState();
}

class _NetworkListViewState extends ConsumerState<NetworkListView> {
  List<NetworkModel> _networks = [];
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
      final raw = await DockerRepository.instance.listNetworks(
        widget.serverId,
        forceRefresh: force,
      );

      if (!mounted) return;

      setState(() {
        _networks = raw.map((m) => NetworkModel.fromDockerJson(m)).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = AppLocalizations.of(context).failedLoadNetworks('$e');
        _loading = false;
      });
    }
  }

  Future<void> _showCreateDialog() async {
    final nameCtrl = TextEditingController();
    String driver = 'bridge';

    final result = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
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
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.lan_rounded, color: AppColors.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  AppLocalizations.of(context).createNetwork,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(context).networkName,
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              SizedBox(height: 7),
              TextField(
                controller: nameCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'my_network',
                  filled: true,
                  fillColor: AppColors.surfaceDarkAlt,
                  prefixIcon: const Icon(Icons.tag_rounded, size: 19),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Driver',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              SizedBox(height: 7),
              DropdownButtonFormField<String>(
                initialValue: driver,
                dropdownColor: AppColors.surfaceDarkAlt,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.surfaceDarkAlt,
                  prefixIcon: const Icon(Icons.account_tree_rounded, size: 19),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'bridge', child: Text('bridge')),
                  DropdownMenuItem(value: 'overlay', child: Text('overlay')),
                  DropdownMenuItem(value: 'macvlan', child: Text('macvlan')),
                ],
                onChanged: (v) {
                  setDialogState(() => driver = v ?? 'bridge');
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context).cancel),
            ),
            FilledButton.icon(
              onPressed: () =>
                  Navigator.pop(context, '${nameCtrl.text.trim()}|$driver'),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(AppLocalizations.of(context).create),
            ),
          ],
        ),
      ),
    );

    disposeControllerLater(nameCtrl);

    if (result == null) return;

    final parts = result.split('|');
    final name = parts[0];
    final driverChosen = parts.length > 1 ? parts[1] : 'bridge';

    if (name.isEmpty) return;

    try {
      await DockerRepository.instance.createNetwork(
        widget.serverId,
        name,
        driver: driverChosen,
      );

      await _refresh(force: true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).failedCreateNetwork('$e'),
            ),
          ),
        );
      }
    }
  }

  Future<void> _confirmRemove(NetworkModel n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.border),
        ),
        title: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.delete_outline_rounded,
                color: AppColors.danger,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                AppLocalizations.of(context).delete,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: Text(
          AppLocalizations.of(context).deleteNetworkBody(n.name),
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

    setState(() => _busyNames.add(n.name));

    try {
      await DockerRepository.instance.removeNetwork(widget.serverId, n.name);

      await _refresh(force: true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).failedDelete('$e')),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busyNames.remove(n.name));
      }
    }
  }

  Future<void> _showInspect(NetworkModel n) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _NetworkDetailSheet(
        serverId: widget.serverId,
        network: n,
        onChanged: () => _refresh(force: true),
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
                      'Networks',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      AppLocalizations.of(context).networkSubtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              _HeaderButton(
                icon: Icons.refresh_rounded,
                tooltip: AppLocalizations.of(context).refresh,
                onPressed: _loading ? null : () => _refresh(force: true),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _showCreateDialog,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(AppLocalizations.of(context).create),
              ),
            ],
          ),
        ),
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildBody() {
    if (_loading && _networks.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: .10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  color: AppColors.danger,
                  size: 26,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                _error!,
                style: TextStyle(color: AppColors.danger, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
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

    if (_networks.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.surfaceDarkAlt,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                Icons.lan_outlined,
                size: 30,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).noNetworksFound,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 5),
            Text(
              AppLocalizations.of(context).createNetworkHint,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _showCreateDialog,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(AppLocalizations.of(context).createNetwork),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _refresh(force: true),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        itemCount: _networks.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final n = _networks[i];
          final busy = _busyNames.contains(n.name);

          return _NetworkCard(
            network: n,
            busy: busy,
            onTap: () => _showInspect(n),
            onDelete: () => _confirmRemove(n),
          );
        },
      ),
    );
  }
}

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

class _NetworkCard extends StatelessWidget {
  final NetworkModel network;
  final bool busy;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _NetworkCard({
    required this.network,
    required this.busy,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceDark,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  Icons.lan_rounded,
                  color: AppColors.accent,
                  size: 23,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            network.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (network.isBuiltIn) ...[
                          const SizedBox(width: 7),
                          Icon(
                            Icons.lock_outline_rounded,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: 9),
                    Wrap(
                      spacing: 6,
                      runSpacing: 5,
                      children: [
                        _NetworkBadge(
                          icon: Icons.account_tree_rounded,
                          label: network.driver,
                        ),
                        _NetworkBadge(
                          icon: Icons.public_rounded,
                          label: network.scope,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (busy)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else if (network.isBuiltIn)
                Tooltip(
                  message: AppLocalizations.of(context).builtInNetwork,
                  child: Icon(
                    Icons.shield_outlined,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                )
              else
                IconButton(
                  onPressed: onDelete,
                  tooltip: AppLocalizations.of(context).delete,
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.danger,
                    size: 20,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NetworkBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _NetworkBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceDarkAlt,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textSecondary),
          SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _NetworkDetailSheet extends StatefulWidget {
  final String serverId;
  final NetworkModel network;
  final VoidCallback onChanged;

  const _NetworkDetailSheet({
    required this.serverId,
    required this.network,
    required this.onChanged,
  });

  @override
  State<_NetworkDetailSheet> createState() => _NetworkDetailSheetState();
}

class _NetworkDetailSheetState extends State<_NetworkDetailSheet> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;
  bool _busy = false;

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
      final data = await DockerRepository.instance.inspectNetwork(
        widget.serverId,
        widget.network.name,
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

  Future<void> _disconnect(String containerId, String containerName) async {
    setState(() => _busy = true);

    try {
      await DockerRepository.instance.disconnectContainerFromNetwork(
        widget.serverId,
        widget.network.name,
        containerId,
      );

      await _load();
      widget.onChanged();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).failedDisconnect('$e')),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _showConnectDialog() async {
    List<ContainerModel> allContainers;

    try {
      allContainers = await DockerRepository.instance.listContainers(
        widget.serverId,
        includeStopped: false,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).failedLoadContainers('$e'),
            ),
          ),
        );
      }
      return;
    }

    final connected = (_data?['Containers'] as Map?) ?? {};

    final available = allContainers
        .where((c) => !connected.containsKey(c.id))
        .toList();

    if (!mounted) return;

    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).allContainersConnected),
        ),
      );
      return;
    }

    final picked = await showDialog<ContainerModel>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.border),
        ),
        title: Text(
          AppLocalizations.of(context).connectContainer,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: available.length,
            separatorBuilder: (_, _) => const SizedBox(height: 6),
            itemBuilder: (context, i) {
              final container = available[i];

              return Material(
                color: AppColors.surfaceDarkAlt,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => Navigator.pop(context, container),
                  child: Padding(
                    padding: const EdgeInsets.all(13),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: .10),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.inventory_2_outlined,
                            color: AppColors.accent,
                            size: 19,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                container.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                container.image,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).cancel),
          ),
        ],
      ),
    );

    if (picked == null) return;

    setState(() => _busy = true);

    try {
      await DockerRepository.instance.connectContainerToNetwork(
        widget.serverId,
        widget.network.name,
        picked.id,
      );

      await _load();
      widget.onChanged();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).failedConnect('$e')),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final containers = (_data?['Containers'] as Map?) ?? {};

    return DraggableScrollableSheet(
      initialChildSize: 0.62,
      maxChildSize: 0.92,
      minChildSize: 0.45,
      expand: false,
      builder: (context, scrollCtrl) {
        if (_loading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (_error != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                _error!,
                style: TextStyle(color: AppColors.danger),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            SizedBox(height: 24),

            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: .10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.lan_rounded,
                    color: AppColors.accent,
                    size: 25,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.network.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Docker Network',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceDarkAlt,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _InfoItem(
                      label: AppLocalizations.of(context).driver,
                      value: _data?['Driver']?.toString() ?? '-',
                    ),
                  ),
                  Container(width: 1, height: 30, color: AppColors.border),
                  Expanded(
                    child: _InfoItem(
                      label: AppLocalizations.of(context).scope,
                      value: _data?['Scope']?.toString() ?? '-',
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context).connectedContainers,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        AppLocalizations.of(context).containersOnNetwork,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: _busy ? null : _showConnectDialog,
                  icon: Icon(Icons.add_rounded, size: 17),
                  label: Text(AppLocalizations.of(context).connect),
                ),
              ],
            ),

            const SizedBox(height: 12),

            if (containers.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 28,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDarkAlt,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.link_off_rounded,
                      size: 28,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(height: 10),
                    Text(
                      AppLocalizations.of(context).noConnectedContainers,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      AppLocalizations.of(context).connectContainerHint,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              )
            else
              ...containers.entries.map((e) {
                final id = e.key as String;
                final info = e.value as Map;

                final name = info['Name']?.toString() ?? id;

                final ip = info['IPv4Address']?.toString() ?? '-';

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDarkAlt,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: .08),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Icon(
                          Icons.inventory_2_outlined,
                          color: AppColors.accent,
                          size: 19,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.lan_outlined,
                                  size: 12,
                                  color: AppColors.textSecondary,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  ip,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (_busy)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        IconButton(
                          tooltip: AppLocalizations.of(context).disconnect,
                          onPressed: () => _disconnect(id, name),
                          icon: Icon(
                            Icons.link_off_rounded,
                            size: 19,
                            color: AppColors.danger,
                          ),
                        ),
                    ],
                  ),
                );
              }),
          ],
        );
      },
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;

  const _InfoItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
