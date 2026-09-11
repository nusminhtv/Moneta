import 'dart:io';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/design_system/atoms/moneta_badge.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';
import 'package:moneta/design_system/tokens/colors.dart';
import 'package:moneta/design_system/tokens/spacing.dart';

import '../../support/api_surface.dart';
import '../../support/pump.dart';

void main() {
  const colors = MonetaColors.dark();
  final text = MonetaTheme.dark().text;

  /// The authored pairs from `17:32`, written out rather than derived.
  ///
  /// Derivation is exactly what this table exists to catch: four tones follow
  /// `*Subtle` + the tone colour and `Neutral` does not, so a rule that reads
  /// a token family by name is wrong for one of five and would be wrong
  /// silently.
  final pairs = <MonetaBadgeTone, (Color, Color)>{
    MonetaBadgeTone.success: (colors.incomeSubtle, colors.income),
    MonetaBadgeTone.warning: (colors.warningSubtle, colors.warning),
    MonetaBadgeTone.danger: (colors.expenseSubtle, colors.expense),
    MonetaBadgeTone.info: (colors.infoSubtle, colors.info),
    MonetaBadgeTone.neutral: (colors.surfaceRaised, colors.textSecondary),
  };

  Future<void> pumpBadge(
    WidgetTester tester, {
    required MonetaBadgeTone tone,
    MonetaBadgeSize size = MonetaBadgeSize.sm,
    bool dot = true,
    String label = 'Label',
    double? width,
    TextScaler textScaler = TextScaler.noScaling,
  }) {
    final badge = MonetaBadge(label: label, tone: tone, size: size, dot: dot);
    return pumpMonetaWidget(
      tester,
      width == null ? badge : SizedBox(width: width, child: badge),
      textScaler: textScaler,
    );
  }

  /// The pill's own box — the [DecoratedBox] carrying the fill.
  Finder pill() => find
      .descendant(
        of: find.byType(MonetaBadge),
        matching: find.byType(DecoratedBox),
      )
      .first;

  BoxDecoration pillDecoration(WidgetTester tester) =>
      tester.widget<DecoratedBox>(pill()).decoration as BoxDecoration;

  group('every tone carries its authored pair', () {
    for (final entry in pairs.entries) {
      for (final size in MonetaBadgeSize.values) {
        testWidgets('${entry.key.name} at ${size.name}', (tester) async {
          await pumpBadge(tester, tone: entry.key, size: size);

          final (fill, labelColor) = entry.value;
          expect(pillDecoration(tester).color, fill);
          expect(
            tester.widget<Text>(find.text('Label')).style!.color,
            labelColor,
          );
          // The dot takes the label's colour, which is why it is not a second
          // channel and why the label is mandatory.
          expect(
            (tester
                        .widget<DecoratedBox>(
                          // `.first` is the nearest ancestor: the dot's own
                          // box. Without it this also matches the pill, and
                          // the finder fails as ambiguous.
                          find
                              .ancestor(
                                of: find.byKey(MonetaBadge.dotKey),
                                matching: find.byType(DecoratedBox),
                              )
                              .first,
                        )
                        .decoration
                    as BoxDecoration)
                .color,
            labelColor,
          );
        });
      }
    }

    testWidgets('Neutral is not a subtle pair', (tester) async {
      await pumpBadge(tester, tone: MonetaBadgeTone.neutral);
      final fill = pillDecoration(tester).color;
      expect(fill, colors.surfaceRaised);
      // Named individually: the four subtle fills are the plausible wrong
      // answers, and `isNot(anyOf(...))` says so rather than leaving it to the
      // table above.
      expect(
        fill,
        isNot(
          anyOf(
            colors.incomeSubtle,
            colors.warningSubtle,
            colors.expenseSubtle,
            colors.infoSubtle,
          ),
        ),
      );
    });

    testWidgets('the ten pairs are ten distinct pairs', (tester) async {
      // Guards the table itself: if two tones resolved to the same colours the
      // per-tone tests above would all still pass.
      final seen = <String>{};
      for (final tone in MonetaBadgeTone.values) {
        await pumpBadge(tester, tone: tone);
        seen.add(
          '${pillDecoration(tester).color}'
          '/${tester.widget<Text>(find.text('Label')).style!.color}',
        );
      }
      expect(seen, hasLength(MonetaBadgeTone.values.length));
    });
  });

  group('the shape and the box', () {
    testWidgets('the pill is a pill', (tester) async {
      await pumpBadge(tester, tone: MonetaBadgeTone.info);
      expect(
        pillDecoration(tester).borderRadius,
        MonetaTheme.dark().radii.borderPill,
      );
    });

    testWidgets('22 tall at Sm and 26 at Md', (tester) async {
      // The authored totals. Asserted as literals *and* against the type
      // token, because the paddings alone can be right while the box is wrong.
      await pumpBadge(tester, tone: MonetaBadgeTone.info);
      expect(tester.getSize(pill()).height, 22);
      expect(MonetaBadgeSize.sm.heightIn(text), 22);

      await pumpBadge(
        tester,
        tone: MonetaBadgeTone.info,
        size: MonetaBadgeSize.md,
      );
      expect(tester.getSize(pill()).height, 26);
      expect(MonetaBadgeSize.md.heightIn(text), 26);
    });

    testWidgets('the four metrics that change with size, and only those', (
      tester,
    ) async {
      expect(MonetaBadgeSize.sm.horizontalPadding, MonetaSpacing.spaceSm);
      expect(MonetaBadgeSize.md.horizontalPadding, 10);
      expect(MonetaBadgeSize.sm.verticalPadding, 3);
      expect(MonetaBadgeSize.md.verticalPadding, 5);
      expect(MonetaBadgeSize.sm.gap, MonetaSpacing.spaceXs);
      expect(MonetaBadgeSize.md.gap, 5);
      expect(MonetaBadgeSize.sm.dotSize, 5);
      expect(MonetaBadgeSize.md.dotSize, 6);

      // And the two things that must NOT change: the type style and both
      // colours. Asserted across sizes rather than assumed.
      for (final size in MonetaBadgeSize.values) {
        await pumpBadge(
          tester,
          tone: MonetaBadgeTone.warning,
          size: size,
        );
        expect(
          tester.widget<Text>(find.text('Label')).style!.fontSize,
          text.labelSm.fontSize,
        );
        expect(pillDecoration(tester).color, colors.warningSubtle);
        expect(
          tester.widget<Text>(find.text('Label')).style!.color,
          colors.warning,
        );
      }
    });

    testWidgets('the dot measures 5 at Sm and 6 at Md', (tester) async {
      for (final size in MonetaBadgeSize.values) {
        await pumpBadge(tester, tone: MonetaBadgeTone.success, size: size);
        expect(
          tester.getSize(find.byKey(MonetaBadge.dotKey)),
          Size.square(size.dotSize),
        );
      }
    });
  });

  group('the label is the cue that survives', () {
    testWidgets('a dotless badge still carries its text', (tester) async {
      await pumpBadge(tester, tone: MonetaBadgeTone.success, dot: false);
      expect(find.byKey(MonetaBadge.dotKey), findsNothing);
      expect(find.text('Label'), findsOneWidget);
    });

    testWidgets('the dot is present by default', (tester) async {
      await pumpBadge(tester, tone: MonetaBadgeTone.success);
      expect(find.byKey(MonetaBadge.dotKey), findsOneWidget);
    });

    test('an empty or blank label asserts', () {
      expect(
        () => MonetaBadge(label: '', tone: MonetaBadgeTone.info),
        throwsAssertionError,
      );
      expect(
        () => MonetaBadge(label: '   ', tone: MonetaBadgeTone.info),
        throwsAssertionError,
      );
    });

    test('no raw design value can be supplied', () {
      // Reads the widget's **field declarations**, not its constructor's
      // parameter list. Every parameter here is `this.x`, so the type lives
      // outside that list — `change-verifier` put a `Color? tint` through the
      // public API of all five of this change's components and the whole gate
      // stayed green. See `test/support/api_surface.dart`.
      final source = File(
        'lib/design_system/atoms/moneta_badge.dart',
      ).readAsStringSync();
      expect(rawDesignValueFields(source, 'MonetaBadge'), isEmpty);
    });

    test('and that check can itself fail', () {
      // The counterfeit. Without it, the assertion above is indistinguishable
      // from one that always passes — which is exactly what it replaced.
      expect(
        rawDesignValueFields(
          'class MonetaBadge extends StatelessWidget {\n'
              '  /// A doc comment mentioning final Color, which is not a field.\n'
              '  final Color? tint;\n'
              '}\n',
          'MonetaBadge',
        ),
        ['final Color? tint;'],
      );
      expect(
        rawDesignValueFields('class Other {}', 'MonetaBadge'),
        ['<class MonetaBadge not found in source>'],
      );
    });
  });

  group('a label bigger than its space', () {
    testWidgets('truncates on one line inside a 120px parent', (tester) async {
      await pumpBadge(
        tester,
        tone: MonetaBadgeTone.danger,
        label: 'Renews on the fourteenth of every month',
        width: 120,
      );
      expect(tester.takeException(), isNull);

      final paragraph = tester.renderObject<RenderParagraph>(
        find.text('Renews on the fourteenth of every month'),
      );
      expect(paragraph.didExceedMaxLines, isTrue);
      expect(tester.getSize(pill()).width, lessThanOrEqualTo(120));
      // Height is the Sm box, so it truncated rather than wrapping.
      expect(tester.getSize(pill()).height, 22);
    });

    testWidgets('and at 1.0, 1.3 and 2.0 platform text', (tester) async {
      // Containment, not width: under the metrics-only test font a width is a
      // fact about that font, not about the design. See CLAUDE.md.
      for (final scale in <double>[1, 1.3, 2]) {
        await pumpBadge(
          tester,
          tone: MonetaBadgeTone.danger,
          label: 'Renews on the fourteenth',
          width: 120,
          textScaler: TextScaler.linear(scale),
        );
        expect(
          tester.takeException(),
          isNull,
          reason: 'overflowed at ${scale}x text',
        );
        expect(tester.getSize(pill()).width, lessThanOrEqualTo(120));
      }
    });
  });
}
