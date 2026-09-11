import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';

/// Pumps [child] inside a real Moneta theme.
///
/// Design-system widgets read tokens from context and throw without them, so
/// every widget test goes through here. [theme] lets a test substitute a token
/// set — that substitutability is the reason tokens are a ThemeExtension.
///
/// [textScaler] is the platform's text size. It defaults to no scaling, which
/// is *not* the only case worth testing: a line box a fraction taller than its
/// nominal height is enough to overflow a layout with no slack, and text
/// scaling is how a test reproduces that on demand.
Future<void> pumpMonetaWidget(
  WidgetTester tester,
  Widget child, {
  MonetaTheme? theme,
  Size? surfaceSize,
  EdgeInsets viewPadding = EdgeInsets.zero,
  TextScaler textScaler = TextScaler.noScaling,
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
        data: MediaQueryData(
          viewPadding: viewPadding,
          padding: viewPadding,
          textScaler: textScaler,
        ),
        child: Scaffold(body: Center(child: child)),
      ),
    ),
  );
}
