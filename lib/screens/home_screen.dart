import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:uuid/uuid.dart';
import 'package:tezshare/models/peer_device.dart';
import 'package:tezshare/services/discovery_service.dart';
import 'package:tezshare/services/transfer_service.dart';
import 'package:tezshare/screens/received_files_screen.dart';
import 'package:tezshare/theme/app_theme.dart';
import 'package:tezshare/widgets/device_tile.dart';
import 'package:tezshare/widgets/sending_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final DiscoveryService _discovery;
  late final TransferService _transfer;

  String _myName = 'Mera Device';
  String _myIp = '...';
  List<PeerDevice> _peers = [];
  int _receivedCount = 0;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final id = const Uuid().v4();
    _myName = Platform.isAndroid ? 'Phone-${id.substring(0, 4)}' : 'Laptop-${id.substring(0, 4)}';

    _transfer = TransferService(
      onFileReceived: (path) {
        setState(() => _receivedCount++);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Nayi file aayi: ${path.split(Platform.pathSeparator).last}')),
          );
        }
      },
    );
    await _transfer.startServer();

    _discovery = DiscoveryService(myId: id, myName: _myName);
    await _discovery.start();
    _discovery.peersStream.listen((peers) {
      if (mounted) setState(() => _peers = peers);
    });

    final info = NetworkInfo();
    final ip = await info.getWifiIP();
    if (mounted) {
      setState(() => _myIp = ip ?? 'Not connected to WiFi');
    }
  }

  @override
  void dispose() {
    _discovery.dispose();
    _transfer.stopServer();
    super.dispose();
  }

  Future<void> _pickAndSend(PeerDevice peer) async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.single.path == null) return;

    final file = File(result.files.single.path!);
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SendingSheet(
        file: file,
        peerName: peer.name,
        ip: peer.ip,
        port: peer.port,
        transferService: _transfer,
      ),
    );
  }

  void _showManualIpDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text('IP Se Connect Karo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Agar dusra device automatically nahi dikh raha, uska IP address yahan daalo.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'jaise 192.168.1.5',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final ip = controller.text.trim();
              if (ip.isNotEmpty) {
                _discovery.addManualPeer(ip);
              }
              Navigator.pop(context);
            },
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TezShare ⚡'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ReceivedFilesScreen(transferService: _transfer),
                ),
              );
            },
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.download_rounded),
                if (_receivedCount > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: AppColors.amber,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        '$_receivedCount',
                        style: const TextStyle(fontSize: 10, color: Colors.black),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.electricBlue, AppColors.darkBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.wifi_tethering_rounded, color: AppColors.amber, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_myName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                      Text('Ye Device: $_myIp',
                          style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text('Aas-paas ke Devices',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Spacer(),
                TextButton.icon(
                  onPressed: _showManualIpDialog,
                  icon: const Icon(Icons.add_link_rounded, size: 18),
                  label: const Text('IP se jodo'),
                ),
              ],
            ),
          ),
          Expanded(
            child: _peers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.search_rounded, size: 48, color: AppColors.textMuted),
                        const SizedBox(height: 12),
                        const Text(
                          'Koi device dhoondh rahe hain...',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Dusra device bhi TezShare khole aur\nsame WiFi/Hotspot pe ho',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _peers.length,
                    itemBuilder: (context, index) {
                      final peer = _peers[index];
                      return DeviceTile(
                        device: peer,
                        onTap: () => _pickAndSend(peer),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
