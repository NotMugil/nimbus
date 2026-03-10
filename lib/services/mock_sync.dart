import 'dart:math';

import 'package:nimbus/models/sync_record.dart';
import 'package:nimbus/services/sync_repository.dart';

typedef CloudSyncProgressCallback = void Function(CloudSyncBatchProgress value);

class CloudSyncBatchProgress {
  const CloudSyncBatchProgress({
    required this.total,
    required this.completed,
    required this.currentMediaId,
    required this.currentPhase,
    required this.currentItemProgress,
  });

  final int total;
  final int completed;
  final String currentMediaId;
  final String currentPhase;
  final double currentItemProgress;
}

class MockCloudSyncService {
  MockCloudSyncService(this.repository);

  final CloudSyncRepository repository;
  final Random _random = Random();

  Future<void> removeFromCloud(Iterable<String> mediaIds) {
    return repository.setUnsynced(mediaIds);
  }

  Future<void> sync(
    Iterable<String> mediaIds, {
    CloudSyncProgressCallback? onProgress,
  }) async {
    final List<String> targets = mediaIds.toSet().toList(growable: false);
    if (targets.isEmpty) {
      return;
    }

    int completed = 0;
    for (final String mediaId in targets) {
      await repository.setStatus(
        mediaId,
        CloudSyncStatus.uploading,
        progress: 0,
      );
      onProgress?.call(
        CloudSyncBatchProgress(
          total: targets.length,
          completed: completed,
          currentMediaId: mediaId,
          currentPhase: 'Encrypting',
          currentItemProgress: 0,
        ),
      );

      for (int i = 1; i <= 5; i += 1) {
        final double progress = (i / 5) * 0.35;
        await Future<void>.delayed(const Duration(milliseconds: 120));
        await repository.setStatus(
          mediaId,
          CloudSyncStatus.uploading,
          progress: progress,
        );
        onProgress?.call(
          CloudSyncBatchProgress(
            total: targets.length,
            completed: completed,
            currentMediaId: mediaId,
            currentPhase: 'Encrypting',
            currentItemProgress: progress,
          ),
        );
      }

      bool didFail = _random.nextInt(100) < 8;
      for (int i = 1; i <= 8; i += 1) {
        final double progress = 0.35 + ((i / 8) * 0.65);
        await Future<void>.delayed(const Duration(milliseconds: 150));
        await repository.setStatus(
          mediaId,
          CloudSyncStatus.uploading,
          progress: progress,
        );
        onProgress?.call(
          CloudSyncBatchProgress(
            total: targets.length,
            completed: completed,
            currentMediaId: mediaId,
            currentPhase: 'Uploading',
            currentItemProgress: progress,
          ),
        );
      }

      if (didFail) {
        await repository.setStatus(
          mediaId,
          CloudSyncStatus.failed,
          progress: 0,
        );
      } else {
        await repository.setStatus(
          mediaId,
          CloudSyncStatus.synced,
          progress: 1,
        );
      }
      completed += 1;
      onProgress?.call(
        CloudSyncBatchProgress(
          total: targets.length,
          completed: completed,
          currentMediaId: mediaId,
          currentPhase: didFail ? 'Failed' : 'Completed',
          currentItemProgress: didFail ? 0 : 1,
        ),
      );
    }
  }
}
