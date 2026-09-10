import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/design_system/atoms/moneta_avatar.dart';
import 'package:moneta/design_system/atoms/moneta_icon.dart';
import 'package:moneta/design_system/atoms/moneta_icon_name.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';
import 'package:moneta/design_system/tokens/colors.dart';

import '../../support/pump.dart';

/// A 1×1 transparent PNG, so the image variant is exercised without any I/O.
final _pixel = MemoryImage(
  Uint8List.fromList(const [
    137,
    80,
    78,
    71,
    13,
    10,
    26,
    10,
    0,
    0,
    0,
    13,
    73,
    72,
    68,
    82,
    0,
    0,
    0,
    1,
    0,
    0,
    0,
    1,
    8,
    6,
    0,
    0,
    0,
    31,
    21,
    196,
    137,
    0,
    0,
    0,
    10,
    73,
    68,
    65,
    84,
    120,
    156,
    99,
    0,
    1,
    0,
    0,
    5,
    0,
    1,
    13,
    10,
    45,
    180,
    0,
    0,
    0,
    0,
    73,
    69,
    78,
    68,
    174,
    66,
    96,
    130,
  ]),
);

void main() {
  const colors = MonetaColors.dark();
  final theme = MonetaTheme.dark();

  Future<void> pumpAvatar(
    WidgetTester tester, {
    required MonetaAvatarType type,
    required MonetaAvatarSize size,
    String? name,
    ImageProvider<Object>? image,
  }) => pumpMonetaWidget(
    tester,
    MonetaAvatar(type: type, size: size, name: name, image: image),
    surfaceSize: const Size(200, 200),
  );

  BoxDecoration decorationIn(WidgetTester tester) =>
      tester.widget<DecoratedBox>(find.byType(DecoratedBox)).decoration
          as BoxDecoration;

  group('all twelve authored variants', () {
    for (final type in MonetaAvatarType.values) {
      for (final size in MonetaAvatarSize.values) {
        testWidgets('Type=${type.name}, ${size.figmaName}', (tester) async {
          await pumpAvatar(
            tester,
            type: type,
            size: size,
            name: 'Minh Tran',
            image: _pixel,
          );

          expect(
            tester.getSize(find.byType(MonetaAvatar)),
            Size(size.diameter, size.diameter),
          );
          final decoration = decorationIn(tester);
          expect(decoration.shape, BoxShape.circle);
          expect(
            decoration.color,
            colors.brandSubtle,
            reason: 'every variant sits on the brand tint',
          );
        });
      }
    }

    testWidgets('the four diameters are the authored ones', (tester) async {
      expect(
        MonetaAvatarSize.values.map((s) => s.diameter),
        [24, 32, 40, 56],
      );
      await pumpAvatar(
        tester,
        type: MonetaAvatarType.icon,
        size: MonetaAvatarSize.lg,
      );
      expect(tester.getSize(find.byType(MonetaAvatar)), const Size(56, 56));
    });
  });

  group('initials wear the type style bound for their size', () {
    // 24 and 32 share `label/sm`; 40 is `label/md`; 56 is `title/md`. Asserted
    // against the theme's own styles, so a change to the type scale moves both
    // together rather than silently disagreeing.
    testWidgets('each size uses its authored style', (tester) async {
      final expected = {
        MonetaAvatarSize.xs: theme.text.labelSm,
        MonetaAvatarSize.sm: theme.text.labelSm,
        MonetaAvatarSize.md: theme.text.labelMd,
        MonetaAvatarSize.lg: theme.text.titleMd,
      };

      for (final entry in expected.entries) {
        await pumpAvatar(
          tester,
          type: MonetaAvatarType.initials,
          size: entry.key,
          name: 'Minh Tran',
        );
        final style = tester
            .widget<Text>(find.byKey(MonetaAvatar.initialsKey))
            .style!;
        expect(style.fontSize, entry.value.fontSize, reason: entry.key.name);
        expect(
          style.fontWeight,
          entry.value.fontWeight,
          reason: entry.key.name,
        );
        expect(style.color, colors.brandOnSurface, reason: entry.key.name);
      }
    });

    test('the style table is not a scale, which is why it is a table', () {
      // The property a formula would break: two sizes share a style and two do
      // not. Anything derived from the diameter has to special-case at least
      // two of the four.
      expect(
        MonetaAvatarSize.xs.initialsStyle(theme.text).fontSize,
        MonetaAvatarSize.sm.initialsStyle(theme.text).fontSize,
        reason: '24 and 32 share label/sm',
      );
      expect(
        MonetaAvatarSize.md.initialsStyle(theme.text).fontSize,
        isNot(MonetaAvatarSize.sm.initialsStyle(theme.text).fontSize),
      );
      expect(
        MonetaAvatarSize.lg.initialsStyle(theme.text).fontSize,
        isNot(MonetaAvatarSize.md.initialsStyle(theme.text).fontSize),
      );
    });
  });

  group('the glyph carries the authored size and colour', () {
    testWidgets('each size uses its authored glyph size', (tester) async {
      const expected = {
        MonetaAvatarSize.xs: 14.0,
        MonetaAvatarSize.sm: 18.0,
        MonetaAvatarSize.md: 22.0,
        MonetaAvatarSize.lg: 28.0,
      };
      for (final entry in expected.entries) {
        await pumpAvatar(
          tester,
          type: MonetaAvatarType.icon,
          size: entry.key,
        );
        final icon = tester.widget<MonetaIcon>(
          find.byKey(MonetaAvatar.glyphKey),
        );
        expect(icon.size, entry.value, reason: entry.key.name);
        expect(icon.icon, MonetaIconName.user);
      }
    });

    test('the glyph sizes are not the formula they nearly fit', () {
      // 14, 18 and 22 are all `diameter / 2 + 2`. 28 is `diameter / 2`. A
      // formula fitted to the first three gives 30 at 56, and this is the
      // assertion that says so out loud.
      for (final size in [
        MonetaAvatarSize.xs,
        MonetaAvatarSize.sm,
        MonetaAvatarSize.md,
      ]) {
        expect(size.glyphSize, size.diameter / 2 + 2, reason: size.name);
      }
      expect(
        MonetaAvatarSize.lg.glyphSize,
        MonetaAvatarSize.lg.diameter / 2,
        reason: 'and 56 breaks it',
      );
      expect(
        MonetaAvatarSize.lg.glyphSize,
        isNot(MonetaAvatarSize.lg.diameter / 2 + 2),
      );
    });

    testWidgets('the glyph is textSecondary, not the brand colour', (
      tester,
    ) async {
      // `21:120`'s exported glyph is `stroke="#9AA3B4"`. I assumed
      // `brandOnSurface`, because that is what the initials use, and the file
      // says otherwise.
      await pumpAvatar(
        tester,
        type: MonetaAvatarType.icon,
        size: MonetaAvatarSize.lg,
      );
      final icon = tester.widget<MonetaIcon>(find.byKey(MonetaAvatar.glyphKey));
      expect(icon.color, colors.textSecondary);
      expect(icon.color, isNot(colors.brandOnSurface));
    });
  });

  group('initials are derived from a name', () {
    test('one word gives one letter, several give two', () {
      expect(MonetaAvatar.initialsOf('Minh'), 'M');
      expect(MonetaAvatar.initialsOf('Minh Tran'), 'MT');
      expect(
        MonetaAvatar.initialsOf('Nguyen Thi Minh Khai'),
        'NK',
        reason: 'first and last, not the first two',
      );
    });

    test('case and spacing are normalised', () {
      expect(MonetaAvatar.initialsOf('minh tran'), 'MT');
      expect(MonetaAvatar.initialsOf('  Minh   Tran  '), 'MT');
    });

    test('punctuation and digits are not initials', () {
      expect(MonetaAvatar.initialsOf('!!!'), '');
      expect(MonetaAvatar.initialsOf('123 456'), '');
      expect(MonetaAvatar.initialsOf('  '), '');
      expect(MonetaAvatar.initialsOf(null), '');
      expect(MonetaAvatar.initialsOf(''), '');
    });

    test('Vietnamese diacritics count as letters', () {
      expect(MonetaAvatar.initialsOf('Đặng Hà'), 'ĐH');
      expect(MonetaAvatar.initialsOf('Ưu Ái'), 'ƯÁ');
    });

    test('never more than two', () {
      for (final name in [
        'A B C D E F',
        'One Two Three',
        'Nguyen Van Anh Tuan',
      ]) {
        expect(
          MonetaAvatar.initialsOf(name).length,
          lessThanOrEqualTo(MonetaAvatar.maxInitials),
          reason: name,
        );
      }
    });

    testWidgets('initials stay inside the circle at the smallest size', (
      tester,
    ) async {
      // Font-independent: the placeholder font makes any width assertion
      // measure that font, so this asserts containment rather than size.
      await pumpAvatar(
        tester,
        type: MonetaAvatarType.initials,
        size: MonetaAvatarSize.xs,
        name: 'Minh Tran',
      );
      expect(tester.takeException(), isNull);

      final circle = tester.getRect(find.byType(MonetaAvatar));
      final text = tester.getRect(find.byKey(MonetaAvatar.initialsKey));
      expect(text.left, greaterThanOrEqualTo(circle.left));
      expect(text.right, lessThanOrEqualTo(circle.right));
      expect(text.top, greaterThanOrEqualTo(circle.top));
      expect(text.bottom, lessThanOrEqualTo(circle.bottom));
    });
  });

  group('the fallback order is photo, initials, glyph', () {
    testWidgets('an image type with no image falls back to initials', (
      tester,
    ) async {
      await pumpAvatar(
        tester,
        type: MonetaAvatarType.image,
        size: MonetaAvatarSize.lg,
        name: 'Minh Tran',
      );
      expect(find.byKey(MonetaAvatar.imageKey), findsNothing);
      expect(find.byKey(MonetaAvatar.initialsKey), findsOneWidget);
    });

    testWidgets('an image type with neither falls back to the glyph', (
      tester,
    ) async {
      await pumpAvatar(
        tester,
        type: MonetaAvatarType.image,
        size: MonetaAvatarSize.lg,
      );
      expect(find.byKey(MonetaAvatar.glyphKey), findsOneWidget);
      expect(
        find.byKey(MonetaAvatar.initialsKey),
        findsNothing,
        reason: 'an empty circle is not a state; the glyph is',
      );
    });

    testWidgets('an initials type with a letterless name falls back', (
      tester,
    ) async {
      await pumpAvatar(
        tester,
        type: MonetaAvatarType.initials,
        size: MonetaAvatarSize.md,
        name: '123',
      );
      expect(find.byKey(MonetaAvatar.glyphKey), findsOneWidget);
    });

    testWidgets('the icon type stays the icon even with a name', (
      tester,
    ) async {
      // Explicitly asking for the glyph is not a fallback; it is a choice.
      await pumpAvatar(
        tester,
        type: MonetaAvatarType.icon,
        size: MonetaAvatarSize.md,
        name: 'Minh Tran',
      );
      expect(find.byKey(MonetaAvatar.glyphKey), findsOneWidget);
      expect(find.byKey(MonetaAvatar.initialsKey), findsNothing);
    });

    testWidgets('a supplied image is used and clipped to the circle', (
      tester,
    ) async {
      await pumpAvatar(
        tester,
        type: MonetaAvatarType.image,
        size: MonetaAvatarSize.lg,
        name: 'Minh Tran',
        image: _pixel,
      );
      expect(find.byKey(MonetaAvatar.imageKey), findsOneWidget);
      expect(find.byKey(MonetaAvatar.initialsKey), findsNothing);
      expect(
        find.ancestor(
          of: find.byKey(MonetaAvatar.imageKey),
          matching: find.byType(ClipOval),
        ),
        findsOneWidget,
        reason: 'a square photo behind a circle is not an avatar',
      );
    });

    test('resolvedType reports what will actually be drawn', () {
      expect(
        const MonetaAvatar(
          type: MonetaAvatarType.image,
          size: MonetaAvatarSize.md,
        ).resolvedType,
        MonetaAvatarType.icon,
      );
      expect(
        const MonetaAvatar(
          type: MonetaAvatarType.image,
          size: MonetaAvatarSize.md,
          name: 'Minh Tran',
        ).resolvedType,
        MonetaAvatarType.initials,
      );
    });
  });

  group('accessibility', () {
    testWidgets('announces the name when it has one', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpAvatar(
        tester,
        type: MonetaAvatarType.initials,
        size: MonetaAvatarSize.lg,
        name: 'Minh Tran',
      );
      expect(
        tester.getSemantics(find.byType(MonetaAvatar)),
        matchesSemantics(label: 'Minh Tran'),
      );
      handle.dispose();
    });

    testWidgets('falls back to a description when it has no name', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpAvatar(
        tester,
        type: MonetaAvatarType.icon,
        size: MonetaAvatarSize.lg,
      );
      expect(
        tester.getSemantics(find.byType(MonetaAvatar)),
        matchesSemantics(label: 'Profile picture'),
      );
      handle.dispose();
    });
  });
}
