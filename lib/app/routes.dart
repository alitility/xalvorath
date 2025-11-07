import 'package:flutter/material.dart';
import '../features/shell/shell_screen.dart';
import '../features/settings/settings_screen.dart';

class AppRoutes {
  static const home = '/';
  static const settings = '/settings';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute(builder: (_) => const ShellScreen());
      case AppRoutes.settings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      default:
        return MaterialPageRoute(builder: (_) => const ShellScreen());
    }
  }
}

