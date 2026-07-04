import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:tezshare/services/transfer_service.dart';
import 'package:tezshare/theme/app_theme.dart';

class ReceivedFilesScreen extends StatefulWidget {
  final TransferService transferService;

  const ReceivedFilesScreen({super.key, required this.transferService});

  @override
  State<ReceivedFilesScreen> createState() => _ReceivedFilesScreenState();
}

class _ReceivedFilesScreenState extends State<ReceivedFilesScreen> {
  List<FileSystemEntity> _files = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    setState(() => _loading = true);
    final folder = await widget.transferService.getReceivedFolder();
    final files = folder.listSync()
      ..sort((a, b) =>
          b.statSync().modified.compareTo(a.statSync().modified));
    setState(() {
      _files = files;
      _loading = false;
    });
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aayi Hui Files'),
        actions: [
          IconButton(
            onPressed: _loadFiles,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _files.isEmpty
              ? const Center(
                  child: Text(
                    'Abhi tak koi file nahi aayi',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _files.length,
                  itemBuilder: (context, index) {
                    final file = _files[index];
                    final stat = file.statSync();
                    return Card(
                      margin:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: ListTile(
                        leading: const Icon(Icons.insert_drive_file_rounded,
                            color: AppColors.amber),
                        title: Text(p.basename(file.path),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(_formatSize(stat.size)),
                      ),
                    );
                  },
                ),
    );
  }
}
