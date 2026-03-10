import 'package:nimbus/models/app_album.dart';

class DuplicateAlbumNameException implements Exception {
  const DuplicateAlbumNameException(this.name);

  final String name;
}

abstract interface class AppAlbumRepository {
  Future<List<AppAlbum>> listAlbums();

  Future<AppAlbum> createAlbum(String name);

  Future<AppAlbum?> getById(String albumId);

  Future<bool> existsByName(String name);

  Future<void> renameAlbum(String albumId, String newName);

  Future<void> addMediaToAlbum(String albumId, Set<String> mediaIds);

  Future<void> addLocalMediaToAlbum(String albumId, Set<String> localPaths);

  Future<void> removeMediaFromAlbum(
    String albumId, {
    Set<String> mediaIds = const <String>{},
    Set<String> localPaths = const <String>{},
  });

  Future<void> setAlbumCover(
    String albumId, {
    String? mediaId,
    String? localPath,
  });
}
