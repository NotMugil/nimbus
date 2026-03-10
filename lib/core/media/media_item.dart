import 'package:nimbus/core/media/media_type.dart';
import 'package:nimbus/core/media/thumbnail_ref.dart';

class MediaItem {
  const MediaItem({
    required this.id,
    required this.type,
    required this.createdAt,
    required this.thumbnail,
    required this.isSynced,
  });

  final String id;
  final MediaType type;
  final DateTime createdAt;
  final ThumbnailRef thumbnail;
  final bool isSynced;

  MediaItem copyWith({
    String? id,
    MediaType? type,
    DateTime? createdAt,
    ThumbnailRef? thumbnail,
    bool? isSynced,
  }) {
    return MediaItem(
      id: id ?? this.id,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      thumbnail: thumbnail ?? this.thumbnail,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
