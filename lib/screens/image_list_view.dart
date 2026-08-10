import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../providers/settings_provider.dart';
import '../models/image_model.dart';
import '../services/docker_repository.dart';
import '../theme/app_theme.dart';

class ImageListView extends ConsumerStatefulWidget {
  final String serverId;

  const ImageListView({super.key, required this.serverId});

  @override
  ConsumerState<ImageListView> createState() => _ImageListViewState();
}

class _ImageListViewState extends ConsumerState<ImageListView> {
  List<ImageModel> _images = [];
  bool _loading = true;
  bool _pulling = false;
  bool _building = false;
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
      final raw = await DockerRepository.instance.listImages(
        widget.serverId,
        forceRefresh: force,
      );

      if (!mounted) return;

      setState(() {
        _images = raw.map((m) => ImageModel.fromDockerJson(m)).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = AppLocalizations.of(context).failedLoadImages('$e');
        _loading = false;
      });
    }
  }

  Future<void> _doPull(String imageName) async {
    if (!mounted) return;
    setState(() => _pulling = true);
    try {
      await DockerRepository.instance.pullImage(widget.serverId, imageName);
      await _refresh(force: true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).failedPull('$e')),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _pulling = false);
    }
  }

  Future<void> _showSearchPullSheet() async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return _SearchPullSheet(
          serverId: widget.serverId,
          onPull: (name) async {
            Navigator.pop(ctx);
            await _doPull(name);
          },
        );
      },
    );
  }

  Future<void> _showBuildDialog() async {
    if (!mounted) return;
    final result = await showDialog<_BuildImageResult>(
      context: context,
      builder: (ctx) => const _BuildImageDialog(),
    );
    if (result == null || !mounted) return;

    setState(() => _building = true);
    try {
      await DockerRepository.instance.buildImage(
        widget.serverId,
        name: result.name,
        tag: result.tag,
        dockerfileContent: result.useDockerfile ? result.dockerfile : null,
        contextPath: result.contextPath,
      );
      await _refresh(force: true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).failedBuild('$e')),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _building = false);
    }
  }

  Future<void> _confirmRemove(ImageModel img) async {
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
            SizedBox(width: 12),
            Expanded(
              child: Text(
                AppLocalizations.of(context).delete,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: Text(
          AppLocalizations.of(context).deleteImageBody(img.displayName),
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

    setState(() => _busyIds.add(img.id));

    try {
      await DockerRepository.instance.removeImage(widget.serverId, img.id);

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
        setState(() => _busyIds.remove(img.id));
      }
    }
  }

  Future<void> _showInspect(ImageModel img) async {
    try {
      final data = await DockerRepository.instance.inspectImage(
        widget.serverId,
        img.id,
      );

      if (!mounted) return;

      final config = (data['Config'] as Map?) ?? {};
      final envList = (config['Env'] as List?) ?? [];

      showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.surfaceDark,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) => DraggableScrollableSheet(
          initialChildSize: 0.66,
          maxChildSize: 0.94,
          minChildSize: 0.45,
          expand: false,
          builder: (context, scrollCtrl) {
            return Column(
              children: [
                SizedBox(height: 12),
                Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                SizedBox(height: 20),
                Expanded(
                  child: ListView(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                    children: [
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
                              Icons.layers_rounded,
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
                                  img.displayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  img.id,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: AppColors.textSecondary,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 20),

                      Row(
                        children: [
                          Expanded(
                            child: _MetricCard(
                              icon: Icons.storage_rounded,
                              label: AppLocalizations.of(context).size,
                              value: img.size,
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: _MetricCard(
                              icon: Icons.schedule_rounded,
                              label: AppLocalizations.of(context).created,
                              value: img.createdSince,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 26),

                      _SectionTitle(
                        icon: Icons.info_outline_rounded,
                        title: AppLocalizations.of(context).imageDetails,
                      ),
                      SizedBox(height: 10),

                      _InfoTile(
                        label: AppLocalizations.of(context).architecture,
                        value: data['Architecture']?.toString() ?? '-',
                      ),

                      _InfoTile(
                        label: AppLocalizations.of(context).osLabel,
                        value: data['Os']?.toString() ?? '-',
                      ),

                      _InfoTile(
                        label: AppLocalizations.of(context).entrypoint,
                        value:
                            (config['Entrypoint'] as List?)?.join(' ') ?? '-',
                      ),

                      _InfoTile(
                        label: AppLocalizations.of(context).command,
                        value: (config['Cmd'] as List?)?.join(' ') ?? '-',
                      ),

                      if (envList.isNotEmpty) ...[
                        SizedBox(height: 18),

                        _SectionTitle(
                          icon: Icons.tune_rounded,
                          title: AppLocalizations.of(context).envVars,
                        ),

                        const SizedBox(height: 10),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceDarkAlt,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: envList.map((e) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: SelectableText(
                                  e.toString(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontFamily: 'monospace',
                                    height: 1.4,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).failedInspect('$e')),
          ),
        );
      }
    }
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
                          AppLocalizations.of(context).imagesTitle,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          AppLocalizations.of(context).imagesSubtitle,
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
                ],
              ),
            ),

            if (_pulling || _building)
              const LinearProgressIndicator(
                minHeight: 2.5,
                backgroundColor: Colors.transparent,
              ),

            Expanded(child: _buildBody()),
          ],
        ),
        Positioned(right: 16, bottom: 16, child: _buildFab(context)),
      ],
    );
  }

  /// FAB menu: Search & Pull / Build Image
  Widget _buildFab(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final busy = _pulling || _building;
    return FloatingActionButton.extended(
      onPressed: busy ? null : () => _showFabMenu(context),
      backgroundColor: AppColors.accent,
      foregroundColor: Colors.white,
      elevation: 3,
      icon: Icon(
        busy ? Icons.hourglass_top_rounded : Icons.add_rounded,
        size: 20,
      ),
      label: Text(
        busy ? (_building ? l10n.buildingImage : l10n.pullingImage) : 'Image',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }

  Future<void> _showFabMenu(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                ListTile(
                  leading: Icon(
                    Icons.travel_explore_rounded,
                    color: AppColors.accent,
                  ),
                  title: Text(l10n.searchPullImage),
                  subtitle: Text(
                    l10n.searchImageHint,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onTap: () => Navigator.pop(ctx, 'search'),
                ),
                ListTile(
                  leading: Icon(
                    Icons.build_circle_outlined,
                    color: AppColors.accent,
                  ),
                  title: Text(l10n.buildImage),
                  subtitle: Text(
                    l10n.useDockerfile,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onTap: () => Navigator.pop(ctx, 'build'),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (!mounted) return;
    if (choice == 'search') {
      await _showSearchPullSheet();
    } else if (choice == 'build') {
      await _showBuildDialog();
    }
  }

  Widget _buildBody() {
    if (_loading && _images.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(strokeWidth: 2.5),
            SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).loadingImages,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
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
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: .10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  size: 28,
                  color: AppColors.danger,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.danger,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: () => _refresh(force: true),
                icon: Icon(Icons.refresh_rounded, size: 17),
                label: Text(AppLocalizations.of(context).tryAgain),
              ),
            ],
          ),
        ),
      );
    }

    if (_images.isEmpty) {
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
                Icons.layers_outlined,
                size: 32,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).noImagesFound,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 5),
            Text(
              AppLocalizations.of(context).pullImageHint,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            SizedBox(height: 18),
            FilledButton.icon(
              onPressed: (_pulling || _building)
                  ? null
                  : () => _showFabMenu(context),
              icon: Icon(Icons.download_rounded, size: 18),
              label: Text(AppLocalizations.of(context).searchPullImage),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _refresh(force: true),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        itemCount: _images.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final img = _images[i];
          final busy = _busyIds.contains(img.id);

          return _ImageCard(
            image: img,
            busy: busy,
            onTap: () => _showInspect(img),
            onDelete: () => _confirmRemove(img),
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

class _ImageCard extends StatelessWidget {
  final ImageModel image;
  final bool busy;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ImageCard({
    required this.image,
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
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  Icons.layers_rounded,
                  color: AppColors.accent,
                  size: 24,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      image.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Wrap(
                      spacing: 6,
                      runSpacing: 5,
                      children: [
                        _ImageBadge(
                          icon: Icons.storage_rounded,
                          label: image.size,
                        ),
                        _ImageBadge(
                          icon: Icons.schedule_rounded,
                          label: image.createdSince,
                        ),
                      ],
                    ),

                    const SizedBox(height: 7),

                    Text(
                      _shortId(image.id),
                      style: TextStyle(
                        fontSize: 10.5,
                        color: AppColors.textSecondary,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              if (busy)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
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

  String _shortId(String id) {
    if (id.length <= 16) return id;
    return '${id.substring(0, 16)}…';
  }
}

class _ImageBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ImageBadge({required this.icon, required this.label});

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

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.surfaceDarkAlt,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 17, color: AppColors.accent),
          ),
          SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.accent),
        const SizedBox(width: 7),
        Text(
          title,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;

  const _InfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDarkAlt,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 95,
            child: Text(
              label,
              style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SelectableText(
              value,
              style: TextStyle(fontSize: 12.5, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _BuildImageResult {
  final String name;
  final String tag;
  final bool useDockerfile;
  final String dockerfile;
  final String contextPath;
  const _BuildImageResult({
    required this.name,
    required this.tag,
    required this.useDockerfile,
    required this.dockerfile,
    required this.contextPath,
  });
}

class _BuildImageDialog extends StatefulWidget {
  const _BuildImageDialog();

  @override
  State<_BuildImageDialog> createState() => _BuildImageDialogState();
}

class _BuildImageDialogState extends State<_BuildImageDialog> {
  final _nameCtrl = TextEditingController();
  final _tagCtrl = TextEditingController(text: 'latest');
  final _dockerCtrl = TextEditingController(
    text: 'FROM alpine:latest\n\nCMD ["echo", "hello"]\n',
  );
  final _pathCtrl = TextEditingController(text: '.');
  bool _useDockerfile = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _tagCtrl.dispose();
    _dockerCtrl.dispose();
    _pathCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      backgroundColor: AppColors.surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppColors.border),
      ),
      title: Text(
        l10n.buildImage,
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _nameCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: l10n.imageName,
                  hintText: 'my-app',
                  filled: true,
                  fillColor: AppColors.surfaceDarkAlt,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _tagCtrl,
                decoration: InputDecoration(
                  labelText: l10n.imageTag,
                  hintText: 'latest',
                  filled: true,
                  fillColor: AppColors.surfaceDarkAlt,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.useDockerfile),
                value: _useDockerfile,
                activeThumbColor: AppColors.accent,
                onChanged: (v) => setState(() => _useDockerfile = v),
              ),
              if (_useDockerfile) ...[
                Text(
                  l10n.dockerfileContent,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _dockerCtrl,
                  maxLines: 8,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.surfaceDarkAlt,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ] else ...[
                TextField(
                  controller: _pathCtrl,
                  decoration: InputDecoration(
                    labelText: l10n.buildContextPath,
                    hintText: '/path/to/context',
                    filled: true,
                    fillColor: AppColors.surfaceDarkAlt,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () {
            final name = _nameCtrl.text.trim();
            if (name.isEmpty) return;
            final tag = _tagCtrl.text.trim().isEmpty
                ? 'latest'
                : _tagCtrl.text.trim();
            Navigator.pop(
              context,
              _BuildImageResult(
                name: name,
                tag: tag,
                useDockerfile: _useDockerfile,
                dockerfile: _dockerCtrl.text,
                contextPath: _pathCtrl.text.trim().isEmpty
                    ? '.'
                    : _pathCtrl.text.trim(),
              ),
            );
          },
          child: Text(l10n.buildImage),
        ),
      ],
    );
  }
}

class _SearchPullSheet extends StatefulWidget {
  final String serverId;
  final Future<void> Function(String imageName) onPull;

  const _SearchPullSheet({required this.serverId, required this.onPull});

  @override
  State<_SearchPullSheet> createState() => _SearchPullSheetState();
}

class _SearchPullSheetState extends State<_SearchPullSheet> {
  final _queryCtrl = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _searching = false;
  bool _searched = false;
  String? _error;
  String? _pullingName;

  @override
  void dispose() {
    _queryCtrl.dispose();
    super.dispose();
  }

  String get _query => _queryCtrl.text.trim();

  Future<void> _search() async {
    final q = _query;
    if (q.isEmpty) return;
    setState(() {
      _searching = true;
      _error = null;
      _searched = true;
    });
    try {
      final raw = await DockerRepository.instance.searchImages(
        widget.serverId,
        q,
      );
      if (!mounted) return;
      setState(() {
        _results = raw;
        _searching = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = AppLocalizations.of(context).failedSearch('$e');
        _searching = false;
        _results = [];
      });
    }
  }

  Future<void> _pullExact() async {
    final q = _query;
    if (q.isEmpty) return;
    setState(() => _pullingName = q);
    try {
      await widget.onPull(q);
    } finally {
      if (mounted) setState(() => _pullingName = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final q = _query;
    final pullingExact = _pullingName == q && q.isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.78,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.searchPullImage,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _queryCtrl,
                    autofocus: true,
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _search(),
                    decoration: InputDecoration(
                      hintText: 'nginx:latest / user/repo',
                      filled: true,
                      fillColor: AppColors.surfaceDarkAlt,
                      prefixIcon: const Icon(Icons.search_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _searching || q.isEmpty ? null : _search,
                          icon: _searching
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.search_rounded, size: 18),
                          label: Text(l10n.search),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: pullingExact || q.isEmpty
                              ? null
                              : _pullExact,
                          icon: pullingExact
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.download_rounded, size: 18),
                          label: Text(l10n.pullExact),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Text(_error!, style: TextStyle(color: AppColors.danger)),
              ),
            Expanded(child: _buildResults(l10n, q)),
          ],
        ),
      ),
    );
  }

  Widget _buildResults(AppLocalizations l10n, String q) {
    if (_searching) {
      return Center(
        child: Text(
          l10n.searchingImages,
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _searched ? l10n.noSearchResults : l10n.searchImageHint,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
              if (q.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  l10n.pullExactHint,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: _pullingName != null ? null : _pullExact,
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: Text('${l10n.pull} $q'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      itemCount: _results.length,
      separatorBuilder: (_, _) => const SizedBox(height: 6),
      itemBuilder: (context, i) {
        final m = _results[i];
        final name = (m['Name'] ?? m['name'] ?? '').toString();
        final desc = (m['Description'] ?? m['description'] ?? '').toString();
        final stars = (m['StarCount'] ?? m['star_count'] ?? 0).toString();
        final official = m['IsOfficial'] == true || m['is_official'] == true;
        final pulling = _pullingName == name;
        return ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppColors.border),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (official)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    l10n.official,
                    style: TextStyle(fontSize: 10, color: AppColors.accent),
                  ),
                ),
            ],
          ),
          subtitle: Text(
            desc.isEmpty
                ? '★ $stars ${l10n.stars}'
                : '$desc\n★ $stars ${l10n.stars}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          trailing: FilledButton(
            onPressed: pulling || name.isEmpty
                ? null
                : () async {
                    setState(() => _pullingName = name);
                    try {
                      await widget.onPull(name);
                    } finally {
                      if (mounted) setState(() => _pullingName = null);
                    }
                  },
            child: pulling
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(l10n.pull),
          ),
        );
      },
    );
  }
}
