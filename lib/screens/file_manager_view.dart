import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../providers/settings_provider.dart';
import 'package:path_provider/path_provider.dart';

import '../services/sftp_service.dart';
import '../theme/app_theme.dart';
import '../widgets/safe_input_dialog.dart';

class FileManagerView extends ConsumerStatefulWidget {
  final String serverId;

  const FileManagerView({super.key, required this.serverId});

  @override
  FileManagerViewState createState() => FileManagerViewState();
}

/// State sengaja PUBLIC agar widget luar seperti
/// ServerShellScreen dapat mengakses:
/// - isAtRoot
/// - goUp()
/// - navigateTo()
///
/// Digunakan untuk system back navigation dan
/// membuka lokasi file dari halaman Compose.
class FileManagerViewState extends ConsumerState<FileManagerView> {
  String _currentPath = '/';
  List<SftpFileEntry> _entries = [];

  bool _loading = true;
  String? _error;
  bool _busy = false;
  bool _isGridView = false;

  bool get isAtRoot {
    final p = _currentPath.trim();
    return p.isEmpty || p == '/';
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    SftpService.instance.closeSession(widget.serverId);
    super.dispose();
  }

  String _join(String base, String name) {
    if (base == '/') return '/$name';
    return '$base/$name';
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final list = await SftpService.instance.listDirectory(
        widget.serverId,
        _currentPath,
      );

      if (!mounted) return;

      setState(() {
        _entries = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = AppLocalizations.of(context).failedOpenFolder('$e');
        _loading = false;
      });
    }
  }

  void _enterFolder(String name) {
    setState(() {
      _currentPath = _join(_currentPath, name);
    });

    _load();
  }

  /// Kembali satu level direktori.
  void goUp() {
    if (isAtRoot) return;

    final parts = _currentPath.split('/')..removeWhere((p) => p.isEmpty);

    if (parts.isEmpty) {
      setState(() {
        _currentPath = '/';
      });
    } else {
      parts.removeLast();

      setState(() {
        _currentPath = parts.isEmpty ? '/' : '/${parts.join('/')}';
      });
    }

    _load();
  }

  /// Lompat langsung ke path tertentu.
  void navigateTo(String path) {
    var p = path.trim();

    if (p.isEmpty) p = '/';

    if (p.length > 1 && p.endsWith('/')) {
      p = p.substring(0, p.length - 1);
    }

    setState(() {
      _currentPath = p;
    });

    _load();
  }

  /// Kembali langsung ke root directory.
  void _goHome() {
    if (isAtRoot) return;

    setState(() {
      _currentPath = '/';
    });

    _load();
  }

  Future<void> _showCreateFolderDialog() async {
    final l10n = AppLocalizations.of(context);
    final name = await showSafeInputDialog(
      context: context,
      title: l10n.newFolder,
      actionLabel: l10n.create,
      cancelLabel: l10n.cancel,
      hint: 'folder_name',
      icon: Icons.create_new_folder_outlined,
    );

    if (name == null || name.isEmpty) return;
    if (!mounted) return;

    try {
      await SftpService.instance.createDirectory(
        widget.serverId,
        _join(_currentPath, name),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      _showError(AppLocalizations.of(context).failedCreateFolder('$e'));
    }
  }

  bool _isTextFile(String name) {
    final lower = name.toLowerCase();
    const exts = [
      '.txt',
      '.md',
      '.json',
      '.yaml',
      '.yml',
      '.xml',
      '.html',
      '.htm',
      '.css',
      '.js',
      '.ts',
      '.dart',
      '.py',
      '.sh',
      '.bash',
      '.zsh',
      '.conf',
      '.cfg',
      '.ini',
      '.env',
      '.log',
      '.csv',
      '.sql',
      '.toml',
      '.properties',
      '.gitignore',
      '.dockerfile',
      '.compose',
    ];
    if (exts.any((e) => lower.endsWith(e))) return true;
    // no extension or common config names
    if (!lower.contains('.')) return true;
    final base = lower.split('/').last;
    return base == 'dockerfile' ||
        base == 'makefile' ||
        base == 'readme' ||
        base.startsWith('.env');
  }

  Future<void> _showCreateFileDialog() async {
    final l10n = AppLocalizations.of(context);
    final name = await showSafeInputDialog(
      context: context,
      title: l10n.newFile,
      actionLabel: l10n.create,
      cancelLabel: l10n.cancel,
      hint: 'filename.txt',
      icon: Icons.note_add_outlined,
    );

    if (name == null || name.isEmpty) return;
    if (!mounted) return;

    final remotePath = _join(_currentPath, name);
    await _openTextEditor(remotePath: remotePath, isNew: true);
  }

  Future<void> _openTextEditor({
    required String remotePath,
    bool isNew = false,
  }) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => _TextEditorScreen(
          serverId: widget.serverId,
          remotePath: remotePath,
          isNew: isNew,
        ),
      ),
    );
    if (result == true && mounted) {
      await _load();
    }
  }

  Future<void> _showRenameDialog(SftpFileEntry entry) async {
    final ctrl = TextEditingController(text: entry.name);

    final newName = await showDialog<String>(
      context: context,
      builder: (context) => _InputDialog(
        title: AppLocalizations.of(context).rename,
        icon: Icons.drive_file_rename_outline_rounded,
        hint: 'New name',
        controller: ctrl,
        actionLabel: AppLocalizations.of(context).rename,
      ),
    );

    disposeControllerLater(ctrl);

    if (newName == null || newName.isEmpty || newName == entry.name) {
      return;
    }

    try {
      await SftpService.instance.rename(
        widget.serverId,
        _join(_currentPath, entry.name),
        _join(_currentPath, newName),
      );

      await _load();
    } catch (e) {
      if (!mounted) return;
      _showError(AppLocalizations.of(context).failedRename('$e'));
    }
  }

  Future<void> _confirmDelete(SftpFileEntry entry) async {
    final type = entry.isDirectory
        ? AppLocalizations.of(context).folder
        : AppLocalizations.of(context).fileLabel;

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
                color: AppColors.danger.withValues(alpha: .10),
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
                '${AppLocalizations.of(context).delete} $type?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Text(
            entry.isDirectory
                ? AppLocalizations.of(context).deleteFolderBody(entry.name)
                : AppLocalizations.of(context).deleteFileBody(entry.name),
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

    final path = _join(_currentPath, entry.name);

    setState(() {
      _busy = true;
    });

    try {
      if (entry.isDirectory) {
        await SftpService.instance.deleteDirectoryRecursive(
          widget.serverId,
          path,
        );
      } else {
        await SftpService.instance.deleteFile(widget.serverId, path);
      }

      await _load();
    } catch (e) {
      if (!mounted) return;
      _showError(AppLocalizations.of(context).failedDelete('$e'));
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _uploadFile() async {
    final result = await FilePicker.platform.pickFiles();

    if (result == null || result.files.single.path == null) {
      return;
    }

    final localPath = result.files.single.path!;
    final fileName = result.files.single.name;
    final remotePath = _join(_currentPath, fileName);

    setState(() {
      _busy = true;
    });

    try {
      await SftpService.instance.uploadFile(
        widget.serverId,
        localPath,
        remotePath,
      );

      await _load();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(AppLocalizations.of(context).uploadSuccess(fileName)),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      _showError(AppLocalizations.of(context).failedUpload('$e'));
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _downloadFile(SftpFileEntry entry) async {
    setState(() {
      _busy = true;
    });

    try {
      final dir = await getApplicationDocumentsDirectory();

      final localPath = '${dir.path}/${entry.name}';

      await SftpService.instance.downloadFile(
        widget.serverId,
        _join(_currentPath, entry.name),
        localPath,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(AppLocalizations.of(context).savedTo(localPath)),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      _showError(AppLocalizations.of(context).failedDownload('$e'));
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  void _showError(String msg) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(behavior: SnackBarBehavior.floating, content: Text(msg)),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }

    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }

    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
    }

    return '${(bytes / 1024 / 1024 / 1024).toStringAsFixed(1)} GB';
  }

  void _showEntryMenu(SftpFileEntry entry) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 12),
          child: Wrap(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
                child: Row(
                  children: [
                    Icon(
                      entry.isDirectory
                          ? Icons.folder_rounded
                          : Icons.insert_drive_file_outlined,
                      color: entry.isDirectory
                          ? AppColors.accent
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        entry.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),

              if (!entry.isDirectory) ...[
                if (_isTextFile(entry.name))
                  _BottomSheetAction(
                    icon: Icons.edit_note_rounded,
                    title: AppLocalizations.of(context).edit,
                    onTap: () {
                      Navigator.pop(context);
                      _openTextEditor(
                        remotePath: _join(_currentPath, entry.name),
                      );
                    },
                  ),
                _BottomSheetAction(
                  icon: Icons.download_rounded,
                  title: AppLocalizations.of(context).download,
                  onTap: () {
                    Navigator.pop(context);
                    _downloadFile(entry);
                  },
                ),
              ],

              _BottomSheetAction(
                icon: Icons.drive_file_rename_outline_rounded,
                title: AppLocalizations.of(context).rename,
                onTap: () {
                  Navigator.pop(context);
                  _showRenameDialog(entry);
                },
              ),

              _BottomSheetAction(
                icon: Icons.delete_outline_rounded,
                title: AppLocalizations.of(context).delete,
                destructive: true,
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(entry);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Menu untuk aksi global File Manager.
  void _showHeaderMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 12),
          child: Wrap(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 6, 16, 14),
                child: Text(
                  'File Actions',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),

              _BottomSheetAction(
                icon: Icons.upload_file_rounded,
                title: AppLocalizations.of(context).uploadFile,
                onTap: () {
                  Navigator.pop(context);
                  if (!_busy) {
                    _uploadFile();
                  }
                },
              ),

              _BottomSheetAction(
                icon: Icons.note_add_outlined,
                title: AppLocalizations.of(context).newFile,
                onTap: () {
                  Navigator.pop(context);
                  if (!_busy) {
                    _showCreateFileDialog();
                  }
                },
              ),

              _BottomSheetAction(
                icon: Icons.create_new_folder_outlined,
                title: AppLocalizations.of(context).newFolder,
                onTap: () {
                  Navigator.pop(context);
                  if (!_busy) {
                    _showCreateFolderDialog();
                  }
                },
              ),

              _BottomSheetAction(
                icon: Icons.refresh_rounded,
                title: AppLocalizations.of(context).refresh,
                onTap: () {
                  Navigator.pop(context);
                  if (!_loading) {
                    _load();
                  }
                },
              ),
            ],
          ),
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
    return Column(
      children: [
        _buildHeader(),
        _buildPathBar(),

        if (_busy) const LinearProgressIndicator(minHeight: 2),

        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Files',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 3),
                Text(
                  AppLocalizations.of(context).filesSubtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // HOME
          _HeaderButton(
            icon: Icons.home_rounded,
            tooltip: AppLocalizations.of(context).rootDirectory,
            onPressed: isAtRoot ? null : _goHome,
          ),

          const SizedBox(width: 7),

          // GRID / LIST
          _HeaderButton(
            icon: _isGridView
                ? Icons.view_list_rounded
                : Icons.grid_view_rounded,
            tooltip: _isGridView
                ? AppLocalizations.of(context).listView
                : AppLocalizations.of(context).gridView,
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
          ),

          const SizedBox(width: 7),

          // MORE
          _HeaderButton(
            icon: Icons.more_vert_rounded,
            tooltip: AppLocalizations.of(context).moreActions,
            onPressed: _showHeaderMenu,
          ),
        ],
      ),
    );
  }

  Widget _buildPathBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: AppColors.surfaceDarkAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            if (!isAtRoot)
              IconButton(
                tooltip: AppLocalizations.of(context).parentDirectory,
                onPressed: goUp,
                icon: Icon(Icons.arrow_upward_rounded, size: 18),
              )
            else
              const SizedBox(width: 8),

            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.folder_open_rounded,
                size: 16,
                color: AppColors.accent,
              ),
            ),

            const SizedBox(width: 8),

            Expanded(
              child: Text(
                _currentPath,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontFamily: 'monospace',
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && _entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(strokeWidth: 2.5),
            SizedBox(height: 14),
            Text(
              AppLocalizations.of(context).loadingFiles,
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
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded, size: 17),
                label: Text(AppLocalizations.of(context).tryAgain),
              ),
            ],
          ),
        ),
      );
    }

    if (_entries.isEmpty) {
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
                Icons.folder_open_outlined,
                size: 34,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 15),
            Text(
              AppLocalizations.of(context).folderEmpty,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 5),
            Text(
              AppLocalizations.of(context).uploadOrCreateHint,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.accent,
      child: _isGridView ? _buildGrid() : _buildList(),
    );
  }

  Widget _buildList() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      itemCount: _entries.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final entry = _entries[index];

        return _FileListTile(
          entry: entry,
          size: entry.isDirectory ? null : _formatSize(entry.size),
          onTap: entry.isDirectory
              ? () => _enterFolder(entry.name)
              : () {
                  if (_isTextFile(entry.name)) {
                    _openTextEditor(
                      remotePath: _join(_currentPath, entry.name),
                    );
                  } else {
                    _downloadFile(entry);
                  }
                },
          onMenu: () => _showEntryMenu(entry),
        );
      },
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 150,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: .86,
      ),
      itemCount: _entries.length,
      itemBuilder: (context, index) {
        final entry = _entries[index];

        return _FileGridTile(
          entry: entry,
          size: entry.isDirectory ? null : _formatSize(entry.size),
          onTap: entry.isDirectory
              ? () => _enterFolder(entry.name)
              : () {
                  if (_isTextFile(entry.name)) {
                    _openTextEditor(
                      remotePath: _join(_currentPath, entry.name),
                    );
                  } else {
                    _downloadFile(entry);
                  }
                },
          onMenu: () => _showEntryMenu(entry),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// File List Tile
// ─────────────────────────────────────────────

class _FileListTile extends StatelessWidget {
  final SftpFileEntry entry;
  final String? size;
  final VoidCallback onTap;
  final VoidCallback onMenu;

  const _FileListTile({
    required this.entry,
    required this.size,
    required this.onTap,
    required this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    final isFolder = entry.isDirectory;

    return Material(
      color: AppColors.surfaceDark,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isFolder
                      ? AppColors.accent.withValues(alpha: .10)
                      : AppColors.surfaceDarkAlt,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  isFolder
                      ? Icons.folder_rounded
                      : Icons.insert_drive_file_outlined,
                  size: 21,
                  color: isFolder ? AppColors.accent : AppColors.textSecondary,
                ),
              ),

              SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    if (size != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        size!,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ] else ...[
                      SizedBox(height: 4),
                      Text(
                        'Directory',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              IconButton(
                tooltip: AppLocalizations.of(context).more,
                onPressed: onMenu,
                icon: Icon(
                  Icons.more_vert_rounded,
                  size: 19,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// File Grid Tile
// ─────────────────────────────────────────────

class _FileGridTile extends StatelessWidget {
  final SftpFileEntry entry;
  final String? size;
  final VoidCallback onTap;
  final VoidCallback onMenu;

  const _FileGridTile({
    required this.entry,
    required this.size,
    required this.onTap,
    required this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    final isFolder = entry.isDirectory;

    return Material(
      color: AppColors.surfaceDark,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        onLongPress: onMenu,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Stack(
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 8, 4, 2),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: isFolder
                              ? AppColors.accent.withValues(alpha: .10)
                              : AppColors.surfaceDarkAlt,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          isFolder
                              ? Icons.folder_rounded
                              : Icons.insert_drive_file_outlined,
                          size: 27,
                          color: isFolder
                              ? AppColors.accent
                              : AppColors.textSecondary,
                        ),
                      ),

                      SizedBox(height: 10),

                      Text(
                        entry.name,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      if (size != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          size!,
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              Positioned(
                top: 0,
                right: 0,
                child: IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: AppLocalizations.of(context).more,
                  onPressed: onMenu,
                  icon: Icon(
                    Icons.more_horiz_rounded,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
  }) : accent = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 19),
        style: IconButton.styleFrom(
          backgroundColor: accent ? AppColors.accent : AppColors.surfaceDarkAlt,
          foregroundColor: accent ? Colors.white : AppColors.textPrimary,
          disabledBackgroundColor: AppColors.surfaceDarkAlt.withValues(
            alpha: .5,
          ),
          disabledForegroundColor: AppColors.textSecondary.withValues(
            alpha: .45,
          ),
          // disabledForegroundColor: AppColors.textSecondary.withValues(alpha: .45),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Input Dialog
// ─────────────────────────────────────────────

class _InputDialog extends StatelessWidget {
  final String title;
  final IconData icon;
  final String hint;
  final String actionLabel;
  final TextEditingController controller;

  const _InputDialog({
    required this.title,
    required this.icon,
    required this.hint,
    required this.controller,
    required this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
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
              color: AppColors.accent.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.accent),
          ),

          SizedBox(width: 12),

          Expanded(
            child: Text(
              title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      content: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: AppColors.surfaceDarkAlt,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.accent, width: 1.5),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context).cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text.trim()),
          child: Text(actionLabel),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Bottom Sheet Action
// ─────────────────────────────────────────────

class _BottomSheetAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool destructive;

  const _BottomSheetAction({
    required this.icon,
    required this.title,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppColors.danger : AppColors.textPrimary;

    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: Icon(icon, color: color, size: 21),
      title: Text(
        title,
        style: TextStyle(
          color: color,
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }
}

// ─────────────────────────────────────────────
// Simple Text Editor
// ─────────────────────────────────────────────

class _TextEditorScreen extends StatefulWidget {
  final String serverId;
  final String remotePath;
  final bool isNew;

  const _TextEditorScreen({
    required this.serverId,
    required this.remotePath,
    this.isNew = false,
  });

  @override
  State<_TextEditorScreen> createState() => _TextEditorScreenState();
}

class _TextEditorScreenState extends State<_TextEditorScreen> {
  final _controller = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.isNew) {
      _loading = false;
    } else {
      _load();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final content = await SftpService.instance.readTextFile(
        widget.serverId,
        widget.remotePath,
      );
      if (!mounted) return;
      _controller.text = content;
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = AppLocalizations.of(context).failedReadFile('$e');
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await SftpService.instance.writeTextFile(
        widget.serverId,
        widget.remotePath,
        _controller.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(AppLocalizations.of(context).saved),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(AppLocalizations.of(context).failedSave('$e')),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fileName = widget.remotePath.split('/').last;
    return Scaffold(
      backgroundColor: AppColors.surfaceDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        title: Text(
          fileName,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              tooltip: AppLocalizations.of(context).save,
              icon: const Icon(Icons.save_rounded),
              onPressed: _loading || _error != null ? null : _save,
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2.5))
            : _error != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 40,
                        color: AppColors.danger,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: TextStyle(color: AppColors.danger),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: _load,
                        icon: const Icon(Icons.refresh_rounded, size: 17),
                        label: Text(AppLocalizations.of(context).tryAgain),
                      ),
                    ],
                  ),
                ),
              )
            : Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: TextField(
                  controller: _controller,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.surfaceDarkAlt,
                    hintText: widget.isNew
                        ? AppLocalizations.of(context).startTyping
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.accent,
                        width: 1.5,
                      ),
                    ),
                    contentPadding: const EdgeInsets.all(14),
                  ),
                ),
              ),
      ),
    );
  }
}
