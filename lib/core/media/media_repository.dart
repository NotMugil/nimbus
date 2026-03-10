import 'package:nimbus/core/media/media_item.dart';
import 'package:nimbus/models/device_album.dart';

enum MediaPermissionStatus { granted, limited, denied }

abstract interface class MediaRepository {
  Future<MediaPermissionStatus> requestPermission();

  Future<List<MediaItem>> fetchAllMedia();

  Future<List<MediaItem>> refreshMedia();

  Future<List<DeviceAlbum>> fetchDeviceAlbums();

  Future<List<MediaItem>> fetchMediaForDeviceAlbum(String albumId);

  Future<List<MediaItem>> fetchMediaByIds(List<String> mediaIds);

  Future<List<MediaItem>> fetchFavoriteMedia();

  Future<List<MediaItem>> fetchTrashMedia();

  Future<void> updateSyncStatus(Set<String> syncedMediaIds);
}
