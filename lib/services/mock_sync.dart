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

  // Demo-only endpoint to show that encrypted blobs go to a local NAS.
  static const String _localNasBaseUrl = 'http://192.168.1.24:9000/nimbus';

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
      await _simulateNasBlobTransfer(
        mediaId: mediaId,
        blobType: 'thumbnail',
        startProgress: 0.35,
        endProgress: 0.58,
        total: targets.length,
        completed: completed,
        onProgress: onProgress,
      );
      await _simulateNasBlobTransfer(
        mediaId: mediaId,
        blobType: 'image',
        startProgress: 0.58,
        endProgress: 0.9,
        total: targets.length,
        completed: completed,
        onProgress: onProgress,
      );
      await _simulateNasBlobTransfer(
        mediaId: mediaId,
        blobType: 'metadata',
        startProgress: 0.9,
        endProgress: 0.98,
        total: targets.length,
        completed: completed,
        onProgress: onProgress,
      );
      await _simulateNasMetadataFetch(
        mediaId: mediaId,
        total: targets.length,
        completed: completed,
        onProgress: onProgress,
      );

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

  Future<void> _simulateNasBlobTransfer({
    required String mediaId,
    required String blobType,
    required double startProgress,
    required double endProgress,
    required int total,
    required int completed,
    required CloudSyncProgressCallback? onProgress,
  }) async {
    // Demo-only: this simulates uploading encrypted .enc blobs to local NAS.
    final String blobUrl =
        '$_localNasBaseUrl/blobs/$mediaId/$blobType.enc';
    for (int i = 1; i <= 4; i += 1) {
      final double progress =
          startProgress + ((i / 4) * (endProgress - startProgress));
      await Future<void>.delayed(const Duration(milliseconds: 130));
      await repository.setStatus(
        mediaId,
        CloudSyncStatus.uploading,
        progress: progress,
      );
      onProgress?.call(
        CloudSyncBatchProgress(
          total: total,
          completed: completed,
          currentMediaId: mediaId,
          currentPhase:
              'NAS upload: $blobType.enc -> ${Uri.parse(blobUrl).host} '
              '(encrypted blob)',
          currentItemProgress: progress,
        ),
      );
    }
  }

  Future<void> _simulateNasMetadataFetch({
    required String mediaId,
    required int total,
    required int completed,
    required CloudSyncProgressCallback? onProgress,
  }) async {
    // Demo-only fetch to show encrypted metadata retrieval from local NAS.
    final String metadataUrl =
        '$_localNasBaseUrl/blobs/$mediaId/metadata.enc';
    await Future<void>.delayed(const Duration(milliseconds: 120));
    await repository.setStatus(mediaId, CloudSyncStatus.uploading, progress: 1);
    onProgress?.call(
      CloudSyncBatchProgress(
        total: total,
        completed: completed,
        currentMediaId: mediaId,
        currentPhase:
            'NAS fetch: metadata.enc <- ${Uri.parse(metadataUrl).host}',
        currentItemProgress: 1,
      ),
    );
  }
}
