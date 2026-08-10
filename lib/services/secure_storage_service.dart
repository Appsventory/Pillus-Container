import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/credential_model.dart';

class SecureStorageService {
  SecureStorageService._();
  static final instance = SecureStorageService._();

  // encryptedSharedPreferences dihapus di v11+ (Jetpack Security deprecated),
  // Android sekarang default pakai Tink/DataStore.
  final _storage = const FlutterSecureStorage();

  String _credKey(String serverId) => 'cred_$serverId';
  String _fingerprintKey(String serverId) => 'fingerprint_$serverId';

  Future<void> saveCredential(String serverId, CredentialModel cred) async {
    await _storage.write(
      key: _credKey(serverId),
      value: jsonEncode(cred.toMap()),
    );
  }

  Future<CredentialModel?> getCredential(String serverId) async {
    final raw = await _storage.read(key: _credKey(serverId));
    if (raw == null) return null;
    return CredentialModel.fromMap(jsonDecode(raw));
  }

  Future<void> deleteCredential(String serverId) async {
    await _storage.delete(key: _credKey(serverId));
    await _storage.delete(key: _fingerprintKey(serverId));
  }

  /// Trust-on-first-use: simpan fingerprint host yang sudah diverifikasi user.
  Future<void> saveKnownFingerprint(
    String serverId,
    String fingerprintHex,
  ) async {
    await _storage.write(key: _fingerprintKey(serverId), value: fingerprintHex);
  }

  Future<String?> getKnownFingerprint(String serverId) async {
    return _storage.read(key: _fingerprintKey(serverId));
  }

  // --- Daftar server (metadata statis: id/name/host/port/username) ---
  static const _serverListKey = 'server_list';

  Future<void> saveServerList(List<Map<String, dynamic>> servers) async {
    await _storage.write(key: _serverListKey, value: jsonEncode(servers));
  }

  Future<List<Map<String, dynamic>>> getServerList() async {
    final raw = await _storage.read(key: _serverListKey);
    if (raw == null) return [];
    return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
  }
}
