import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:tezshare/services/transfer_service.dart';
import 'package:tezshare/theme/app_theme.dart';

/// Bottom sheet shown while a file is being sent to a peer.
/// Shows a live progress bar (0% -> 100%).
class SendingSheet extends StatefulWidget {
  final File file;
  final String peerName;
  final String ip;
  final int port;
  final TransferService transferService;

  const SendingSheet({
    super.key,
    required this.file,
    required this.peerName,
    required this.ip,
    required this.port,
    required this.transferService,
  });

  @override
  State<SendingSheet> createState() => _SendingSheetState();
}

class _SendingSheetState extends State<SendingSheet> {
  double _percent = 0;
  bool _done = false;
  bool _error = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _startSending();
  }

  Future<void> _startSending() async {
    await widget.transferService.sendFile(
      ip: widget.ip,
      port: widget.port,
      file: widget.file,
      onProgress: (TransferProgress progress) {
        if (!mounted) return;
        setState(() {
          _percent = progress.percent;
          _done = progress.isDone;
          _error = progress.isError;
          _errorMsg = progress.errorMessage;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final fileName = p.basename(widget.file.path);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _error
                ? 'Bhejne mein error aa gaya'
                : _done
                    ? 'Bhej diya! ✅'
                    : 'Bhej rahe hain...',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text('$fileName  →  ${widget.peerName}',
              style: const TextStyle(color: AppColors.textMuted)),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _error ? 0 : _percent,
              minHeight: 10,
              backgroundColor: AppColors.cardBackground,
              valueColor: AlwaysStoppedAnimation<Color>(
                _error ? AppColors.error : AppColors.amber,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error
                ? (_errorMsg ?? 'Kuch galat ho gaya')
                : '${(_percent * 100).toStringAsFixed(0)}%',
            style: const TextStyle(color: AppColors.textMuted),
          ),
          const SizedBox(height: 20),
          if (_done || _error)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Band Karo'),
              ),
            ),
        ],
      ),
    );
  }
}
