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

  group('the label cannot contradict the arc', () {
    test('there is no way to set the label text', () {
      // Figma has no TEXT property here and types the percentage onto each
      // instance (ledger I10). Adding a `label` parameter would reintroduce
      // exactly that: a number that can disagree with the sweep.
      const ring = MonetaCircularProgress(fraction: 0.62);
      expect(
        ring.toDiagnosticsNode().getProperties().map((p) => p.name),
        isNot(contains('label')),
      );
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
