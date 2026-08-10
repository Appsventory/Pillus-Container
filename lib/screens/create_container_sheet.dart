import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/docker_repository.dart';
import '../theme/app_theme.dart';

/// Hasil form create container.
class CreateContainerRequest {
  final String image;
  final String? name;
  final String? network;
  final String restartPolicy;
  final List<String> ports;
  final List<String> env;
  final List<String> volumes;
  final String? command;
  final bool autoRemove;
  final bool privileged;

  const CreateContainerRequest({
    required this.image,
    this.name,
    this.network,
    this.restartPolicy = 'no',
    this.ports = const [],
    this.env = const [],
    this.volumes = const [],
    this.command,
    this.autoRemove = false,
    this.privileged = false,
  });
}

Future<CreateContainerRequest?> showCreateContainerSheet({
  required BuildContext context,
  required String serverId,
}) {
  return showModalBottomSheet<CreateContainerRequest>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceDark,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (_) => _CreateContainerSheet(serverId: serverId),
  );
}

class _CreateContainerSheet extends StatefulWidget {
  final String serverId;
  const _CreateContainerSheet({required this.serverId});

  @override
  State<_CreateContainerSheet> createState() => _CreateContainerSheetState();
}

class _CreateContainerSheetState extends State<_CreateContainerSheet> {
  final _nameCtrl = TextEditingController();
  final _cmdCtrl = TextEditingController();
  final _portHost = TextEditingController();
  final _portContainer = TextEditingController();
  final _envKey = TextEditingController();
  final _envVal = TextEditingController();
  final _volHost = TextEditingController();
  final _volContainer = TextEditingController();

  List<String> _images = [];
  List<String> _networks = [];
  List<String> _volumeNames = [];

  String? _image;
  String? _network;
  String _restart = 'no';
  String _portProto = 'tcp';
  bool _volRo = false;
  bool _autoRemove = false;
  bool _privileged = false;
  bool _loadingMeta = true;
  String? _metaError;

  final List<String> _ports = [];
  final List<String> _env = [];
  final List<String> _volumes = [];

  static const _restarts = ['no', 'always', 'unless-stopped', 'on-failure'];

  @override
  void initState() {
    super.initState();
    _loadMeta();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _cmdCtrl.dispose();
    _portHost.dispose();
    _portContainer.dispose();
    _envKey.dispose();
    _envVal.dispose();
    _volHost.dispose();
    _volContainer.dispose();
    super.dispose();
  }

  Future<void> _loadMeta() async {
    setState(() {
      _loadingMeta = true;
      _metaError = null;
    });
    try {
      final repo = DockerRepository.instance;
      final imgs = await repo.listImages(widget.serverId);
      final nets = await repo.listNetworks(widget.serverId);
      final vols = await repo.listVolumes(widget.serverId);

      final imageNames = <String>[];
      for (final m in imgs) {
        final repoTag = (m['Repository'] ?? m['repository'] ?? '').toString();
        final tag = (m['Tag'] ?? m['tag'] ?? 'latest').toString();
        if (repoTag.isEmpty || repoTag == '<none>') continue;
        final full = tag.isEmpty || tag == '<none>' ? repoTag : '$repoTag:$tag';
        if (!imageNames.contains(full)) imageNames.add(full);
      }
      imageNames.sort();

      final netNames =
          nets
              .map((m) => (m['Name'] ?? m['name'] ?? '').toString())
              .where((n) => n.isNotEmpty)
              .toList()
            ..sort();

      final volNames =
          vols
              .map((m) => (m['Name'] ?? m['name'] ?? '').toString())
              .where((n) => n.isNotEmpty)
              .toList()
            ..sort();

      if (!mounted) return;
      setState(() {
        _images = imageNames;
        _networks = netNames;
        _volumeNames = volNames;
        _image = imageNames.isNotEmpty ? imageNames.first : null;
        _network = netNames.contains('bridge')
            ? 'bridge'
            : (netNames.isNotEmpty ? netNames.first : null);
        _loadingMeta = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _metaError = '$e';
        _loadingMeta = false;
      });
    }
  }

  void _addPort() {
    final h = _portHost.text.trim();
    final c = _portContainer.text.trim();
    if (h.isEmpty || c.isEmpty) return;
    final entry = '$h:$c/$_portProto';
    if (!_ports.contains(entry)) {
      setState(() {
        _ports.add(entry);
        _portHost.clear();
        _portContainer.clear();
      });
    }
  }

  void _addEnv() {
    final k = _envKey.text.trim();
    final v = _envVal.text.trim();
    if (k.isEmpty) return;
    final entry = '$k=$v';
    setState(() {
      _env.removeWhere((e) => e.split('=').first == k);
      _env.add(entry);
      _envKey.clear();
      _envVal.clear();
    });
  }

  void _addVolume() {
    final h = _volHost.text.trim();
    final c = _volContainer.text.trim();
    if (h.isEmpty || c.isEmpty) return;
    final entry = _volRo ? '$h:$c:ro' : '$h:$c';
    if (!_volumes.contains(entry)) {
      setState(() {
        _volumes.add(entry);
        _volHost.clear();
        _volContainer.clear();
        _volRo = false;
      });
    }
  }

  void _submit() {
    final image = _image?.trim() ?? '';
    if (image.isEmpty) return;
    final name = _nameCtrl.text.trim();
    Navigator.pop(
      context,
      CreateContainerRequest(
        image: image,
        name: name.isEmpty ? null : name,
        network: _network,
        restartPolicy: _restart,
        ports: List.of(_ports),
        env: List.of(_env),
        volumes: List.of(_volumes),
        command: _cmdCtrl.text.trim().isEmpty ? null : _cmdCtrl.text.trim(),
        autoRemove: _autoRemove,
        privileged: _privileged,
      ),
    );
  }

  InputDecoration _dec(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: AppColors.surfaceDarkAlt,
      isDense: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
      ),
    );
  }

  Widget _chipList(List<String> items, void Function(String) onRemove) {
    if (items.isEmpty) {
      return Text(
        '—',
        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
      );
    }
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: items
          .map(
            (e) => InputChip(
              label: Text(e, style: const TextStyle(fontSize: 12)),
              onDeleted: () => onRemove(e),
              backgroundColor: AppColors.surfaceDarkAlt,
              side: BorderSide(color: AppColors.border),
            ),
          )
          .toList(),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.92,
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
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.createContainer,
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
            if (_loadingMeta)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              )
            else if (_metaError != null)
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _metaError!,
                      style: TextStyle(color: AppColors.danger),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  children: [
                    _sectionTitle(l10n.imageName),
                    DropdownButtonFormField<String>(
                      initialValue: _image,
                      isExpanded: true,
                      decoration: _dec(l10n.imageName),
                      items: _images
                          .map(
                            (i) => DropdownMenuItem(
                              value: i,
                              child: Text(i, overflow: TextOverflow.ellipsis),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _image = v),
                    ),
                    if (_images.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          l10n.noImagesFound,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.danger,
                          ),
                        ),
                      ),

                    _sectionTitle(l10n.containerName),
                    TextField(
                      controller: _nameCtrl,
                      decoration: _dec(
                        l10n.containerName,
                        hint: l10n.optionalAuto,
                      ),
                    ),

                    _sectionTitle(l10n.network),
                    DropdownButtonFormField<String>(
                      initialValue: _network,
                      isExpanded: true,
                      decoration: _dec(l10n.network),
                      items: _networks
                          .map(
                            (n) => DropdownMenuItem(value: n, child: Text(n)),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _network = v),
                    ),

                    _sectionTitle(l10n.restartPolicy),
                    DropdownButtonFormField<String>(
                      initialValue: _restart,
                      isExpanded: true,
                      decoration: _dec(l10n.restartPolicy),
                      items: _restarts
                          .map(
                            (r) => DropdownMenuItem(value: r, child: Text(r)),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _restart = v ?? 'no'),
                    ),

                    _sectionTitle(l10n.portMapping),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _portHost,
                            keyboardType: TextInputType.number,
                            decoration: _dec(l10n.hostPort, hint: '8080'),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Text(':'),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _portContainer,
                            keyboardType: TextInputType.number,
                            decoration: _dec(l10n.containerPort, hint: '80'),
                          ),
                        ),
                        const SizedBox(width: 6),
                        SizedBox(
                          width: 88,
                          child: DropdownButtonFormField<String>(
                            initialValue: _portProto,
                            decoration: _dec(l10n.protocol),
                            items: const [
                              DropdownMenuItem(
                                value: 'tcp',
                                child: Text('tcp'),
                              ),
                              DropdownMenuItem(
                                value: 'udp',
                                child: Text('udp'),
                              ),
                            ],
                            onChanged: (v) =>
                                setState(() => _portProto = v ?? 'tcp'),
                          ),
                        ),
                        IconButton(
                          onPressed: _addPort,
                          icon: Icon(Icons.add_circle, color: AppColors.accent),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    _chipList(_ports, (e) => setState(() => _ports.remove(e))),

                    _sectionTitle(l10n.envVars),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _envKey,
                            decoration: _dec('KEY', hint: 'NODE_ENV'),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Text('='),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _envVal,
                            decoration: _dec('VALUE', hint: 'production'),
                          ),
                        ),
                        IconButton(
                          onPressed: _addEnv,
                          icon: Icon(Icons.add_circle, color: AppColors.accent),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    _chipList(_env, (e) => setState(() => _env.remove(e))),

                    _sectionTitle(l10n.volumeMounts),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _volHost,
                            decoration: _dec(
                              l10n.hostPath,
                              hint: _volumeNames.isNotEmpty
                                  ? _volumeNames.first
                                  : '/data',
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Text(':'),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _volContainer,
                            decoration: _dec(
                              l10n.containerPath,
                              hint: '/app/data',
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _addVolume,
                          icon: Icon(Icons.add_circle, color: AppColors.accent),
                        ),
                      ],
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: Text(
                        l10n.readOnly,
                        style: TextStyle(fontSize: 13),
                      ),
                      value: _volRo,
                      onChanged: (v) => setState(() => _volRo = v ?? false),
                    ),
                    if (_volumeNames.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Wrap(
                          spacing: 6,
                          children: _volumeNames.take(8).map((v) {
                            return ActionChip(
                              label: Text(
                                v,
                                style: const TextStyle(fontSize: 11),
                              ),
                              onPressed: () {
                                _volHost.text = v;
                                setState(() {});
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    _chipList(
                      _volumes,
                      (e) => setState(() => _volumes.remove(e)),
                    ),

                    _sectionTitle(l10n.command),
                    TextField(
                      controller: _cmdCtrl,
                      decoration: _dec(l10n.command, hint: l10n.optionalAuto),
                    ),

                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        l10n.autoRemove,
                        style: TextStyle(fontSize: 13),
                      ),
                      subtitle: Text(
                        l10n.autoRemoveHint,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      value: _autoRemove,
                      activeThumbColor: AppColors.accent,
                      onChanged: (v) => setState(() => _autoRemove = v),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        l10n.privileged,
                        style: TextStyle(fontSize: 13),
                      ),
                      value: _privileged,
                      activeThumbColor: AppColors.accent,
                      onChanged: (v) => setState(() => _privileged = v),
                    ),

                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _image == null ? null : _submit,
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: Text(l10n.createContainer),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
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
