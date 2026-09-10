import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/design_system/atoms/moneta_circular_progress.dart';
import 'package:moneta/design_system/molecules/progress_bar.dart';
import 'package:moneta/design_system/tokens/colors.dart';

import '../../support/pump.dart';

void main() {
  const colors = MonetaColors.dark();

  Future<void> pumpRing(
    WidgetTester tester,
    double fraction, {
    MonetaCircularProgressSize size = MonetaCircularProgressSize.md,
  }) => pumpMonetaWidget(
    tester,
    MonetaCircularProgress(fraction: fraction, size: size),
    surfaceSize: const Size(200, 200),
  );

  group('the colour rule is shared with the bar, not copied', () {
    test('ring and bar agree at every threshold', () {
      // Two threshold tables drift. This asserts there is one: if the ring
      // grows its own thresholds, some fraction will disagree.
      for (final f in [0.0, 0.4, 0.79, 0.8, 0.99, 1.0, 1.01, 1.4]) {
        expect(
          MonetaCircularProgress.arcColorFor(f, colors),
          MonetaProgressBar.fillColorFor(f, colors),
          reason: 'ring and bar disagree at $f',
        );
      }
    });

    test('the three states are three different colours', () {
      final under = MonetaCircularProgress.arcColorFor(0.4, colors);
      final near = MonetaCircularProgress.arcColorFor(0.9, colors);
      final over = MonetaCircularProgress.arcColorFor(1.2, colors);
      expect({under, near, over}, hasLength(3));
      expect(under, colors.income);
      expect(near, colors.warning);
      expect(over, colors.expense);
    });
  });

  group('sizes', () {
    testWidgets('each renders at its authored diameter', (tester) async {
      for (final (size, diameter) in [
        (MonetaCircularProgressSize.sm, 48.0),
        (MonetaCircularProgressSize.md, 72.0),
        (MonetaCircularProgressSize.lg, 120.0),
      ]) {
        await pumpRing(tester, 0.62, size: size);
        expect(
          tester.getSize(find.byType(MonetaCircularProgress)),
          Size(diameter, diameter),
          reason: '$size',
        );
      }
    });

    testWidgets('small carries no label, medium and large do', (tester) async {
      await pumpRing(tester, 0.62, size: MonetaCircularProgressSize.sm);
      expect(find.byType(Text), findsNothing);

      await pumpRing(tester, 0.62, size: MonetaCircularProgressSize.md);
      expect(find.text('62%'), findsOneWidget);

      await pumpRing(tester, 0.62, size: MonetaCircularProgressSize.lg);
      expect(find.text('62%'), findsOneWidget);
    });

    testWidgets('the two labelled sizes use different type styles', (
      tester,
    ) async {
      // Figma gives Md label/md and Lg display/amount-md. One style for both
      // would make the hero ring read like an inline one.
      await pumpRing(tester, 0.62, size: MonetaCircularProgressSize.md);
      final md = tester.widget<Text>(find.text('62%')).style!;

      await pumpRing(tester, 0.62, size: MonetaCircularProgressSize.lg);
      final lg = tester.widget<Text>(find.text('62%')).style!;

      expect(lg.fontSize, greaterThan(md.fontSize!));
      expect(lg.fontFamily, isNot(md.fontFamily));
    });
  });

  group('what the ring actually paints', () {
    // Nothing asserted this. Swapping arcColor and trackColor in the painter
    // drew the progress arc in track grey and left all 1196 tests green -- the
    // flagship requirement of this component, unguarded. The parity tests above
    // compare two identical expressions to each other, which is not the same as
    // checking what reaches the canvas.
    //
    // Correction (insight-components, task 3.1): the commit that added these
    // tests also rewrote the painter to build a fresh Paint per draw, and said
    // the shared mutated Paint was why the swap went unnoticed. It was not.
    // Reverting the painter to one shared instance leaves these fourteen tests
    // passing, so the aliasing story was wrong; the assertions below are what
    // catch the swap, and their absence is what let it through.
    testWidgets('under the threshold the arc is drawn in income', (
      tester,
    ) async {
      await pumpRing(tester, 0.4);
      expect(
        find.byType(CustomPaint).last,
        paints
          ..arc(color: colors.track)
          ..arc(color: colors.income),
      );
    });

    testWidgets('near the limit the arc is drawn in warning', (tester) async {
      await pumpRing(tester, 0.9);
      expect(
        find.byType(CustomPaint).last,
        paints
          ..arc(color: colors.track)
          ..arc(color: colors.warning),
      );
    });

    testWidgets('over the limit the arc is drawn in expense', (tester) async {
      await pumpRing(tester, 1.2);
      expect(
        find.byType(CustomPaint).last,
        paints
          ..arc(color: colors.track)
          ..arc(color: colors.expense),
      );
    });

    testWidgets('the track is painted first, so the arc sits on top', (
      tester,
    ) async {
      // Reversed, the track would cover the progress it is meant to sit under.
      //
      // This asserted only `paintsExactlyCountTimes(#drawArc, 2)`, which
      // survives reversing the draw order — the thing the test is named after.
      // The ordered `paints` sequence below is what actually pins it: the track
      // must be the FIRST arc recorded.
      await pumpRing(tester, 0.4);
      expect(
        find.byType(CustomPaint).last,
        paintsExactlyCountTimes(#drawArc, 2),
      );
      expect(
        find.byType(CustomPaint).last,
        paints
          ..arc(color: colors.track)
          ..arc(color: colors.income),
      );
    });

    testWidgets('an empty ring paints the track and no arc', (tester) async {
      await pumpRing(tester, 0);
      expect(
        find.byType(CustomPaint).last,
        paintsExactlyCountTimes(#drawArc, 1),
      );
      expect(find.byType(CustomPaint).last, paints..arc(color: colors.track));
    });
  });

  group('the label cannot contradict the arc', () {
    test('there is no way to set the label text', () {
      // Figma has no TEXT property here and types the percentage onto each
      // instance (ledger I10). Adding a `label` parameter would reintroduce
      // exactly that: a number that can disagree with the sweep.
      //
      // This used to inspect `toDiagnosticsNode().getProperties()`, which is
      // EMPTY for a widget that does not override debugFillProperties -- so it
      // passed just as happily for a widget that did take a label. It reads the
      // source instead, the way the token layer already guards
      // MonetaColors.all.
      final source = File(
        'lib/design_system/atoms/moneta_circular_progress.dart',
      ).readAsStringSync();
      final constructor = source.substring(
        source.indexOf('const MonetaCircularProgress({'),
        source.indexOf('});', source.indexOf('const MonetaCircularProgress({')),
      );
      expect(
        constructor,
        isNot(contains('label')),
        reason:
            'the ring gained a label parameter, so a number can now '
            'disagree with the sweep',
      );
      // Guards the guard: the substring really did capture the parameter list.
      expect(constructor, contains('this.fraction'));
    });

    testWidgets('over budget sweeps a full turn and still reports the truth', (
      tester,
    ) async {
      await pumpRing(tester, 1.4);
      // The arc cannot draw 140%, so the number is the only place that fact
      // survives. Clamping the label too would delete it.
      expect(find.text('140%'), findsOneWidget);

      final semantics = tester.getSemantics(
        find.byType(MonetaCircularProgress),
      );
      expect(semantics.value, '100%', reason: 'the drawn sweep is full');
    });
  });

  group('degenerate input', () {
    testWidgets('NaN, infinities and negatives do not throw', (tester) async {
      for (final f in [
        double.nan,
        double.infinity,
        double.negativeInfinity,
        -0.5,
      ]) {
        await pumpRing(tester, f);
        expect(tester.takeException(), isNull, reason: 'threw on $f');
      }
    });

    testWidgets('a negative fraction draws nothing rather than backwards', (
      tester,
    ) async {
      await pumpRing(tester, -0.5);
      expect(find.text('-50%'), findsOneWidget);
      expect(
        tester.getSemantics(find.byType(MonetaCircularProgress)).value,
        '0%',
      );
    });
  });
}
