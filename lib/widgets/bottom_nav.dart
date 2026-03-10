import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/ion.dart';
import 'package:nimbus/theme/colors.dart';

class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  NavigationDestination _destination({
    required int index,
    required String label,
    required String selectedIcon,
    required String unselectedIcon,
  }) {
    final bool isSelected = selectedIndex == index;
    return NavigationDestination(
      icon: Iconify(
        isSelected ? selectedIcon : unselectedIcon,
        color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
        size: 20,
      ),
      label: label,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xAA111111),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: NavigationBar(
                    height: 58,
                    backgroundColor: Colors.transparent,
                    surfaceTintColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    labelBehavior:
                        NavigationDestinationLabelBehavior.alwaysHide,
                    indicatorColor: AppColors.surfaceVariant,
                    selectedIndex: selectedIndex,
                    onDestinationSelected: onDestinationSelected,
                    destinations: <NavigationDestination>[
                      _destination(
                        index: 0,
                        label: 'Home',
                        selectedIcon: Ion.home,
                        unselectedIcon: Ion.home_outline,
                      ),
                      _destination(
                        index: 1,
                        label: 'Albums',
                        selectedIcon: Ion.albums,
                        unselectedIcon: Ion.albums_outline,
                      ),
                      _destination(
                        index: 2,
                        label: 'Search',
                        selectedIcon: Ion.search,
                        unselectedIcon: Ion.search_outline,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
