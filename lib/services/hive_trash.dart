import 'package:hive/hive.dart';
import 'package:nimbus/models/deleted_entry.dart';
import 'package:nimbus/services/trash_repository.dart';

class HiveRecentlyDeletedRepository implements RecentlyDeletedRepository {
  HiveRecentlyDeletedRepository._();

  static final HiveRecentlyDeletedRepository instance =
      HiveRecentlyDeletedRepository._();

  static const String _boxName = 'nimbus.recently_deleted.v1';

  Future<Box<String>>? _boxFuture;

  Future<Box<String>> _openBox() {
    return _boxFuture ??= Hive.openBox<String>(_boxName);
  }

  @override
  Future<void> markDeleted(Iterable<String> mediaIds) async {
    final Box<String> box = await _openBox();
    final String timestamp = DateTime.now().toUtc().toIso8601String();
    for (final String mediaId in mediaIds) {
      if (mediaId.isEmpty) {
        continue;
      }
      await box.put(mediaId, timestamp);
    }
  }

  @override
  Future<void> restore(Iterable<String> mediaIds) async {
    final Box<String> box = await _openBox();
    await box.deleteAll(mediaIds.where((String id) => id.isNotEmpty));
  }

  @override
  Future<Set<String>> listDeletedIds() async {
    final Box<String> box = await _openBox();
    return box.keys.cast<String>().toSet();
  }

  @override
  Future<List<RecentlyDeletedEntry>> listEntries() async {
    final Box<String> box = await _openBox();
    final List<RecentlyDeletedEntry> entries = <RecentlyDeletedEntry>[];
    for (final String key in box.keys.cast<String>()) {
      final String? value = box.get(key);
      final DateTime deletedAt =
          DateTime.tryParse(value ?? '')?.toLocal() ?? DateTime.now().toLocal();
      entries.add(RecentlyDeletedEntry(mediaId: key, deletedAt: deletedAt));
    }
    entries.sort(
      (RecentlyDeletedEntry a, RecentlyDeletedEntry b) =>
          b.deletedAt.compareTo(a.deletedAt),
    );
    return entries;
  }

  @override
  Future<bool> isDeleted(String mediaId) async {
    final Box<String> box = await _openBox();
    return box.containsKey(mediaId);
  }

  @override
  Future<void> pruneMissing(Iterable<String> validMediaIds) async {
    final Box<String> box = await _openBox();
    final Set<String> valid = validMediaIds.toSet();
    final List<String> stale = box.keys
        .cast<String>()
        .where((String id) => !valid.contains(id))
        .toList(growable: false);
    if (stale.isNotEmpty) {
      await box.deleteAll(stale);
    }
  }

  @override
  Stream<Set<String>> watchDeletedIds() async* {
    final Box<String> box = await _openBox();
    yield box.keys.cast<String>().toSet();
    yield* box.watch().map((_) => box.keys.cast<String>().toSet());
  }
}
