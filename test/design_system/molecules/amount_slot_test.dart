import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/design_system/molecules/amount_slot.dart';

import '../../support/pump.dart';

void main() {
  Future<void> pumpSlot(
    WidgetTester tester, {
    required double rowWidth,
    required double childWidth,
    double? share,
  }) {
    return pumpMonetaWidget(
      tester,
      SizedBox(
        width: rowWidth,
        child: Row(
          children: [
            AmountSlot(
              rowWidth: rowWidth,
              share: share ?? AmountSlot.defaultShare,
              child: SizedBox(width: childWidth, height: 20),
            ),
          ],
        ),
      ),
      surfaceSize: Size(rowWidth + 40, 200),
    );
  }

  test('the default share leaves most of the row to the label', () {
    expect(AmountSlot.defaultShare, lessThan(0.6));
    expect(AmountSlot.defaultShare, greaterThan(0.4));
  });

  testWidgets('a child narrower than the cap keeps its own width', (
    tester,
  ) async {
    await pumpSlot(tester, rowWidth: 300, childWidth: 80);
    expect(tester.getSize(find.byType(AmountSlot)).width, 80);
  });

  testWidgets('a child wider than the cap is clamped to it', (tester) async {
    await pumpSlot(tester, rowWidth: 300, childWidth: 400);
    expect(
      tester.getSize(find.byType(AmountSlot)).width,
      300 * AmountSlot.defaultShare,
    );
  });

  testWidgets('the cap is a share of the row, not a fixed width', (
    tester,
  ) async {
    await pumpSlot(tester, rowWidth: 200, childWidth: 400);
    expect(
      tester.getSize(find.byType(AmountSlot)).width,
      200 * AmountSlot.defaultShare,
    );
  });

  testWidgets('an explicit share overrides the default', (tester) async {
    await pumpSlot(tester, rowWidth: 300, childWidth: 400, share: 0.25);
    expect(tester.getSize(find.byType(AmountSlot)).width, 75);
  });

  testWidgets('a zero-width row collapses the slot rather than throwing', (
    tester,
  ) async {
    await pumpSlot(tester, rowWidth: 0, childWidth: 100);
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(AmountSlot)).width, 0);
  });
}
