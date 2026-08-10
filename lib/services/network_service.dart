import 'dart:io';

/// Cek apakah host "hidup" tanpa perlu SSH auth penuh.
/// ICMP ping asli dibatasi di Android/iOS (butuh raw socket + permission
/// yang gak selalu dikasih), jadi dipakai TCP connect ke port SSH sebagai
/// gantinya - fungsinya sama (host reachable atau enggak) tapi portable
/// di semua platform tanpa dependency tambahan.
class NetworkService {
  static Future<bool> isReachable(
    String host,
    int port, {
    Duration timeout = const Duration(seconds: 3),
  }) async {
    try {
      final socket = await Socket.connect(host, port, timeout: timeout);
      socket.destroy();
      return true;
    } catch (_) {
      return false;
    }
  }
}
