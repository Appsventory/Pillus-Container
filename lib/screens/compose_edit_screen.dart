import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/sftp_service.dart';
import '../theme/app_theme.dart';

class ComposeEditScreen extends StatefulWidget {
  final String serverId;
  final String configFile;

  const ComposeEditScreen({
    super.key,
    required this.serverId,
    required this.configFile,
  });

  @override
  State<ComposeEditScreen> createState() => _ComposeEditScreenState();
}

class _ComposeEditScreenState extends State<ComposeEditScreen> {
  final _controller = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
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
        widget.configFile,
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
        widget.configFile,
        _controller.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).saved)));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).failedSave('$e'))));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.configFile.split('/').last,
          style: TextStyle(fontWeight: FontWeight.w600),
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
              icon: const Icon(Icons.save_rounded),
              onPressed: _loading ? null : _save,
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
            : Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  controller: _controller,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12.5,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.surfaceDarkAlt,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
              ),
      ),
    );
  }
}
