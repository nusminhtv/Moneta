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

    testWidgets('reports row taps separately from toggle taps', (tester) async {
      var rowTaps = 0;
      final toggleValues = <bool>[];
      await pumpRow(
        tester,
        accessory: ListRowAccessory.toggle,
        onTap: () => rowTaps++,
        onToggle: toggleValues.add,
      );

      await tester.tap(find.text('Notifications'));
      await tester.tap(find.byKey(ListRow.toggleKey));

      expect(rowTaps, 1);
      expect(toggleValues, [true]);
    });
  });
}
