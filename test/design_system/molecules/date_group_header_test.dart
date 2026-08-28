import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/design_system/molecules/date_group_header.dart';
import 'package:moneta/design_system/tokens/colors.dart';

import '../../support/pump.dart';

void main() {
  const colors = MonetaColors.dark();

  Future<void> pumpHeader(
    WidgetTester tester, {
    required DateTime date,
    double width = 353,
  }) {
    return pumpMonetaWidget(
      tester,
      SizedBox(
        width: width,
        child: DateGroupHeader(date: date),
      ),
      surfaceSize: const Size(420, 180),
    );
  }

  testWidgets('formats the local calendar date', (tester) async {
    final date = DateTime.utc(2026, DateTime.august, 28, 17);
    await pumpHeader(tester, date: date);

    expect(find.text('29 August'), findsOneWidget);
  });

  testWidgets('uses secondary text styling', (tester) async {
    await pumpHeader(tester, date: DateTime(2026, DateTime.august, 28));

    final text = tester.widget<Text>(find.text('28 August'));
    expect(text.style!.color, colors.textSecondary);
  });

  testWidgets('does not overflow narrow widths', (tester) async {
    await pumpHeader(
      tester,
      date: DateTime(2026, DateTime.september, 1),
      width: 96,
    );

    expect(tester.takeException(), isNull);
    final row = tester.getRect(find.byType(DateGroupHeader));
    final label = tester.getRect(find.text('1 September'));
    expect(label.left, greaterThanOrEqualTo(row.left));
    expect(label.right, lessThanOrEqualTo(row.right));
  });
}
