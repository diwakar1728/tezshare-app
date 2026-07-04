/// Represents another device found on the local network
/// that is also running TezShare.
class PeerDevice {
  final String id;
  final String name;
  final String ip;
  final int port;
  DateTime lastSeen;

  PeerDevice({
    required this.id,
    required this.name,
    required this.ip,
    required this.port,
    required this.lastSeen,
  });

  factory PeerDevice.fromJson(Map<String, dynamic> json) {
    return PeerDevice(
      id: json['id'] as String,
      name: json['name'] as String,
      ip: json['ip'] as String,
      port: json['port'] as int,
      lastSeen: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'ip': ip,
      'port': port,
    };
  }

  /// A peer is considered "offline" if we haven't heard its
  /// broadcast in the last few seconds.
  bool get isStale =>
      DateTime.now().difference(lastSeen) > const Duration(seconds: 8);
}
