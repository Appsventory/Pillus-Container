import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dartssh2/dartssh2.dart';
import 'docker_repository.dart';

class SftpFileEntry {
  final String name;
  final bool isDirectory;
  final int size;
  final DateTime? modifyTime;

  const SftpFileEntry({
    required this.name,
    required this.isDirectory,
    required this.size,
    this.modifyTime,
  });
}

/// SFTP jalan di atas koneksi SSH yang sama (reuse dari session pool
/// DockerRepository), jadi gak perlu buka koneksi terpisah buat file
/// manager.
class SftpService {
  SftpService._();
  static final instance = SftpService._();

  final Map<String, SftpClient> _sftpPool = {};

  Future<SftpClient> _getSftp(String serverId) async {
    final existing = _sftpPool[serverId];
    if (existing != null) return existing;

    final client = DockerRepository.instance.getClient(serverId);
    if (client == null) {
      throw StateError('Belum ada sesi SSH aktif untuk server ini');
    }
    final sftp = await client.sftp();
    _sftpPool[serverId] = sftp;
    return sftp;
  }

  void closeSession(String serverId) {
    _sftpPool.remove(serverId);
  }

  Future<List<SftpFileEntry>> listDirectory(
    String serverId,
    String path,
  ) async {
    final sftp = await _getSftp(serverId);
    final names = await sftp.listdir(path);

    final entries = names
        .where((n) => n.filename != '.' && n.filename != '..')
        .map(
          (n) => SftpFileEntry(
            name: n.filename,
            isDirectory: n.attr.isDirectory,
            size: n.attr.size ?? 0,
            modifyTime: n.attr.modifyTime != null
                ? DateTime.fromMillisecondsSinceEpoch(n.attr.modifyTime! * 1000)
                : null,
          ),
        )
        .toList();

    entries.sort((a, b) {
      if (a.isDirectory != b.isDirectory) return a.isDirectory ? -1 : 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return entries;
  }

  Future<void> createDirectory(String serverId, String path) async {
    final sftp = await _getSftp(serverId);
    await sftp.mkdir(path);
  }

  Future<void> deleteFile(String serverId, String path) async {
    final sftp = await _getSftp(serverId);
    await sftp.remove(path);
  }

  /// SFTP rmdir cuma bisa hapus folder KOSONG, jadi buat hapus folder
  /// berisi dipakai `rm -rf` lewat shell command (reuse client yang sama).
  Future<void> deleteDirectoryRecursive(String serverId, String path) async {
    final client = DockerRepository.instance.getClient(serverId);
    if (client == null) {
      throw StateError('Belum ada sesi SSH aktif untuk server ini');
    }
    final safePath = path.replaceAll("'", "'\\''");
    await client.run("rm -rf '$safePath'");
  }

  Future<void> rename(String serverId, String oldPath, String newPath) async {
    final sftp = await _getSftp(serverId);
    await sftp.rename(oldPath, newPath);
  }

  Future<void> uploadFile(
    String serverId,
    String localPath,
    String remotePath, {
    void Function(int sent, int total)? onProgress,
  }) async {
    final sftp = await _getSftp(serverId);
    final localFile = File(localPath);
    final total = await localFile.length();

    final remoteFile = await sftp.open(
      remotePath,
      mode:
          SftpFileOpenMode.create |
          SftpFileOpenMode.write |
          SftpFileOpenMode.truncate,
    );

    int sent = 0;
    final stream = localFile.openRead().map((chunk) {
      sent += chunk.length;
      onProgress?.call(sent, total);
      return Uint8List.fromList(chunk);
    });

    await remoteFile.write(stream);
    await remoteFile.close();
  }

  Future<void> downloadFile(
    String serverId,
    String remotePath,
    String localPath, {
    void Function(int received)? onProgress,
  }) async {
    final sftp = await _getSftp(serverId);
    final remoteFile = await sftp.open(remotePath, mode: SftpFileOpenMode.read);
    final sink = File(localPath).openWrite();

    int received = 0;
    await for (final chunk in remoteFile.read()) {
      sink.add(chunk);
      received += chunk.length;
      onProgress?.call(received);
    }
    await sink.close();
    await remoteFile.close();
  }

  /// Baca isi file teks (dipakai buat editor compose file, dll).
  Future<String> readTextFile(String serverId, String remotePath) async {
    final sftp = await _getSftp(serverId);
    final file = await sftp.open(remotePath, mode: SftpFileOpenMode.read);
    final chunks = <int>[];
    await for (final chunk in file.read()) {
      chunks.addAll(chunk);
    }
    await file.close();
    return utf8.decode(chunks, allowMalformed: true);
  }

  /// Tulis/timpa isi file teks langsung dari string (bukan dari file lokal).
  Future<void> writeTextFile(
    String serverId,
    String remotePath,
    String content,
  ) async {
    final sftp = await _getSftp(serverId);
    final file = await sftp.open(
      remotePath,
      mode:
          SftpFileOpenMode.create |
          SftpFileOpenMode.write |
          SftpFileOpenMode.truncate,
    );
    final bytes = Uint8List.fromList(utf8.encode(content));
    await file.write(Stream.value(bytes));
    await file.close();
  }
}
