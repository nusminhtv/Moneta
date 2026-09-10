import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/design_system/atoms/moneta_radio.dart';
import 'package:moneta/design_system/tokens/colors.dart';

import '../../support/pump.dart';

void main() {
  const colors = MonetaColors.dark();

  Future<void> pumpRadio(
    WidgetTester tester, {
    required bool selected,
    bool enabled = true,
    VoidCallback? onSelected,
  }) => pumpMonetaWidget(
    tester,
    MonetaRadio(
      selected: selected,
      semanticLabel: 'Weekly',
      enabled: enabled,
      onSelected: onSelected,
    ),
    surfaceSize: const Size(393, 200),
  );

  BoxDecoration controlDecoration(WidgetTester tester) =>
      tester
              .widgetList<DecoratedBox>(find.byType(DecoratedBox))
              .first
              .decoration
          as BoxDecoration;

  group('all four authored variants', () {
    // 2 x 2, and each is asserted rather than only the two the first screen
    // needs. The values are derived from `25:229` and flagged as derived; what
    // these tests pin is that they reach the render tree at all, and that the
    // four variants are four.
    testWidgets('Selected=False, Disabled=False', (tester) async {
      await pumpRadio(tester, selected: false);
      final decoration = controlDecoration(tester);
      expect(decoration.color, colors.surfaceRaised);
      expect(decoration.border!.top.color, colors.borderStrong);
      expect(decoration.shape, BoxShape.circle);
      expect(find.byKey(MonetaRadio.dotKey), findsNothing);
    });

    testWidgets('Selected=True, Disabled=False', (tester) async {
      await pumpRadio(tester, selected: true);
      final decoration = controlDecoration(tester);
      expect(decoration.color, colors.brand);
      expect(decoration.border!.top.color, colors.brand);
      expect(find.byKey(MonetaRadio.dotKey), findsOneWidget);
    });

    testWidgets('Selected=False, Disabled=True', (tester) async {
      await pumpRadio(tester, selected: false, enabled: false);
      final decoration = controlDecoration(tester);
      expect(decoration.color, colors.surfaceRaised);
      expect(decoration.border!.top.color, colors.borderSubtle);
      expect(find.byKey(MonetaRadio.dotKey), findsNothing);
    });

    testWidgets('Selected=True, Disabled=True', (tester) async {
      await pumpRadio(tester, selected: true, enabled: false);
      final decoration = controlDecoration(tester);
      // Disabled wins over selected for the fill: a disabled control must not
      // read as an active brand affordance.
      expect(decoration.color, colors.surfaceRaised);
      expect(decoration.border!.top.color, colors.borderSubtle);
      expect(
        find.byKey(MonetaRadio.dotKey),
        findsOneWidget,
        reason:
            'a disabled radio still has to say which option is selected, so '
            'the dot stays and only its colour changes',
      );
    });

    testWidgets('the four variants are four distinguishable renders', (
      tester,
    ) async {
      final seen = <String>{};
      for (final selected in [false, true]) {
        for (final enabled in [false, true]) {
          await pumpRadio(tester, selected: selected, enabled: enabled);
          final decoration = controlDecoration(tester);
          final dot = find.byKey(MonetaRadio.dotKey).evaluate().isEmpty
              ? 'none'
              : (tester
                            .widgetList<DecoratedBox>(find.byType(DecoratedBox))
                            .last
                            .decoration
                        as BoxDecoration)
                    .color!
                    .toARGB32()
                    .toRadixString(16);
          seen.add('${decoration.color}/${decoration.border!.top.color}/$dot');
        }
      }
      expect(
        seen,
        hasLength(4),
        reason:
            'two variants that render identically make one of the four a '
            'duplicate rather than a variant',
      );
    });
  });

  group('selection is not the same as toggling', () {
    testWidgets('the control is the authored 22, in a 44 hit area', (
      tester,
    ) async {
      await pumpRadio(tester, selected: false);
      expect(
        tester.getSize(find.byType(MonetaRadio)),
        const Size(MonetaRadio.hitSize, MonetaRadio.hitSize),
      );
      expect(
        tester.getSize(find.byType(DecoratedBox).first),
        const Size(MonetaRadio.controlSize, MonetaRadio.controlSize),
      );
    });

    testWidgets('a disabled radio fires no callback', (tester) async {
      var fired = 0;
      await pumpRadio(
        tester,
        selected: false,
        enabled: false,
        onSelected: () => fired++,
      );
      await tester.tap(find.byType(MonetaRadio));
      await tester.pump();
      expect(fired, 0);
    });

    testWidgets('an enabled unselected radio reports the tap', (tester) async {
      var fired = 0;
      await pumpRadio(tester, selected: false, onSelected: () => fired++);
      await tester.tap(find.byType(MonetaRadio));
      await tester.pump();
      expect(fired, 1);
    });

    testWidgets('tapping the selected radio is a no-op', (tester) async {
      var fired = 0;
      await pumpRadio(tester, selected: true, onSelected: () => fired++);
      await tester.tap(find.byType(MonetaRadio));
      await tester.pump();
      expect(
        fired,
        0,
        reason:
            'a group always has a selection, so there is nothing to report; '
            'deselecting is what a checkbox does',
      );
    });

    testWidgets('the whole 44px area is tappable, not just the 22px control', (
      tester,
    ) async {
      var fired = 0;
      await pumpRadio(tester, selected: false, onSelected: () => fired++);
      final rect = tester.getRect(find.byType(MonetaRadio));
      // A corner of the hit area, outside the drawn circle.
      await tester.tapAt(Offset(rect.left + 2, rect.top + 2));
      await tester.pump();
      expect(fired, 1);
    });
  });

  group('a screen reader is told this is one of a group', () {
    testWidgets('the control announces its group, state and label', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpRadio(tester, selected: true);

      expect(
        tester.getSemantics(find.byType(MonetaRadio)),
        matchesSemantics(
          label: 'Weekly',
          isInMutuallyExclusiveGroup: true,
          isChecked: true,
          hasCheckedState: true,
          hasEnabledState: true,
          isEnabled: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('a disabled radio says so', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpRadio(tester, selected: false, enabled: false);

      expect(
        tester.getSemantics(find.byType(MonetaRadio)),
        matchesSemantics(
          label: 'Weekly',
          isInMutuallyExclusiveGroup: true,
          hasCheckedState: true,
          hasEnabledState: true,
        ),
      );
      handle.dispose();
    });
  });
}
