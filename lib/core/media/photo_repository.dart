import 'dart:io';

import 'package:nimbus/core/media/media_item.dart';
import 'package:nimbus/core/media/media_repository.dart';
import 'package:nimbus/core/media/media_type.dart';
import 'package:nimbus/core/media/thumbnail_ref.dart';
import 'package:nimbus/models/device_album.dart';
import 'package:photo_manager/photo_manager.dart';

class PhotoManagerMediaRepository implements MediaRepository {
  List<MediaItem> _cache = const <MediaItem>[];

  @override
  Future<MediaPermissionStatus> requestPermission() async {
    final PermissionState permissionState =
        await PhotoManager.requestPermissionExtend();

    if (permissionState == PermissionState.limited) {
      return MediaPermissionStatus.limited;
    }

    if (permissionState.hasAccess) {
      return MediaPermissionStatus.granted;
    }

    return MediaPermissionStatus.denied;
  }

  @override
  Future<List<MediaItem>> fetchAllMedia() async {
    _cache = await _loadAllMedia();
    return List<MediaItem>.unmodifiable(_cache);
  }

  @override
  Future<List<MediaItem>> refreshMedia() {
    return fetchAllMedia();
  }

  @override
  Future<List<DeviceAlbum>> fetchDeviceAlbums() async {
    final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
      type: RequestType.common,
      onlyAll: false,
      filterOption: FilterOptionGroup(
        orders: const <OrderOption>[
          OrderOption(type: OrderOptionType.createDate, asc: false),
        ],
      ),
    );

    final List<DeviceAlbum> albums = <DeviceAlbum>[];
    for (final AssetPathEntity path in paths) {
      final int count = await path.assetCountAsync;
      if (count == 0) {
        continue;
      }

      final List<AssetEntity> coverAssets = await path.getAssetListRange(
        start: 0,
        end: 1,
      );
      if (coverAssets.isEmpty) {
        continue;
      }

      albums.add(
        DeviceAlbum(
          id: path.id,
          name: path.name,
          count: count,
          coverThumbnail: AssetEntityThumbnailRef(coverAssets.first),
        ),
      );
    }
    return albums;
  }

  @override
  Future<List<MediaItem>> fetchMediaForDeviceAlbum(String albumId) async {
    final List<AssetPathEntity> paths = await _fetchPaths(onlyAll: false);

    AssetPathEntity? albumPath;
    for (final AssetPathEntity path in paths) {
      if (path.id == albumId) {
        albumPath = path;
        break;
      }
    }
    if (albumPath == null) {
      return const <MediaItem>[];
    }

    return _fetchMediaFromPath(albumPath);
  }

  @override
  Future<List<MediaItem>> fetchMediaByIds(List<String> mediaIds) async {
    final List<MediaItem> items = <MediaItem>[];
    for (final String mediaId in mediaIds) {
      final AssetEntity? asset = await AssetEntity.fromId(mediaId);
      if (asset == null) {
        continue;
      }
      items.add(_toMediaItem(asset));
    }
    items.sort(
      (MediaItem a, MediaItem b) => b.createdAt.compareTo(a.createdAt),
    );
    return items;
  }

  @override
  Future<List<MediaItem>> fetchFavoriteMedia() async {
    final List<AssetEntity> assets = await _loadAllAssets();
    final List<MediaItem> items = assets
        .where((AssetEntity asset) => asset.isFavorite)
        .map(_toMediaItem)
        .toList(growable: false);
    items.sort(
      (MediaItem a, MediaItem b) => b.createdAt.compareTo(a.createdAt),
    );
    return items;
  }

  @override
  Future<List<MediaItem>> fetchTrashMedia() async {
    if (Platform.isAndroid) {
      final List<MediaItem> trashedByFlag = await _fetchAndroidTrashedMedia();
      if (trashedByFlag.isNotEmpty) {
        return trashedByFlag;
      }
    }

    final List<AssetPathEntity> paths = await _fetchPaths(onlyAll: false);
    AssetPathEntity? trashPath;
    for (final AssetPathEntity path in paths) {
      final String normalized = path.name.trim().toLowerCase();
      if (normalized == 'trash' ||
          normalized == 'recently deleted' ||
          normalized == 'deleted' ||
          normalized == 'recycle bin' ||
          normalized == 'bin') {
        trashPath = path;
        break;
      }
    }

    if (trashPath == null) {
      return const <MediaItem>[];
    }
    return _fetchMediaFromPath(trashPath);
  }

  Future<List<MediaItem>> _fetchAndroidTrashedMedia() async {
    try {
      final String isTrashedColumn = CustomColumns.android.isTrashed;
      final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
        type: RequestType.common,
        onlyAll: true,
        filterOption: CustomFilter.sql(
          where: '$isTrashedColumn = 1',
          orderBy: <OrderByItem>[
            OrderByItem.desc(CustomColumns.base.createDate),
          ],
        ),
      );
      if (paths.isEmpty) {
        return const <MediaItem>[];
      }
      return _fetchMediaFromPath(paths.first);
    } catch (_) {
      return const <MediaItem>[];
    }
  }

  @override
  Future<void> updateSyncStatus(Set<String> syncedMediaIds) async {
    _cache = _cache
        .map(
          (MediaItem item) =>
              item.copyWith(isSynced: syncedMediaIds.contains(item.id)),
        )
        .toList(growable: false);
  }

  Future<List<MediaItem>> _loadAllMedia() async {
    final List<AssetEntity> assets = await _loadAllAssets();
    final List<MediaItem> items = assets
        .map(_toMediaItem)
        .toList(growable: false);
    items.sort(
      (MediaItem a, MediaItem b) => b.createdAt.compareTo(a.createdAt),
    );
    return items;
  }

  Future<List<AssetPathEntity>> _fetchPaths({required bool onlyAll}) {
    return PhotoManager.getAssetPathList(
      type: RequestType.common,
      onlyAll: onlyAll,
      filterOption: FilterOptionGroup(
        orders: const <OrderOption>[
          OrderOption(type: OrderOptionType.createDate, asc: false),
        ],
      ),
    );
  }

  Future<List<AssetEntity>> _loadAllAssets() async {
    final List<AssetPathEntity> paths = await _fetchPaths(onlyAll: true);
    if (paths.isEmpty) {
      return const <AssetEntity>[];
    }
    final AssetPathEntity allMediaPath = paths.first;
    final int totalCount = await allMediaPath.assetCountAsync;
    if (totalCount == 0) {
      return const <AssetEntity>[];
    }
    return allMediaPath.getAssetListRange(start: 0, end: totalCount);
  }

  Future<List<MediaItem>> _fetchMediaFromPath(AssetPathEntity path) async {
    final int count = await path.assetCountAsync;
    if (count == 0) {
      return const <MediaItem>[];
    }
    final List<AssetEntity> assets = await path.getAssetListRange(
      start: 0,
      end: count,
    );
    final List<MediaItem> items = assets
        .map(_toMediaItem)
        .toList(growable: false);
    items.sort(
      (MediaItem a, MediaItem b) => b.createdAt.compareTo(a.createdAt),
    );
    return items;
  }

  MediaItem _toMediaItem(AssetEntity asset) {
    final MediaType mediaType = asset.type == AssetType.video
        ? MediaType.video
        : MediaType.image;

    final DateTime fallbackDate = asset.modifiedDateTime.toLocal();
    final DateTime createDate = asset.createDateTime.toLocal();
    final DateTime resolvedDate = createDate.millisecondsSinceEpoch > 0
        ? createDate
        : fallbackDate;

    return MediaItem(
      id: asset.id,
      type: mediaType,
      createdAt: resolvedDate,
      thumbnail: AssetEntityThumbnailRef(asset),
      isSynced: false,
    );
  }
}
