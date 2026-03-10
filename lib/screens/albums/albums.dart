import 'package:flutter/material.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/ion.dart';
import 'package:nimbus/core/media/media_item.dart';
import 'package:nimbus/core/media/media_repository.dart';
import 'package:nimbus/core/media/photo_repository.dart';
import 'package:nimbus/models/app_album.dart';
import 'package:nimbus/models/device_album.dart';
import 'package:nimbus/screens/album_view/album_view.dart';
import 'package:nimbus/screens/albums/album_widgets.dart';
import 'package:nimbus/services/album_repository.dart';
import 'package:nimbus/services/sync_repository.dart';
import 'package:nimbus/services/hive_sync.dart';
import 'package:nimbus/services/hive_trash.dart';
import 'package:nimbus/services/mock_sync.dart';
import 'package:nimbus/services/trash_repository.dart';
import 'package:nimbus/services/prefs_album.dart';
import 'package:nimbus/theme/colors.dart';
import 'package:nimbus/widgets/top_bar.dart';
import 'package:nimbus/widgets/toast.dart';

class AlbumsScreen extends StatefulWidget {
  AlbumsScreen({
    super.key,
    MediaRepository? repository,
    AppAlbumRepository? appAlbumRepository,
    RecentlyDeletedRepository? recentlyDeletedRepository,
    CloudSyncRepository? cloudSyncRepository,
    MockCloudSyncService? cloudSyncService,
  }) : repository = repository ?? PhotoManagerMediaRepository(),
       appAlbumRepository =
           appAlbumRepository ?? SharedPreferencesAppAlbumRepository.instance,
       recentlyDeletedRepository =
           recentlyDeletedRepository ?? HiveRecentlyDeletedRepository.instance,
       cloudSyncRepository =
           cloudSyncRepository ?? HiveCloudSyncRepository.instance,
       cloudSyncService =
           cloudSyncService ??
           MockCloudSyncService(
             cloudSyncRepository ?? HiveCloudSyncRepository.instance,
           );

  final MediaRepository repository;
  final AppAlbumRepository appAlbumRepository;
  final RecentlyDeletedRepository recentlyDeletedRepository;
  final CloudSyncRepository cloudSyncRepository;
  final MockCloudSyncService cloudSyncService;

  @override
  State<AlbumsScreen> createState() => AlbumsScreenState();
}

class AlbumsScreenState extends State<AlbumsScreen>
    with WidgetsBindingObserver {
  List<DeviceAlbum> _deviceAlbums = const <DeviceAlbum>[];
  List<AppAlbum> _appAlbums = const <AppAlbum>[];
  bool _isLoading = true;
  bool _permissionDenied = false;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearching = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadAlbums();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadAlbums();
    }
  }

  Future<void> refreshFromParent() async {
    await _loadAlbums();
  }

  Future<void> _loadAlbums() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final MediaPermissionStatus permissionStatus = await widget.repository
          .requestPermission();
      final List<AppAlbum> appAlbums = await widget.appAlbumRepository
          .listAlbums();

      if (permissionStatus == MediaPermissionStatus.denied) {
        setState(() {
          _isLoading = false;
          _permissionDenied = true;
          _deviceAlbums = const <DeviceAlbum>[];
          _appAlbums = appAlbums;
        });
        return;
      }

      final List<DeviceAlbum> deviceAlbums = await widget.repository
          .fetchDeviceAlbums();

      setState(() {
        _isLoading = false;
        _permissionDenied = false;
        _deviceAlbums = deviceAlbums;
        _appAlbums = appAlbums;
      });
    } catch (_) {
      setState(() {
        _isLoading = false;
        _permissionDenied = false;
        _deviceAlbums = const <DeviceAlbum>[];
        _appAlbums = const <AppAlbum>[];
        _errorMessage = 'Unable to load albums right now.';
      });
    }
  }

  Future<void> _createAlbum() async {
    String draftName = '';
    final String? inputName = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Create Album'),
          content: TextField(
            autofocus: true,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(hintText: 'Album name'),
            onChanged: (String value) {
              draftName = value;
            },
            onSubmitted: (_) {
              Navigator.of(context).pop(draftName.trim());
            },
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(draftName.trim()),
              child: const Text('Create'),
            ),
          ],
        );
      },
    );

    if (inputName == null || !mounted) {
      return;
    }

    final String albumName = inputName.trim();
    if (albumName.isEmpty) {
      AppToast.show(context, 'Album name cannot be empty.');
      return;
    }

    try {
      final bool exists = await widget.appAlbumRepository.existsByName(
        albumName,
      );
      if (!mounted) {
        return;
      }

      if (exists) {
        AppToast.show(context, 'Album name already exists.');
        return;
      }

      await widget.appAlbumRepository.createAlbum(albumName);
      final List<AppAlbum> appAlbums = await widget.appAlbumRepository
          .listAlbums();

      if (!mounted) {
        return;
      }

      setState(() {
        _appAlbums = appAlbums;
      });

      AppToast.show(context, 'Album "$albumName" created.');
    } catch (_) {
      if (!mounted) {
        return;
      }
      AppToast.show(context, 'Could not create album.');
    }
  }

  void _enterSearch() {
    if (_isSearching) {
      return;
    }
    setState(() {
      _isSearching = true;
    });
  }

  void _exitSearch() {
    FocusScope.of(context).unfocus();
    _searchController.clear();
    setState(() {
      _isSearching = false;
      _searchQuery = '';
    });
  }

  void _clearSearchQuery() {
    _searchController.clear();
    _onSearchChanged('');
    FocusScope.of(context).unfocus();
  }

  void _onSearchChanged(String value) {
    if (_searchQuery == value) {
      return;
    }
    setState(() {
      _searchQuery = value;
    });
  }

  List<DeviceAlbum> get _filteredDeviceAlbums {
    final String query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return _deviceAlbums;
    }
    return _deviceAlbums
        .where((DeviceAlbum album) => album.name.toLowerCase().contains(query))
        .toList(growable: false);
  }

  List<AppAlbum> get _filteredAppAlbums {
    final String query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return _appAlbums;
    }
    return _appAlbums
        .where((AppAlbum album) => album.name.toLowerCase().contains(query))
        .toList(growable: false);
  }

  void _openAllDeviceAlbumsPage() {
    FocusScope.of(context).unfocus();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AllDeviceAlbumsPage(
          albums: _filteredDeviceAlbums,
          onAlbumTap: _openDeviceAlbumView,
        ),
      ),
    );
  }

  void _openAllAppAlbumsPage() {
    FocusScope.of(context).unfocus();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AllAppAlbumsPage(
          albums: _filteredAppAlbums,
          onAlbumTap: _openAppAlbumView,
        ),
      ),
    );
  }

  void _openFavoritesPage() {
    FocusScope.of(context).unfocus();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MediaCollectionPage(
          title: 'Favorites',
          loader: () async {
            final Set<String> deletedIds = await widget
                .recentlyDeletedRepository
                .listDeletedIds();
            final List<MediaItem> items = await widget.repository
                .fetchFavoriteMedia();
            return items
                .where((MediaItem item) => !deletedIds.contains(item.id))
                .toList(growable: false);
          },
          emptyMessage: 'No favorites yet.',
        ),
      ),
    );
  }

  void _openTrashPage() {
    FocusScope.of(context).unfocus();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RecentlyDeletedPage(
          repository: widget.repository,
          recentlyDeletedRepository: widget.recentlyDeletedRepository,
        ),
      ),
    );
  }

  Future<void> _openDeviceAlbumView(DeviceAlbum album) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AlbumViewScreen.device(
          album: album,
          mediaRepository: widget.repository,
          appAlbumRepository: widget.appAlbumRepository,
          recentlyDeletedRepository: widget.recentlyDeletedRepository,
          cloudSyncRepository: widget.cloudSyncRepository,
          cloudSyncService: widget.cloudSyncService,
        ),
      ),
    );
    if (!mounted) {
      return;
    }
    await _loadAlbums();
  }

  Future<void> _openAppAlbumView(AppAlbum album) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AlbumViewScreen.app(
          album: album,
          mediaRepository: widget.repository,
          appAlbumRepository: widget.appAlbumRepository,
          recentlyDeletedRepository: widget.recentlyDeletedRepository,
          cloudSyncRepository: widget.cloudSyncRepository,
          cloudSyncService: widget.cloudSyncService,
        ),
      ),
    );
    if (!mounted) {
      return;
    }
    await _loadAlbums();
  }

  PreferredSizeWidget _buildAppBar() {
    if (!_isSearching) {
      return AppTopBar(
        title: 'Albums',
        onMenuPressed: _enterSearch,
        leadingTooltip: 'Search albums',
        leadingIcon: const Iconify(
          Ion.search_outline,
          color: AppColors.textPrimary,
          size: 22,
        ),
      );
    }

    return AppBar(
      automaticallyImplyLeading: false,
      leading: IconButton(
        onPressed: _exitSearch,
        icon: const Iconify(
          Ion.arrow_back,
          color: AppColors.textPrimary,
          size: 22,
        ),
      ),
      titleSpacing: 0,
      title: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        autofocus: true,
        textInputAction: TextInputAction.search,
        onChanged: _onSearchChanged,
        decoration: const InputDecoration(
          hintText: 'Search albums',
          border: InputBorder.none,
          isCollapsed: true,
        ),
      ),
      actions: <Widget>[
        IconButton(
          tooltip: 'Clear',
          onPressed: _searchQuery.isEmpty ? null : _clearSearchQuery,
          icon: const Iconify(
            Ion.close_outline,
            color: AppColors.textPrimary,
            size: 20,
          ),
        ),
      ],
    );
  }

  Widget _buildDeviceAlbumRow(List<DeviceAlbum> deviceAlbums) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_permissionDenied) {
      return const AlbumsEmptyStateCard(
        message: 'Allow gallery permission to view phone albums.',
      );
    }

    if (deviceAlbums.isEmpty) {
      if (_searchQuery.trim().isNotEmpty) {
        return const AlbumsEmptyStateCard(
          message: 'No matching device albums.',
        );
      }
      return const AlbumsEmptyStateCard(message: 'No device albums found.');
    }

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      itemBuilder: (BuildContext context, int index) {
        final DeviceAlbum album = deviceAlbums[index];
        return DeviceAlbumCard(
          album: album,
          width: 118,
          onTap: () => _openDeviceAlbumView(album),
        );
      },
      separatorBuilder: (_, _) => const SizedBox(width: 12),
      itemCount: deviceAlbums.length,
    );
  }

  Widget _buildAppAlbumTile({
    required int index,
    required List<AppAlbum> appAlbums,
    required bool showCreateTile,
  }) {
    if (showCreateTile && index == 0) {
      return CreateAlbumTile(onTap: _createAlbum);
    }

    final int appAlbumIndex = showCreateTile ? index - 1 : index;
    final AppAlbum album = appAlbums[appAlbumIndex];
    return AppAlbumTile(album: album, onTap: () => _openAppAlbumView(album));
  }

  @override
  Widget build(BuildContext context) {
    final List<DeviceAlbum> visibleDeviceAlbums = _filteredDeviceAlbums;
    final List<AppAlbum> visibleAppAlbums = _filteredAppAlbums;
    final bool showCreateTile =
        !(_isSearching && _searchQuery.trim().isNotEmpty);
    final bool canSeeAll = visibleDeviceAlbums.isNotEmpty && !_permissionDenied;
    final bool canSeeAllAppAlbums = visibleAppAlbums.isNotEmpty;
    final bool showSearchEmptyState =
        _searchQuery.trim().isNotEmpty &&
        !_isLoading &&
        visibleDeviceAlbums.isEmpty &&
        visibleAppAlbums.isEmpty;

    return Scaffold(
      appBar: _buildAppBar(),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: RefreshIndicator(
          onRefresh: _loadAlbums,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: <Widget>[
              if (_errorMessage != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                    child: Text(
                      _errorMessage!,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.redAccent),
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 16, 14, 10),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          'Photos on Device',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      TextButton(
                        key: const Key('device-albums-see-all'),
                        onPressed: canSeeAll ? _openAllDeviceAlbumsPage : null,
                        child: const Text('See all'),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 182,
                  child: _buildDeviceAlbumRow(visibleDeviceAlbums),
                ),
              ),
              SliverToBoxAdapter(
                child: AlbumsShortcutButtons(
                  onFavoritesTap: _openFavoritesPage,
                  onTrashTap: _openTrashPage,
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 18, 14, 10),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          'My Albums',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      TextButton(
                        key: const Key('app-albums-see-all'),
                        onPressed: canSeeAllAppAlbums
                            ? _openAllAppAlbumsPage
                            : null,
                        child: const Text('See all'),
                      ),
                    ],
                  ),
                ),
              ),
              if (showSearchEmptyState)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(14, 10, 14, 120),
                    child: AlbumsEmptyStateCard(
                      message: 'No albums match your search.',
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 110),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 4,
                          childAspectRatio: 0.72,
                        ),
                    delegate: SliverChildBuilderDelegate(
                      (BuildContext context, int index) => _buildAppAlbumTile(
                        index: index,
                        appAlbums: visibleAppAlbums,
                        showCreateTile: showCreateTile,
                      ),
                      childCount:
                          visibleAppAlbums.length + (showCreateTile ? 1 : 0),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
