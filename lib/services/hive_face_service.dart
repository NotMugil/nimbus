                  import 'dart:convert';

import 'package:hive/hive.dart';
import 'package:nimbus/core/hive_service.dart';
import 'package:nimbus/models/face_album.dart';
import 'package:nimbus/models/face_record.dart';
import 'package:nimbus/services/face_match_service.dart';

class HiveFaceService {
  HiveFaceService({FaceMatchService? matcher})
    : _matcher = matcher ?? const FaceMatchService();

  static const String _recordKeyPrefix = 'record:';
  static const String _personCounterKey = '_meta:person_counter';

  final FaceMatchService _matcher;
  Future<Box<String>>? _boxFuture;

  Future<Box<String>> _openBox() {
    return _boxFuture ??= HiveService.openFacesBox();
  }

  Future<List<FaceRecord>> listFaceRecords() async {
    final Box<String> box = await _openBox();
    final List<FaceRecord> records = <FaceRecord>[];

    for (final String key in box.keys.cast<String>()) {
      if (!key.startsWith(_recordKeyPrefix)) {
        continue;
      }
      final FaceRecord? decoded = FaceRecord.tryDecode(box.get(key));
      if (decoded != null) {
        records.add(decoded);
      }
    }

    records.sort(
      (FaceRecord a, FaceRecord b) => a.createdAt.compareTo(b.createdAt),
    );
    return records;
  }

  Future<List<FaceAlbum>> listAlbums() async {
    final List<FaceRecord> records = await listFaceRecords();
    final Map<String, List<String>> grouped = <String, List<String>>{};

    for (final FaceRecord record in records) {
      grouped
          .putIfAbsent(record.personId, () => <String>[])
          .add(record.imagePath);
    }

    final List<FaceAlbum> albums = grouped.entries
        .map(
          (MapEntry<String, List<String>> entry) => FaceAlbum(
            personId: entry.key,
            imagePaths: List<String>.unmodifiable(entry.value),
          ),
        )
        .toList(growable: false);
    albums.sort((FaceAlbum a, FaceAlbum b) => a.personId.compareTo(b.personId));
    return albums;
  }

  Future<String?> findMatchingPersonId(
    List<double> candidateEmbedding, {
    double threshold = 0.8,
  }) async {
    final List<FaceRecord> records = await listFaceRecords();
    double? bestDistance;
    String? bestPersonId;

    for (final FaceRecord record in records) {
      final double distance = _matcher.calculateEuclideanDistance(
        candidateEmbedding,
        record.embedding,
      );
      if (distance >= threshold) {
        continue;
      }

      if (bestDistance == null || distance < bestDistance) {
        bestDistance = distance;
        bestPersonId = record.personId;
      }
    }

    return bestPersonId;
  }

  Future<FaceRecord> saveFace({
    required String imagePath,
    required List<double> embedding,
    String? personId,
  }) async {
    final Box<String> box = await _openBox();
    final String resolvedPersonId = personId ?? await _nextPersonId(box);
    final String id = 'face_${DateTime.now().microsecondsSinceEpoch}';

    final FaceRecord record = FaceRecord(
      id: id,
      personId: resolvedPersonId,
      imagePath: imagePath,
      embedding: List<double>.unmodifiable(embedding),
      createdAt: DateTime.now().toLocal(),
    );

    await box.put('$_recordKeyPrefix$id', jsonEncode(record.toJson()));
    return record;
  }

  Future<FaceRecord> saveFaceWithAutoPersonMatch({
    required String imagePath,
    required List<double> embedding,
    double threshold = 0.8,
  }) async {
    final String? personId = await findMatchingPersonId(
      embedding,
      threshold: threshold,
    );
    return saveFace(
      imagePath: imagePath,
      embedding: embedding,
      personId: personId,
    );
  }

  Future<String> _nextPersonId(Box<String> box) async {
    final int current = int.tryParse(box.get(_personCounterKey) ?? '0') ?? 0;
    final int next = current + 1;
    await box.put(_personCounterKey, '$next');
    return 'person_$next';
  }
}
