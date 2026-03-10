import 'package:flutter_test/flutter_test.dart';
import 'dart:convert';

import 'package:nimbus/models/app_album.dart';
import 'package:nimbus/services/album_repository.dart';
import 'package:nimbus/services/prefs_album.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferencesAppAlbumRepository repository;

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    repository = SharedPreferencesAppAlbumRepository.instance;
  });

  test('creates and lists app albums', () async {
    await repository.createAlbum('Travel');

    final List<AppAlbum> albums = await repository.listAlbums();
    expect(albums, hasLength(1));
    expect(albums.first.name, 'Travel');
  });

  test('deduplicates media ids while adding to album', () async {
    final AppAlbum album = await repository.createAlbum('Family');

    await repository.addMediaToAlbum(album.id, <String>{'a', 'b'});
    await repository.addMediaToAlbum(album.id, <String>{'b', 'c'});

    final AppAlbum? updated = await repository.getById(album.id);
    expect(updated, isNotNull);
    expect(updated!.mediaIds.toSet(), <String>{'a', 'b', 'c'});
  });

  test('deduplicates local media paths while adding to album', () async {
    final AppAlbum album = await repository.createAlbum('Local');

    await repository.addLocalMediaToAlbum(album.id, <String>{'p1', 'p2'});
    await repository.addLocalMediaToAlbum(album.id, <String>{'p2', 'p3'});

    final AppAlbum? updated = await repository.getById(album.id);
    expect(updated, isNotNull);
    expect(updated!.localMediaPaths.toSet(), <String>{'p1', 'p2', 'p3'});
  });

  test('rejects duplicate album names case-insensitively', () async {
    await repository.createAlbum('Memories');

    expect(
      () => repository.createAlbum('memories'),
      throwsA(isA<DuplicateAlbumNameException>()),
    );
  });

  test('renames an album and rejects duplicate names on rename', () async {
    final AppAlbum first = await repository.createAlbum('Trips');
    await repository.createAlbum('Family');

    await repository.renameAlbum(first.id, 'Travel');
    final AppAlbum? renamed = await repository.getById(first.id);
    expect(renamed, isNotNull);
    expect(renamed!.name, 'Travel');

    expect(
      () => repository.renameAlbum(first.id, 'family'),
      throwsA(isA<DuplicateAlbumNameException>()),
    );
  });

  test('removes media ids and local paths from album', () async {
    final AppAlbum album = await repository.createAlbum('Mixed');
    await repository.addMediaToAlbum(album.id, <String>{'a', 'b', 'c'});
    await repository.addLocalMediaToAlbum(album.id, <String>{'p1', 'p2'});

    await repository.removeMediaFromAlbum(
      album.id,
      mediaIds: <String>{'b'},
      localPaths: <String>{'p2'},
    );

    final AppAlbum? updated = await repository.getById(album.id);
    expect(updated, isNotNull);
    expect(updated!.mediaIds.toSet(), <String>{'a', 'c'});
    expect(updated.localMediaPaths.toSet(), <String>{'p1'});
  });

  test('sets album cover to media id and clears when missing', () async {
    final AppAlbum album = await repository.createAlbum('Cover test');
    await repository.addMediaToAlbum(album.id, <String>{'a', 'b'});

    await repository.setAlbumCover(album.id, mediaId: 'b');
    final AppAlbum? withCover = await repository.getById(album.id);
    expect(withCover, isNotNull);
    expect(withCover!.coverMediaId, 'b');

    await repository.removeMediaFromAlbum(album.id, mediaIds: <String>{'b'});
    final AppAlbum? afterRemove = await repository.getById(album.id);
    expect(afterRemove, isNotNull);
    expect(afterRemove!.coverMediaId, isNull);
  });

  test('AppAlbum decode supports older JSON without localMediaPaths', () {
    final String raw = jsonEncode(<Map<String, dynamic>>[
      <String, dynamic>{
        'id': '1',
        'name': 'Legacy',
        'mediaIds': <String>['a'],
        'createdAt': DateTime(2026, 3, 1).toIso8601String(),
      },
    ]);

    final List<AppAlbum> decoded = AppAlbum.decodeList(raw);
    expect(decoded, hasLength(1));
    expect(decoded.first.localMediaPaths, isEmpty);
    expect(decoded.first.mediaIds, <String>['a']);
  });
}
