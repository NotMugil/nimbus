import 'dart:convert';

import 'package:hive/hive.dart';
import 'package:nimbus/models/sync_record.dart';
import 'package:nimbus/services/sync_repository.dart';

class HiveCloudSyncRepository implements CloudSyncRepository {
  HiveCloudSyncRepository._();

  static final HiveCloudSyncRepository instance = HiveCloudSyncRepository._();

  static const String _boxName = 'nimbus.cloud_sync.v1';

  Future<Box<String>>? _boxFuture;

  Future<Box<String>> _openBox() {
    return _boxFuture ??= Hive.openBox<String>(_boxName);
  }

  Map<String, CloudSyncRecord> _snapshot(Box<String> box) {
    final Map<String, CloudSyncRecord> records = <String, CloudSyncRecord>{};
    for (final String key in box.keys.cast<String>()) {
      final String? raw = box.get(key);
      if (raw == null || raw.isEmpty) {
        continue;
      }
      try {
        final Map<String, dynamic> json =
            jsonDecode(raw) as Map<String, dynamic>;
        records[key] = CloudSyncRecord.fromJson(json);
      } catch (_) {
        continue;
      }
    }
    return records;
  }

  @override
  Future<Map<String, CloudSyncRecord>> listAll() async {
    final Box<String> box = await _openBox();
    return _snapshot(box);
  }

  @override
  Future<Map<String, CloudSyncRecord>> getForIds(
    Iterable<String> mediaIds,
  ) async {
    final Box<String> box = await _openBox();
    final Map<String, CloudSyncRecord> records = <String, CloudSyncRecord>{};
    for (final String id in mediaIds) {
      final String? raw = box.get(id);
      if (raw == null || raw.isEmpty) {
        continue;
      }
      try {
        records[id] = CloudSyncRecord.fromJson(
          jsonDecode(raw) as Map<String, dynamic>,
        );
      } catch (_) {
        continue;
      }
    }
    return records;
  }

  @override
  Future<CloudSyncRecord?> getById(String mediaId) async {
    final Box<String> box = await _openBox();
    final String? raw = box.get(mediaId);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      return CloudSyncRecord.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> setRecord(CloudSyncRecord record) async {
    final Box<String> box = await _openBox();
    await box.put(record.mediaId, jsonEncode(record.toJson()));
  }

  @override
  Future<void> setStatus(
    String mediaId,
    CloudSyncStatus status, {
    double progress = 0,
  }) {
    return setRecord(
      CloudSyncRecord(
        mediaId: mediaId,
        status: status,
        progress: progress.clamp(0, 1),
        updatedAt: DateTime.now().toLocal(),
      ),
    );
  }

  @override
  Future<void> setUnsynced(Iterable<String> mediaIds) async {
    final Box<String> box = await _openBox();
    for (final String mediaId in mediaIds) {
      final CloudSyncRecord record = CloudSyncRecord(
        mediaId: mediaId,
        status: CloudSyncStatus.unsynced,
        progress: 0,
        updatedAt: DateTime.now().toLocal(),
      );
      await box.put(mediaId, jsonEncode(record.toJson()));
    }
  }

  @override
  Stream<Map<String, CloudSyncRecord>> watchAll() async* {
    final Box<String> box = await _openBox();
    yield _snapshot(box);
    yield* box.watch().map((_) => _snapshot(box));
  }
}
