import 'package:flutter/material.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/ion.dart';
import 'package:nimbus/routes/app_routes.dart';
import 'package:nimbus/theme/colors.dart';

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({
    super.key,
    required this.title,
    this.onMenuPressed,
    this.onProfilePressed,
    this.leadingIcon,
    this.leadingTooltip,
    this.showTrailingAction = true,
  });

  final String title;
  final VoidCallback? onMenuPressed;
  final VoidCallback? onProfilePressed;
  final Widget? leadingIcon;
  final String? leadingTooltip;
  final bool showTrailingAction;

  void _navigateToSettings(BuildContext context) {
    if (ModalRoute.of(context)?.settings.name == AppRoutes.settings) {
      return;
    }
    Navigator.of(context).pushNamed(AppRoutes.settings);
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      titleTextStyle: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      leading: IconButton(
        onPressed: onProfilePressed ?? () => _navigateToSettings(context),
        icon: const Iconify(
          Ion.person_circle_outline,
          color: AppColors.textPrimary,
          size: 24,
        ),
      ),
      actions: showTrailingAction
          ? <Widget>[
              IconButton(
                tooltip: leadingTooltip,
                onPressed: onMenuPressed ?? () {},
                icon:
                    leadingIcon ??
                    const Iconify(
                      Ion.menu_outline,
                      color: AppColors.textPrimary,
                      size: 24,
                    ),
              ),
            ]
          : const <Widget>[],
    );
  }
}
