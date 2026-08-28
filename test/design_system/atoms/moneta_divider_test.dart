import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/design_system/atoms/moneta_divider.dart';
import 'package:moneta/design_system/tokens/colors.dart';
import 'package:moneta/design_system/tokens/spacing.dart';

import '../../support/pump.dart';

void main() {
  const colors = MonetaColors.dark();

  Future<void> pumpDivider(
    WidgetTester tester,
    Widget child, {
    Size surface = const Size(200, 200),
  }) => pumpMonetaWidget(tester, child, surfaceSize: surface);

  Color colourOf(WidgetTester tester) => tester
      .widget<ColoredBox>(
        find
            .descendant(
              of: find.byType(MonetaDivider),
              matching: find.byType(ColoredBox),
            )
            .first,
      )
      .color;

  group('orientation decides which dimension is the hairline', () {
    testWidgets('horizontal is one pixel tall and fills the width', (
      tester,
    ) async {
      await pumpDivider(
        tester,
        const SizedBox(width: 160, child: MonetaDivider()),
      );
      final size = tester.getSize(find.byType(MonetaDivider));
      expect(size.height, MonetaLayout.borderWidthHairline);
      expect(size.width, 160);
    });

    testWidgets('vertical is one pixel wide and fills the height', (
      tester,
    ) async {
      await pumpDivider(
        tester,
        const SizedBox(
          height: 120,
          child: MonetaDivider(
            orientation: MonetaDividerOrientation.vertical,
          ),
        ),
      );
      final size = tester.getSize(find.byType(MonetaDivider));
      expect(size.width, MonetaLayout.borderWidthHairline);
      expect(size.height, 120);
    });
  });

  group('tone', () {
    testWidgets('the two tones resolve to different border tokens', (
      tester,
    ) async {
      await pumpDivider(
        tester,
        const SizedBox(width: 160, child: MonetaDivider()),
      );
      expect(colourOf(tester), colors.borderSubtle);

      await pumpDivider(
        tester,
        const SizedBox(
          width: 160,
          child: MonetaDivider(tone: MonetaDividerTone.standard),
        ),
      );
      expect(colourOf(tester), colors.borderDefault);
      expect(colors.borderSubtle, isNot(colors.borderDefault));
    });
  });

  group('unbounded parents', () {
    testWidgets('a horizontal divider in an unbounded row does not throw', (
      tester,
    ) async {
      await pumpDivider(
        tester,
        const Row(
          mainAxisSize: MainAxisSize.min,
          children: [MonetaDivider()],
        ),
        surface: const Size(400, 400),
      );
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(MonetaDivider)).width,
        MonetaDivider.intrinsicLength,
      );
    });

    testWidgets('a vertical divider in an unbounded column does not throw', (
      tester,
    ) async {
      await pumpDivider(
        tester,
        const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MonetaDivider(orientation: MonetaDividerOrientation.vertical),
          ],
        ),
        surface: const Size(400, 400),
      );
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(MonetaDivider)).height,
        MonetaDivider.intrinsicLength,
      );
    });
  });
}
