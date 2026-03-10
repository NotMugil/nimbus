import 'dart:typed_data';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/ion.dart';
import 'package:nimbus/core/media/media_item.dart';
import 'package:nimbus/core/media/media_repository.dart';
import 'package:nimbus/core/media/media_type.dart';
import 'package:nimbus/core/media/thumbnail_ref.dart';
import 'package:nimbus/models/app_album.dart';
import 'package:nimbus/models/device_album.dart';
import 'package:nimbus/screens/image_view/image_view.dart';
import 'package:nimbus/screens/media_viewer/media_viewer.dart';
import 'package:nimbus/screens/media_viewer/media_viewer_item.dart';
import 'package:nimbus/services/hive_trash.dart';
import 'package:nimbus/services/trash_repository.dart';
import 'package:nimbus/theme/colors.dart';
import 'package:nimbus/widgets/toast.dart';
import 'package:photo_manager/photo_manager.dart';

class AlbumsEmptyStateCard extends StatelessWidget {
  const AlbumsEmptyStateCard({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }
}

class DeviceAlbumCard extends StatelessWidget {
  const DeviceAlbumCard({
    super.key,
    required this.album,
    this.width,
    this.onTap,
  });

  final DeviceAlbum album;
  final double? width;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Widget card = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        AspectRatio(
          aspectRatio: 1,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: ThumbnailRefImage(thumbnail: album.coverThumbnail),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          album.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );

    final Widget wrapped = onTap == null
        ? card
        : InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: card,
          );

    if (width == null) {
      return wrapped;
    }
    return SizedBox(width: width, child: wrapped);
  }
}

class CreateAlbumTile extends StatelessWidget {
  const CreateAlbumTile({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: const Key('create-app-album-tile'),
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AspectRatio(
            aspectRatio: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(child: Iconify(Ion.add, size: 30)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create Album',
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class AppAlbumTile extends StatelessWidget {
  const AppAlbumTile({super.key, required this.album, this.onTap});

  final AppAlbum album;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: Key('app-album-tile-${album.id}'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: AppAlbumCover(
                mediaIds: album.mediaIds,
                localMediaPaths: album.localMediaPaths,
                coverMediaId: album.coverMediaId,
                coverLocalPath: album.coverLocalPath,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            album.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class AlbumsShortcutButtons extends StatelessWidget {
  const AlbumsShortcutButtons({
    super.key,
    required this.onFavoritesTap,
    required this.onTrashTap,
  });

  final VoidCallback onFavoritesTap;
  final VoidCallback onTrashTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _ShortcutButton(
              label: 'Favorites',
              icon: Ion.star_outline,
              onTap: onFavoritesTap,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ShortcutButton(
              label: 'Trash',
              icon: Ion.trash_outline,
              onTap: onTrashTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShortcutButton extends StatelessWidget {
  const _ShortcutButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Iconify(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class AllDeviceAlbumsPage extends StatelessWidget {
  const AllDeviceAlbumsPage({super.key, required this.albums, this.onAlbumTap});

  final List<DeviceAlbum> albums;
  final ValueChanged<DeviceAlbum>? onAlbumTap;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          key: const Key('all-device-albums-back'),
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Iconify(Ion.arrow_back, color: Colors.white, size: 20),
        ),
        title: Text(
          'Photos on Device',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      body: albums.isEmpty
          ? const Center(child: Text('No device albums found.'))
          : GridView.builder(
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 18),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.78,
              ),
              itemCount: albums.length,
              itemBuilder: (BuildContext context, int index) {
                return DeviceAlbumCard(
                  album: albums[index],
                  onTap: onAlbumTap == null
                      ? null
                      : () => onAlbumTap!(albums[index]),
                );
              },
            ),
    );
  }
}

class AllAppAlbumsPage extends StatelessWidget {
  const AllAppAlbumsPage({super.key, required this.albums, this.onAlbumTap});

  final List<AppAlbum> albums;
  final ValueChanged<AppAlbum>? onAlbumTap;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          key: const Key('all-app-albums-back'),
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Iconify(Ion.arrow_back, color: Colors.white, size: 20),
        ),
        title: Text(
          'My Albums',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      body: albums.isEmpty
          ? const Center(child: Text('No app albums found.'))
          : GridView.builder(
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 18),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 8,
                childAspectRatio: 0.78,
              ),
              itemCount: albums.length,
              itemBuilder: (BuildContext context, int index) {
                return AppAlbumTile(
                  album: albums[index],
                  onTap: onAlbumTap == null
                      ? null
                      : () => onAlbumTap!(albums[index]),
                );
              },
            ),
    );
  }
}

class MediaCollectionPage extends StatefulWidget {
  const MediaCollectionPage({
    super.key,
    required this.title,
    required this.loader,
    required this.emptyMessage,
  });

  final String title;
  final Future<List<MediaItem>> Function() loader;
  final String emptyMessage;

  @override
  State<MediaCollectionPage> createState() => _MediaCollectionPageState();
}

class _MediaCollectionPageState extends State<MediaCollectionPage> {
  bool _isLoading = true;
  List<MediaItem> _items = const <MediaItem>[];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final List<MediaItem> items = await widget.loader();
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _items = items;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _items = const <MediaItem>[];
        _errorMessage = 'Could not load media.';
      });
    }
  }

  Future<void> _openMediaAt(int index) async {
    final List<MediaViewerItem> viewerItems = _items
        .map(MediaViewerItem.asset)
        .toList(growable: false);
    if (viewerItems.isEmpty) {
      return;
    }

    final MediaViewerItem tapped = viewerItems[index];
    if (!tapped.isVideo) {
      final List<MediaViewerItem> images = viewerItems
          .where((MediaViewerItem item) => !item.isVideo)
          .toList(growable: false);
      final int imageIndex = images.indexWhere(
        (MediaViewerItem item) => item.id == tapped.id,
      );
      if (imageIndex >= 0) {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ImageViewScreen.items(
              items: images,
              initialIndex: imageIndex,
              isFromAppAlbum: false,
            ),
          ),
        );
        if (mounted) {
          await _load();
        }
        return;
      }
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            MediaViewerScreen.items(items: viewerItems, initialIndex: index),
      ),
    );
    if (mounted) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Iconify(Ion.arrow_back, color: Colors.white, size: 20),
        ),
        title: Text(
          widget.title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: Builder(
          builder: (BuildContext context) {
            if (_isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (_errorMessage != null) {
              return Center(child: Text(_errorMessage!));
            }
            if (_items.isEmpty) {
              return Center(child: Text(widget.emptyMessage));
            }

            return GridView.builder(
              padding: const EdgeInsets.all(2),
              itemCount: _items.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 2,
                mainAxisSpacing: 2,
              ),
              itemBuilder: (BuildContext context, int index) {
                final MediaItem item = _items[index];
                return GestureDetector(
                  onTap: () => _openMediaAt(index),
                  child: Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      ThumbnailRefImage(thumbnail: item.thumbnail),
                      if (item.type == MediaType.video)
                        const Center(
                          child: Iconify(
                            Ion.play_circle,
                            color: Colors.white60,
                            size: 34,
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class RecentlyDeletedPage extends StatefulWidget {
  RecentlyDeletedPage({
    super.key,
    required this.repository,
    RecentlyDeletedRepository? recentlyDeletedRepository,
  }) : recentlyDeletedRepository =
           recentlyDeletedRepository ?? HiveRecentlyDeletedRepository.instance;

  final MediaRepository repository;
  final RecentlyDeletedRepository recentlyDeletedRepository;

  @override
  State<RecentlyDeletedPage> createState() => _RecentlyDeletedPageState();
}

class _RecentlyDeletedPageState extends State<RecentlyDeletedPage> {
  bool _isLoading = true;
  bool _isRecovering = false;
  String? _errorMessage;
  List<MediaItem> _items = const <MediaItem>[];
  Set<String> _selectedIds = <String>{};

  bool get _isSelectionMode => _selectedIds.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final List<MediaItem> all = await widget.repository.fetchAllMedia();
      final Set<String> deletedIds = await widget.recentlyDeletedRepository
          .listDeletedIds();
      final List<MediaItem> matched =
          all
              .where((MediaItem item) => deletedIds.contains(item.id))
              .toList(growable: false)
            ..sort(
              (MediaItem a, MediaItem b) => b.createdAt.compareTo(a.createdAt),
            );

      final Set<String> matchedIds = matched
          .map((MediaItem item) => item.id)
          .toSet();
      final Set<String> staleIds = deletedIds.difference(matchedIds);
      if (staleIds.isNotEmpty) {
        await widget.recentlyDeletedRepository.restore(staleIds);
      }

      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _items = matched;
        _selectedIds = _selectedIds.intersection(matchedIds);
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _items = const <MediaItem>[];
        _errorMessage = 'Could not load recently deleted media.';
      });
    }
  }

  Future<void> _recoverSelected() async {
    if (_selectedIds.isEmpty || _isRecovering) {
      return;
    }
    setState(() {
      _isRecovering = true;
    });
    try {
      await widget.recentlyDeletedRepository.restore(_selectedIds);
      final int recoveredCount = _selectedIds.length;
      _selectedIds = <String>{};
      await _load();
      if (!mounted) {
        return;
      }
      AppToast.show(context, '$recoveredCount item(s) recovered');
    } finally {
      if (mounted) {
        setState(() {
          _isRecovering = false;
        });
      }
    }
  }

  Future<void> _openMediaAt(int index) async {
    final List<MediaViewerItem> viewerItems = _items
        .map(MediaViewerItem.asset)
        .toList(growable: false);
    if (viewerItems.isEmpty) {
      return;
    }

    final MediaViewerItem tapped = viewerItems[index];
    if (!tapped.isVideo) {
      final List<MediaViewerItem> images = viewerItems
          .where((MediaViewerItem item) => !item.isVideo)
          .toList(growable: false);
      final int imageIndex = images.indexWhere(
        (MediaViewerItem item) => item.id == tapped.id,
      );
      if (imageIndex >= 0) {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ImageViewScreen.items(
              items: images,
              initialIndex: imageIndex,
              isFromAppAlbum: false,
            ),
          ),
        );
        if (mounted) {
          await _load();
        }
        return;
      }
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            MediaViewerScreen.items(items: viewerItems, initialIndex: index),
      ),
    );
    if (mounted) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: _isSelectionMode
              ? () => setState(() => _selectedIds = <String>{})
              : () => Navigator.of(context).maybePop(),
          icon: const Iconify(Ion.arrow_back, color: Colors.white, size: 20),
        ),
        title: Text(
          _isSelectionMode ? '${_selectedIds.length} selected' : 'Trash',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        actions: _isSelectionMode
            ? <Widget>[
                TextButton(
                  onPressed: _isRecovering ? null : _recoverSelected,
                  child: const Text('Recover'),
                ),
              ]
            : const <Widget>[],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: Builder(
          builder: (BuildContext context) {
            if (_isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (_errorMessage != null) {
              return Center(child: Text(_errorMessage!));
            }
            if (_items.isEmpty) {
              return const Center(child: Text('No recently deleted items.'));
            }

            return GridView.builder(
              padding: const EdgeInsets.all(2),
              itemCount: _items.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 2,
                mainAxisSpacing: 2,
              ),
              itemBuilder: (BuildContext context, int index) {
                final MediaItem item = _items[index];
                final bool isSelected = _selectedIds.contains(item.id);
                return GestureDetector(
                  onLongPress: () {
                    setState(() {
                      if (isSelected) {
                        _selectedIds.remove(item.id);
                      } else {
                        _selectedIds.add(item.id);
                      }
                    });
                  },
                  onTap: () {
                    if (_isSelectionMode) {
                      setState(() {
                        if (isSelected) {
                          _selectedIds.remove(item.id);
                        } else {
                          _selectedIds.add(item.id);
                        }
                      });
                      return;
                    }
                    _openMediaAt(index);
                  },
                  child: Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      ThumbnailRefImage(thumbnail: item.thumbnail),
                      if (item.type == MediaType.video)
                        const Center(
                          child: Iconify(
                            Ion.play_circle,
                            color: Colors.white60,
                            size: 34,
                          ),
                        ),
                      if (isSelected)
                        Container(
                          color: const Color(0x66000000),
                          alignment: Alignment.topRight,
                          padding: const EdgeInsets.all(6),
                          child: const Iconify(
                            Ion.checkmark_circle,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class AppAlbumCover extends StatelessWidget {
  const AppAlbumCover({
    super.key,
    required this.mediaIds,
    required this.localMediaPaths,
    this.coverMediaId,
    this.coverLocalPath,
  });

  final List<String> mediaIds;
  final List<String> localMediaPaths;
  final String? coverMediaId;
  final String? coverLocalPath;

  @override
  Widget build(BuildContext context) {
    if (coverLocalPath != null && coverLocalPath!.isNotEmpty) {
      final File localPreview = File(coverLocalPath!);
      if (localPreview.existsSync()) {
        return Image.file(localPreview, fit: BoxFit.cover);
      }
    }

    if (coverMediaId != null && coverMediaId!.isNotEmpty) {
      return FutureBuilder<AssetEntity?>(
        future: AssetEntity.fromId(coverMediaId!),
        builder: (BuildContext context, AsyncSnapshot<AssetEntity?> snapshot) {
          final AssetEntity? asset = snapshot.data;
          if (asset == null) {
            return _fallbackFromAlbumContent();
          }
          return FutureBuilder<Uint8List?>(
            future: asset.thumbnailDataWithSize(
              const ThumbnailSize.square(500),
              quality: 85,
            ),
            builder: (BuildContext context, AsyncSnapshot<Uint8List?> bytes) {
              if (bytes.hasData && bytes.data != null) {
                return Image.memory(bytes.data!, fit: BoxFit.cover);
              }
              return _fallbackFromAlbumContent();
            },
          );
        },
      );
    }

    return _fallbackFromAlbumContent();
  }

  Widget _fallbackFromAlbumContent() {
    if (mediaIds.isEmpty && localMediaPaths.isNotEmpty) {
      final File localPreview = File(localMediaPaths.first);
      if (localPreview.existsSync()) {
        return Image.file(localPreview, fit: BoxFit.cover);
      }
    }

    if (mediaIds.isEmpty) {
      return const ColoredBox(color: AppColors.surfaceVariant);
    }

    return FutureBuilder<AssetEntity?>(
      future: AssetEntity.fromId(mediaIds.first),
      builder: (BuildContext context, AsyncSnapshot<AssetEntity?> snapshot) {
        final AssetEntity? asset = snapshot.data;
        if (asset == null) {
          return const ColoredBox(color: AppColors.surfaceVariant);
        }

        return FutureBuilder<Uint8List?>(
          future: asset.thumbnailDataWithSize(
            const ThumbnailSize.square(500),
            quality: 85,
          ),
          builder: (BuildContext context, AsyncSnapshot<Uint8List?> bytes) {
            if (bytes.hasData && bytes.data != null) {
              return Image.memory(bytes.data!, fit: BoxFit.cover);
            }
            return const ColoredBox(color: AppColors.surfaceVariant);
          },
        );
      },
    );
  }
}

class ThumbnailRefImage extends StatelessWidget {
  const ThumbnailRefImage({super.key, required this.thumbnail});

  final ThumbnailRef thumbnail;

  @override
  Widget build(BuildContext context) {
    if (thumbnail is PlaceholderThumbnailRef) {
      return ColoredBox(color: (thumbnail as PlaceholderThumbnailRef).color);
    }

    if (thumbnail is AssetEntityThumbnailRef) {
      final AssetEntity asset = (thumbnail as AssetEntityThumbnailRef).asset;
      return FutureBuilder<Uint8List?>(
        future: asset.thumbnailDataWithSize(
          const ThumbnailSize.square(360),
          quality: 80,
        ),
        builder: (BuildContext context, AsyncSnapshot<Uint8List?> snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            return Image.memory(snapshot.data!, fit: BoxFit.cover);
          }
          return const ColoredBox(color: AppColors.surfaceVariant);
        },
      );
    }

    return const ColoredBox(color: AppColors.surfaceVariant);
  }
}
