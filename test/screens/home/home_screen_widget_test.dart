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
import 'package:nimbus/screens/home/home.dart';
import 'package:nimbus/services/album_repository.dart';
import 'package:nimbus/services/sync_repository.dart';
import 'package:nimbus/services/trash_repository.dart';

void main() {
  testWidgets('renders day headers, video icon and unsynced indicators', (
    WidgetTester tester,
  ) async {
    final FakeMediaRepository repository = FakeMediaRepository(<MediaItem>[
      MediaItem(
        id: '1',
        type: MediaType.image,
        createdAt: DateTime(2026, 3, 6, 10),
        thumbnail: const PlaceholderThumbnailRef(color: Colors.red),
        isSynced: false,
      ),
      MediaItem(
        id: '2',
        type: MediaType.video,
        createdAt: DateTime(2026, 3, 6, 8),
        thumbnail: const PlaceholderThumbnailRef(color: Colors.green),
        isSynced: false,
      ),
      MediaItem(
        id: '3',
        type: MediaType.image,
        createdAt: DateTime(2026, 3, 5, 12),
        thumbnail: const PlaceholderThumbnailRef(color: Colors.blue),
        isSynced: false,
      ),
    ]);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeScreen(
            repository: repository,
            appAlbumRepository: FakeAppAlbumRepository(),
            recentlyDeletedRepository: FakeRecentlyDeletedRepository(),
            cloudSyncRepository: FakeCloudSyncRepository(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('6 Mar'), findsOneWidget);
    expect(find.text('5 Mar'), findsOneWidget);

    final double sixMarY = tester.getTopLeft(find.text('6 Mar')).dy;
    final double fiveMarY = tester.getTopLeft(find.text('5 Mar')).dy;
    expect(sixMarY, lessThan(fiveMarY));

    expect(find.byKey(const Key('video-indicator-2')), findsOneWidget);
    expect(find.byKey(const Key('sync-indicator-1')), findsOneWidget);
    expect(find.byKey(const Key('sync-indicator-2')), findsOneWidget);
    expect(find.byKey(const Key('sync-indicator-3')), findsOneWidget);
  });

  testWidgets('shows cancel and full-width action bar in selection mode', (
    WidgetTester tester,
  ) async {
    final FakeMediaRepository repository = FakeMediaRepository(<MediaItem>[
      MediaItem(
        id: 'tile-1',
        type: MediaType.image,
        createdAt: DateTime(2026, 3, 6, 10),
        thumbnail: const PlaceholderThumbnailRef(color: Colors.red),
        isSynced: false,
      ),
    ]);

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          repository: repository,
          appAlbumRepository: FakeAppAlbumRepository(),
          recentlyDeletedRepository: FakeRecentlyDeletedRepository(),
          cloudSyncRepository: FakeCloudSyncRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.longPress(find.byKey(const Key('media-tile-tile-1')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('home-selection-action-bar')), findsOneWidget);
    expect(find.byKey(const Key('home-cancel-selection')), findsOneWidget);

    await tester.tap(find.byKey(const Key('home-cancel-selection')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('home-selection-action-bar')), findsNothing);
  });
}

class FakeMediaRepository implements MediaRepository {
  FakeMediaRepository(this.items);

  final List<MediaItem> items;

  @override
  Future<List<MediaItem>> fetchAllMedia() async {
    return items;
  }

  @override
  Future<MediaPermissionStatus> requestPermission() async {
    return MediaPermissionStatus.granted;
  }

  @override
  Future<List<MediaItem>> refreshMedia() async {
    return items;
  }

  @override
  Future<List<DeviceAlbum>> fetchDeviceAlbums() async {
    return const <DeviceAlbum>[];
  }

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
  Future<AppAlbum> createAlbum(String name) {
    throw UnimplementedError();
  }

  @override
  Future<bool> existsByName(String name) async => false;

  @override
  Future<AppAlbum?> getById(String albumId) async => null;

  @override
  Future<List<AppAlbum>> listAlbums() async => const <AppAlbum>[];
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
