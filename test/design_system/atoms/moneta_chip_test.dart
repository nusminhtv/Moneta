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

import '../../support/api_surface.dart';
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
      // An input chip must be removable — see the constructor's assert — so
      // the helper supplies both unless a test is checking the assert itself.
      onClose: type == MonetaChipType.input ? (onClose ?? () {}) : onClose,
      closeSemanticLabel: type == MonetaChipType.input ? 'Remove $label' : null,
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
      expect(MonetaChip.pillHeightIn(theme.text, TextScaler.noScaling), 34);
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

  group('what a screen reader hears', () {
    testWidgets('the label is announced once, as a button', (tester) async {
      // It was announced **twice** before this: the pill's own `Text` node
      // carried "Expenses" as static text and the hit layer carried
      // "Expenses, button". Neither this component nor `MonetaBadge` had a
      // single semantics assertion until now — striking, given that owning a
      // 44px box for accessibility is this component's headline decision.
      //
      // The handle is disposed at the end of the body, not through
      // `addTearDown`: the framework verifies handles *before* tear-downs run,
      // so a tear-down disposal fails the test it is meant to clean up.
      final handle = tester.ensureSemantics();

      await pumpChip(
        tester,
        type: MonetaChipType.input,
        onSelected: () {},
        onClose: () {},
      );

      // One node per label. Two would mean the reader meets the same string
      // twice — once as text, once as a button.
      expect(find.bySemanticsLabel('Expenses'), findsOneWidget);
      expect(find.bySemanticsLabel('Remove Expenses'), findsOneWidget);

      handle.dispose();
    });

    testWidgets('a selected chip reports itself selected', (tester) async {
      final handle = tester.ensureSemantics();

      await pumpChip(
        tester,
        type: MonetaChipType.filter,
        selected: true,
        onSelected: () {},
      );
      // Snapshotted as a string **immediately**, because `SemanticsNode` is a
      // live object: holding the node across a second pump and reading it
      // afterwards compares the new state with itself, which is how the first
      // version of this test passed for a chip with no selected state at all.
      final selected = tester
          .getSemantics(find.byKey(MonetaChip.selectHitKey))
          .getSemanticsData()
          .toString();
      expect(selected, contains('label: "Expenses"'));
      expect(selected, contains('isSelected'));

      await pumpChip(
        tester,
        type: MonetaChipType.filter,
        onSelected: () {},
      );
      final unselected = tester
          .getSemantics(find.byKey(MonetaChip.selectHitKey))
          .getSemanticsData()
          .toString();

      // Selection reaches the reader, not only the paint: a colour-only
      // selected state would leave these two identical.
      expect(selected, isNot(unselected));

      handle.dispose();
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

    testWidgets('a filter chip with no callback is inert and silent', (
      tester,
    ) async {
      await pumpChip(tester, type: MonetaChipType.filter);
      await tester.tap(find.byKey(MonetaChip.selectHitKey));
      expect(tester.takeException(), isNull);
    });

    test('an input chip without its close action asserts', () {
      // `17:65` draws the close control unconditionally for `Type=Input`, so a
      // chip that cannot close would paint an affordance it cannot honour —
      // deviation 31's rule, one layer down. Filter and Choice are the types
      // for a chip that is not removable.
      expect(
        () => MonetaChip(
          label: 'Coffee',
          type: MonetaChipType.input,
          closeSemanticLabel: 'Remove Coffee',
        ),
        throwsAssertionError,
      );
      expect(
        () => MonetaChip(
          label: 'Coffee',
          type: MonetaChipType.input,
          onClose: () {},
        ),
        throwsAssertionError,
        reason: 'icon/x carries no authored label, so one must be supplied',
      );
      // And the legal construction does not.
      expect(
        () => MonetaChip(
          label: 'Coffee',
          type: MonetaChipType.input,
          onClose: () {},
          closeSemanticLabel: 'Remove Coffee',
        ),
        returnsNormally,
      );
      // While a filter chip needs neither.
      expect(
        () => MonetaChip(label: 'Coffee', type: MonetaChipType.filter),
        returnsNormally,
      );
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

    testWidgets('the label still fits at 1.0, 1.3 and 2.0 platform text', (
      tester,
    ) async {
      // Two earlier versions of this could not fail.
      //
      // "Nothing threw" passed while the label was **clipped**: the pill stayed
      // 34 at every text size, so at 2x the glyphs wanted a 36px line box
      // inside an 18px one, and no overflow is thrown for that.
      //
      // Then measuring `getSize(find.text(...))` passed too, because the
      // paragraph is inside a fixed-height box — its *rendered* size is already
      // clamped to the space it was given, so it can never report being too
      // tall. And comparing the pill to `pillHeightIn` asserted the
      // implementation against itself.
      //
      // So: the pill's height against a **literal** per scale, and the
      // paragraph's **intrinsic** height — what it actually wants — against
      // the room it has.
      // A list of pairs, not a map: `double` keys cannot be const map keys.
      const expectedPillHeight = [
        [1.0, 34.0],
        [1.3, 39.4],
        [2.0, 52.0],
      ];

      for (final pair in expectedPillHeight) {
        final scale = pair[0];
        final expected = pair[1];
        await pumpChip(
          tester,
          type: MonetaChipType.filter,
          label: 'Bills',
          textScaler: TextScaler.linear(scale),
        );
        expect(
          tester.takeException(),
          isNull,
          reason: 'overflowed at ${scale}x text',
        );

        final pill = tester.getSize(find.byKey(MonetaChip.pillKey));
        expect(
          pill.height,
          closeTo(expected, 0.01),
          reason: 'the pill did not grow with ${scale}x text',
        );

        // The label's own line box, **two-sided**.
        //
        // `lessThanOrEqualTo` alone was half a guard: it caught a label
        // wanting more room than it has — the original defect — and passed a
        // label frozen at 1x inside a pill that grew, which
        // `change-verifier` demonstrated by pinning `textScaler:
        // TextScaler.noScaling` on the `Text`. The pill grew, the glyphs did
        // not, nothing overflowed, and 1726 tests passed. So the line box must
        // *equal* the scaled token, not merely fit.
        final paragraph = tester.renderObject<RenderParagraph>(
          find.text('Bills'),
        );
        expect(
          paragraph.getMaxIntrinsicHeight(double.infinity),
          // Half a pixel, because the engine rounds a line box to whole
          // pixels: at 1.3x the arithmetic says 23.4 and the paragraph
          // reports 23.0. The same rounding this project met in the donut's
          // centre. The tolerance is far tighter than the 5.4px a label
          // frozen at 1x would be out by, so the mutation still fails.
          closeTo(expected - MonetaChip.verticalPadding * 2, 0.5),
          reason: 'the label did not scale with ${scale}x text',
        );

        // And the occupied box still contains the pill it exists to hold.
        expect(
          tester.getSize(find.byType(MonetaChip)).height,
          greaterThanOrEqualTo(pill.height),
        );
      }
    });

    test('no raw design value can be supplied', () {
      // Reads the widget's **field declarations**, not its constructor's
      // parameter list. Every parameter here is `this.x`, so the type lives
      // outside that list — `change-verifier` put a `Color? tint` through the
      // public API of all five of this change's components and the whole gate
      // stayed green. See `test/support/api_surface.dart`.
      final source = File(
        'lib/design_system/atoms/moneta_chip.dart',
      ).readAsStringSync();
      expect(rawDesignValueFields(source, 'MonetaChip'), isEmpty);
    });

    test('and that check can itself fail', () {
      // The counterfeit. Without it, the assertion above is indistinguishable
      // from one that always passes — which is exactly what it replaced.
      expect(
        rawDesignValueFields(
          'class MonetaChip extends StatelessWidget {\n'
              '  /// A doc comment mentioning final Color, which is not a field.\n'
              '  final Color? tint;\n'
              '}\n',
          'MonetaChip',
        ),
        ['final Color? tint;'],
      );
      expect(
        rawDesignValueFields('class Other {}', 'MonetaChip'),
        ['<class MonetaChip not found in source>'],
      );
    });
  });
}
