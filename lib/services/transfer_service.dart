import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;

import 'discovery_service.dart';

/// Reports how a transfer is going, so the UI can show a progress bar.
class TransferProgress {
  final int bytesSent;
  final int totalBytes;
  final bool isDone;
  final bool isError;
  final String? errorMessage;

  TransferProgress({
    required this.bytesSent,
    required this.totalBytes,
    this.isDone = false,
    this.isError = false,
    this.errorMessage,
  });

  double get percent => totalBytes == 0 ? 0 : bytesSent / totalBytes;
}

/// Handles BOTH sides of file transfer:
///  - Running a small local HTTP server (to RECEIVE incoming files)
///  - Sending files to another device's server (to SEND files out)
///
/// Filenames are always preserved exactly as-is (sent via a header),
/// so documents never get renamed during transfer.
class TransferService {
  HttpServer? _server;
  final void Function(String savedFilePath)? onFileReceived;

  TransferService({this.onFileReceived});

  /// Folder where incoming files are saved on this device.
  Future<Directory> getReceivedFolder() async {
    Directory base;
    if (Platform.isAndroid) {
      // App-specific external storage — no special runtime permission
      // needed on any Android version, and it's still easy for the user
      // to find (visible to file managers under Android/data/.../files).
      final extDir = await getExternalStorageDirectory();
      base = Directory(p.join(extDir!.path, 'TezShare Received'));
    } else if (Platform.isWindows) {
      final userProfile = Platform.environment['USERPROFILE'] ?? '.';
      base = Directory(p.join(userProfile, 'Downloads', 'TezShare'));
    } else {
      base = Directory.systemTemp;
    }
    if (!await base.exists()) {
      await base.create(recursive: true);
    }
    return base;
  }

  /// Starts the local server that listens for incoming files.
  Future<void> startServer({int port = kTransferPort}) async {
    final router = shelf.Pipeline().addHandler((shelf.Request request) async {
      if (request.method == 'POST' && request.url.path == 'upload') {
        return _handleUpload(request);
      }
      if (request.method == 'GET' && request.url.path == 'ping') {
        return shelf.Response.ok('tezshare-ok');
      }
      return shelf.Response.notFound('Not found');
    });

    _server = await shelf_io.serve(router, InternetAddress.anyIPv4, port);
  }

  Future<shelf.Response> _handleUpload(shelf.Request request) async {
    try {
      final rawName = request.headers['x-file-name'] ?? 'received_file';
      // Decode in case filename has special characters (spaces, emojis etc.)
      final fileName = Uri.decodeComponent(rawName);
      // Prevent path traversal — keep only the base file name.
      final safeName = p.basename(fileName);

      final folder = await getReceivedFolder();
      String targetPath = p.join(folder.path, safeName);
      targetPath = _avoidOverwrite(targetPath);

      final file = File(targetPath);
      final sink = file.openWrite();
      await request.read().pipe(sink);

      onFileReceived?.call(targetPath);

      return shelf.Response.ok(jsonEncode({'status': 'ok', 'path': targetPath}),
          headers: {'Content-Type': 'application/json'});
    } catch (e) {
      return shelf.Response.internalServerError(body: 'Upload failed: $e');
    }
  }

  /// If a file with the same name already exists, add " (1)", " (2)" etc.
  /// so we never silently overwrite an existing file, but we also never
  /// change the name of the file being SENT — only how it's stored if a
  /// clash happens on the receiving side.
  String _avoidOverwrite(String path) {
    if (!File(path).existsSync()) return path;
    final dir = p.dirname(path);
    final ext = p.extension(path);
    final baseName = p.basenameWithoutExtension(path);
    int i = 1;
    String candidate;
    do {
      candidate = p.join(dir, '$baseName ($i)$ext');
      i++;
    } while (File(candidate).existsSync());
    return candidate;
  }

  /// Sends a file to another device. Reports progress via [onProgress].
  Future<void> sendFile({
    required String ip,
    required int port,
    required File file,
    required void Function(TransferProgress progress) onProgress,
  }) async {
    final fileName = p.basename(file.path);
    final totalBytes = await file.length();
    final uri = Uri.parse('http://$ip:$port/upload');

    final request = http.StreamedRequest('POST', uri);
    request.headers['X-File-Name'] = Uri.encodeComponent(fileName);
    request.headers['Content-Length'] = totalBytes.toString();
    request.headers['Content-Type'] = 'application/octet-stream';

    int sent = 0;
    final client = http.Client();

    // Stream the file in chunks so we can report progress as we go.
    file.openRead().listen(
      (chunk) {
        request.sink.add(chunk);
        sent += chunk.length;
        onProgress(TransferProgress(bytesSent: sent, totalBytes: totalBytes));
      },
      onDone: () => request.sink.close(),
      onError: (e) {
        request.sink.close();
        onProgress(TransferProgress(
          bytesSent: sent,
          totalBytes: totalBytes,
          isError: true,
          errorMessage: e.toString(),
        ));
      },
    );

    try {
      final response = await client.send(request);
      if (response.statusCode == 200) {
        onProgress(TransferProgress(
          bytesSent: totalBytes,
          totalBytes: totalBytes,
          isDone: true,
        ));
      } else {
        onProgress(TransferProgress(
          bytesSent: sent,
          totalBytes: totalBytes,
          isError: true,
          errorMessage: 'Server responded with ${response.statusCode}',
        ));
      }
    } catch (e) {
      onProgress(TransferProgress(
        bytesSent: sent,
        totalBytes: totalBytes,
        isError: true,
        errorMessage: e.toString(),
      ));
    } finally {
      client.close();
    }
  }

  Future<void> stopServer() async {
    await _server?.close(force: true);
    _server = null;
  }
}
