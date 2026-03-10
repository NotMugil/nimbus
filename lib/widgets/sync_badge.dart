import 'package:flutter/material.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/ion.dart';
import 'package:nimbus/models/sync_record.dart';

class CloudSyncBadge extends StatelessWidget {
  const CloudSyncBadge({super.key, required this.record});

  final CloudSyncRecord? record;

  @override
  Widget build(BuildContext context) {
    final CloudSyncStatus status = record?.status ?? CloudSyncStatus.unsynced;
    if (status == CloudSyncStatus.uploading) {
      return SizedBox(
        width: 16,
        height: 16,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            CircularProgressIndicator(
              value: record?.progress ?? 0,
              strokeWidth: 2,
              color: Colors.white,
              backgroundColor: const Color(0x66FFFFFF),
            ),
          ],
        ),
      );
    }

    if (status == CloudSyncStatus.synced) {
      return const Iconify(Ion.cloud, color: Colors.white, size: 15);
    }

    if (status == CloudSyncStatus.failed) {
      return const Iconify(
        Ion.alert_circled,
        color: Color(0xFFFFB3B3),
        size: 15,
      );
    }

    return const Iconify(
      Ion.cloud_offline_outline,
      color: Colors.white70,
      size: 15,
    );
  }
}
