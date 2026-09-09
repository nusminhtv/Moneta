import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/design_system/molecules/moneta_segmented_control.dart';
import 'package:moneta/design_system/tokens/colors.dart';

import '../../support/pump.dart';

void main() {
  const colors = MonetaColors.dark();

  Future<void> pumpControl(
    WidgetTester tester, {
    List<String> labels = const ['Weekly', 'Monthly', 'Yearly'],
    int selected = 1,
    ValueChanged<int>? onChanged,
    double width = 353,
  }) => pumpMonetaWidget(
    tester,
    SizedBox(
      width: width,
      child: MonetaSegmentedControl(
        labels: labels,
        selectedIndex: selected,
        onChanged: onChanged,
      ),
    ),
    surfaceSize: const Size(393, 200),
  );

  List<MonetaSegmentedItem> items(WidgetTester tester) => tester
      .widgetList<MonetaSegmentedItem>(
        find.byType(MonetaSegmentedItem),
      )
      .toList();

  group('selection', () {
    testWidgets('exactly one segment is selected', (tester) async {
      await pumpControl(tester);
      expect(items(tester).map((i) => i.selected), [false, true, false]);
    });

    testWidgets('selection is a fill, not only a text colour', (tester) async {
      // A fill is a luminance difference, so it survives greyscale. Text colour
      // alone would not.
      await pumpControl(tester);
      final boxes = tester
          .widgetList<DecoratedBox>(
            find.descendant(
              of: find.byType(MonetaSegmentedItem),
              matching: find.byType(DecoratedBox),
            ),
          )
          .map((b) => (b.decoration as BoxDecoration).color)
          .toList();
      expect(boxes, [null, colors.surfaceRaised, null]);
    });
  });

  group('layout', () {
    testWidgets('segments divide the track equally', (tester) async {
      await pumpControl(tester);
      final widths = find
          .byType(MonetaSegmentedItem)
          .evaluate()
          .map((e) => tester.getSize(find.byWidget(e.widget)).width)
          .toSet();
      expect(widths, hasLength(1), reason: 'segment widths differ');
    });

    testWidgets('the segments and gaps fill the track', (tester) async {
      // Equal widths alone would also hold if every segment were fixed at
      // Figma's authored 105 and the track had 38px of slack on the right.
      await pumpControl(tester);
      final track = tester.getRect(find.byType(MonetaSegmentedControl));
      final first = tester.getRect(find.byType(MonetaSegmentedItem).first);
      final last = tester.getRect(find.byType(MonetaSegmentedItem).last);

      expect(
        first.left - track.left,
        closeTo(MonetaSegmentedControl.gap, 0.01),
      );
      expect(
        track.right - last.right,
        closeTo(MonetaSegmentedControl.gap, 0.01),
      );
    });

    testWidgets('a much longer label does not take more room', (tester) async {
      // Font-independent: it compares the segments to each other, not to a
      // measured string. The test font makes every glyph fontSize wide, so a
      // width assertion against a literal would measure the harness.
      await pumpControl(
        tester,
        labels: const ['A', 'An extremely long period name', 'C'],
      );
      final widths = find
          .byType(MonetaSegmentedItem)
          .evaluate()
          .map((e) => tester.getSize(find.byWidget(e.widget)).width)
          .toSet();
      expect(widths, hasLength(1));
    });

    testWidgets('two and four segments both lay out', (tester) async {
      for (final labels in [
        const ['On', 'Off'],
        const ['D', 'W', 'M', 'Y'],
      ]) {
        await pumpControl(tester, labels: labels, selected: 0);
        expect(tester.takeException(), isNull);
        expect(items(tester), hasLength(labels.length));
      }
    });

    testWidgets('the track is 44 and the segment is drawn 36', (tester) async {
      await pumpControl(tester);
      expect(
        tester.getSize(find.byType(MonetaSegmentedControl)).height,
        MonetaSegmentedControl.trackHeight,
      );
      expect(
        tester.getSize(find.byType(MonetaSegmentedItem).first).height,
        MonetaSegmentedItem.height,
      );
    });
  });

  group('the touch target is the track, not the drawing', () {
    testWidgets('tapping the strip above a segment still selects it', (
      tester,
    ) async {
      // The segment is drawn 36 tall inside a 44 track. If the hit area were
      // the drawing, this 4px strip would be dead and the control would miss
      // the 44px minimum without looking like it did.
      var tapped = -1;
      await pumpControl(tester, onChanged: (i) => tapped = i);

      final segment = tester.getRect(find.byType(MonetaSegmentedItem).at(2));
      await tester.tapAt(Offset(segment.center.dx, segment.top - 2));

      expect(tapped, 2);
    });

    testWidgets('the whole hit area is at least 44 tall', (tester) async {
      var tapped = -1;
      await pumpControl(tester, onChanged: (i) => tapped = i);
      final control = tester.getRect(find.byType(MonetaSegmentedControl));
      final segment = tester.getRect(find.byType(MonetaSegmentedItem).first);

      await tester.tapAt(Offset(segment.center.dx, control.top + 1));
      expect(tapped, 0);
      await tester.tapAt(Offset(segment.center.dx, control.bottom - 1));
      expect(tapped, 0);
      expect(control.height, greaterThanOrEqualTo(44));
    });
  });

  group('onChanged', () {
    testWidgets('reports the tapped index', (tester) async {
      final taps = <int>[];
      await pumpControl(tester, onChanged: taps.add);
      await tester.tap(find.text('Yearly'));
      await tester.tap(find.text('Weekly'));
      expect(taps, [2, 0]);
    });

    testWidgets('re-tapping the current segment still reports it', (
      tester,
    ) async {
      // A caller may want to treat that as a refresh. Swallowing it here would
      // take the choice away without saying so.
      final taps = <int>[];
      await pumpControl(tester, selected: 1, onChanged: taps.add);
      await tester.tap(find.text('Monthly'));
      expect(taps, [1]);
    });

    testWidgets('a control with no callback does not throw when tapped', (
      tester,
    ) async {
      await pumpControl(tester);
      await tester.tap(find.text('Yearly'));
      expect(tester.takeException(), isNull);
    });
  });

  group('the segment count is bounded', () {
    test('one segment and five segments are rejected', () {
      expect(
        () => MonetaSegmentedControl(
          labels: const ['Only'],
          selectedIndex: 0,
        ),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => MonetaSegmentedControl(
          labels: const ['A', 'B', 'C', 'D', 'E'],
          selectedIndex: 0,
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('selectedIndex must name a segment', () {
    // The label count was asserted; the index was not, so -1 or 7 rendered
    // every segment unselected and threw nothing. That silently contradicts
    // "exactly one segment is selected" and reads as a control with no value.
    test('a negative index is rejected', () {
      expect(
        () => MonetaSegmentedControl(
          labels: const ['Jul', 'Aug', 'Sep'],
          selectedIndex: -1,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('an index past the last segment is rejected', () {
      expect(
        () => MonetaSegmentedControl(
          labels: const ['Jul', 'Aug', 'Sep'],
          selectedIndex: 3,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('the first and last segments are both allowed', () {
      expect(
        () => MonetaSegmentedControl(
          labels: const ['Jul', 'Aug', 'Sep'],
          selectedIndex: 0,
        ),
        returnsNormally,
      );
      expect(
        () => MonetaSegmentedControl(
          labels: const ['Jul', 'Aug', 'Sep'],
          selectedIndex: 2,
        ),
        returnsNormally,
      );
    });
  });
}
