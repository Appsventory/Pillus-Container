import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/server_model.dart';
import '../models/credential_model.dart';
import '../providers/server_provider.dart';
import '../services/secure_storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/fingerprint_dialog.dart';

class AddServerScreen extends ConsumerStatefulWidget {
  /// Isi ini kalau lagi mode edit server yang udah ada. Null = mode
  /// tambah server baru (perilaku default, gak berubah).
  final ServerModel? editingServer;

  const AddServerScreen({super.key, this.editingServer});

  @override
  ConsumerState<AddServerScreen> createState() => _AddServerScreenState();
}

class _AddServerScreenState extends ConsumerState<AddServerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _hostCtrl = TextEditingController();
  final _portCtrl = TextEditingController(text: '22');
  final _userCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _privateKeyCtrl = TextEditingController();
  final _passphraseCtrl = TextEditingController();

  SshAuthType _authType = SshAuthType.password;
  bool _connecting = false;
  bool _loadingCredential = false;
  String? _errorMessage;

  bool get _isEditMode => widget.editingServer != null;

  @override
  void initState() {
    super.initState();
    final editing = widget.editingServer;
    if (editing != null) {
      _nameCtrl.text = editing.name;
      _hostCtrl.text = editing.host;
      _portCtrl.text = editing.port.toString();
      _userCtrl.text = editing.username;
      _loadExistingCredential(editing.id);
    }
  }

  /// Pre-fill kredensial yang udah tersimpan biar user gak perlu ngetik
  /// ulang password/key cuma buat ganti nama server atau port doang.
  Future<void> _loadExistingCredential(String id) async {
    setState(() => _loadingCredential = true);
    final credential = await SecureStorageService.instance.getCredential(id);
    if (!mounted || credential == null) {
      if (mounted) setState(() => _loadingCredential = false);
      return;
    }
    setState(() {
      _authType = credential.authType;
      _passwordCtrl.text = credential.password ?? '';
      _privateKeyCtrl.text = credential.privateKeyPem ?? '';
      _passphraseCtrl.text = credential.passphrase ?? '';
      _loadingCredential = false;
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _hostCtrl.dispose();
    _portCtrl.dispose();
    _userCtrl.dispose();
    _passwordCtrl.dispose();
    _privateKeyCtrl.dispose();
    _passphraseCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final host = _hostCtrl.text.trim();

    // Dialog "IP udah kepake" cuma relevan buat nambah server baru -
    // di mode edit, tabrakan host udah ditangani sendiri sama
    // updateServerAndReconnect (nolak diam2 kalau host baru punya server LAIN).
    if (!_isEditMode) {
      final existing = ref
          .read(serverListProvider)
          .where((s) => s.host.trim().toLowerCase() == host.toLowerCase())
          .toList();

      if (existing.isNotEmpty && mounted) {
        final proceed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.surfaceDark,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: AppColors.border),
            ),
            title: Text(AppLocalizations.of(context).ipAlreadyRegistered),
            content: Text(
              AppLocalizations.of(
                context,
              ).hostAlreadyUsed(host, existing.first.name),
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13.5),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(AppLocalizations.of(context).cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(AppLocalizations.of(context).update),
              ),
            ],
          ),
        );
        if (proceed != true) return;
      }
    }

    setState(() {
      _connecting = true;
      _errorMessage = null;
    });

    final credential = CredentialModel(
      authType: _authType,
      password: _authType == SshAuthType.password ? _passwordCtrl.text : null,
      privateKeyPem: _authType == SshAuthType.privateKey
          ? _privateKeyCtrl.text
          : null,
      passphrase:
          _authType == SshAuthType.privateKey && _passphraseCtrl.text.isNotEmpty
          ? _passphraseCtrl.text
          : null,
    );

    Future<bool> onFingerprintPrompt({
      required String host,
      required String? keyType,
      required String? fingerprint,
      required bool changed,
    }) {
      return showFingerprintDialog(
        context,
        host: host,
        keyType: keyType,
        fingerprint: fingerprint,
        changed: changed,
      );
    }

    bool success;
    if (_isEditMode) {
      final updatedInfo = ServerModel(
        id: widget.editingServer!.id,
        name: _nameCtrl.text.trim(),
        host: _hostCtrl.text.trim(),
        port: int.tryParse(_portCtrl.text.trim()) ?? 22,
        username: _userCtrl.text.trim(),
      );
      success = await ref
          .read(serverListProvider.notifier)
          .updateServerAndReconnect(
            id: widget.editingServer!.id,
            updatedInfo: updatedInfo,
            credential: credential,
            onFingerprintPrompt: onFingerprintPrompt,
          );
    } else {
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final server = ServerModel(
        id: id,
        name: _nameCtrl.text.trim(),
        host: _hostCtrl.text.trim(),
        port: int.tryParse(_portCtrl.text.trim()) ?? 22,
        username: _userCtrl.text.trim(),
      );
      success = await ref
          .read(serverListProvider.notifier)
          .addAndConnect(
            server: server,
            credential: credential,
            onFingerprintPrompt: onFingerprintPrompt,
          );
    }

    if (!mounted) return;

    setState(() => _connecting = false);

    if (success) {
      if (mounted) Navigator.pop(context);
    } else {
      setState(() {
        _errorMessage = AppLocalizations.of(context).failedConnectCreds;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditMode
              ? AppLocalizations.of(context).editServerTitle
              : AppLocalizations.of(context).addServerTitle,
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _field(
                      _nameCtrl,
                      AppLocalizations.of(context).serverName,
                      hint: 'Production - Jakarta',
                    ),
                    const SizedBox(height: 14),
                    _field(
                      _hostCtrl,
                      AppLocalizations.of(context).hostIp,
                      hint: '10.10.1.4',
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: _field(
                            _userCtrl,
                            AppLocalizations.of(context).username,
                            hint: 'root',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _field(
                            _portCtrl,
                            AppLocalizations.of(context).port,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    SegmentedButton<SshAuthType>(
                      segments: [
                        ButtonSegment(
                          value: SshAuthType.password,
                          label: Text(AppLocalizations.of(context).password),
                          icon: Icon(Icons.password_rounded),
                        ),
                        ButtonSegment(
                          value: SshAuthType.privateKey,
                          label: Text(AppLocalizations.of(context).privateKey),
                          icon: Icon(Icons.key_rounded),
                        ),
                      ],
                      selected: {_authType},
                      onSelectionChanged: (s) =>
                          setState(() => _authType = s.first),
                    ),
                    const SizedBox(height: 14),
                    if (_authType == SshAuthType.password)
                      _field(_passwordCtrl, 'Password', obscure: true)
                    else ...[
                      _field(
                        _privateKeyCtrl,
                        AppLocalizations.of(context).privateKeyPem,
                        maxLines: 5,
                        hint: '-----BEGIN OPENSSH PRIVATE KEY-----',
                      ),
                      const SizedBox(height: 14),
                      _field(
                        _passphraseCtrl,
                        AppLocalizations.of(context).passphraseOptional,
                        obscure: true,
                        required: false,
                      ),
                    ],
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.danger.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: AppColors.danger,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 22),
                    FilledButton(
                      onPressed: (_connecting || _loadingCredential)
                          ? null
                          : _submit,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _connecting
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              _isEditMode
                                  ? AppLocalizations.of(context).saveChanges
                                  : AppLocalizations.of(context).connectAndSave,
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label, {
    String? hint,
    bool obscure = false,
    bool required = true,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: ctrl,
      obscureText: obscure,
      maxLines: obscure ? 1 : maxLines,
      keyboardType: keyboardType,
      style: maxLines > 1
          ? TextStyle(fontFamily: 'monospace', fontSize: 12.5)
          : null,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: AppColors.surfaceDarkAlt,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.border),
        ),
      ),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty)
                ? AppLocalizations.of(context).requiredField
                : null
          : null,
    );
  }
}
