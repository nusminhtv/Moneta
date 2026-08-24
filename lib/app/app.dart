import 'package:flutter/material.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';

/// Root widget. Carries the design-system theme; routes are added by the
/// changes that introduce screens.
class MonetaApp extends StatelessWidget {
  /// Creates the application root.
  const MonetaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Moneta',
      debugShowCheckedModeBanner: false,
      theme: MonetaTheme.dark().toThemeData(),
      home: const Scaffold(body: Center(child: Text('Moneta'))),
    );
  }
}
