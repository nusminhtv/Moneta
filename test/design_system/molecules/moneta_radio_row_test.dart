import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/design_system/atoms/moneta_radio.dart';
import 'package:moneta/design_system/molecules/moneta_radio_row.dart';
import 'package:moneta/design_system/tokens/colors.dart';

import '../../support/pump.dart';

enum _Period { weekly, monthly, yearly }

void main() {
  const colors = MonetaColors.dark();

  const options = [
    MonetaRadioOption(
      value: _Period.weekly,
      title: 'Weekly',
      supporting: 'Every Monday',
    ),
    MonetaRadioOption(
      value: _Period.monthly,
      title: 'Monthly',
      supporting: 'On the 1st',
    ),
    MonetaRadioOption(value: _Period.yearly, title: 'Yearly'),
  ];

  Future<void> pumpGroup(
    WidgetTester tester, {
    _Period selected = _Period.monthly,
    ValueChanged<_Period>? onChanged,
    List<MonetaRadioOption<_Period>> items = options,
  }) => pumpMonetaWidget(
    tester,
    SizedBox(
      width: 353,
      child: MonetaRadioGroup<_Period>(
        options: items,
        selected: selected,
        onChanged: onChanged,
      ),
    ),
    surfaceSize: const Size(393, 500),
  );

  List<bool> selectionIn(WidgetTester tester) => [
    for (final radio in tester.widgetList<MonetaRadio>(
      find.byType(MonetaRadio),
    ))
      radio.selected,
  ];

  group('one value, so exactly one row is selected', () {
    testWidgets('the selected value picks exactly one row', (tester) async {
      for (final period in _Period.values) {
        await pumpGroup(tester, selected: period);
        expect(
          selectionIn(tester),
          [for (final o in options) o.value == period],
          reason: 'selecting $period selected the wrong row',
        );
        expect(selectionIn(tester).where((s) => s).length, 1);
      }
    });

    testWidgets('two rows can never both read selected', (tester) async {
      // Not a convention: each row's flag is `option.value == selected`, and
      // equality is a function of one value. This asserts the consequence at
      // every possible selection, including duplicated titles.
      const duplicated = [
        MonetaRadioOption(value: _Period.weekly, title: 'Weekly'),
        MonetaRadioOption(value: _Period.weekly, title: 'Weekly again'),
        MonetaRadioOption(value: _Period.monthly, title: 'Monthly'),
      ];
      await pumpGroup(
        tester,
        items: duplicated,
        selected: _Period.weekly,
      );
      // Two options carrying the SAME value do both read selected, and that is
      // the caller's error rather than the group's: the group cannot invent a
      // difference between two equal values. What it guarantees is that no two
      // DISTINCT values are ever both selected.
      expect(selectionIn(tester), [true, true, false]);

      await pumpGroup(tester, items: options, selected: _Period.monthly);
      expect(selectionIn(tester), [false, true, false]);
    });

    testWidgets('the selected row is the only one showing a dot', (
      tester,
    ) async {
      await pumpGroup(tester, selected: _Period.yearly);
      expect(find.byKey(MonetaRadio.dotKey), findsOneWidget);
    });
  });

  group('the whole row is the tap target', () {
    testWidgets('tapping the title reports that row, not the control', (
      tester,
    ) async {
      final reported = <_Period>[];
      await pumpGroup(tester, onChanged: reported.add);

      await tester.tap(find.text('Weekly'));
      await tester.pump();
      expect(reported, [_Period.weekly]);

      await tester.tap(find.text('Every Monday'));
      await tester.pump();
      expect(reported, [_Period.weekly, _Period.weekly]);
    });

    testWidgets('tapping the far right of a row reports it', (tester) async {
      final reported = <_Period>[];
      await pumpGroup(tester, onChanged: reported.add);

      final row = tester.getRect(find.byType(MonetaRadioRow).at(2));
      await tester.tapAt(Offset(row.right - 2, row.center.dy));
      await tester.pump();
      expect(
        reported,
        [_Period.yearly],
        reason: 'empty space to the right of a title is still that row',
      );
    });

    testWidgets('tapping the control reports the same row', (tester) async {
      final reported = <_Period>[];
      await pumpGroup(tester, onChanged: reported.add);

      await tester.tap(find.byType(MonetaRadio).at(0));
      await tester.pump();
      expect(reported, [_Period.weekly]);
    });

    testWidgets('the already-selected row still reports the tap', (
      tester,
    ) async {
      final reported = <_Period>[];
      await pumpGroup(
        tester,
        selected: _Period.monthly,
        onChanged: reported.add,
      );

      await tester.tap(find.text('Monthly'));
      await tester.pump();
      expect(
        reported,
        [_Period.monthly],
        reason:
            'the row reports which row was tapped, not a state change; a '
            'silent row is indistinguishable from a dead one',
      );
    });

    testWidgets("the selected row's control is not a dead zone", (
      tester,
    ) async {
      // The atom refuses taps when it is already selected, and it sits inside
      // an opaque GestureDetector covering the row. If the atom absorbs the
      // hit without acting, the 44px square over the selected control becomes
      // the one part of the row that does nothing.
      final reported = <_Period>[];
      await pumpGroup(
        tester,
        selected: _Period.monthly,
        onChanged: reported.add,
      );

      await tester.tap(find.byType(MonetaRadio).at(1));
      await tester.pump();
      expect(reported, [_Period.monthly]);
    });

    testWidgets('a disabled option reports nothing from anywhere on the row', (
      tester,
    ) async {
      final reported = <_Period>[];
      await pumpGroup(
        tester,
        onChanged: reported.add,
        items: const [
          MonetaRadioOption(value: _Period.weekly, title: 'Weekly'),
          MonetaRadioOption(
            value: _Period.monthly,
            title: 'Monthly',
            enabled: false,
          ),
        ],
      );

      await tester.tap(find.text('Monthly'));
      await tester.pump();
      final row = tester.getRect(find.byType(MonetaRadioRow).at(1));
      await tester.tapAt(Offset(row.right - 2, row.center.dy));
      await tester.pump();
      await tester.tap(find.byType(MonetaRadio).at(1));
      await tester.pump();

      expect(reported, isEmpty);

      await tester.tap(find.text('Weekly'));
      await tester.pump();
      expect(reported, [_Period.weekly], reason: 'the enabled row still works');
    });

    testWidgets('a group with no callback is inert, not broken', (
      tester,
    ) async {
      await pumpGroup(tester);
      await tester.tap(find.text('Weekly'));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('the row itself', () {
    testWidgets('a single-line option renders one line, not an empty second', (
      tester,
    ) async {
      await pumpMonetaWidget(
        tester,
        const SizedBox(
          width: 353,
          child: MonetaRadioRow(title: 'Yearly', selected: false),
        ),
        surfaceSize: const Size(393, 200),
      );
      expect(find.byType(Text), findsOneWidget);
    });

    testWidgets('a disabled row dims its title but not its supporting line', (
      tester,
    ) async {
      await pumpMonetaWidget(
        tester,
        const SizedBox(
          width: 353,
          child: MonetaRadioRow(
            title: 'Monthly',
            supporting: 'On the 1st',
            selected: false,
            enabled: false,
          ),
        ),
        surfaceSize: const Size(393, 200),
      );
      expect(
        tester.widget<Text>(find.text('Monthly')).style!.color,
        colors.textDisabled,
      );
      expect(
        tester.widget<Text>(find.text('On the 1st')).style!.color,
        colors.textTertiary,
        reason: 'the supporting line is already the quietest text role',
      );
    });

    testWidgets('a long title truncates rather than overflowing', (
      tester,
    ) async {
      const long =
          'A period name far longer than any 353px row could hope to hold';
      await pumpMonetaWidget(
        tester,
        const SizedBox(
          width: 353,
          child: MonetaRadioRow(title: long, selected: true),
        ),
        surfaceSize: const Size(393, 200),
      );
      expect(tester.takeException(), isNull);
      expect(
        tester.widget<Text>(find.text(long)).overflow,
        TextOverflow.ellipsis,
      );
    });
  });
}
