import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dartssh2/dartssh2.dart';
import '../models/credential_model.dart';

/// Hasil percobaan connect. Kalau fingerprint host baru / berubah,
/// [needsFingerprintConfirm] true dan UI wajib tampilkan dialog konfirmasi
/// sebelum lanjut (dipanggil ulang lewat [trustFingerprint]).
class SshConnectResult {
  final SSHClient? client;
  final bool needsFingerprintConfirm;
  final bool fingerprintChanged;
  final String? fingerprintHex;
  final String? hostKeyType;
  final String? error;

  SshConnectResult({
    this.client,
    this.needsFingerprintConfirm = false,
    this.fingerprintChanged = false,
    this.fingerprintHex,
    this.hostKeyType,
    this.error,
  });

  bool get success => client != null;
}

class ServerInfoResult {
  final String? osInfo;
  final String? dockerVersion;
  final int containerRunning;
  final int containerTotal;
  final int imageCount;
  final double cpuUsagePercent;
  final double ramUsagePercent;
  final double diskUsagePercent;

  ServerInfoResult({
    this.osInfo,
    this.dockerVersion,
    this.containerRunning = 0,
    this.containerTotal = 0,
    this.imageCount = 0,
    this.cpuUsagePercent = 0,
    this.ramUsagePercent = 0,
    this.diskUsagePercent = 0,
  });
}

class SshService {
  SshService._();
  static final instance = SshService._();

  /// dartssh2 2.22.x mengirim fingerprint sebagai teks siap-pakai
  /// (format "SHA256:base64hash..."), bukan raw MD5 bytes lagi.
  /// Jadi cukup decode sebagai UTF-8, jangan di-hex-encode ulang.
  String formatFingerprint(Uint8List fingerprintBytes) {
    return utf8.decode(fingerprintBytes);
  }

  /// Coba connect. [knownFingerprint] null = host belum pernah dipercaya (TOFU).
  /// Kalau fingerprint server beda dari yang tersimpan -> ditolak otomatis,
  /// balikin fingerprintChanged=true (indikasi kemungkinan MITM).
  Future<SshConnectResult> connect({
    required String host,
    required int port,
    required String username,
    required CredentialModel credential,
    String? knownFingerprint,
  }) async {
    String? seenFingerprint;
    String? seenType;
    bool rejectedByMismatch = false;
    bool isNewHost = false;

    try {
      final socket = await SSHSocket.connect(
        host,
        port,
        timeout: const Duration(seconds: 10),
      );

      final client = SSHClient(
        socket,
        username: username,
        onPasswordRequest: credential.authType == SshAuthType.password
            ? () => credential.password ?? ''
            : null,
        identities: credential.authType == SshAuthType.privateKey &&
                credential.privateKeyPem != null
            ? SSHKeyPair.fromPem(
                credential.privateKeyPem!,
                credential.passphrase,
              )
            : null,
        onVerifyHostKey: (type, fingerprint) {
          seenType = type;
          // fingerprint sini format "SHA256:xxxx" siap tampil, bukan md5 raw.
          seenFingerprint = formatFingerprint(fingerprint);

          if (knownFingerprint == null) {
            // Host baru, belum ada fingerprint tersimpan -> tahan dulu,
            // biar UI yang minta konfirmasi user (TOFU).
            isNewHost = true;
            return false;
          }
          if (knownFingerprint == seenFingerprint) {
            return true;
          }
          // Fingerprint beda dari yang tersimpan -> tolak, curigai MITM.
          rejectedByMismatch = true;
          return false;
        },
      );

      // Kalau onVerifyHostKey menolak, client.done ikut reject dan tidak
      // pernah di-listen siapa pun -> muncul sebagai unhandled exception
      // terpisah (ini yang bikin debugger selalu berhenti/pause).
      // Ditangkap di sini biar gak "bocor" ke luar.
      unawaited(client.done.catchError((_) {}));

      await client.authenticated;

      return SshConnectResult(
        client: client,
        fingerprintHex: seenFingerprint,
        hostKeyType: seenType,
      );
    } catch (e) {
      if (isNewHost) {
        return SshConnectResult(
          needsFingerprintConfirm: true,
          fingerprintHex: seenFingerprint,
          hostKeyType: seenType,
        );
      }
      if (rejectedByMismatch) {
        return SshConnectResult(
          fingerprintChanged: true,
          fingerprintHex: seenFingerprint,
          hostKeyType: seenType,
          error:
              'Fingerprint host berubah dari yang tersimpan. Koneksi ditolak demi keamanan.',
        );
      }
      return SshConnectResult(error: e.toString());
    }
  }

  /// Dipanggil setelah user konfirmasi fingerprint baru di dialog.
  /// Simpan fingerprint dulu (lewat SecureStorageService) baru panggil connect() lagi
  /// dengan knownFingerprint terisi.

  Future<ServerInfoResult> fetchServerInfo(SSHClient client) async {
    final osInfo = await _runSafe(client, 'cat /etc/os-release | grep PRETTY_NAME | cut -d\'"\' -f2');
    final dockerVersion = await _runSafe(client, 'docker version --format "{{.Server.Version}}"');
    final running = await _runSafe(client, 'docker ps -q | wc -l');
    final total = await _runSafe(client, 'docker ps -aq | wc -l');
    final images = await _runSafe(client, 'docker images -q | wc -l');
    final cpuLine = await _runSafe(
      client,
      "top -bn1 | grep 'Cpu(s)' | awk '{print \$2}'",
    );
    final memLine = await _runSafe(client, "free -m | awk '/Mem:/ {printf \"%.0f\", \$3*100/\$2}'");
    final diskLine = await _runSafe(client, "df -h / | awk 'NR==2 {print \$5}' | tr -d '%'");

    return ServerInfoResult(
      osInfo: osInfo?.trim().isNotEmpty == true ? osInfo!.trim() : null,
      dockerVersion: dockerVersion?.trim(),
      containerRunning: int.tryParse(running?.trim() ?? '') ?? 0,
      containerTotal: int.tryParse(total?.trim() ?? '') ?? 0,
      imageCount: int.tryParse(images?.trim() ?? '') ?? 0,
      cpuUsagePercent: double.tryParse(cpuLine?.trim() ?? '') ?? 0,
      ramUsagePercent: double.tryParse(memLine?.trim() ?? '') ?? 0,
      diskUsagePercent: double.tryParse(diskLine?.trim() ?? '') ?? 0,
    );
  }

  Future<String?> _runSafe(SSHClient client, String command) async {
    try {
      final result = await client.run(command);
      return utf8.decode(result, allowMalformed: true);
    } catch (_) {
      return null;
    }
  }
}
