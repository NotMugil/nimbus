import 'dart:math';

import 'package:nimbus/models/app_album.dart';
import 'package:nimbus/services/album_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesAppAlbumRepository implements AppAlbumRepository {
  SharedPreferencesAppAlbumRepository._();

  static final SharedPreferencesAppAlbumRepository instance =
      SharedPreferencesAppAlbumRepository._();

  static const String _storageKey = 'nimbus.app_albums.v1';

  Future<SharedPreferences> _prefs() {
    return SharedPreferences.getInstance();
  }

  @override
  Future<void> addMediaToAlbum(String albumId, Set<String> mediaIds) async {
    if (mediaIds.isEmpty) {
      return;
    }

    final List<AppAlbum> albums = await listAlbums();
    final int index = albums.indexWhere(
      (AppAlbum album) => album.id == albumId,
    );
    if (index < 0) {
      return;
    }

    final AppAlbum existing = albums[index];
    final Set<String> dedupedIds = <String>{...existing.mediaIds, ...mediaIds};

    albums[index] = existing.copyWith(mediaIds: dedupedIds.toList()..sort());
    await _saveAlbums(albums);
  }

  @override
  Future<void> removeMediaFromAlbum(
    String albumId, {
    Set<String> mediaIds = const <String>{},
    Set<String> localPaths = const <String>{},
  }) async {
    if (mediaIds.isEmpty && localPaths.isEmpty) {
      return;
    }

    final List<AppAlbum> albums = await listAlbums();
    final int index = albums.indexWhere(
      (AppAlbum album) => album.id == albumId,
    );
    if (index < 0) {
      return;
    }

    final AppAlbum existing = albums[index];
    final Set<String> nextMediaIds = <String>{...existing.mediaIds}
      ..removeAll(mediaIds);
    final Set<String> nextLocalPaths = <String>{...existing.localMediaPaths}
      ..removeAll(localPaths);

    final bool removedCoverMedia =
        existing.coverMediaId != null &&
        mediaIds.contains(existing.coverMediaId);
    final bool removedCoverPath =
        existing.coverLocalPath != null &&
        localPaths.contains(existing.coverLocalPath);

    albums[index] = existing.copyWith(
      mediaIds: nextMediaIds.toList()..sort(),
      localMediaPaths: nextLocalPaths.toList()..sort(),
      clearCoverMediaId: removedCoverMedia,
      clearCoverLocalPath: removedCoverPath,
    );
    await _saveAlbums(albums);
  }

  @override
  Future<void> addLocalMediaToAlbum(
    String albumId,
    Set<String> localPaths,
  ) async {
    if (localPaths.isEmpty) {
      return;
    }

    final List<AppAlbum> albums = await listAlbums();
    final int index = albums.indexWhere(
      (AppAlbum album) => album.id == albumId,
    );
    if (index < 0) {
      return;
    }

    final AppAlbum existing = albums[index];
    final Set<String> dedupedPaths = <String>{
      ...existing.localMediaPaths,
      ...localPaths,
    };

    albums[index] = existing.copyWith(
      localMediaPaths: dedupedPaths.toList()..sort(),
    );
    await _saveAlbums(albums);
  }

  @override
  Future<void> renameAlbum(String albumId, String newName) async {
    final String trimmed = newName.trim();
    if (trimmed.isEmpty) {
      throw const FormatException('Album name cannot be empty.');
    }

    final List<AppAlbum> albums = await listAlbums();
    final int index = albums.indexWhere(
      (AppAlbum album) => album.id == albumId,
    );
    if (index < 0) {
      return;
    }

    final String lowered = trimmed.toLowerCase();
    final bool duplicateExists = albums.any(
      (AppAlbum album) =>
          album.id != albumId && album.name.trim().toLowerCase() == lowered,
    );
    if (duplicateExists) {
      throw DuplicateAlbumNameException(trimmed);
    }

    final AppAlbum existing = albums[index];
    albums[index] = existing.copyWith(name: trimmed);
    await _saveAlbums(albums);
  }

  @override
  Future<void> setAlbumCover(
    String albumId, {
    String? mediaId,
    String? localPath,
  }) async {
    final List<AppAlbum> albums = await listAlbums();
    final int index = albums.indexWhere(
      (AppAlbum album) => album.id == albumId,
    );
    if (index < 0) {
      return;
    }

    final AppAlbum existing = albums[index];
    final bool isMediaValid =
        mediaId != null && existing.mediaIds.contains(mediaId);
    final bool isPathValid =
        localPath != null && existing.localMediaPaths.contains(localPath);

    if (!isMediaValid && !isPathValid) {
      albums[index] = existing.copyWith(
        clearCoverMediaId: true,
        clearCoverLocalPath: true,
      );
    } else {
      albums[index] = existing.copyWith(
        coverMediaId: isMediaValid ? mediaId : null,
        coverLocalPath: isPathValid ? localPath : null,
        clearCoverMediaId: !isMediaValid,
        clearCoverLocalPath: !isPathValid,
      );
    }
    await _saveAlbums(albums);
  }

  @override
  Future<AppAlbum> createAlbum(String name) async {
    final String trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw const FormatException('Album name cannot be empty.');
    }

    if (await existsByName(trimmed)) {
      throw DuplicateAlbumNameException(trimmed);
    }

    final List<AppAlbum> albums = await listAlbums();
    final AppAlbum album = AppAlbum(
      id: '${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(1 << 32)}',
      name: trimmed,
      mediaIds: const <String>[],
      localMediaPaths: const <String>[],
      coverMediaId: null,
      coverLocalPath: null,
      createdAt: DateTime.now().toLocal(),
    );

    final List<AppAlbum> nextAlbums = <AppAlbum>[...albums, album]
      ..sort((AppAlbum a, AppAlbum b) => a.createdAt.compareTo(b.createdAt));
    await _saveAlbums(nextAlbums);
    return album;
  }

  @override
  Future<bool> existsByName(String name) async {
    final String lowered = name.trim().toLowerCase();
    if (lowered.isEmpty) {
      return false;
    }

    final List<AppAlbum> albums = await listAlbums();
    return albums.any(
      (AppAlbum album) => album.name.trim().toLowerCase() == lowered,
    );
  }

  @override
  Future<AppAlbum?> getById(String albumId) async {
    final List<AppAlbum> albums = await listAlbums();
    for (final AppAlbum album in albums) {
      if (album.id == albumId) {
        return album;
      }
    }
    return null;
  }

  @override
  Future<List<AppAlbum>> listAlbums() async {
    final SharedPreferences prefs = await _prefs();
    final String? raw = prefs.getString(_storageKey);
    if (raw == null) {
      return const <AppAlbum>[];
    }

    try {
      final List<AppAlbum> decoded = AppAlbum.decodeList(raw);
      decoded.sort(
        (AppAlbum a, AppAlbum b) => a.createdAt.compareTo(b.createdAt),
      );
      return decoded;
    } catch (_) {
      return const <AppAlbum>[];
    }
  }

  Future<void> _saveAlbums(List<AppAlbum> albums) async {
    final SharedPreferences prefs = await _prefs();
    await prefs.setString(_storageKey, AppAlbum.encodeList(albums));
  }
}
