import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nimbus/core/media/media_item.dart';
import 'package:nimbus/core/media/media_repository.dart';
import 'package:nimbus/core/media/media_type.dart';
import 'package:nimbus/core/media/thumbnail_ref.dart';
import 'package:nimbus/models/app_album.dart';
import 'package:nimbus/models/sync_record.dart';
import 'package:nimbus/models/device_album.dart';
import 'package:nimbus/models/deleted_entry.dart';
import 'package:nimbus/screens/album_view/album_view.dart';
import 'package:nimbus/services/album_repository.dart';
import 'package:nimbus/services/sync_repository.dart';
import 'package:nimbus/services/trash_repository.dart';

void main() {
  final FakeCloudSyncRepository cloudSyncRepository = FakeCloudSyncRepository();
  final FakeRecentlyDeletedRepository recentlyDeletedRepository =
      FakeRecentlyDeletedRepository();

  testWidgets('app album view shows import FAB', (WidgetTester tester) async {
    final FakeMediaRepository mediaRepository = FakeMediaRepository();
    final FakeAppAlbumRepository appAlbumRepository = FakeAppAlbumRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: AlbumViewScreen.app(
          album: appAlbumRepository.albums.first,
          mediaRepository: mediaRepository,
          appAlbumRepository: appAlbumRepository,
          cloudSyncRepository: cloudSyncRepository,
          recentlyDeletedRepository: recentlyDeletedRepository,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.byTooltip('Edit album'), findsOneWidget);
    expect(find.byTooltip('Switch to 5-column grid'), findsOneWidget);
  });

  testWidgets('device album view hides import FAB', (
    WidgetTester tester,
  ) async {
    final FakeMediaRepository mediaRepository = FakeMediaRepository();
    final FakeAppAlbumRepository appAlbumRepository = FakeAppAlbumRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: AlbumViewScreen.device(
          album: mediaRepository.deviceAlbums.first,
          mediaRepository: mediaRepository,
          appAlbumRepository: appAlbumRepository,
          cloudSyncRepository: cloudSyncRepository,
          recentlyDeletedRepository: recentlyDeletedRepository,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.byTooltip('Edit album'), findsNothing);
    expect(find.byTooltip('Switch to 5-column grid'), findsOneWidget);
  });

  testWidgets('grid button toggles between 3 and 5 columns', (
    WidgetTester tester,
  ) async {
    final FakeMediaRepository mediaRepository = FakeMediaRepository();
    final FakeAppAlbumRepository appAlbumRepository = FakeAppAlbumRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: AlbumViewScreen.app(
          album: appAlbumRepository.albums.first,
          mediaRepository: mediaRepository,
          appAlbumRepository: appAlbumRepository,
          cloudSyncRepository: cloudSyncRepository,
          recentlyDeletedRepository: recentlyDeletedRepository,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Switch to 5-column grid'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Switch to 3-column grid'), findsOneWidget);
  });

  testWidgets('tapping image tile opens image view', (
    WidgetTester tester,
  ) async {
    final FakeMediaRepository mediaRepository = FakeMediaRepository();
    final FakeAppAlbumRepository appAlbumRepository = FakeAppAlbumRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: AlbumViewScreen.app(
          album: appAlbumRepository.albums.first,
          mediaRepository: mediaRepository,
          appAlbumRepository: appAlbumRepository,
          cloudSyncRepository: cloudSyncRepository,
          recentlyDeletedRepository: recentlyDeletedRepository,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('album-view-tile-asset-1')));
    await tester.pumpAndSettle();

    expect(find.text('1/1'), findsOneWidget);
  });

  testWidgets('long press enters selection mode with remove action', (
    WidgetTester tester,
  ) async {
    final FakeMediaRepository mediaRepository = FakeMediaRepository();
    final FakeAppAlbumRepository appAlbumRepository = FakeAppAlbumRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: AlbumViewScreen.app(
          album: appAlbumRepository.albums.first,
          mediaRepository: mediaRepository,
          appAlbumRepository: appAlbumRepository,
          cloudSyncRepository: cloudSyncRepository,
          recentlyDeletedRepository: recentlyDeletedRepository,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.longPress(find.byKey(const Key('album-view-tile-asset-1')));
    await tester.pumpAndSettle();

    expect(find.text('1 selected'), findsOneWidget);
    expect(find.byKey(const Key('album-selection-action-bar')), findsOneWidget);
    expect(find.byKey(const Key('album-action-remove')), findsOneWidget);
  });
}

class FakeMediaRepository implements MediaRepository {
  final List<DeviceAlbum> deviceAlbums = const <DeviceAlbum>[
    DeviceAlbum(
      id: 'dev-album',
      name: 'Camera',
      count: 1,
      coverThumbnail: PlaceholderThumbnailRef(color: Colors.blue),
    ),
  ];

  @override
  Future<List<MediaItem>> fetchAllMedia() async => const <MediaItem>[];

  @override
  Future<List<DeviceAlbum>> fetchDeviceAlbums() async => deviceAlbums;

  @override
  Future<List<MediaItem>> fetchMediaByIds(List<String> mediaIds) async {
    return <MediaItem>[
      MediaItem(
        id: 'asset-1',
        type: MediaType.image,
        createdAt: DateTime(2026, 3, 10),
        thumbnail: const PlaceholderThumbnailRef(color: Colors.red),
        isSynced: false,
      ),
    ];
  }

  @override
  Future<List<MediaItem>> fetchMediaForDeviceAlbum(String albumId) async {
    return <MediaItem>[
      MediaItem(
        id: 'asset-device-1',
        type: MediaType.image,
        createdAt: DateTime(2026, 3, 10),
        thumbnail: const PlaceholderThumbnailRef(color: Colors.green),
        isSynced: false,
      ),
    ];
  }

  @override
  Future<MediaPermissionStatus> requestPermission() async {
    return MediaPermissionStatus.granted;
  }

  @override
  Future<List<MediaItem>> fetchFavoriteMedia() async => const <MediaItem>[];

  @override
  Future<List<MediaItem>> fetchTrashMedia() async => const <MediaItem>[];

  @override
  Future<List<MediaItem>> refreshMedia() async => const <MediaItem>[];

  @override
  Future<void> updateSyncStatus(Set<String> syncedMediaIds) async {}
}

class FakeAppAlbumRepository implements AppAlbumRepository {
  final List<AppAlbum> albums = <AppAlbum>[
    AppAlbum(
      id: 'app-album-1',
      name: 'Trips',
      mediaIds: const <String>['asset-1'],
      localMediaPaths: const <String>[],
      createdAt: DateTime(2026, 3, 10),
    ),
  ];

  @override
  Future<void> addLocalMediaToAlbum(
    String albumId,
    Set<String> localPaths,
  ) async {}

  @override
  Future<void> addMediaToAlbum(String albumId, Set<String> mediaIds) async {}

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
    throw UnimplementedError();
  }

  @override
  Future<bool> existsByName(String name) async => false;

  @override
  Future<AppAlbum?> getById(String albumId) async {
    for (final AppAlbum album in albums) {
      if (album.id == albumId) {
        return album;
      }
    }
    return null;
  }

  @override
  Future<List<AppAlbum>> listAlbums() async => albums;
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
