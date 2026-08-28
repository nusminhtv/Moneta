import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/design_system/atoms/moneta_icon.dart';
import 'package:moneta/design_system/atoms/moneta_icon_name.dart';
import 'package:moneta/design_system/organisms/banner.dart';
import 'package:moneta/design_system/tokens/colors.dart';

import '../../support/pump.dart';

void main() {
  const colors = MonetaColors.dark();

  Future<void> pumpBanner(
    WidgetTester tester, {
    required BannerTone tone,
    String title = 'Budget almost reached',
    String message = 'Food & drink is close to its monthly limit.',
    VoidCallback? onTap,
    double width = 353,
  }) {
    return pumpMonetaWidget(
      tester,
      SizedBox(
        width: width,
        child: MonetaBanner(
          tone: tone,
          title: title,
          message: message,
          onTap: onTap,
        ),
      ),
      surfaceSize: const Size(420, 240),
    );
  }

  (Color, Color, MonetaIconName) expectedFor(BannerTone tone) => switch (tone) {
    BannerTone.warning => (
      colors.warning,
      colors.warningSubtle,
      MonetaIconName.alertTriangle,
    ),
    BannerTone.danger => (
      colors.expense,
      colors.expenseSubtle,
      MonetaIconName.x,
    ),
    BannerTone.info => (colors.info, colors.infoSubtle, MonetaIconName.info),
    BannerTone.success => (
      colors.income,
      colors.incomeSubtle,
      MonetaIconName.check,
    ),
  };

  BoxDecoration decoration(WidgetTester tester) {
    final box = tester.widget<DecoratedBox>(
      find
          .descendant(
            of: find.byType(MonetaBanner),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    return box.decoration as BoxDecoration;
  }

  for (final tone in BannerTone.values) {
    testWidgets('${tone.name} tone uses its colour pair and icon', (
      tester,
    ) async {
      await pumpBanner(tester, tone: tone);

      final (accent, background, icon) = expectedFor(tone);
      final title = tester.widget<Text>(find.text('Budget almost reached'));
      final iconWidget = tester.widget<MonetaIcon>(find.byType(MonetaIcon));
      final box = decoration(tester);

      expect(title.style!.color, accent);
      expect(iconWidget.icon, icon);
      expect(iconWidget.color, accent);
      expect(box.color, background);
      expect(box.border, Border.all(color: accent));
    });
  }

  testWidgets('reports taps when interactive', (tester) async {
    var taps = 0;
    await pumpBanner(
      tester,
      tone: BannerTone.info,
      onTap: () => taps++,
    );

    await tester.tap(find.byType(MonetaBanner));
    expect(taps, 1);
  });

  testWidgets('semantics includes tone and copy', (tester) async {
    await pumpBanner(
      tester,
      tone: BannerTone.success,
      title: 'Goal updated',
      message: 'You are ahead of pace.',
    );

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label ==
                'success: Goal updated. You are ahead of pace.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('long copy stays inside the banner', (tester) async {
    await pumpBanner(
      tester,
      tone: BannerTone.warning,
      title: 'A very long warning title that should not escape',
      message:
          'A very long warning message that should wrap or truncate while the '
          'component remains inside its parent.',
      width: 220,
    );

    expect(tester.takeException(), isNull);
    final banner = tester.getRect(find.byType(MonetaBanner));
    for (final text in find.byType(Text).evaluate()) {
      final rect = tester.getRect(find.byWidget(text.widget));
      expect(rect.left, greaterThanOrEqualTo(banner.left));
      expect(rect.right, lessThanOrEqualTo(banner.right));
    }
  });
}
