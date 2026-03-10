import 'package:flutter/material.dart';
import 'package:nimbus/routes/app_routes.dart';
import 'package:nimbus/screens/albums/albums.dart';
import 'package:nimbus/screens/home/home.dart';
import 'package:nimbus/screens/search/search.dart';
import 'package:nimbus/widgets/bottom_nav.dart';

class AppNavigationShell extends StatefulWidget {
  const AppNavigationShell({super.key, required this.initialRoute});

  final String initialRoute;

  @override
  State<AppNavigationShell> createState() => _AppNavigationShellState();
}

class _AppNavigationShellState extends State<AppNavigationShell> {
  int _selectedIndex = 0;
  bool _isHomeSelectionMode = false;
  final GlobalKey<AlbumsScreenState> _albumsKey =
      GlobalKey<AlbumsScreenState>();
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = <Widget>[
      HomeScreen(onSelectionModeChanged: _onHomeSelectionModeChanged),
      AlbumsScreen(key: _albumsKey),
      SearchScreen(),
    ];
    final int initialIndex = AppRoutes.indexOf(widget.initialRoute);
    _selectedIndex = initialIndex == 2 ? 0 : initialIndex;
  }

  void _onHomeSelectionModeChanged(bool isSelectionMode) {
    if (_isHomeSelectionMode == isSelectionMode) {
      return;
    }
    setState(() {
      _isHomeSelectionMode = isSelectionMode;
    });
  }

  void _onDestinationSelected(int index) {
    if (index == 2) {
      return;
    }
    if (index == _selectedIndex) {
      if (index == 1) {
        _albumsKey.currentState?.refreshFromParent();
      }
      return;
    }
    setState(() {
      _selectedIndex = index;
    });
    if (index == 1) {
      _albumsKey.currentState?.refreshFromParent();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<void>(
      canPop: _selectedIndex == 0,
      onPopInvokedWithResult: (bool didPop, void result) {
        if (didPop) {
          return;
        }
        if (_selectedIndex != 0) {
          _onDestinationSelected(0);
        }
      },
      child: Scaffold(
        extendBody: true,
        appBar: null,
        body: IndexedStack(index: _selectedIndex, children: _pages),
        bottomNavigationBar: (_selectedIndex == 0 && _isHomeSelectionMode)
            ? const SizedBox.shrink()
            : AppBottomNavBar(
                selectedIndex: _selectedIndex,
                onDestinationSelected: _onDestinationSelected,
              ),
      ),
    );
  }
}
