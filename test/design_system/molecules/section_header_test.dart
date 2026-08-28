import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/design_system/molecules/section_header.dart';
import 'package:moneta/design_system/tokens/colors.dart';

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
}
