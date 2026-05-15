import 'package:flutter/material.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/ion.dart';
import 'package:nimbus/core/media/media_item.dart';
import 'package:nimbus/core/media/media_repository.dart';
import 'package:nimbus/core/media/photo_repository.dart';
import 'package:nimbus/core/media/thumbnail_ref.dart';
import 'package:nimbus/models/app_album.dart';
import 'package:nimbus/models/device_album.dart';
import 'package:nimbus/screens/album_view/album_view.dart';
import 'package:nimbus/screens/albums/album_widgets.dart';
import 'package:nimbus/services/album_repository.dart';
import 'package:nimbus/services/mock_face_recognition_service.dart';
import 'package:nimbus/services/prefs_album.dart';
import 'package:nimbus/theme/colors.dart';

class SearchScreen extends StatefulWidget {
  SearchScreen({
    super.key,
    MediaRepository? mediaRepository,
    AppAlbumRepository? appAlbumRepository,
  }) : mediaRepository = mediaRepository ?? PhotoManagerMediaRepository(),
       appAlbumRepository =
           appAlbumRepository ?? SharedPreferencesAppAlbumRepository.instance;

  final MediaRepository mediaRepository;
  final AppAlbumRepository appAlbumRepository;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with WidgetsBindingObserver {
  static final List<_SearchPlaceholder> _fallbackPeople =
      <_SearchPlaceholder>[
        _SearchPlaceholder.icon('Family', Ion.person_outline),
        _SearchPlaceholder.icon('Friends', Ion.person_outline),
        _SearchPlaceholder.icon('Coworkers', Ion.person_outline),
        _SearchPlaceholder.icon('Favorites', Ion.person_outline),
      ];
  static final List<_SearchPlaceholder> _peopleFromPermissionDenied =
      <_SearchPlaceholder>[
        _SearchPlaceholder.icon('Family', Ion.person_outline),
        _SearchPlaceholder.icon('Friends', Ion.person_outline),
        _SearchPlaceholder.icon('Coworkers', Ion.person_outline),
        _SearchPlaceholder.icon('Favorites', Ion.person_outline),
      ];
  static final List<_SearchPlaceholder> _locations = <_SearchPlaceholder>[
    _SearchPlaceholder.icon('Chennai', Ion.location_outline),
    _SearchPlaceholder.icon('Bengaluru', Ion.location_outline),
    _SearchPlaceholder.icon('Mumbai', Ion.location_outline),
    _SearchPlaceholder.icon('Hyderabad', Ion.location_outline),
  ];
  static final List<_SearchPlaceholder> _fileTypes = <_SearchPlaceholder>[
    _SearchPlaceholder.icon('Images', Ion.image_outline),
    _SearchPlaceholder.icon('Videos', Ion.videocam_outline),
    _SearchPlaceholder.icon('Screenshots', Ion.image_outline),
    _SearchPlaceholder.icon('GIFs', Ion.film_outline),
  ];

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final MockFaceRecognitionService _mockFaceRecognitionService =
      MockFaceRecognitionService();
  List<DeviceAlbum> _deviceAlbums = const <DeviceAlbum>[];
  List<AppAlbum> _appAlbums = const <AppAlbum>[];
  List<_SearchPlaceholder> _people = _fallbackPeople;
  bool _isLoading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final MediaPermissionStatus permission = await widget.mediaRepository
          .requestPermission();
      final List<AppAlbum> appAlbums = await widget.appAlbumRepository
          .listAlbums();
      final bool denied = permission == MediaPermissionStatus.denied;
      final List<DeviceAlbum> deviceAlbums = denied
          ? const <DeviceAlbum>[]
          : await widget.mediaRepository.fetchDeviceAlbums();
      final List<_SearchPlaceholder> peoplePreviews;
      if (denied) {
        peoplePreviews = _peopleFromPermissionDenied;
      } else {
        final List<MediaItem> mediaItems = (await widget.mediaRepository
                .fetchAllMedia())
            .take(48)
            .toList(growable: false);
        peoplePreviews = _mockFaceRecognitionService
            .buildPeoplePreview(mediaItems)
            .map(_SearchPlaceholder.fromMockIdentity)
            .toList(growable: false);
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _deviceAlbums = deviceAlbums;
        _appAlbums = appAlbums;
        _people = peoplePreviews;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _people = _fallbackPeople;
        _deviceAlbums = const <DeviceAlbum>[];
        _appAlbums = const <AppAlbum>[];
        _isLoading = false;
      });
    }
  }

  void _onQueryChanged(String value) {
    if (_query == value) {
      return;
    }
    setState(() {
      _query = value;
    });
  }

  List<_SearchAlbumEntry> get _albumEntries {
    final String query = _query.trim().toLowerCase();
    final List<_SearchAlbumEntry> device = _deviceAlbums
        .where(
          (DeviceAlbum album) =>
              query.isEmpty || album.name.toLowerCase().contains(query),
        )
        .map(_SearchAlbumEntry.device)
        .toList(growable: false);
    final List<_SearchAlbumEntry> app = _appAlbums
        .where(
          (AppAlbum album) =>
              query.isEmpty || album.name.toLowerCase().contains(query),
        )
        .map(_SearchAlbumEntry.app)
        .toList(growable: false);
    return <_SearchAlbumEntry>[...device, ...app];
  }

  List<_SearchPlaceholder> _filterPlaceholders(
    List<_SearchPlaceholder> source,
  ) {
    final String query = _query.trim().toLowerCase();
    if (query.isEmpty) {
      return source;
    }
    return source
        .where((item) => item.label.toLowerCase().contains(query))
        .toList(growable: false);
  }

  Future<void> _openAlbum(_SearchAlbumEntry entry) async {
    if (entry.deviceAlbum != null) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => AlbumViewScreen.device(
            album: entry.deviceAlbum!,
            mediaRepository: widget.mediaRepository,
            appAlbumRepository: widget.appAlbumRepository,
          ),
        ),
      );
    } else if (entry.appAlbum != null) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => AlbumViewScreen.app(
            album: entry.appAlbum!,
            mediaRepository: widget.mediaRepository,
            appAlbumRepository: widget.appAlbumRepository,
          ),
        ),
      );
    }
    if (!mounted) {
      return;
    }
    await _load();
  }

  void _openSectionSeeAll(String title, List<_SearchPlaceholder> items) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _SearchSectionPage(title: title, items: items),
      ),
    );
  }

  void _openAlbumsSeeAll() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            _SearchAlbumsPage(albums: _albumEntries, onAlbumTap: _openAlbum),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<_SearchPlaceholder> people = _filterPlaceholders(_people);
    final List<_SearchPlaceholder> locations = _filterPlaceholders(_locations);
    final List<_SearchPlaceholder> fileTypes = _filterPlaceholders(_fileTypes);
    final List<_SearchAlbumEntry> albums = _albumEntries;

    return Scaffold(
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusScope.of(context).unfocus(),
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 110),
              children: <Widget>[
                _SearchBar(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  onChanged: _onQueryChanged,
                ),
                const SizedBox(height: 16),
                _SectionHeader(
                  title: 'People',
                  onChevronTap: () => _openSectionSeeAll('People', people),
                ),
                const SizedBox(height: 8),
                _SearchPlaceholderRow(items: people),
                const SizedBox(height: 18),
                _SectionHeader(
                  title: 'Albums',
                  onChevronTap: _openAlbumsSeeAll,
                ),
                const SizedBox(height: 8),
                if (_isLoading)
                  const SizedBox(
                    height: 110,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  _SearchAlbumsRow(albums: albums, onAlbumTap: _openAlbum),
                const SizedBox(height: 18),
                _SectionHeader(
                  title: 'Locations',
                  onChevronTap: () =>
                      _openSectionSeeAll('Locations', locations),
                ),
                const SizedBox(height: 8),
                _SearchPlaceholderRow(items: locations),
                const SizedBox(height: 18),
                _SectionHeader(
                  title: 'File types',
                  onChevronTap: () =>
                      _openSectionSeeAll('File types', fileTypes),
                ),
                const SizedBox(height: 8),
                _SearchPlaceholderRow(items: fileTypes),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchSectionPage extends StatelessWidget {
  const _SearchSectionPage({required this.title, required this.items});

  final String title;
  final List<_SearchPlaceholder> items;

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
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 14,
          crossAxisSpacing: 12,
          childAspectRatio: 0.72,
        ),
        itemBuilder: (BuildContext context, int index) {
          return _SearchPreviewTile(
            label: items[index].label,
            preview: _SearchPlaceholderPreview(item: items[index]),
          );
        },
      ),
    );
  }
}

class _SearchAlbumsPage extends StatelessWidget {
  const _SearchAlbumsPage({required this.albums, required this.onAlbumTap});

  final List<_SearchAlbumEntry> albums;
  final ValueChanged<_SearchAlbumEntry> onAlbumTap;

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
          'Albums',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      body: albums.isEmpty
          ? const Center(child: Text('No albums found.'))
          : GridView.builder(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
              itemCount: albums.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.72,
              ),
              itemBuilder: (BuildContext context, int index) {
                final _SearchAlbumEntry album = albums[index];
                return _SearchPreviewTile(
                  label: album.name,
                  onTap: () => onAlbumTap(album),
                  preview: album.deviceAlbum != null
                      ? ThumbnailRefImage(
                          thumbnail: album.deviceAlbum!.coverThumbnail,
                        )
                      : AppAlbumCover(
                          mediaIds:
                              album.appAlbum?.mediaIds ?? const <String>[],
                          localMediaPaths:
                              album.appAlbum?.localMediaPaths ??
                              const <String>[],
                          coverMediaId: album.appAlbum?.coverMediaId,
                          coverLocalPath: album.appAlbum?.coverLocalPath,
                        ),
                );
              },
            ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: <Widget>[
          const Iconify(
            Ion.search_outline,
            color: AppColors.textSecondary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              decoration: const InputDecoration(
                hintText: 'Search',
                border: InputBorder.none,
              ),
              onChanged: onChanged,
            ),
          ),
          if (controller.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                controller.clear();
                onChanged('');
                focusNode.unfocus();
              },
              child: const Iconify(Ion.close_outline, size: 18),
            ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.onChevronTap});

  final String title;
  final VoidCallback onChevronTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        IconButton(
          onPressed: onChevronTap,
          icon: const Iconify(Ion.chevron_right, size: 18),
        ),
      ],
    );
  }
}

class _SearchPlaceholderRow extends StatelessWidget {
  const _SearchPlaceholderRow({required this.items});

  final List<_SearchPlaceholder> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox(
        height: 112,
        child: Center(child: Text('No results')),
      );
    }

    return SizedBox(
      height: 112,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (BuildContext context, int index) {
          final _SearchPlaceholder item = items[index];
          return _SearchPreviewTile(
            width: 88,
            label: item.label,
            preview: _SearchPlaceholderPreview(item: item),
          );
        },
      ),
    );
  }
}

class _SearchAlbumsRow extends StatelessWidget {
  const _SearchAlbumsRow({required this.albums, required this.onAlbumTap});

  final List<_SearchAlbumEntry> albums;
  final ValueChanged<_SearchAlbumEntry> onAlbumTap;

  @override
  Widget build(BuildContext context) {
    if (albums.isEmpty) {
      return const SizedBox(
        height: 112,
        child: Center(child: Text('No album results')),
      );
    }

    return SizedBox(
      height: 126,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: albums.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (BuildContext context, int index) {
          final _SearchAlbumEntry entry = albums[index];
          return _SearchPreviewTile(
            width: 98,
            onTap: () => onAlbumTap(entry),
            label: entry.name,
            preview: entry.deviceAlbum != null
                ? ThumbnailRefImage(
                    thumbnail: entry.deviceAlbum!.coverThumbnail,
                  )
                : AppAlbumCover(
                    mediaIds: entry.appAlbum?.mediaIds ?? const <String>[],
                    localMediaPaths:
                        entry.appAlbum?.localMediaPaths ?? const <String>[],
                    coverMediaId: entry.appAlbum?.coverMediaId,
                    coverLocalPath: entry.appAlbum?.coverLocalPath,
                  ),
          );
        },
      ),
    );
  }
}

class _SearchPreviewTile extends StatelessWidget {
  const _SearchPreviewTile({
    required this.label,
    required this.preview,
    this.width = 98,
    this.onTap,
  });

  final String label;
  final Widget preview;
  final double width;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Widget child = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        AspectRatio(
          aspectRatio: 1,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: preview,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );

    return SizedBox(
      width: width,
      child: onTap == null
          ? child
          : InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: onTap,
              child: child,
            ),
    );
  }
}

class _SearchPlaceholder {
  const _SearchPlaceholder.icon(this.label, this.icon)
    : localThumbnail = null,
      mockAssetPath = null;

  factory _SearchPlaceholder.fromMockIdentity(MockFaceIdentity identity) {
    return _SearchPlaceholder._(
      label: identity.label,
      icon: Ion.person_outline,
      localThumbnail: identity.localThumbnail,
      mockAssetPath: identity.mockAssetPath,
    );
  }

  const _SearchPlaceholder._({
    required this.label,
    required this.icon,
    this.localThumbnail,
    this.mockAssetPath,
  });

  final String label;
  final String icon;
  final ThumbnailRef? localThumbnail;
  final String? mockAssetPath;
}

class _SearchPlaceholderPreview extends StatelessWidget {
  const _SearchPlaceholderPreview({required this.item});

  final _SearchPlaceholder item;

  @override
  Widget build(BuildContext context) {
    if (item.localThumbnail != null) {
      return ThumbnailRefImage(thumbnail: item.localThumbnail!);
    }
    if (item.mockAssetPath != null) {
      return Image.asset(item.mockAssetPath!, fit: BoxFit.cover);
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Iconify(item.icon, color: AppColors.textSecondary, size: 20),
      ),
    );
  }
}

class _SearchAlbumEntry {
  const _SearchAlbumEntry._({
    required this.name,
    this.deviceAlbum,
    this.appAlbum,
  });

  factory _SearchAlbumEntry.device(DeviceAlbum album) {
    return _SearchAlbumEntry._(name: album.name, deviceAlbum: album);
  }

  factory _SearchAlbumEntry.app(AppAlbum album) {
    return _SearchAlbumEntry._(name: album.name, appAlbum: album);
  }

  final String name;
  final DeviceAlbum? deviceAlbum;
  final AppAlbum? appAlbum;
}
