import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/design_system/atoms/moneta_icon.dart';
import 'package:moneta/design_system/atoms/moneta_icon_name.dart';
import 'package:moneta/design_system/tokens/colors.dart';

import '../../support/pump.dart';

void main() {
  // rootBundle does real asynchronous I/O. testWidgets runs its body inside a
  // FakeAsync zone, where a real I/O future never completes and the test hangs
  // forever rather than failing. Asset checks therefore use plain test() with
  // the binding initialised explicitly.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('catalogue', () {
    test('covers the whole Figma iconography page', () {
      // Node 5:7 holds 50 icons. If Figma gains one, this fails until the
      // catalogue is regenerated — which is the point.
      expect(MonetaIconName.values, hasLength(50));
    });

    test('every entry has a distinct Figma name', () {
      final names = MonetaIconName.values.map((i) => i.figmaName).toSet();
      expect(names, hasLength(MonetaIconName.values.length));
    });

    test('Figma names are kebab-case with no icon/ prefix', () {
      final kebab = RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*$');
      for (final icon in MonetaIconName.values) {
        expect(icon.figmaName, matches(kebab), reason: icon.name);
      }
    });

    test('asset paths point into the declared assets directory', () {
      for (final icon in MonetaIconName.values) {
        expect(icon.assetPath, 'assets/icons/${icon.figmaName}.svg');
      }
    });

    test('tryParse round-trips, and rejects unknown names', () {
      for (final icon in MonetaIconName.values) {
        expect(MonetaIconName.tryParse(icon.figmaName), icon);
      }
      expect(MonetaIconName.tryParse('rocket'), isNull);
      expect(MonetaIconName.tryParse('alertTriangle'), isNull);
    });
  });

  group('bundled assets', () {
    // These must fail in CI rather than on a user's device: an enum entry whose
    // file was never committed renders as empty space, which reads as a spacing
    // bug rather than a missing file.
    test('every icon resolves to a real bundled asset', () async {
      for (final icon in MonetaIconName.values) {
        final data = await rootBundle.loadString(icon.assetPath);
        expect(data, isNotEmpty, reason: '${icon.assetPath} is empty');
        expect(data, contains('<svg'), reason: '${icon.assetPath} not an SVG');
      }
    });

    test('every stroked icon is at the design stroke weight', () async {
      // Stroke weight 1.75 is the whole reason these are exported assets rather
      // than an icon package (ADR 0002). A re-export at 2.0 must fail here.
      for (final icon in MonetaIconName.values) {
        final data = await rootBundle.loadString(icon.assetPath);
        if (!data.contains('stroke-width')) continue; // filled brand marks
        expect(
          data,
          contains('stroke-width="1.75"'),
          reason: '${icon.assetPath} is not at stroke weight 1.75',
        );
      }
    });

    test('assets are on the 24px canvas', () async {
      for (final icon in MonetaIconName.values) {
        final data = await rootBundle.loadString(icon.assetPath);
        expect(
          data,
          contains('viewBox="0 0 24 24"'),
          reason: '${icon.assetPath} is not 24x24',
        );
      }
    });
  });

  group('colour handling', () {
    test('exactly one icon preserves its own colours', () {
      final preserved = MonetaIconName.values
          .where((i) => i.preservesColour)
          .toList();
      expect(preserved, [MonetaIconName.brandGoogle]);
    });

    testWidgets('a normal icon is tinted with the requested colour', (
      tester,
    ) async {
      const magenta = Color(0xFFFF00FF);
      await pumpMonetaWidget(
        tester,
        const MonetaIcon(MonetaIconName.plus, color: magenta),
      );
      final svg = tester.widget<SvgPicture>(find.byType(SvgPicture));
      expect(svg.colorFilter, const ColorFilter.mode(magenta, BlendMode.srcIn));
    });

    testWidgets('an untinted icon defaults to the primary text colour', (
      tester,
    ) async {
      await pumpMonetaWidget(tester, const MonetaIcon(MonetaIconName.home));
      final svg = tester.widget<SvgPicture>(find.byType(SvgPicture));
      expect(
        svg.colorFilter,
        const ColorFilter.mode(Color(0xFFF6F8FB), BlendMode.srcIn),
      );
      // The assets are already drawn in this colour, so the default tint is a
      // no-op rather than a surprise.
      expect(const MonetaColors.dark().textPrimary, const Color(0xFFF6F8FB));
    });

    testWidgets('the multi-colour brand mark is never tinted', (tester) async {
      await pumpMonetaWidget(
        tester,
        const MonetaIcon(
          MonetaIconName.brandGoogle,
          color: Color(0xFFFF00FF),
        ),
      );
      final svg = tester.widget<SvgPicture>(find.byType(SvgPicture));
      expect(svg.colorFilter, isNull);
    });

    test('brand-google really does carry four colours', () async {
      // Justifies the exception above rather than taking it on trust.
      final data = await rootBundle.loadString(
        MonetaIconName.brandGoogle.assetPath,
      );
      final fills = RegExp(
        'fill="(#[0-9A-Fa-f]{6})"',
      ).allMatches(data).map((m) => m.group(1)).toSet();
      expect(fills, hasLength(4));
    });

    testWidgets('the other brand mark is monochrome, so it is tinted', (
      tester,
    ) async {
      expect(MonetaIconName.brandApple.preservesColour, isFalse);
      await pumpMonetaWidget(
        tester,
        const MonetaIcon(MonetaIconName.brandApple),
      );
      final svg = tester.widget<SvgPicture>(find.byType(SvgPicture));
      expect(svg.colorFilter, isNotNull);
    });
  });

  group('sizing', () {
    testWidgets('defaults to the 24px design canvas', (tester) async {
      await pumpMonetaWidget(tester, const MonetaIcon(MonetaIconName.search));
      final svg = tester.widget<SvgPicture>(find.byType(SvgPicture));
      expect(svg.width, 24);
      expect(svg.height, 24);
    });

    testWidgets('an explicit size is square', (tester) async {
      await pumpMonetaWidget(
        tester,
        const MonetaIcon(MonetaIconName.search, size: 20),
      );
      final svg = tester.widget<SvgPicture>(find.byType(SvgPicture));
      expect(svg.width, 20);
      expect(svg.height, 20);
    });
  });

  group('accessibility', () {
    testWidgets('a label reaches the semantics tree', (tester) async {
      await pumpMonetaWidget(
        tester,
        const MonetaIcon(MonetaIconName.eye, semanticLabel: 'Show balance'),
      );
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Show balance'), findsOneWidget);
    });
  });
}
