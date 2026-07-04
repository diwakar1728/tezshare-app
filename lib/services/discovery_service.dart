import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:tezshare/models/peer_device.dart';

/// Port used only for discovery "hello, I exist" messages.
const int kDiscoveryPort = 45678;

/// Port used for the actual file transfer HTTP server.
const int kTransferPort = 45679;

/// DiscoveryService continuously:
///  1. Broadcasts "I am here" packets on the local WiFi network.
///  2. Listens for similar packets from other devices.
///  3. Keeps a live list of currently visible peers.
///
/// This is what makes devices "automatically appear" without
/// the user typing any IP address, similar to how AirDrop/LocalSend work.
class DiscoveryService {
  final String myId;
  final String myName;
  final int myTransferPort;

  RawDatagramSocket? _socket;
  Timer? _broadcastTimer;
  Timer? _cleanupTimer;

  final Map<String, PeerDevice> _peers = {};
  final StreamController<List<PeerDevice>> _peersController =
      StreamController<List<PeerDevice>>.broadcast();

  Stream<List<PeerDevice>> get peersStream => _peersController.stream;

  DiscoveryService({
    required this.myId,
    required this.myName,
    this.myTransferPort = kTransferPort,
  });

  Future<void> start() async {
    try {
      _socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        kDiscoveryPort,
        reuseAddress: true,
        reusePort: true,
      );
      _socket!.broadcastEnabled = true;

      _socket!.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          final Datagram? dg = _socket!.receive();
          if (dg == null) return;
          _handleIncomingPacket(dg);
        }
      });

      // Announce ourselves every 2 seconds
      _broadcastTimer =
          Timer.periodic(const Duration(seconds: 2), (_) => _broadcast());
      _broadcast(); // send one immediately

      // Remove peers we haven't heard from recently
      _cleanupTimer =
          Timer.periodic(const Duration(seconds: 3), (_) => _cleanupPeers());
    } catch (e) {
      // If binding fails (rare), discovery simply won't work,
      // but manual IP-connect fallback in the app still works.
    }
  }

  void _handleIncomingPacket(Datagram dg) {
    try {
      final String message = utf8.decode(dg.data);
      final Map<String, dynamic> json = jsonDecode(message);

      final String id = json['id'];
      if (id == myId) return; // ignore our own broadcast

      final peer = PeerDevice(
        id: id,
        name: json['name'],
        ip: dg.address.address,
        port: json['port'],
        lastSeen: DateTime.now(),
      );

      _peers[id] = peer;
      _emitPeers();
    } catch (_) {
      // ignore malformed packets
    }
  }

  void _broadcast() {
    if (_socket == null) return;
    final payload = jsonEncode({
      'id': myId,
      'name': myName,
      'port': myTransferPort,
    });
    final data = utf8.encode(payload);
    try {
      _socket!.send(data, InternetAddress('255.255.255.255'), kDiscoveryPort);
    } catch (_) {
      // ignore send errors (e.g. network temporarily unavailable)
    }
  }

  void _cleanupPeers() {
    final before = _peers.length;
    _peers.removeWhere((key, peer) => peer.isStale);
    if (_peers.length != before) {
      _emitPeers();
    }
  }

  void _emitPeers() {
    final list = _peers.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    _peersController.add(list);
  }

  /// Manually add a device by IP (fallback if auto-discovery
  /// doesn't find it, e.g. due to strict router/WiFi settings).
  void addManualPeer(String ip, {int port = kTransferPort}) {
    final id = 'manual-$ip-$port';
    _peers[id] = PeerDevice(
      id: id,
      name: ip,
      ip: ip,
      port: port,
      lastSeen: DateTime.now(),
    );
    _emitPeers();
  }

  void dispose() {
    _broadcastTimer?.cancel();
    _cleanupTimer?.cancel();
    _socket?.close();
    _peersController.close();
  }
}
