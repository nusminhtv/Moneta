import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';
import 'package:moneta/features/onboarding/presentation/onboarding_providers.dart';
import 'package:moneta/features/onboarding/presentation/splash_screen.dart';

void main() {
  const minimum = Duration(milliseconds: 900);

  // The decision is overridden with a future under the test's own control, not
  // read from a real store. A `testWidgets` body runs in FakeAsync, so awaiting
  // sqflite here would hang forever instead of failing — see CLAUDE.md.
  Future<List<bool>> pumpSplash(
    WidgetTester tester, {
    required Future<bool> decision,
    Duration minimumDuration = minimum,
  }) async {
    final decided = <bool>[];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          shouldShowOnboardingProvider.overrideWith((ref) => decision),
        ],
        child: MaterialApp(
          theme: MonetaTheme.dark().toThemeData(),
          home: SplashScreen(
            minimumDuration: minimumDuration,
            onDecided: ({required showOnboarding}) =>
                decided.add(showOnboarding),
          ),
        ),
      ),
    );
    return decided;
  }

  group('appearance', () {
    testWidgets('shows the brand copy transcribed from Figma 71:2', (
      tester,
    ) async {
      await pumpSplash(tester, decision: Future.value(true));
      expect(find.text('Moneta'), findsOneWidget);
      expect(find.text('Personal finance, on your device'), findsOneWidget);
      await tester.pump(minimum);
    });

    testWidgets('offers nothing to tap — the design has no control', (
      tester,
    ) async {
      await pumpSplash(tester, decision: Future.value(true));
      expect(find.byType(ButtonStyleButton), findsNothing);
      expect(find.byType(GestureDetector), findsNothing);
      await tester.pump(minimum);
    });
  });

  group('the decision', () {
    testWidgets('reports the introduction is due on a first run', (
      tester,
    ) async {
      final decided = await pumpSplash(tester, decision: Future.value(true));
      await tester.pump(minimum);
      expect(decided, [true]);
    });

    testWidgets('reports it is not due once completion is recorded', (
      tester,
    ) async {
      final decided = await pumpSplash(tester, decision: Future.value(false));
      await tester.pump(minimum);
      expect(decided, [false]);
    });
  });

  group('timing', () {
    testWidgets('a fast read still waits out the minimum, so it cannot flash', (
      tester,
    ) async {
      // The read is already complete before the first frame.
      final decided = await pumpSplash(tester, decision: Future.value(true));

      await tester.pump(minimum - const Duration(milliseconds: 1));
      expect(
        decided,
        isEmpty,
        reason: 'handed over early — the splash would flash',
      );

      await tester.pump(const Duration(milliseconds: 1));
      expect(decided, [true]);
    });

    testWidgets('a slow read holds the splash past the minimum', (
      tester,
    ) async {
      final slow = Completer<bool>();
      final decided = await pumpSplash(tester, decision: slow.future);

      await tester.pump(minimum * 3);
      expect(
        decided,
        isEmpty,
        reason: 'handed over before knowing which screen to show',
      );

      slow.complete(false);
      await tester.pump();
      expect(decided, [false]);
    });

    testWidgets('hands over exactly once', (tester) async {
      final decided = await pumpSplash(tester, decision: Future.value(true));
      await tester.pump(minimum);
      await tester.pump(minimum);
      await tester.pump(const Duration(seconds: 5));
      expect(decided, hasLength(1));
    });

    testWidgets('says nothing after it has been navigated away from', (
      tester,
    ) async {
      final slow = Completer<bool>();
      final decided = await pumpSplash(tester, decision: slow.future);
      await tester.pump(minimum);

      // Replace the splash: whatever resolves later must not call back into a
      // dead State.
      // The same override list: Riverpod asserts if a rebuilt ProviderScope
      // changes how many overrides it carries.
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            shouldShowOnboardingProvider.overrideWith((ref) => slow.future),
          ],
          child: MaterialApp(
            theme: MonetaTheme.dark().toThemeData(),
            home: const SizedBox.shrink(),
          ),
        ),
      );
      slow.complete(true);
      await tester.pump();

      expect(decided, isEmpty);
    });
  });
}
