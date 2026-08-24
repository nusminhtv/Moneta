import 'package:flutter/material.dart';

/// Root widget. The theme and router are wired in by feature changes;
/// this shell exists so the project always builds between changes.
class MonetaApp extends StatelessWidget {
  /// Creates the application root.
  const MonetaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Moneta',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(child: Text('Moneta')),
      ),
    );
  }
}
