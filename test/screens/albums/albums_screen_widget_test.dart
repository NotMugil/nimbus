import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nimbus/core/media/media_item.dart';
import 'package:nimbus/core/media/media_repository.dart';
import 'package:nimbus/core/media/thumbnail_ref.dart';
import 'package:nimbus/models/app_album.dart';
import 'package:nimbus/models/sync_record.dart';
import 'package:nimbus/models/device_album.dart';
import 'package:nimbus/models/deleted_entry.dart';
import 'package:nimbus/screens/albums/albums.dart';
import 'package:nimbus/services/album_repository.dart';
import 'package:nimbus/services/sync_repository.dart';
import 'package:nimbus/services/trash_repository.dart';

void main() {
  final FakeCloudSyncRepository cloudSyncRepository = FakeCloudSyncRepository();
  final FakeRecentlyDeletedRepository recentlyDeletedRepository =
      FakeRecentlyDeletedRepository();

  testWidgets('renders device albums row and app albums grid', (
    WidgetTester tester,
  ) async {
    final FakeMediaRepository mediaRepository = FakeMediaRepository();
    final FakeAppAlbumRepository appAlbumRepository = FakeAppAlbumRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: AlbumsScreen(
          repository: mediaRepository,
          appAlbumRepository: appAlbumRepository,
          cloudSyncRepository: cloudSyncRepository,
          recentlyDeletedRepository: recentlyDeletedRepository,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Photos on Device'), findsOneWidget);
    expect(find.text('My Albums'), findsOneWidget);
    expect(find.text('See all'), findsNWidgets(2));
    expect(find.text('Favorites'), findsOneWidget);
    expect(find.text('Trash'), findsOneWidget);
    expect(find.byKey(const Key('create-app-album-tile')), findsOneWidget);
    expect(find.text('Camera'), findsOneWidget);
    expect(find.text('Trips'), findsOneWidget);
    expect(find.text('Create Album'), findsOneWidget);
  });

  testWidgets('opens see all page and shows back app bar', (
    WidgetTester tester,
  ) async {
    final FakeMediaRepository mediaRepository = FakeMediaRepository();
    final FakeAppAlbumRepository appAlbumRepository = FakeAppAlbumRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: AlbumsScreen(
          repository: mediaRepository,
          appAlbumRepository: appAlbumRepository,
          cloudSyncRepository: cloudSyncRepository,
          recentlyDeletedRepository: recentlyDeletedRepository,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('device-albums-see-all')));
    await tester.pumpAndSettle();

    expect(find.text('Photos on Device'), findsWidgets);
    expect(find.byKey(const Key('all-device-albums-back')), findsOneWidget);
  });

  testWidgets('opens album view from app album card tap', (
    WidgetTester tester,
  ) async {
    final FakeMediaRepository mediaRepository = FakeMediaRepository();
    final FakeAppAlbumRepository appAlbumRepository = FakeAppAlbumRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: AlbumsScreen(
          repository: mediaRepository,
          appAlbumRepository: appAlbumRepository,
          cloudSyncRepository: cloudSyncRepository,
          recentlyDeletedRepository: recentlyDeletedRepository,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('app-album-tile-1')));
    await tester.pumpAndSettle();

    expect(find.text('Trips'), findsWidgets);
  });
}

class FakeMediaRepository implements MediaRepository {
  @override
  Future<List<DeviceAlbum>> fetchDeviceAlbums() async {
    return const <DeviceAlbum>[
      DeviceAlbum(
        id: 'camera',
        name: 'Camera',
        count: 12,
        coverThumbnail: PlaceholderThumbnailRef(color: Colors.blue),
      ),
    ];
  }

  @override
  Future<List<MediaItem>> fetchAllMedia() async => const <MediaItem>[];

  @override
  Future<MediaPermissionStatus> requestPermission() async {
    return MediaPermissionStatus.granted;
  }

  @override
  Future<List<MediaItem>> refreshMedia() async => const <MediaItem>[];

  @override
  Future<List<MediaItem>> fetchMediaByIds(List<String> mediaIds) async {
    return const <MediaItem>[];
  }

  @override
  Future<List<MediaItem>> fetchMediaForDeviceAlbum(String albumId) async {
    return const <MediaItem>[];
  }

  @override
  Future<List<MediaItem>> fetchFavoriteMedia() async {
    return const <MediaItem>[];
  }

  @override
  Future<List<MediaItem>> fetchTrashMedia() async {
    return const <MediaItem>[];
  }

  @override
  Future<void> updateSyncStatus(Set<String> syncedMediaIds) async {}
}

class FakeAppAlbumRepository implements AppAlbumRepository {
  final List<AppAlbum> _albums = <AppAlbum>[
    AppAlbum(
      id: '1',
      name: 'Trips',
      mediaIds: const <String>[],
      createdAt: DateTime(2026, 3, 10),
    ),
  ];

  @override
  Future<void> addMediaToAlbum(String albumId, Set<String> mediaIds) async {}

  @override
  Future<void> addLocalMediaToAlbum(
    String albumId,
    Set<String> localPaths,
  ) async {}

  @override
  Future<void> removeMediaFromAlbum(
    String albumId, {
    Set<String> mediaIds = const <String>{},
    Set<String> localPaths = const <String>{},
  }) async {}

  @override
  Future<void> renameAlbum(String albumId, String newName) async {}

  @override
  Future<void> setAlbumCover(
    String albumId, {
    String? mediaId,
    String? localPath,
  }) async {}

  @override
  Future<AppAlbum> createAlbum(String name) async {
    final AppAlbum album = AppAlbum(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      mediaIds: const <String>[],
      localMediaPaths: const <String>[],
      createdAt: DateTime.now(),
    );
    _albums.add(album);
    return album;
  }

  @override
  Future<bool> existsByName(String name) async {
    final String lowered = name.toLowerCase();
    return _albums.any((AppAlbum album) => album.name.toLowerCase() == lowered);
  }

  @override
  Future<AppAlbum?> getById(String albumId) async {
    for (final AppAlbum album in _albums) {
      if (album.id == albumId) {
        return album;
      }
    }
    return null;
  }

  @override
  Future<List<AppAlbum>> listAlbums() async => List<AppAlbum>.from(_albums);
}

class FakeRecentlyDeletedRepository implements RecentlyDeletedRepository {
  @override
  Future<bool> isDeleted(String mediaId) async => false;

  @override
  Future<Set<String>> listDeletedIds() async => <String>{};

  @override
  Future<List<RecentlyDeletedEntry>> listEntries() async =>
      const <RecentlyDeletedEntry>[];

  @override
  Future<void> markDeleted(Iterable<String> mediaIds) async {}

  @override
  Future<void> pruneMissing(Iterable<String> validMediaIds) async {}

  @override
  Future<void> restore(Iterable<String> mediaIds) async {}

  @override
  Stream<Set<String>> watchDeletedIds() =>
      Stream<Set<String>>.value(<String>{});
}

class FakeCloudSyncRepository implements CloudSyncRepository {
  @override
  Future<CloudSyncRecord?> getById(String mediaId) async => null;

  @override
  Future<Map<String, CloudSyncRecord>> getForIds(
    Iterable<String> mediaIds,
  ) async {
    return const <String, CloudSyncRecord>{};
  }

  @override
  Future<Map<String, CloudSyncRecord>> listAll() async {
    return const <String, CloudSyncRecord>{};
  }

  @override
  Future<void> setRecord(CloudSyncRecord record) async {}

  @override
  Future<void> setStatus(
    String mediaId,
    CloudSyncStatus status, {
    double progress = 0,
  }) async {}

  @override
  Future<void> setUnsynced(Iterable<String> mediaIds) async {}

  @override
  Stream<Map<String, CloudSyncRecord>> watchAll() =>
      Stream<Map<String, CloudSyncRecord>>.value(
        const <String, CloudSyncRecord>{},
      );
}
