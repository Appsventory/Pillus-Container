import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:dartssh2/dartssh2.dart';
import 'package:xterm2/xterm.dart';
import '../services/docker_repository.dart';
import '../theme/app_theme.dart';

class HostTerminalScreen extends StatefulWidget {
  final String serverId;
  final String serverName;

  const HostTerminalScreen({
    super.key,
    required this.serverId,
    required this.serverName,
  });

  @override
  State<HostTerminalScreen> createState() => _HostTerminalScreenState();
}

class _HostTerminalScreenState extends State<HostTerminalScreen> {
  late final Terminal _terminal;
  SSHSession? _session;
  bool _connecting = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _terminal = Terminal(maxLines: 3000);
    _terminal.onOutput = (data) {
      _session?.write(utf8.encode(data));
    };
    _terminal.onResize = (width, height, pixelWidth, pixelHeight) {
      _session?.resizeTerminal(width, height, pixelWidth, pixelHeight);
    };
    _connect();
  }

  Future<void> _connect() async {
    try {
      final session = await DockerRepository.instance.openHostShell(
        widget.serverId,
        cols: _terminal.viewWidth,
        rows: _terminal.viewHeight,
      );
      _session = session;

      session.stdout
          .cast<List<int>>()
          .transform(const Utf8Decoder(allowMalformed: true))
          .listen(_terminal.write);
      session.stderr
          .cast<List<int>>()
          .transform(const Utf8Decoder(allowMalformed: true))
          .listen(_terminal.write);

      unawaited(
        session.done.then((_) {
          if (mounted) _terminal.write(AppLocalizations.of(context).sessionEnded);
        }),
      );

      if (mounted) setState(() => _connecting = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = AppLocalizations.of(context).failedOpenHostTerminal('$e');
          _connecting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _session?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).terminalHostTitle(widget.serverName),
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: _connecting
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
            : TerminalView(_terminal, autofocus: true),
      ),
    );
  }
}
