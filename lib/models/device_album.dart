import 'package:nimbus/core/media/thumbnail_ref.dart';

class DeviceAlbum {
  const DeviceAlbum({
    required this.id,
    required this.name,
    required this.count,
    required this.coverThumbnail,
  });

  final String id;
  final String name;
  final int count;
  final ThumbnailRef coverThumbnail;
}
