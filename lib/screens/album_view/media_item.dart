import 'package:nimbus/core/media/media_item.dart';
import 'package:nimbus/core/media/media_type.dart';

enum AlbumViewMediaSource { asset, localFile }

class AlbumViewMediaItem {
  const AlbumViewMediaItem._({
    required this.id,
    required this.source,
    required this.isVideo,
    required this.createdAt,
    this.assetItem,
    this.localFilePath,
  });

  factory AlbumViewMediaItem.asset(MediaItem item) {
    return AlbumViewMediaItem._(
      id: item.id,
      source: AlbumViewMediaSource.asset,
      isVideo: item.type == MediaType.video,
      createdAt: item.createdAt,
      assetItem: item,
    );
  }

  factory AlbumViewMediaItem.localFile({
    required String id,
    required String path,
    required bool isVideo,
    required DateTime createdAt,
  }) {
    return AlbumViewMediaItem._(
      id: id,
      source: AlbumViewMediaSource.localFile,
      isVideo: isVideo,
      createdAt: createdAt,
      localFilePath: path,
    );
  }

  final String id;
  final AlbumViewMediaSource source;
  final bool isVideo;
  final DateTime createdAt;
  final MediaItem? assetItem;
  final String? localFilePath;
}
