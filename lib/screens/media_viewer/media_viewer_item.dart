import 'package:nimbus/core/media/media_item.dart';
import 'package:nimbus/core/media/media_type.dart';

enum MediaViewerItemSource { asset, localFile }

class MediaViewerItem {
  const MediaViewerItem._({
    required this.id,
    required this.source,
    required this.isVideo,
    this.assetItem,
    this.localFilePath,
  });

  factory MediaViewerItem.asset(MediaItem item) {
    return MediaViewerItem._(
      id: item.id,
      source: MediaViewerItemSource.asset,
      isVideo: item.type == MediaType.video,
      assetItem: item,
    );
  }

  factory MediaViewerItem.localFile({
    required String path,
    required bool isVideo,
  }) {
    return MediaViewerItem._(
      id: path,
      source: MediaViewerItemSource.localFile,
      isVideo: isVideo,
      localFilePath: path,
    );
  }

  final String id;
  final MediaViewerItemSource source;
  final bool isVideo;
  final MediaItem? assetItem;
  final String? localFilePath;
}
