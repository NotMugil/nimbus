import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

abstract class ThumbnailRef {
  const ThumbnailRef();
}

class AssetEntityThumbnailRef extends ThumbnailRef {
  const AssetEntityThumbnailRef(this.asset);

  final AssetEntity asset;
}

class PlaceholderThumbnailRef extends ThumbnailRef {
  const PlaceholderThumbnailRef({required this.color});

  final Color color;
}
