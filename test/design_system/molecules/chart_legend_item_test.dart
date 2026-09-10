import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/core/money.dart';
import 'package:moneta/design_system/molecules/chart_legend_item.dart';
import 'package:moneta/design_system/molecules/chart_series.dart';
import 'package:moneta/design_system/tokens/colors.dart';

import '../../support/pump.dart';

void main() {
  const colors = MonetaColors.dark();
  const vnd = Currency.vnd;
  const amount = Money(6760000, vnd);

  Future<void> pumpRow(
    WidgetTester tester, {
    required ChartSlot slot,
    String label = 'Food & drink',
    double fraction = 0.26,
    Money value = amount,
    double width = 353,
  }) => pumpMonetaWidget(
    tester,
    SizedBox(
      width: width,
      child: ChartLegendItem(
        label: label,
        fraction: fraction,
        amount: value,
        slot: slot,
      ),
    ),
    surfaceSize: const Size(393, 200),
  );

  Color swatchColorIn(WidgetTester tester) {
    final box = tester.widget<DecoratedBox>(
      find.ancestor(
        of: find.byKey(ChartLegendItem.swatchKey),
        matching: find.byType(DecoratedBox),
      ),
    );
    return (box.decoration as BoxDecoration).color!;
  }

  List<TextStyle> textStylesIn(WidgetTester tester) => [
    for (final text in tester.widgetList<Text>(find.byType(Text))) text.style!,
  ];

  group('only the swatch carries identity', () {
    // One test per authored variant. `47:47`'s description is the requirement:
    // "Text wears text tokens; only the swatch carries identity."
    for (final slot in ChartSlot.values) {
      testWidgets('${slot.figmaName} draws its own swatch colour', (
        tester,
      ) async {
        await pumpRow(tester, slot: slot);
        expect(swatchColorIn(tester), slot.colorIn(colors));
      });
    }

    testWidgets('the nine swatches are nine distinguishable colours', (
      tester,
    ) async {
      final seen = <Color>[];
      for (final slot in ChartSlot.values) {
        await pumpRow(tester, slot: slot);
        seen.add(swatchColorIn(tester));
      }
      expect(seen, hasLength(ChartSlot.values.length));
      expect(
        seen.toSet(),
        hasLength(ChartSlot.values.length),
        reason:
            'two slots rendering one colour makes two series indistinguishable '
            'while every per-slot assertion above still passes',
      );
    });

    testWidgets('the three text roles are identical across all nine slots', (
      tester,
    ) async {
      await pumpRow(tester, slot: ChartSlot.slot1);
      final reference = textStylesIn(tester);
      expect(reference, hasLength(3), reason: 'label, percent, amount');

      // Transcribed from `47:4`, `47:5`, `47:6`: body/md secondary, label/md
      // primary, caption/md tertiary.
      expect(reference[0].color, colors.textSecondary);
      expect(reference[1].color, colors.textPrimary);
      expect(reference[2].color, colors.textTertiary);

      for (final slot in ChartSlot.values) {
        await pumpRow(tester, slot: slot);
        expect(
          textStylesIn(tester),
          reference,
          reason:
              '${slot.figmaName} changed a text style; only the swatch may '
              'vary between variants',
        );
      }
    });

    testWidgets('Slot=Other is the neutral text colour, not a ninth hue', (
      tester,
    ) async {
      await pumpRow(tester, slot: ChartSlot.other);
      // Transcribed from `47:42`'s swatch, which exports as `#7C8595` — the
      // same value `textTertiary` carries.
      expect(swatchColorIn(tester), colors.textTertiary);
      for (var slot = 1; slot <= MonetaChartPalette.slotCount; slot++) {
        expect(swatchColorIn(tester), isNot(colors.chart.base(slot)));
      }
    });

    testWidgets('the swatch is the authored 10px circle', (tester) async {
      await pumpRow(tester, slot: ChartSlot.slot1);
      expect(
        tester.getSize(find.byKey(ChartLegendItem.swatchKey)),
        const Size(
          ChartLegendItem.swatchSize,
          ChartLegendItem.swatchSize,
        ),
      );
      final box = tester.widget<DecoratedBox>(
        find.ancestor(
          of: find.byKey(ChartLegendItem.swatchKey),
          matching: find.byType(DecoratedBox),
        ),
      );
      expect((box.decoration as BoxDecoration).shape, BoxShape.circle);
    });
  });

  group('a long label does not push out the figures', () {
    testWidgets('the label truncates and the figures keep their width', (
      tester,
    ) async {
      const long =
          'Food, drink, groceries, coffee, takeaway and everything else '
          'that goes in a mouth';

      await pumpRow(tester, slot: ChartSlot.slot1, label: 'Food');
      final shortLabelBox = tester.getSize(find.text('Food')).width;
      final shortPercent = tester.getSize(find.text('26%')).width;
      final shortAmount = tester.getSize(find.text(amount.format())).width;
      expect(
        tester
            .renderObject<RenderParagraph>(find.text('Food'))
            .didExceedMaxLines,
        isFalse,
      );

      await pumpRow(tester, slot: ChartSlot.slot1, label: long);
      expect(tester.takeException(), isNull, reason: 'nothing overflowed');

      // Font-independent: the placeholder font makes any absolute width
      // meaningless, but "the figures are the same width in both layouts"
      // holds in any font, and so does "the long text did not fit".
      expect(tester.getSize(find.text('26%')).width, shortPercent);
      expect(tester.getSize(find.text(amount.format())).width, shortAmount);
      expect(
        tester.getSize(find.text(long)).width,
        shortLabelBox,
        reason:
            'Expanded pins the label to whatever slack the figures leave, so '
            'a longer name cannot widen the row — it truncates inside a box '
            'that never changes size',
      );
      expect(
        tester.renderObject<RenderParagraph>(find.text(long)).didExceedMaxLines,
        isTrue,
        reason:
            'the label really is being clipped here; without this the '
            'width assertions above would also pass for a label that fits',
      );

      final labelWidget = tester.widget<Text>(find.text(long));
      expect(labelWidget.overflow, TextOverflow.ellipsis);
      expect(labelWidget.maxLines, 1);
    });

    testWidgets('a narrower row takes room from the label, not the figures', (
      tester,
    ) async {
      await pumpRow(tester, slot: ChartSlot.slot1, width: 353);
      final wideLabel = tester.getSize(find.text('Food & drink')).width;
      final widePercent = tester.getSize(find.text('26%')).width;
      final wideAmount = tester.getSize(find.text(amount.format())).width;

      await pumpRow(tester, slot: ChartSlot.slot1, width: 240);
      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.text('26%')).width, widePercent);
      expect(tester.getSize(find.text(amount.format())).width, wideAmount);
      expect(
        tester.getSize(find.text('Food & drink')).width,
        lessThan(wideLabel),
        reason: 'the label is the only part that gives way',
      );
    });

    testWidgets('every part stays inside the row', (tester) async {
      const long =
          'A category name far longer than three hundred pixels can '
          'possibly hold at any font size';
      await pumpRow(tester, slot: ChartSlot.slot1, label: long, width: 353);

      final row = tester.getRect(find.byType(Row));
      for (final part in [
        find.byKey(ChartLegendItem.swatchKey),
        find.text(long),
        find.text('26%'),
        find.text(amount.format()),
      ]) {
        final rect = tester.getRect(part);
        expect(rect.left, greaterThanOrEqualTo(row.left));
        expect(
          rect.right,
          lessThanOrEqualTo(row.right),
          reason: 'a clipped amount is a lost amount',
        );
      }
    });
  });

  group('the row formats its own figures', () {
    testWidgets('the amount arrives as Money and is formatted here', (
      tester,
    ) async {
      await pumpRow(
        tester,
        slot: ChartSlot.slot1,
        value: const Money(1250000, vnd),
      );
      expect(find.text(const Money(1250000, vnd).format()), findsOneWidget);
    });

    testWidgets('a USD amount formats as USD, not as the default currency', (
      tester,
    ) async {
      const usd = Money(1234, Currency.usd);
      await pumpRow(tester, slot: ChartSlot.slot1, value: usd);
      expect(find.text(usd.format()), findsOneWidget);
      expect(find.text(const Money(1234, vnd).format()), findsNothing);
    });

    test('the share is rounded to whole percent, as 47:5 is authored', () {
      String percentFor(double fraction) => ChartLegendItem(
        label: 'x',
        fraction: fraction,
        amount: amount,
        slot: ChartSlot.slot1,
      ).percentLabel;

      expect(percentFor(0.26), '26%');
      expect(percentFor(0), '0%');
      expect(percentFor(1), '100%');
      expect(percentFor(0.004), '0%');
      expect(percentFor(0.005), '1%');
      expect(percentFor(0.999), '100%');
    });
  });

  group('forSeries', () {
    testWidgets('takes label, amount and slot from the datum', (tester) async {
      const series = ChartSeries(
        label: 'Transport',
        amount: Money(980000, vnd),
        slot: ChartSlot.slot4,
      );
      await pumpMonetaWidget(
        tester,
        SizedBox(
          width: 353,
          child: ChartLegendItem.forSeries(series, fraction: 0.12),
        ),
        surfaceSize: const Size(393, 200),
      );

      expect(find.text('Transport'), findsOneWidget);
      expect(find.text(series.amount.format()), findsOneWidget);
      expect(find.text('12%'), findsOneWidget);
      expect(swatchColorIn(tester), colors.chart.base(4));
    });
  });
}
