import 'dart:io';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/design_system/atoms/moneta_chip.dart';
import 'package:moneta/design_system/atoms/moneta_icon.dart';
import 'package:moneta/design_system/atoms/moneta_icon_name.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';
import 'package:moneta/design_system/tokens/colors.dart';
import 'package:moneta/design_system/tokens/spacing.dart';

import '../../support/pump.dart';

void main() {
  const colors = MonetaColors.dark();
  final theme = MonetaTheme.dark();

  Future<void> pumpChip(
    WidgetTester tester, {
    required MonetaChipType type,
    bool selected = false,
    String label = 'Expenses',
    MonetaIconName? leadingIcon,
    VoidCallback? onSelected,
    VoidCallback? onClose,
    double? width,
    TextScaler textScaler = TextScaler.noScaling,
  }) {
    final chip = MonetaChip(
      label: label,
      type: type,
      selected: selected,
      leadingIcon: leadingIcon,
      onSelected: onSelected,
      onClose: onClose,
    );
    return pumpMonetaWidget(
      tester,
      width == null ? chip : SizedBox(width: width, child: chip),
      textScaler: textScaler,
    );
  }

  BoxDecoration pillDecoration(WidgetTester tester) =>
      tester.widget<DecoratedBox>(find.byKey(MonetaChip.pillKey)).decoration
          as BoxDecoration;

  group('selection is three changes at once', () {
    for (final type in MonetaChipType.values) {
      testWidgets('${type.name}, selected', (tester) async {
        await pumpChip(tester, type: type, selected: true);

        // All three together. Asserting one at a time is how a swapped border
        // survives: the fill and the label would still be right.
        final decoration = pillDecoration(tester);
        expect(decoration.color, colors.brandSubtle);
        expect(
          (decoration.border! as Border).top.color,
          colors.brand,
        );
        expect(
          tester.widget<Text>(find.text('Expenses')).style!.color,
          colors.brandOnSurface,
        );
      });

      testWidgets('${type.name}, unselected', (tester) async {
        await pumpChip(tester, type: type);

        final decoration = pillDecoration(tester);
        expect(decoration.color, colors.surfaceRaised);
        expect((decoration.border! as Border).top.color, colors.borderDefault);
        expect(
          tester.widget<Text>(find.text('Expenses')).style!.color,
          colors.textSecondary,
        );
      });
    }

    testWidgets('the two states share no colour', (tester) async {
      // Guards the pair: if selected and unselected resolved to the same
      // triple, both tests above would pass and the chip would have no visible
      // selected state at all.
      await pumpChip(tester, type: MonetaChipType.filter);
      final off = pillDecoration(tester);
      await pumpChip(tester, type: MonetaChipType.filter, selected: true);
      final on = pillDecoration(tester);

      expect(on.color, isNot(off.color));
      expect(
        (on.border! as Border).top.color,
        isNot((off.border! as Border).top.color),
      );
    });

    testWidgets('the label is labelMd and the border a hairline', (
      tester,
    ) async {
      await pumpChip(tester, type: MonetaChipType.choice);
      expect(
        tester.widget<Text>(find.text('Expenses')).style!.fontSize,
        theme.text.labelMd.fontSize,
      );
      expect(
        (pillDecoration(tester).border! as Border).top.width,
        MonetaLayout.borderWidthHairline,
      );
      expect(pillDecoration(tester).borderRadius, theme.radii.borderPill);
    });
  });

  group('Input always carries its close control', () {
    testWidgets('and the other two never do', (tester) async {
      for (final type in MonetaChipType.values) {
        for (final selected in [false, true]) {
          await pumpChip(tester, type: type, selected: selected);
          expect(
            find.byKey(MonetaChip.closeHitKey),
            type == MonetaChipType.input ? findsOneWidget : findsNothing,
            reason: '${type.name}, selected=$selected',
          );
        }
      }
    });

    testWidgets("the close glyph is the set's x, at 14", (tester) async {
      await pumpChip(tester, type: MonetaChipType.input);
      final glyph = tester.widget<MonetaIcon>(
        find.byWidgetPredicate(
          (w) => w is MonetaIcon && w.icon == MonetaIconName.x,
        ),
      );
      expect(glyph.size, MonetaChip.closeGlyphSize);
    });

    testWidgets('closing is not selecting', (tester) async {
      var selectedTaps = 0;
      var closeTaps = 0;
      await pumpChip(
        tester,
        type: MonetaChipType.input,
        onSelected: () => selectedTaps++,
        onClose: () => closeTaps++,
      );

      await tester.tap(find.byKey(MonetaChip.closeHitKey));
      expect(closeTaps, 1);
      expect(
        selectedTaps,
        0,
        reason: 'removing a chip must not also select it',
      );

      await tester.tap(find.byKey(MonetaChip.selectHitKey));
      expect(selectedTaps, 1);
      expect(closeTaps, 1);
    });
  });

  group('the chip meets 44px on its own', () {
    testWidgets('a 34px pill inside a 44px box', (tester) async {
      await pumpChip(tester, type: MonetaChipType.filter);

      // Both, and they must differ: the whole point is that the occupied box
      // is bigger than the thing painted in it.
      expect(tester.getSize(find.byType(MonetaChip)).height, 44);
      expect(tester.getSize(find.byKey(MonetaChip.pillKey)).height, 34);
      expect(MonetaChip.hitHeight, MonetaLayout.minTouchTarget);
      expect(MonetaChip.pillHeightIn(theme.text), 34);
    });

    testWidgets('the two tap areas partition the box', (tester) async {
      await pumpChip(
        tester,
        type: MonetaChipType.input,
        onSelected: () {},
        onClose: () {},
      );

      final chip = tester.getRect(find.byType(MonetaChip));
      final close = tester.getRect(find.byKey(MonetaChip.closeHitKey));
      final select = tester.getRect(find.byKey(MonetaChip.selectHitKey));

      // The close control owns a 44 square at the trailing end.
      expect(close.height, MonetaLayout.minTouchTarget);
      expect(close.width, MonetaLayout.minTouchTarget);
      expect(close.right, chip.right);

      // Select owns the rest, full height, and is itself a legal target
      // thanks to the input minimum width.
      expect(select.height, MonetaLayout.minTouchTarget);
      expect(select.right, close.left);
      expect(select.left, chip.left);
      expect(
        select.width,
        greaterThanOrEqualTo(MonetaLayout.minTouchTarget),
        reason: 'the close square must not squeeze select below 44',
      );
    });

    testWidgets('a one-character input chip still splits legally', (
      tester,
    ) async {
      // The case the input minimum exists for.
      await pumpChip(
        tester,
        type: MonetaChipType.input,
        label: 'A',
        onSelected: () {},
        onClose: () {},
      );
      expect(
        tester.getSize(find.byType(MonetaChip)).width,
        greaterThanOrEqualTo(MonetaChip.inputMinimumWidth),
      );
      expect(
        tester.getRect(find.byKey(MonetaChip.selectHitKey)).width,
        greaterThanOrEqualTo(MonetaLayout.minTouchTarget),
      );
    });

    testWidgets('a filter chip has no minimum and no close area', (
      tester,
    ) async {
      // The minimum is for input chips only, so `08.08`'s authored 78 and 93
      // wide filter chips are unaffected.
      await pumpChip(tester, type: MonetaChipType.filter, label: 'A');
      expect(
        tester.getSize(find.byType(MonetaChip)).width,
        lessThan(MonetaChip.inputMinimumWidth),
      );
    });
  });

  group('the leading glyph', () {
    testWidgets('is drawn at 16 and changes nothing else', (tester) async {
      await pumpChip(tester, type: MonetaChipType.filter, selected: true);
      final withoutGlyph = pillDecoration(tester).color;

      await pumpChip(
        tester,
        type: MonetaChipType.filter,
        selected: true,
        leadingIcon: MonetaIconName.check,
      );
      final glyph = tester.widget<MonetaIcon>(
        find.byWidgetPredicate(
          (w) => w is MonetaIcon && w.icon == MonetaIconName.check,
        ),
      );
      expect(glyph.size, MonetaChip.leadingGlyphSize);
      expect(glyph.color, colors.brandOnSurface);
      expect(pillDecoration(tester).color, withoutGlyph);
    });

    testWidgets('is absent by default', (tester) async {
      await pumpChip(tester, type: MonetaChipType.filter);
      expect(find.byType(MonetaIcon), findsNothing);
    });
  });

  group('boundaries', () {
    test('an empty or blank label asserts', () {
      expect(
        () => MonetaChip(label: '', type: MonetaChipType.filter),
        throwsAssertionError,
      );
      expect(
        () => MonetaChip(label: '  ', type: MonetaChipType.filter),
        throwsAssertionError,
      );
    });

    testWidgets('a chip with no callbacks is inert and silent', (tester) async {
      await pumpChip(tester, type: MonetaChipType.input);
      await tester.tap(find.byKey(MonetaChip.selectHitKey));
      await tester.tap(find.byKey(MonetaChip.closeHitKey));
      expect(tester.takeException(), isNull);
    });

    testWidgets('a long label truncates and the close control survives', (
      tester,
    ) async {
      await pumpChip(
        tester,
        type: MonetaChipType.input,
        label: 'Bills, utilities and everything else',
        width: 140,
        onClose: () {},
      );
      expect(tester.takeException(), isNull);

      expect(
        tester
            .renderObject<RenderParagraph>(
              find.text('Bills, utilities and everything else'),
            )
            .didExceedMaxLines,
        isTrue,
      );
      // The remove affordance is the one thing that must not be clipped: a
      // chip you cannot remove is worse than one with a shortened label.
      final chip = tester.getRect(find.byType(MonetaChip));
      final close = tester.getRect(find.byKey(MonetaChip.closeHitKey));
      expect(close.right, lessThanOrEqualTo(chip.right));
      expect(close.width, MonetaLayout.minTouchTarget);
    });

    testWidgets('nothing overflows at 1.0, 1.3 and 2.0 platform text', (
      tester,
    ) async {
      for (final scale in <double>[1, 1.3, 2]) {
        await pumpChip(
          tester,
          type: MonetaChipType.input,
          label: 'Bills and utilities',
          width: 140,
          textScaler: TextScaler.linear(scale),
        );
        expect(
          tester.takeException(),
          isNull,
          reason: 'overflowed at ${scale}x text',
        );
      }
    });

    test('no colour, style or geometry can be supplied', () {
      final source = File(
        'lib/design_system/atoms/moneta_chip.dart',
      ).readAsStringSync();
      final constructor = source.substring(
        source.indexOf('MonetaChip({'),
        source.indexOf('  /// What the chip says.'),
      );
      expect(constructor, isNot(contains('Color')));
      expect(constructor, isNot(contains('TextStyle')));
      expect(constructor, isNot(contains('EdgeInsets')));
      // Guard the guard: the slice must really be the constructor.
      expect(constructor, contains('required this.label'));
      expect(constructor, contains('required this.type'));
    });
  });
}
