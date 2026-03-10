import 'package:flutter/material.dart';
import 'package:nimbus/routes/navigation_shell.dart';
import 'package:nimbus/routes/app_routes.dart';
import 'package:nimbus/screens/settings/settings.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final String routeName = AppRoutes.normalize(settings.name);

    if (routeName == AppRoutes.settings) {
      return MaterialPageRoute<void>(
        settings: const RouteSettings(name: AppRoutes.settings),
        builder: (_) => const SettingsScreen(),
      );
    }

    return MaterialPageRoute<void>(
      settings: RouteSettings(name: routeName, arguments: settings.arguments),
      builder: (_) => AppNavigationShell(initialRoute: routeName),
    );
  }
}
