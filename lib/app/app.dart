// lib/app/app.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/services/audio_service.dart';
import '../core/services/ui_settings.dart';
import '../core/theme/app_theme.dart';
import 'routes.dart';

class XalvorathApp extends StatelessWidget {
  const XalvorathApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AudioService()),
        ChangeNotifierProvider(create: (_) => UiSettings()),
      ],
      child: MaterialApp(
        title: 'Xalvorath PC',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        onGenerateRoute: AppRoutes.onGenerateRoute,
        initialRoute: AppRoutes.home,
      ),
    );
  }
}
