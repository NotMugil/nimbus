import 'package:nimbus/models/sync_record.dart';

abstract interface class CloudSyncRepository {
  Future<Map<String, CloudSyncRecord>> listAll();

  Future<Map<String, CloudSyncRecord>> getForIds(Iterable<String> mediaIds);

  Future<CloudSyncRecord?> getById(String mediaId);

  Future<void> setRecord(CloudSyncRecord record);

  Future<void> setStatus(
    String mediaId,
    CloudSyncStatus status, {
    double progress = 0,
  });

  Future<void> setUnsynced(Iterable<String> mediaIds);

  Stream<Map<String, CloudSyncRecord>> watchAll();
}
