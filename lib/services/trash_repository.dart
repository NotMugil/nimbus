import 'package:nimbus/models/deleted_entry.dart';

abstract interface class RecentlyDeletedRepository {
  Future<void> markDeleted(Iterable<String> mediaIds);

  Future<void> restore(Iterable<String> mediaIds);

  Future<Set<String>> listDeletedIds();

  Future<List<RecentlyDeletedEntry>> listEntries();

  Future<bool> isDeleted(String mediaId);

  Future<void> pruneMissing(Iterable<String> validMediaIds);

  Stream<Set<String>> watchDeletedIds();
}
