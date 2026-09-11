import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/design_system/atoms/moneta_icon.dart';
import 'package:moneta/design_system/atoms/moneta_icon_name.dart';
import 'package:moneta/design_system/molecules/moneta_search_field.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';
import 'package:moneta/design_system/tokens/colors.dart';
import 'package:moneta/design_system/tokens/spacing.dart';

import '../../support/pump.dart';

void main() {
  const colors = MonetaColors.dark();
  final theme = MonetaTheme.dark();
  const placeholder = 'Search transactions';

  Future<void> pumpField(
    WidgetTester tester, {
    TextEditingController? controller,
    bool enabled = true,
    ValueChanged<String>? onChanged,
    double width = 353,
  }) => pumpMonetaWidget(
    tester,
    SizedBox(
      width: width,
      child: MonetaSearchField(
        placeholder: placeholder,
        controller: controller,
        enabled: enabled,
        onChanged: onChanged,
      ),
    ),
  );

  BoxDecoration decoration(WidgetTester tester) =>
      tester
              .widget<DecoratedBox>(find.byKey(MonetaSearchField.fieldKey))
              .decoration
          as BoxDecoration;

  group('the state is the text', () {
    testWidgets('empty shows its placeholder and no clear', (tester) async {
      await pumpField(tester);

      expect(find.text(placeholder), findsOneWidget);
      expect(find.byKey(MonetaSearchField.clearKey), findsNothing);

      final hint = tester.widget<EditableText>(find.byType(EditableText));
      expect(hint.style.color, colors.textPrimary);
    });

    testWidgets('text shows the value and a clear', (tester) async {
      final controller = TextEditingController(text: 'coffee');
      addTearDown(controller.dispose);
      await pumpField(tester, controller: controller);

      expect(find.text('coffee'), findsOneWidget);
      expect(find.byKey(MonetaSearchField.clearKey), findsOneWidget);
    });

    testWidgets('typing makes the clear appear, clearing makes it go', (
      tester,
    ) async {
      final seen = <String>[];
      await pumpField(tester, onChanged: seen.add);

      await tester.enterText(find.byType(EditableText), 'gr');
      await tester.pump();
      expect(find.byKey(MonetaSearchField.clearKey), findsOneWidget);
      expect(seen, ['gr']);

      await tester.tap(find.byKey(MonetaSearchField.clearKey));
      await tester.pump();
      expect(find.byKey(MonetaSearchField.clearKey), findsNothing);
      expect(find.text(placeholder), findsOneWidget);
      // The clear must be *reported*: a screen filtering a list on this text
      // has to hear that the filter is gone, or it keeps showing the filtered
      // list under an empty field.
      expect(seen, ['gr', '']);
    });

    test('there is no state parameter', () {
      final source = File(
        'lib/design_system/molecules/moneta_search_field.dart',
      ).readAsStringSync();
      // Scoped to the constructor's parameter block on purpose: the widget's
      // own `createState` and its `State` subclass both contain "State", so a
      // whole-file check would fail against a correct implementation.
      final start = source.indexOf('const MonetaSearchField({');
      final block = source.substring(
        source.indexOf('{', start),
        source.indexOf('});', start),
      );
      expect(block.toLowerCase(), isNot(contains('state')));
      // Guard the guard: the slice must be the parameter block, or the
      // assertion above holds over the wrong text.
      expect(block, contains('required this.placeholder'));
      expect(block, contains('this.controller'));
    });
  });

  group('the box', () {
    testWidgets('50 tall, a pill, and a hairline border', (tester) async {
      await pumpField(tester);

      expect(
        tester.getSize(find.byKey(MonetaSearchField.fieldKey)).height,
        50,
      );
      expect(MonetaSearchField.heightIn(theme.text, TextScaler.noScaling), 50);
      expect(decoration(tester).borderRadius, theme.radii.borderPill);
      expect(decoration(tester).color, colors.surfaceRaised);
      expect(
        (decoration(tester).border! as Border).top.color,
        colors.borderDefault,
      );
      expect(
        (decoration(tester).border! as Border).top.width,
        MonetaLayout.borderWidthHairline,
      );
    });

    testWidgets('the clear glyph stays 18 inside a 44 target', (tester) async {
      final controller = TextEditingController(text: 'coffee');
      addTearDown(controller.dispose);
      await pumpField(tester, controller: controller);

      // Both, and they must differ: the glyph is authored, the target is the
      // platform minimum, and conflating them is the defect.
      expect(
        tester.getSize(find.byKey(MonetaSearchField.clearKey)),
        const Size.square(MonetaLayout.minTouchTarget),
      );
      final glyph = tester.widget<MonetaIcon>(
        find.byWidgetPredicate(
          (w) => w is MonetaIcon && w.icon == MonetaIconName.x,
        ),
      );
      expect(glyph.size, MonetaSearchField.clearGlyphSize);
      expect(
        MonetaSearchField.clearGlyphSize,
        lessThan(MonetaLayout.minTouchTarget),
      );
    });

    testWidgets('the search glyph is 20 and decorative', (tester) async {
      await pumpField(tester);
      final glyph = tester.widget<MonetaIcon>(
        find.byWidgetPredicate(
          (w) => w is MonetaIcon && w.icon == MonetaIconName.search,
        ),
      );
      expect(glyph.size, MonetaSearchField.searchGlyphSize);
      expect(
        find.ancestor(
          of: find.byWidgetPredicate(
            (w) => w is MonetaIcon && w.icon == MonetaIconName.search,
          ),
          matching: find.byType(ExcludeSemantics),
        ),
        findsOneWidget,
      );
    });
  });

  group('the controller is disposed only if it was made here', () {
    testWidgets('a supplied controller outlives the field', (tester) async {
      final mine = TextEditingController(text: 'coffee');
      addTearDown(mine.dispose);

      await pumpField(tester, controller: mine);
      await tester.pumpWidget(const SizedBox());

      // The assertion is that it still **works**, not that nothing threw: a
      // missed disposal throws nothing at all, so "no exception" would pass
      // for either behaviour.
      mine
        ..addListener(() {})
        ..text = 'still usable';
      expect(mine.text, 'still usable');
    });

    testWidgets('an owned controller is disposed', (tester) async {
      await pumpField(tester);
      // The field's own controller, reached through the EditableText it built.
      final owned = tester
          .widget<EditableText>(find.byType(EditableText))
          .controller;

      await tester.pumpWidget(const SizedBox());

      expect(
        () => owned.addListener(() {}),
        throwsA(isA<AssertionError>()),
        reason: 'a controller the field created must not outlive it',
      );
    });

    testWidgets('a replaced controller is the one read and reported', (
      tester,
    ) async {
      final first = TextEditingController(text: 'coffee');
      final second = TextEditingController(text: 'rent');
      addTearDown(first.dispose);
      addTearDown(second.dispose);

      await pumpField(tester, controller: first);
      expect(find.text('coffee'), findsOneWidget);

      await pumpField(tester, controller: second);
      expect(find.text('rent'), findsOneWidget);
      expect(find.text('coffee'), findsNothing);

      // And the one it let go of is untouched.
      first.text = 'still usable';
      expect(first.text, 'still usable');
    });
  });

  group('boundaries', () {
    testWidgets('a disabled field accepts nothing and offers no clear', (
      tester,
    ) async {
      final controller = TextEditingController(text: 'coffee');
      addTearDown(controller.dispose);
      await pumpField(tester, controller: controller, enabled: false);

      expect(find.byKey(MonetaSearchField.clearKey), findsNothing);
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).style.color,
        colors.textDisabled,
      );

      await tester.enterText(find.byType(EditableText), 'tea');
      await tester.pump();
      expect(
        controller.text,
        'coffee',
        reason: 'a disabled field must not take input',
      );
    });

    testWidgets('focus changes nothing', (tester) async {
      await pumpField(tester);
      final before = decoration(tester);
      final heightBefore = tester
          .getSize(find.byKey(MonetaSearchField.fieldKey))
          .height;

      await tester.tap(find.byType(EditableText));
      await tester.pumpAndSettle();

      final after = decoration(tester);
      expect(after.color, before.color);
      expect(
        (after.border! as Border).top.color,
        (before.border! as Border).top.color,
      );
      expect(after.boxShadow, before.boxShadow);
      expect(
        tester.getSize(find.byKey(MonetaSearchField.fieldKey)).height,
        heightBefore,
      );
      // `27:44` authors a focus state and `35:38` authors two states, neither
      // of them focus. A focus ring here would be invention.
    });

    testWidgets('a value longer than the field does not grow it', (
      tester,
    ) async {
      final controller = TextEditingController(
        text: 'coffee, rent, groceries, transport and everything else',
      );
      addTearDown(controller.dispose);
      await pumpField(tester, controller: controller);

      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byKey(MonetaSearchField.fieldKey)).height,
        50,
      );
      expect(
        tester.getSize(find.byKey(MonetaSearchField.clearKey)),
        const Size.square(MonetaLayout.minTouchTarget),
      );
    });

    testWidgets('a pasted newline does not make it two lines tall', (
      tester,
    ) async {
      await pumpField(tester);
      await tester.enterText(find.byType(EditableText), 'coffee\nrent');
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byKey(MonetaSearchField.fieldKey)).height,
        50,
      );
    });

    testWidgets('a larger platform text size makes it taller, not broken', (
      tester,
    ) async {
      // The height is fixed rather than content-driven, which is what lets the
      // clear control be 44 tall beside a 24px line. Fixed must not mean
      // frozen: at a larger text size the field grows with the text.
      final controller = TextEditingController(text: 'coffee');
      addTearDown(controller.dispose);

      await pumpMonetaWidget(
        tester,
        SizedBox(
          width: 353,
          child: MonetaSearchField(
            placeholder: placeholder,
            controller: controller,
          ),
        ),
        textScaler: const TextScaler.linear(1.3),
      );

      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byKey(MonetaSearchField.fieldKey)).height,
        greaterThan(50),
      );
      expect(
        tester.getSize(find.byKey(MonetaSearchField.clearKey)),
        const Size.square(MonetaLayout.minTouchTarget),
      );
    });

    testWidgets('a field with no callback is silent, not broken', (
      tester,
    ) async {
      final controller = TextEditingController(text: 'coffee');
      addTearDown(controller.dispose);
      await pumpField(tester, controller: controller);

      await tester.tap(find.byKey(MonetaSearchField.clearKey));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(controller.text, isEmpty);
    });
  });
}
