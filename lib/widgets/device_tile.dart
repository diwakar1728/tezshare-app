import 'package:flutter/material.dart';
import 'package:tezshare/models/peer_device.dart';
import 'package:tezshare/theme/app_theme.dart';

class DeviceTile extends StatelessWidget {
  final PeerDevice device;
  final VoidCallback onTap;

  const DeviceTile({super.key, required this.device, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.electricBlue.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.smartphone_rounded, color: AppColors.amber),
        ),
        title: Text(
          device.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(device.ip, style: const TextStyle(color: AppColors.textMuted)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded,
            size: 16, color: AppColors.textMuted),
      ),
    );
  }
}
