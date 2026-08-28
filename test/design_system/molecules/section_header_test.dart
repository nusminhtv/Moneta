import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/design_system/molecules/section_header.dart';
import 'package:moneta/design_system/tokens/colors.dart';
import 'package:moneta/design_system/tokens/spacing.dart';

import '../../support/pump.dart';

void main() {
  const colors = MonetaColors.dark();

  Future<void> pumpHeader(
    WidgetTester tester, {
    String title = 'Recent activity',
    String? actionLabel,
    VoidCallback? onAction,
    double width = 353,
  }) {
    return pumpMonetaWidget(
      tester,
      SizedBox(
        width: width,
        child: SectionHeader(
          title: title,
          actionLabel: actionLabel,
          onAction: onAction,
        ),
      ),
      surfaceSize: const Size(420, 160),
    );
  }

  testWidgets('renders the title without an action by default', (tester) async {
    await pumpHeader(tester);

    expect(find.text('Recent activity'), findsOneWidget);
    expect(find.byKey(SectionHeader.actionKey), findsNothing);
  });

  testWidgets('renders and reports the optional action', (tester) async {
    var taps = 0;
    await pumpHeader(
      tester,
      actionLabel: 'See all',
      onAction: () => taps++,
    );

    final action = tester.widget<Text>(find.text('See all'));
    expect(action.style!.color, colors.brand);

    await tester.tap(find.byKey(SectionHeader.actionKey));
    expect(taps, 1);
  });

  testWidgets('long title and action stay inside the header', (tester) async {
    await pumpHeader(
      tester,
      title: 'A very long section title that should truncate cleanly',
      actionLabel: 'A long action',
      width: 220,
    );

    expect(tester.takeException(), isNull);
    final header = tester.getRect(find.byType(SectionHeader));
    for (final text in find.byType(Text).evaluate()) {
      final rect = tester.getRect(find.byWidget(text.widget));
      expect(rect.left, greaterThanOrEqualTo(header.left));
      expect(rect.right, lessThanOrEqualTo(header.right));
    }
  });

  group('the title gets the room it needs', () {
    testWidgets('a title that fits is not ellipsised by the action', (
      tester,
    ) async {
      // The action used to be `Flexible`, which defaults to flex: 1 — so the
      // row split its free space evenly and the title got half the width no
      // matter how little the action needed. On Home, "Recent transactions"
      // ellipsised with about 100px to spare. Measured, not eyeballed: the
      // rendered title box must be wide enough for the text it was given.
      await tester.binding.setSurfaceSize(const Size(393, 200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pumpMonetaWidget(
        tester,
        const SizedBox(
          width: 353,
          child: SectionHeader(
            title: 'Recent transactions',
            actionLabel: 'See all',
          ),
        ),
        surfaceSize: const Size(393, 200),
      );

      final titleBox = tester.getRect(find.text('Recent transactions'));
      final actionBox = tester.getRect(find.text('See all'));

      // Font-independent on purpose. `flutter test` renders with a metrics-only
      // font where every glyph is exactly `fontSize` wide, so "does the title
      // fit" measures that font, not the design — CLAUDE.md is explicit. What is
      // measurable is the *gap* the layout leaves between the two: with the
      // action as `Flexible(flex: 1)` the row handed it half the free space and
      // the gap ballooned, while the title was squeezed. With the action at its
      // intrinsic size the gap is exactly the spacer.
      expect(
        actionBox.left - titleBox.right,
        moreOrLessEquals(MonetaSpacing.spaceMd, epsilon: 1),
        reason:
            'the action was allocated space it does not use, '
            'squeezing the title',
      );
    });

    testWidgets('a genuinely over-long title still truncates', (tester) async {
      await pumpMonetaWidget(
        tester,
        const SizedBox(
          width: 353,
          child: SectionHeader(
            title:
                'A section title far longer than any row could show without '
                'cutting it off somewhere near the middle',
            actionLabel: 'See all',
          ),
        ),
        surfaceSize: const Size(393, 200),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('See all'), findsOneWidget);
    });
  });
}
