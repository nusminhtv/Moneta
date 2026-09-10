import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/design_system/atoms/moneta_icon.dart';
import 'package:moneta/design_system/atoms/moneta_icon_name.dart';
import 'package:moneta/design_system/molecules/list_row.dart';
import 'package:moneta/design_system/tokens/colors.dart';

import '../../support/pump.dart';

void main() {
  const colors = MonetaColors.dark();

  Future<void> pumpRow(
    WidgetTester tester, {
    required ListRowAccessory accessory,
    String title = 'Notifications',
    String? subtitle = 'Manage account alerts',
    MonetaIconName? leadingIcon = MonetaIconName.bell,
    String? value,
    String? badgeLabel,
    bool toggled = false,
    VoidCallback? onTap,
    ValueChanged<bool>? onToggle,
    double width = 353,
  }) {
    return pumpMonetaWidget(
      tester,
      SizedBox(
        width: width,
        child: ListRow(
          title: title,
          subtitle: subtitle,
          leadingIcon: leadingIcon,
          accessory: accessory,
          value: value,
          badgeLabel: badgeLabel,
          toggled: toggled,
          onTap: onTap,
          onToggle: onToggle,
        ),
      ),
      surfaceSize: const Size(420, 240),
    );
  }

  group('variants', () {
    testWidgets('chevron variant renders the chevron only', (tester) async {
      await pumpRow(tester, accessory: ListRowAccessory.chevron);

      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Manage account alerts'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is MonetaIcon &&
              widget.icon == MonetaIconName.chevronRight,
        ),
        findsOneWidget,
      );
      expect(find.byKey(ListRow.toggleKey), findsNothing);
    });

    testWidgets('value variant renders the supplied value', (tester) async {
      await pumpRow(
        tester,
        accessory: ListRowAccessory.value,
        value: 'VND',
      );

      final value = tester.widget<Text>(find.text('VND'));
      expect(value.style!.color, colors.textSecondary);
      expect(find.byKey(ListRow.toggleKey), findsNothing);
    });

    testWidgets('toggle variant reports the next value', (tester) async {
      final values = <bool>[];
      await pumpRow(
        tester,
        accessory: ListRowAccessory.toggle,
        toggled: false,
        onToggle: values.add,
      );

      await tester.tap(find.byKey(ListRow.toggleKey));
      expect(values, [true]);
    });

    testWidgets('badge variant renders a compact status label', (tester) async {
      await pumpRow(
        tester,
        accessory: ListRowAccessory.badge,
        badgeLabel: '3 new',
      );

      final badge = tester.widget<Text>(find.text('3 new'));
      expect(badge.style!.color, colors.info);
      expect(find.byKey(ListRow.toggleKey), findsNothing);
    });

    testWidgets('none variant renders no trailing affordance', (tester) async {
      await pumpRow(tester, accessory: ListRowAccessory.none);

      expect(find.text('Notifications'), findsOneWidget);
      expect(find.byType(MonetaIcon), findsOneWidget);
      expect(find.byKey(ListRow.toggleKey), findsNothing);
    });
  });

  group('content and layout', () {
    testWidgets('leading icon is optional', (tester) async {
      await pumpRow(
        tester,
        accessory: ListRowAccessory.none,
        leadingIcon: null,
      );

      expect(find.byType(MonetaIcon), findsNothing);
    });

    testWidgets('subtitle is optional', (tester) async {
      await pumpRow(
        tester,
        accessory: ListRowAccessory.value,
        subtitle: null,
        value: 'VND',
      );

      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Manage account alerts'), findsNothing);
    });

    testWidgets('long text stays within the row', (tester) async {
      await pumpRow(
        tester,
        accessory: ListRowAccessory.value,
        title: 'A very long notification preference title that cannot fit',
        subtitle: 'A very long supporting line that also cannot fit',
        value: 'Very long value',
        width: 220,
      );

      expect(tester.takeException(), isNull);
      final row = tester.getRect(find.byType(ListRow));
      for (final text in find.byType(Text).evaluate()) {
        final rect = tester.getRect(find.byWidget(text.widget));
        expect(rect.left, greaterThanOrEqualTo(row.left));
        expect(rect.right, lessThanOrEqualTo(row.right));
      }
    });

    testWidgets('a toggle row has one action, and it is the toggle', (
      tester,
    ) async {
      // **This test previously asserted the opposite** — that tapping the row
      // called `onTap` while tapping the switch called `onToggle`, so one row
      // carried two different actions. `35:70`'s own description rules that
      // out: *"56px minimum so the whole row is the tap target — never make
      // just the trailing control tappable."* The row area exists to activate
      // the control, not to do something else, and `100:728` says a toggle
      // promises an immediate change — one promise per row.
      //
      // So `onTap` is ignored on a toggle row, and both the row and the switch
      // toggle.
      var rowTaps = 0;
      final toggleValues = <bool>[];
      await pumpRow(
        tester,
        accessory: ListRowAccessory.toggle,
        onTap: () => rowTaps++,
        onToggle: toggleValues.add,
      );

      await tester.tap(find.text('Notifications'));
      await tester.pump();
      await tester.tap(find.byKey(ListRow.toggleKey));
      await tester.pump();

      expect(
        rowTaps,
        0,
        reason: 'a toggle row must not hide a second action behind the row',
      );
      expect(toggleValues, [true, true]);
    });
  });

  group('the destructive flag reddens the label and nothing else', () {
    // `100:269`: "Sign out is the only destructive row and is the only label
    // not on text/primary." `35:113` authors no destructive variant, so this
    // must change exactly one thing.
    Future<void> pumpRow(WidgetTester tester, {required bool destructive}) =>
        pumpMonetaWidget(
          tester,
          SizedBox(
            width: 353,
            child: ListRow(
              title: 'Sign out',
              subtitle: 'You will need your PIN again',
              leadingIcon: MonetaIconName.lock,
              accessory: ListRowAccessory.chevron,
              destructive: destructive,
              onTap: () {},
            ),
          ),
          surfaceSize: const Size(393, 300),
        );

    testWidgets('the title is the expense colour when set', (tester) async {
      await pumpRow(tester, destructive: true);
      expect(
        tester.widget<Text>(find.text('Sign out')).style!.color,
        colors.expense,
      );
    });

    testWidgets('and text/primary when not', (tester) async {
      await pumpRow(tester, destructive: false);
      expect(
        tester.widget<Text>(find.text('Sign out')).style!.color,
        colors.textPrimary,
      );
    });

    testWidgets('nothing else about the row changes', (tester) async {
      // The property that keeps this a flag rather than a variant. Without it,
      // "destructive" could quietly grow a red background or a red icon, and
      // the file authors neither.
      final captured = <String>[];
      for (final destructive in [false, true]) {
        await pumpRow(tester, destructive: destructive);
        final decoration =
            tester
                    .widget<DecoratedBox>(find.byType(DecoratedBox).first)
                    .decoration
                as BoxDecoration;
        final icon = tester.widget<MonetaIcon>(find.byType(MonetaIcon).first);
        final subtitle = tester
            .widget<Text>(find.text('You will need your PIN again'))
            .style!;
        captured.add(
          '${decoration.color}|${icon.color}|${subtitle.color}|'
          '${tester.getSize(find.byType(ListRow))}',
        );
      }
      expect(
        captured.first,
        captured.last,
        reason: 'destructive changed more than the title',
      );
    });
  });

  group('35:70 — the whole row is the tap target', () {
    // The component's own description: "56px minimum so the whole row is the
    // tap target — never make just the trailing control tappable."

    testWidgets('a row without a subtitle still clears 56px', (tester) async {
      // The defect: title-only rows came out at ~46, under the authored
      // minimum and under the 44px platform target too. Every settings screen
      // in this app is made of these.
      await pumpMonetaWidget(
        tester,
        const SizedBox(
          width: 353,
          child: ListRow(
            title: 'Budget exceeded',
            accessory: ListRowAccessory.chevron,
          ),
        ),
        surfaceSize: const Size(393, 300),
      );
      expect(
        tester.getSize(find.byType(ListRow)).height,
        greaterThanOrEqualTo(ListRow.minimumHeight),
      );
    });

    testWidgets('and a row with one is no shorter', (tester) async {
      await pumpMonetaWidget(
        tester,
        const SizedBox(
          width: 353,
          child: ListRow(
            title: '80% of a budget used',
            subtitle: 'One warning per budget per month',
            accessory: ListRowAccessory.toggle,
          ),
        ),
        surfaceSize: const Size(393, 300),
      );
      expect(
        tester.getSize(find.byType(ListRow)).height,
        greaterThanOrEqualTo(ListRow.minimumHeight),
      );
    });

    testWidgets('tapping the row toggles it, not only the switch', (
      tester,
    ) async {
      final changes = <bool>[];
      await pumpMonetaWidget(
        tester,
        SizedBox(
          width: 353,
          child: ListRow(
            title: 'Budget exceeded',
            accessory: ListRowAccessory.toggle,
            onToggle: changes.add,
          ),
        ),
        surfaceSize: const Size(393, 300),
      );

      // The title, which is as far from the switch as the row gets.
      await tester.tap(find.text('Budget exceeded'));
      await tester.pump();
      expect(
        changes,
        [true],
        reason: '35:70 forbids making only the trailing control tappable',
      );
    });

    testWidgets('and it toggles to the opposite of its current state', (
      tester,
    ) async {
      final changes = <bool>[];
      await pumpMonetaWidget(
        tester,
        SizedBox(
          width: 353,
          child: ListRow(
            title: 'Budget exceeded',
            accessory: ListRowAccessory.toggle,
            toggled: true,
            onToggle: changes.add,
          ),
        ),
        surfaceSize: const Size(393, 300),
      );
      await tester.tap(find.text('Budget exceeded'));
      await tester.pump();
      expect(changes, [false], reason: 'an on row must offer to turn off');
    });

    testWidgets('a toggle row with no handler is inert, not broken', (
      tester,
    ) async {
      await pumpMonetaWidget(
        tester,
        const SizedBox(
          width: 353,
          child: ListRow(
            title: 'Budget exceeded',
            accessory: ListRowAccessory.toggle,
          ),
        ),
        surfaceSize: const Size(393, 300),
      );
      await tester.tap(find.text('Budget exceeded'));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('a chevron row still calls onTap, not onToggle', (
      tester,
    ) async {
      var tapped = 0;
      final toggled = <bool>[];
      await pumpMonetaWidget(
        tester,
        SizedBox(
          width: 353,
          child: ListRow(
            title: 'Settings',
            accessory: ListRowAccessory.chevron,
            onTap: () => tapped++,
            onToggle: toggled.add,
          ),
        ),
        surfaceSize: const Size(393, 300),
      );
      await tester.tap(find.text('Settings'));
      await tester.pump();
      expect(tapped, 1);
      expect(
        toggled,
        isEmpty,
        reason: 'the accessory decides which handler fires',
      );
    });
  });
}
