import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/design_system/molecules/onboarding_illustration.dart';
import 'package:moneta/design_system/molecules/pagination_dots.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';
import 'package:moneta/features/onboarding/domain/onboarding_slide.dart';
import 'package:moneta/features/onboarding/presentation/onboarding_screen.dart';

void main() {
  Future<int> pumpOnboarding(WidgetTester tester) async {
    var finished = 0;
    await tester.binding.setSurfaceSize(const Size(393, 852));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: MonetaTheme.dark().toThemeData(),
        home: OnboardingScreen(onFinished: () => finished++),
      ),
    );
    await tester.pumpAndSettle();
    return finished;
  }

  int activeDot(WidgetTester tester) {
    final dots = tester.widget<MonetaPaginationDots>(
      find.byType(MonetaPaginationDots),
    );
    return dots.activeIndex;
  }

  Future<void> tapNext(WidgetTester tester) async {
    await tester.tap(find.byKey(OnboardingScreen.forwardKey));
    await tester.pumpAndSettle();
  }

  group('frame', () {
    testWidgets('starts on the first slide', (tester) async {
      await pumpOnboarding(tester);
      expect(find.text(OnboardingSlide.accounts.title), findsOneWidget);
      expect(activeDot(tester), 0);
    });

    testWidgets('the indicator has one dot per slide', (tester) async {
      await pumpOnboarding(tester);
      final dots = tester.widget<MonetaPaginationDots>(
        find.byType(MonetaPaginationDots),
      );
      expect(dots.count, OnboardingSlide.values.length);
    });

    testWidgets('Skip is offered on the first two slides', (tester) async {
      await pumpOnboarding(tester);
      expect(find.byKey(OnboardingScreen.skipKey), findsOneWidget);
      await tapNext(tester);
      expect(find.byKey(OnboardingScreen.skipKey), findsOneWidget);
    });

    testWidgets('Skip is not offered on the last slide', (tester) async {
      await pumpOnboarding(tester);
      await tapNext(tester);
      await tapNext(tester);
      expect(find.byKey(OnboardingScreen.skipKey), findsNothing);
    });

    testWidgets('the frame does not shift when Skip disappears', (
      tester,
    ) async {
      // Asserted on the PageView, not on the forward button. The button sits
      // below an Expanded and so is pinned to the bottom — it cannot move
      // whatever happens above it. That version of this test passed even with
      // the reserved Skip slot collapsed to height 0, which is exactly the
      // 44px jump the slot exists to prevent.
      await pumpOnboarding(tester);
      final page = tester.getRect(find.byType(PageView));
      final illustration = tester.getRect(
        find.byType(OnboardingIllustration).first,
      );

      await tapNext(tester);
      await tapNext(tester);

      expect(
        tester.getRect(find.byType(PageView)),
        page,
        reason: 'the slide area moved when Skip went away',
      );
      expect(
        tester.getRect(find.byType(OnboardingIllustration).first).top,
        illustration.top,
        reason: 'the illustration jumped on the last slide',
      );
      // And the button still holds its place, which was the original claim.
      expect(
        tester.getRect(find.byKey(OnboardingScreen.forwardKey)).top,
        greaterThan(page.bottom - 1),
      );
    });
  });

  group('advancing', () {
    testWidgets('Next moves to the next slide and the indicator follows', (
      tester,
    ) async {
      await pumpOnboarding(tester);
      await tapNext(tester);
      expect(find.text(OnboardingSlide.budgets.title), findsOneWidget);
      expect(activeDot(tester), 1);
    });

    testWidgets('the label becomes Get started on the last slide', (
      tester,
    ) async {
      await pumpOnboarding(tester);
      expect(find.text('Next'), findsOneWidget);
      await tapNext(tester);
      await tapNext(tester);
      expect(find.text('Get started'), findsOneWidget);
      expect(find.text('Next'), findsNothing);
    });

    testWidgets('swiping moves the indicator too', (tester) async {
      await pumpOnboarding(tester);
      await tester.drag(
        find.text(OnboardingSlide.accounts.title),
        const Offset(-400, 0),
      );
      await tester.pumpAndSettle();
      expect(activeDot(tester), 1);
    });
  });

  group('finishing', () {
    testWidgets('the forward action on the last slide finishes', (
      tester,
    ) async {
      var finished = 0;
      await tester.binding.setSurfaceSize(const Size(393, 852));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          theme: MonetaTheme.dark().toThemeData(),
          home: OnboardingScreen(onFinished: () => finished++),
        ),
      );
      await tester.pumpAndSettle();

      await tapNext(tester);
      await tapNext(tester);
      expect(finished, 0, reason: 'not finished until the last tap');
      await tapNext(tester);
      expect(finished, 1);
    });

    testWidgets('Skip finishes immediately', (tester) async {
      var finished = 0;
      await tester.binding.setSurfaceSize(const Size(393, 852));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          theme: MonetaTheme.dark().toThemeData(),
          home: OnboardingScreen(onFinished: () => finished++),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(OnboardingScreen.skipKey));
      await tester.pumpAndSettle();
      expect(finished, 1);
    });
  });

  group('rendering', () {
    testWidgets('every slide shows its own title, body and glyph', (
      tester,
    ) async {
      await pumpOnboarding(tester);
      for (final slide in OnboardingSlide.values) {
        expect(find.text(slide.title), findsOneWidget, reason: slide.name);
        // The body and the glyph were in this test's name and in none of its
        // assertions, so the illustration could ignore its glyph entirely and
        // this still passed.
        expect(find.text(slide.body), findsOneWidget, reason: slide.name);
        final illustration = tester.widget<OnboardingIllustration>(
          find.byType(OnboardingIllustration).first,
        );
        expect(illustration.glyph, slide.glyph, reason: slide.name);
        expect(illustration.chartSlot, slide.chartSlot, reason: slide.name);
        if (!slide.isLast) await tapNext(tester);
      }
    });

    testWidgets('no overflow at the design size', (tester) async {
      await pumpOnboarding(tester);
      expect(tester.takeException(), isNull);
      await tapNext(tester);
      expect(tester.takeException(), isNull);
      await tapNext(tester);
      expect(tester.takeException(), isNull);
    });
  });
}
