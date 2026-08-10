import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../providers/settings_provider.dart';
import '../services/docker_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/responsive.dart';
import 'compose_list_view.dart';
import 'container_list_view.dart';
import 'image_list_view.dart';
import 'volume_list_view.dart';
import 'network_list_view.dart';
import 'file_manager_view.dart';
import 'host_terminal_screen.dart';
import 'settings_screen.dart';

class ServerShellScreen extends ConsumerStatefulWidget {
  final String serverId;
  final String serverName;

  const ServerShellScreen({
    super.key,
    required this.serverId,
    required this.serverName,
  });

  @override
  ConsumerState<ServerShellScreen> createState() => _ServerShellScreenState();
}

class _TabEntry {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final Widget view;

  const _TabEntry(this.icon, this.selectedIcon, this.label, this.view);
}

class _ServerShellScreenState extends ConsumerState<ServerShellScreen> {
  int _selectedIndex = 0;

  // Untuk memanggil goUp() dari luar (intercept tombol kembali di tab Files)
  final _fileManagerKey = GlobalKey<FileManagerViewState>();

  /// Saat true, body diganti ComposeListView (nav bar tetap tampil).
  bool _showCompose = false;

  /// Null = masih dicek, true/false = hasil supportsCompose.
  bool? _composeSupported;

  @override
  void initState() {
    super.initState();
    _checkComposeSupport();
  }

  Future<void> _checkComposeSupport() async {
    final supported = await DockerRepository.instance.supportsCompose(
      widget.serverId,
    );
    if (mounted) {
      setState(() => _composeSupported = supported);
    }
  }

  List<_TabEntry> _buildTabs(AppLocalizations l10n) => [
    _TabEntry(
      Icons.dns_outlined,
      Icons.dns_rounded,
      l10n.tabContainers,
      ContainerListView(
        serverId: widget.serverId,
        onOpenFileLocation: _openFileManagerAt,
      ),
    ),
    _TabEntry(
      Icons.inventory_2_outlined,
      Icons.inventory_2_rounded,
      l10n.tabImages,
      ImageListView(serverId: widget.serverId),
    ),
    _TabEntry(
      Icons.storage_outlined,
      Icons.storage_rounded,
      l10n.tabVolumes,
      VolumeListView(serverId: widget.serverId),
    ),
    _TabEntry(
      Icons.lan_outlined,
      Icons.lan_rounded,
      l10n.tabNetwork,
      NetworkListView(serverId: widget.serverId),
    ),
    _TabEntry(
      Icons.folder_outlined,
      Icons.folder_rounded,
      l10n.tabFiles,
      FileManagerView(key: _fileManagerKey, serverId: widget.serverId),
    ),
  ];

  void _openFileManagerAt(String path) {
    // Tutup compose dulu kalau sedang terbuka, lalu pindah ke Files.
    final filesIndex = 4; // Files tab
    if (filesIndex < 0) return;

    setState(() {
      _showCompose = false;
      _selectedIndex = filesIndex;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fileManagerKey.currentState?.navigateTo(path);
    });
  }

  void _onSelect(int i) {
    setState(() {
      // Pindah tab otomatis keluar dari mode Compose.
      _showCompose = false;
      _selectedIndex = i;
    });
  }

  void _openHostTerminal() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HostTerminalScreen(
          serverId: widget.serverId,
          serverName: widget.serverName,
        ),
      ),
    );
  }

  void _openCompose() {
    setState(() => _showCompose = true);
  }

  void _closeCompose() {
    setState(() => _showCompose = false);
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch settingsProvider murni buat trigger rebuild pas tema ganti -
    // AppColors itu static getter, gak otomatis ke-notify Flutter,
    // jadi butuh dependency Riverpod eksplisit ini biar widget yang
    // 'kept-alive' (IndexedStack dkk) ikut refresh tanpa reset navigasi.
    ref.watch(settingsProvider);
    final isWide = Responsive.of(context) != ScreenSize.mobile;
    final l10n = AppLocalizations.of(context);
    final tabs = _buildTabs(l10n);
    final selectedIndex = _selectedIndex >= tabs.length ? 0 : _selectedIndex;

    final filesIndex = tabs.length > 4
        ? 4
        : tabs.indexWhere((t) => t.label == l10n.tabFiles);
    final isOnFilesTab =
        !_showCompose && filesIndex != -1 && selectedIndex == filesIndex;
    final isOnContainersTab = selectedIndex == 0;

    // Cuma render tab yang lagi aktif - JANGAN pertahanin semua tab yang
    // pernah dibuka sekaligus (dulu pakai IndexedStack keep-all-alive).
    // Data-nya sendiri udah di-cache di level DockerRepository (TTL 8 detik),
    // jadi pindah tab tetap instan tanpa perlu nge-refetch - tapi WIDGET
    // tree-nya harus tetap dangkal, karena kalau semua tab (Containers+
    // Images+Volumes+Network+Files) numpuk ke-mount bareng, HeroController
    // yang jalan otomatis tiap pindah halaman (walau app ini gak pernah
    // pakai Hero widget secara eksplisit) bakal nyisir tree yang KELEWAT
    // dalam/lebar itu tiap kali - ujungnya stack overflow / app freeze
    // mendadak, persis kayak yang kejadian pas masuk ke Inspect.
    final tabBody = tabs[selectedIndex].view;

    // Saat mode Compose: ganti body dengan ComposeListView (nav tetap).
    final body = _showCompose
        ? ComposeListView(
            serverId: widget.serverId,
            onOpenFileLocation: _openFileManagerAt,
          )
        : tabBody;

    return PopScope(
      canPop: !_showCompose && !isOnFilesTab,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        if (_showCompose) {
          _closeCompose();
          return;
        }

        if (!isOnFilesTab) return;

        final fm = _fileManagerKey.currentState;
        if (fm != null && !fm.isAtRoot) {
          fm.goUp();
        } else {
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          backgroundColor: AppColors.surfaceDark,
          centerTitle: false,
          // Tombol back hanya saat mode Compose.
          leading: _showCompose
              ? IconButton(
                  icon: Icon(Icons.arrow_back_rounded),
                  tooltip: l10n.back,
                  onPressed: _closeCompose,
                )
              : null,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _showCompose ? l10n.composeStacks : widget.serverName,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 17,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                _showCompose ? l10n.dockerCompose : l10n.serverLabel,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          actions: [
            // Settings
            if (!_showCompose)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: IconButton(
                  tooltip: l10n.settings,
                  onPressed: _openSettings,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.surfaceDarkAlt.withValues(
                      alpha: 0.8,
                    ),
                    foregroundColor: AppColors.textSecondary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: Icon(Icons.settings_rounded, size: 20),
                ),
              ),

            // Compose button: hanya di tab Containers + compose supported +
            // tidak sedang di mode Compose.
            if (!_showCompose && isOnContainersTab && _composeSupported == true)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: IconButton(
                  tooltip: l10n.compose,
                  onPressed: _openCompose,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.accent.withValues(alpha: 0.12),
                    foregroundColor: AppColors.accent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: Icon(Icons.layers_rounded, size: 20),
                ),
              ),

            // Terminal Host
            if (!_showCompose)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton(
                  tooltip: l10n.terminalHost,
                  onPressed: _openHostTerminal,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.accent.withValues(alpha: 0.12),
                    foregroundColor: AppColors.accent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.terminal_rounded, size: 20),
                ),
              ),
          ],
        ),
        body: SafeArea(
          child: isWide
              ? Row(
                  children: [
                    // ========== MODERN SIDEBAR ==========
                    Container(
                      width: 220,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceDark,
                        border: Border(
                          right: BorderSide(
                            color: AppColors.border.withValues(alpha: 0.5),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              l10n.resources,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.8,
                                color: AppColors.textSecondary.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              itemCount: tabs.length,
                              itemBuilder: (context, i) {
                                final t = tabs[i];
                                // Saat mode Compose, tab Containers dianggap aktif.
                                final selected = _showCompose
                                    ? i == 0
                                    : i == selectedIndex;

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 2),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () => _onSelect(i),
                                      borderRadius: BorderRadius.circular(10),
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 180,
                                        ),
                                        curve: Curves.easeOut,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 11,
                                        ),
                                        decoration: BoxDecoration(
                                          color: selected
                                              ? AppColors.accent.withValues(
                                                  alpha: 0.12,
                                                )
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          border: selected
                                              ? Border(
                                                  left: BorderSide(
                                                    color: AppColors.accent,
                                                    width: 3,
                                                  ),
                                                )
                                              : null,
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              selected
                                                  ? t.selectedIcon
                                                  : t.icon,
                                              size: 20,
                                              color: selected
                                                  ? AppColors.accent
                                                  : AppColors.textSecondary,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                t.label,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: selected
                                                      ? FontWeight.w600
                                                      : FontWeight.w500,
                                                  color: selected
                                                      ? AppColors.accent
                                                      : AppColors.textSecondary,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          // Footer kecil di sidebar
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                            child: Text(
                              l10n.dockerManager,
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Content
                    Expanded(child: body),
                  ],
                )
              : body,
        ),
        // ========== MOBILE BOTTOM BAR ==========
        bottomNavigationBar: isWide
            ? null
            : Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  border: Border(
                    top: BorderSide(
                      color: AppColors.border.withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                ),
                child: NavigationBar(
                  // Saat mode Compose, highlight tab Containers.
                  selectedIndex: _showCompose ? 0 : selectedIndex,
                  onDestinationSelected: _onSelect,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  height: 70,
                  indicatorColor: AppColors.accent.withValues(alpha: 0.15),
                  indicatorShape: const StadiumBorder(),
                  labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                  destinations: [
                    for (final t in tabs)
                      NavigationDestination(
                        icon: Icon(t.icon, size: 22),
                        selectedIcon: Icon(
                          t.selectedIcon,
                          size: 22,
                          color: AppColors.accent,
                        ),
                        label: t.label,
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}
