import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/design_system/atoms/moneta_icon_button.dart';
import 'package:moneta/design_system/organisms/bottom_sheet.dart';

import '../../support/pump.dart';

void main() {
  Future<void> pumpSheet(
    WidgetTester tester, {
    required Widget child,
    EdgeInsets viewPadding = EdgeInsets.zero,
    VoidCallback? onClose,
    String title = 'Choose a period',
    double height = 852,
  }) => pumpMonetaWidget(
    tester,
    Align(
      alignment: Alignment.bottomCenter,
      child: MonetaBottomSheet(
        title: title,
        onClose: onClose,
        child: child,
      ),
    ),
    viewPadding: viewPadding,
    surfaceSize: Size(393, height),
  );

  double sheetHeight(WidgetTester tester) =>
      tester.getSize(find.byType(MonetaBottomSheet)).height;

  group('the sheet is sized by its content', () {
    testWidgets('short content gives a short sheet', (tester) async {
      await pumpSheet(tester, child: const SizedBox(height: 100));

      // Handle + header + content + inset, and nothing else. `81:644`: "the
      // sheet height is computed from its slot content, not guessed."
      expect(
        sheetHeight(tester),
        MonetaBottomSheet.handleAreaHeight +
            MonetaBottomSheet.headerHeight +
            100,
      );
    });

    testWidgets('the sheet grows with its content, not in steps', (
      tester,
    ) async {
      // Three heights rather than one: a sheet that ignored its content and
      // returned a constant would pass a single-height assertion.
      final measured = <double>[];
      for (final contentHeight in [40.0, 180.0, 320.0]) {
        await pumpSheet(tester, child: SizedBox(height: contentHeight));
        measured.add(sheetHeight(tester));
      }
      expect(measured, [
        MonetaBottomSheet.handleAreaHeight +
            MonetaBottomSheet.headerHeight +
            40,
        MonetaBottomSheet.handleAreaHeight +
            MonetaBottomSheet.headerHeight +
            180,
        MonetaBottomSheet.handleAreaHeight +
            MonetaBottomSheet.headerHeight +
            320,
      ]);
    });

    testWidgets('content taller than the screen scrolls, header intact', (
      tester,
    ) async {
      await pumpSheet(
        tester,
        child: const SizedBox(height: 4000),
        height: 600,
      );
      expect(tester.takeException(), isNull);

      // The sheet stops at the space available rather than overflowing.
      expect(sheetHeight(tester), lessThanOrEqualTo(600));

      // And the header is still on screen, above the scrolling area.
      final header = tester.getRect(find.text('Choose a period'));
      final content = tester.getRect(find.byKey(MonetaBottomSheet.contentKey));
      expect(header.bottom, lessThanOrEqualTo(content.top));
      expect(header.top, greaterThanOrEqualTo(0));

      // Scrolling the content does not move the header.
      final before = tester.getRect(find.text('Choose a period'));
      await tester.drag(
        find.byKey(MonetaBottomSheet.contentKey),
        const Offset(0, -200),
      );
      await tester.pump();
      expect(tester.getRect(find.text('Choose a period')), before);
    });

    testWidgets('short content does not scroll away under a drag', (
      tester,
    ) async {
      await pumpSheet(tester, child: const SizedBox(height: 100));
      final before = tester.getRect(find.byKey(MonetaBottomSheet.contentKey));
      await tester.drag(
        find.byKey(MonetaBottomSheet.contentKey),
        const Offset(0, -200),
      );
      await tester.pump();
      expect(
        tester.getRect(find.byKey(MonetaBottomSheet.contentKey)),
        before,
        reason: 'content that fits has nothing to scroll',
      );
    });
  });

  group('the safe inset comes from the device', () {
    testWidgets('a device inset is honoured', (tester) async {
      await pumpSheet(
        tester,
        child: const SizedBox(height: 100),
        viewPadding: const EdgeInsets.only(bottom: 34),
      );
      expect(
        tester.getSize(find.byKey(MonetaBottomSheet.safeInsetKey)).height,
        34,
      );
    });

    testWidgets('a different inset gives a different sheet', (tester) async {
      // The authored 34 describes one handset. Two insets, so a hardcoded 34
      // fails rather than coinciding with the fixture.
      await pumpSheet(
        tester,
        child: const SizedBox(height: 100),
        viewPadding: const EdgeInsets.only(bottom: 21),
      );
      expect(
        tester.getSize(find.byKey(MonetaBottomSheet.safeInsetKey)).height,
        21,
      );

      await pumpSheet(
        tester,
        child: const SizedBox(height: 100),
        viewPadding: EdgeInsets.zero,
      );
      expect(
        tester.getSize(find.byKey(MonetaBottomSheet.safeInsetKey)).height,
        0,
        reason: 'a device with no bottom inset gets no padding',
      );
    });

    testWidgets('the inset is added to the sheet, not taken from content', (
      tester,
    ) async {
      await pumpSheet(
        tester,
        child: const SizedBox(height: 100),
        viewPadding: const EdgeInsets.only(bottom: 34),
      );
      expect(
        sheetHeight(tester),
        MonetaBottomSheet.handleAreaHeight +
            MonetaBottomSheet.headerHeight +
            100 +
            34,
      );
      expect(
        tester.getSize(find.byKey(MonetaBottomSheet.contentKey)).height,
        100,
      );
    });
  });

  group('the header and its controls', () {
    testWidgets('the close control meets the 44px touch target', (
      tester,
    ) async {
      await pumpSheet(tester, child: const SizedBox(height: 100));
      expect(
        tester.getSize(find.byType(MonetaIconButton)),
        const Size(44, 44),
      );
    });

    testWidgets('close reports the tap', (tester) async {
      var closed = 0;
      await pumpSheet(
        tester,
        child: const SizedBox(height: 100),
        onClose: () => closed++,
      );
      await tester.tap(find.byType(MonetaIconButton));
      await tester.pump();
      expect(closed, 1);
    });

    testWidgets('the close control stays reachable under tall content', (
      tester,
    ) async {
      var closed = 0;
      await pumpSheet(
        tester,
        child: const SizedBox(height: 4000),
        height: 600,
        onClose: () => closed++,
      );
      await tester.tap(find.byType(MonetaIconButton));
      await tester.pump();
      expect(
        closed,
        1,
        reason: 'a sheet you cannot close is worse than one that overflows',
      );
    });

    testWidgets('the grab handle is the authored 40 x 4', (tester) async {
      await pumpSheet(tester, child: const SizedBox(height: 100));
      expect(
        tester.getSize(find.byKey(MonetaBottomSheet.handleKey)),
        const Size(
          MonetaBottomSheet.handleWidth,
          MonetaBottomSheet.handleHeight,
        ),
      );
    });

    testWidgets('a long title truncates rather than displacing close', (
      tester,
    ) async {
      const long =
          'A sheet title far longer than any header row could hope to hold';
      await pumpSheet(
        tester,
        child: const SizedBox(height: 100),
        title: long,
      );
      expect(tester.takeException(), isNull);

      final sheet = tester.getRect(find.byType(MonetaBottomSheet));
      final close = tester.getRect(find.byType(MonetaIconButton));
      expect(close.right, lessThanOrEqualTo(sheet.right));
      expect(
        tester.widget<Text>(find.text(long)).overflow,
        TextOverflow.ellipsis,
      );
    });
  });
}
