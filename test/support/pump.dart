import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';

/// Pumps [child] inside a real Moneta theme.
///
/// Design-system widgets read tokens from context and throw without them, so
/// every widget test goes through here. [theme] lets a test substitute a token
/// set — that substitutability is the reason tokens are a ThemeExtension.
Future<void> pumpMonetaWidget(
  WidgetTester tester,
  Widget child, {
  MonetaTheme? theme,
  Size? surfaceSize,
  EdgeInsets viewPadding = EdgeInsets.zero,
}) async {
  final resolved = theme ?? MonetaTheme.dark();
  if (surfaceSize != null) {
    await tester.binding.setSurfaceSize(surfaceSize);
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }
  await tester.pumpWidget(
    MaterialApp(
      theme: resolved.toThemeData(),
      home: MediaQuery(
        data: MediaQueryData(viewPadding: viewPadding, padding: viewPadding),
        child: Scaffold(body: Center(child: child)),
      ),
    ),
  );
}
