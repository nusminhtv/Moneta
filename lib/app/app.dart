import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:moneta/app/router.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';

/// Root widget. Carries the design-system theme and the router.
class MonetaApp extends StatefulWidget {
  /// Creates the application root.
  const MonetaApp({super.key});

  @override
  State<MonetaApp> createState() => _MonetaAppState();
}

class _MonetaAppState extends State<MonetaApp> {
  late final GoRouter _router = buildRouter();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Moneta',
      debugShowCheckedModeBanner: false,
      theme: MonetaTheme.dark().toThemeData(),
      routerConfig: _router,
    );
  }
}
