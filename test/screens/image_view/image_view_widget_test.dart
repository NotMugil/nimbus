import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nimbus/models/app_album.dart';
import 'package:nimbus/screens/image_view/image_view.dart';
import 'package:nimbus/screens/media_viewer/media_viewer_item.dart';
import 'package:nimbus/services/album_repository.dart';

void main() {
  List<MediaViewerItem> sampleItems() {
    return <MediaViewerItem>[
      MediaViewerItem.localFile(path: 'a.jpg', isVideo: false),
      MediaViewerItem.localFile(path: 'b.jpg', isVideo: false),
    ];
  }

  testWidgets('shows index and app-album actions', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ImageViewScreen.items(
          items: sampleItems(),
          initialIndex: 0,
          isFromAppAlbum: true,
          appAlbumId: 'app-1',
          appAlbumRepository: FakeAppAlbumRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('1/2'), findsOneWidget);
    expect(find.byTooltip('Info'), findsOneWidget);
    expect(find.byTooltip('Share'), findsOneWidget);
    expect(find.byTooltip('Remove from album'), findsOneWidget);
    expect(find.byTooltip('Trash'), findsOneWidget);
  });

  testWidgets('hides remove action for device album source', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ImageViewScreen.items(
          items: sampleItems(),
          initialIndex: 0,
          isFromAppAlbum: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Remove from album'), findsNothing);
    expect(find.byTooltip('Trash'), findsOneWidget);
  });

  testWidgets('wraps around while swiping', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ImageViewScreen.items(
          items: sampleItems(),
          initialIndex: 0,
          isFromAppAlbum: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('1/2'), findsOneWidget);

    await tester.drag(find.byType(PageView), const Offset(600, 0));
    await tester.pumpAndSettle();
    expect(find.text('2/2'), findsOneWidget);

    await tester.drag(find.byType(PageView), const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(find.text('1/2'), findsOneWidget);
  });
}

class FakeAppAlbumRepository implements AppAlbumRepository {
  @override
  Future<void> addLocalMediaToAlbum(
    String albumId,
    Set<String> localPaths,
  ) async {}

  @override
  Future<void> addMediaToAlbum(String albumId, Set<String> mediaIds) async {}

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
}
