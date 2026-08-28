import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/design_system/atoms/moneta_icon.dart';
import 'package:moneta/design_system/atoms/moneta_icon_name.dart';
import 'package:moneta/design_system/atoms/moneta_logo.dart';
import 'package:moneta/design_system/tokens/colors.dart';

import '../../support/pump.dart';

void main() {
  Future<void> pumpLogo(
    WidgetTester tester, {
    bool showWordmark = true,
    double markSize = MonetaLogo.defaultMarkSize,
  }) => pumpMonetaWidget(
    tester,
    MonetaLogo(showWordmark: showWordmark, markSize: markSize),
    surfaceSize: const Size(393, 200),
  );

  group('both forms', () {
    testWidgets('the mark is present with and without the wordmark', (
      tester,
    ) async {
      await pumpLogo(tester);
      expect(find.byType(MonetaIcon), findsOneWidget);
      expect(find.text(MonetaLogo.wordmark), findsOneWidget);

      await pumpLogo(tester, showWordmark: false);
      expect(find.byType(MonetaIcon), findsOneWidget);
      expect(find.text(MonetaLogo.wordmark), findsNothing);
    });

    testWidgets('the mark glyph is the one Figma instances', (tester) async {
      await pumpLogo(tester);
      expect(
        tester.widget<MonetaIcon>(find.byType(MonetaIcon)).icon,
        MonetaIconName.zap,
      );
    });
  });

  group('the mark', () {
    testWidgets('stays square when resized', (tester) async {
      for (final size in <double>[32, 48, 72]) {
        await pumpLogo(tester, showWordmark: false, markSize: size);
        final box = tester.getSize(find.byType(MonetaLogo));
        expect(box.width, size, reason: 'at $size');
        expect(box.height, size, reason: 'at $size');
      }
    });

    testWidgets('the glyph scales with the mark', (tester) async {
      await pumpLogo(tester, markSize: 96);
      expect(
        tester.widget<MonetaIcon>(find.byType(MonetaIcon)).size,
        96 * MonetaLogo.glyphRatio,
      );
    });

    testWidgets('reads its gradient from the palette, not fresh literals', (
      tester,
    ) async {
      await pumpLogo(tester);
      final box = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byType(MonetaLogo),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      final gradient =
          (box.decoration as BoxDecoration).gradient! as LinearGradient;
      expect(
        gradient.colors,
        [MonetaColors.violet500, MonetaColors.mint500],
        reason: 'the mark gradient stopped reading the brand palette',
      );
    });
  });

  group('accessibility', () {
    testWidgets('it announces the product name once', (tester) async {
      await pumpLogo(tester);
      final semantics = tester.getSemantics(find.byType(MonetaLogo));
      expect(semantics.label, MonetaLogo.wordmark);
    });
  });
}
