import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/design_system/atoms/moneta_icon.dart';
import 'package:moneta/design_system/atoms/moneta_icon_name.dart';
import 'package:moneta/design_system/molecules/moneta_text_field.dart';
import 'package:moneta/design_system/tokens/colors.dart';
import 'package:moneta/design_system/tokens/spacing.dart';

import '../../support/pump.dart';

void main() {
  const colors = MonetaColors.dark();

  Future<TextEditingController> pumpField(
    WidgetTester tester, {
    String? label = 'Email',
    String? placeholder = 'you@example.com',
    String? helper = 'We will never share your email.',
    String? errorText,
    bool enabled = true,
    String text = '',
    MonetaIconName? leading,
    MonetaIconName? trailing,
    VoidCallback? onTrailing,
  }) async {
    final controller = TextEditingController(text: text);
    addTearDown(controller.dispose);
    await pumpMonetaWidget(
      tester,
      SizedBox(
        width: 353,
        child: MonetaTextField(
          controller: controller,
          label: label,
          placeholder: placeholder,
          helper: helper,
          errorText: errorText,
          enabled: enabled,
          leadingIcon: leading,
          trailingIcon: trailing,
          onTrailingIconPressed: onTrailing,
        ),
      ),
      surfaceSize: const Size(393, 400),
    );
    return controller;
  }

  BoxDecoration fieldDecoration(WidgetTester tester) {
    final box = tester.widget<DecoratedBox>(
      find
          .descendant(
            of: find.byType(MonetaTextField),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    return box.decoration as BoxDecoration;
  }

  group('state is derived, never passed', () {
    test('the resolution order is disabled, error, focused, filled', () {
      // A disabled field stays disabled even holding an error, and an error
      // outranks focus so the message is not hidden behind a focus ring.
      expect(
        MonetaTextFieldState.of(
          enabled: false,
          focused: true,
          hasText: true,
          hasError: true,
        ),
        MonetaTextFieldState.disabled,
      );
      expect(
        MonetaTextFieldState.of(
          enabled: true,
          focused: true,
          hasText: true,
          hasError: true,
        ),
        MonetaTextFieldState.error,
      );
      expect(
        MonetaTextFieldState.of(
          enabled: true,
          focused: true,
          hasText: true,
          hasError: false,
        ),
        MonetaTextFieldState.focused,
      );
      expect(
        MonetaTextFieldState.of(
          enabled: true,
          focused: false,
          hasText: true,
          hasError: false,
        ),
        MonetaTextFieldState.filled,
      );
      expect(
        MonetaTextFieldState.of(
          enabled: true,
          focused: false,
          hasText: false,
          hasError: false,
        ),
        MonetaTextFieldState.normal,
      );
    });

    testWidgets('typing moves it from normal to filled', (tester) async {
      final controller = await pumpField(tester);
      final before = fieldDecoration(tester);

      controller.text = 'hello';
      await tester.pump();

      // Filled and normal share a border in the design, so the observable
      // difference is the text; this asserts the field re-rendered rather than
      // holding a stale state.
      expect(find.text('hello'), findsOneWidget);
      expect(fieldDecoration(tester).color, before.color);
    });
  });

  group('the field body', () {
    testWidgets('is 52 tall, which clears the touch target unaided', (
      tester,
    ) async {
      await pumpField(tester);
      final body = tester.getSize(
        find
            .descendant(
              of: find.byType(MonetaTextField),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      expect(body.height, 52);
      expect(body.height, greaterThanOrEqualTo(44));
    });
  });

  group('error is not signalled by colour alone', () {
    testWidgets('error changes the border width as well as its colour', (
      tester,
    ) async {
      await pumpField(tester);
      final normal = fieldDecoration(tester).border! as Border;

      await pumpField(tester, errorText: 'That address is not valid');
      final error = fieldDecoration(tester).border! as Border;

      expect(error.top.color, colors.expense);
      expect(
        error.top.width,
        isNot(normal.top.width),
        reason: 'error is distinguishable only by colour — fails in greyscale',
      );
      expect(error.top.width, MonetaLayout.borderWidthEmphasis);
    });

    testWidgets('the helper line turns the error colour too', (tester) async {
      await pumpField(tester, errorText: 'That address is not valid');
      final helper = tester.widget<Text>(
        find.text('That address is not valid'),
      );
      expect(helper.style!.color, colors.expense);
    });

    testWidgets('the error message replaces the helper', (tester) async {
      await pumpField(
        tester,
        helper: 'We will never share your email.',
        errorText: 'That address is not valid',
      );
      expect(find.text('That address is not valid'), findsOneWidget);
      expect(find.text('We will never share your email.'), findsNothing);
    });
  });

  group('focus', () {
    testWidgets('focus thickens the border and adds the brand glow', (
      tester,
    ) async {
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);

      await pumpMonetaWidget(
        tester,
        SizedBox(
          width: 353,
          child: MonetaTextField(focusNode: focusNode, label: 'Email'),
        ),
        surfaceSize: const Size(393, 400),
      );

      final resting = fieldDecoration(tester);
      expect(resting.boxShadow, anyOf(isNull, isEmpty));

      focusNode.requestFocus();
      await tester.pump();

      final focused = fieldDecoration(tester);
      expect((focused.border! as Border).top.color, colors.borderFocus);
      expect(
        (focused.border! as Border).top.width,
        MonetaLayout.borderWidthFocus,
      );
      expect(
        (focused.border! as Border).top.width,
        isNot((resting.border! as Border).top.width),
        reason: 'focus is distinguishable only by colour',
      );
      expect(focused.boxShadow, isNotNull);
      expect(focused.boxShadow, isNotEmpty);
    });
  });

  group('disabled', () {
    testWidgets('reads the disabled tokens rather than dimming', (
      tester,
    ) async {
      await pumpField(tester, enabled: false, text: 'you@example.com');

      expect(fieldDecoration(tester).color, colors.surface);
      expect(
        tester.widget<Text>(find.text('Email')).style!.color,
        colors.textDisabled,
      );
      expect(
        tester
            .widget<Text>(find.text('We will never share your email.'))
            .style!
            .color,
        colors.textDisabled,
      );
    });

    testWidgets('a disabled trailing glyph does not fire', (tester) async {
      var taps = 0;
      await pumpField(
        tester,
        enabled: false,
        trailing: MonetaIconName.eye,
        onTrailing: () => taps++,
      );
      await tester.tap(find.byType(MonetaIcon), warnIfMissed: false);
      expect(taps, 0);
    });
  });

  group('optional parts reserve no space', () {
    testWidgets('omitting the label makes the widget shorter', (tester) async {
      await pumpField(tester, helper: null);
      final withLabel = tester.getSize(find.byType(MonetaTextField)).height;

      await pumpField(tester, label: null, helper: null);
      final without = tester.getSize(find.byType(MonetaTextField)).height;

      expect(without, lessThan(withLabel));
      // And the body starts at the very top, rather than after a blank gap.
      final widget = tester.getRect(find.byType(MonetaTextField));
      final body = tester.getRect(
        find
            .descendant(
              of: find.byType(MonetaTextField),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      expect(body.top, widget.top);
    });

    testWidgets('omitting the helper makes the widget shorter', (
      tester,
    ) async {
      await pumpField(tester, label: null);
      final withHelper = tester.getSize(find.byType(MonetaTextField)).height;

      await pumpField(tester, label: null, helper: null);
      final without = tester.getSize(find.byType(MonetaTextField)).height;

      expect(without, lessThan(withHelper));
    });
  });

  group('long content', () {
    testWidgets('an over-long label, value and helper do not overflow', (
      tester,
    ) async {
      const long = 'Averyveryverylongunbrokenwordthatcannotwrapanywhereatall';
      await pumpField(
        tester,
        label: long,
        helper: long,
        text: long,
      );
      expect(tester.takeException(), isNull);
      expect(
        tester
            .getSize(
              find
                  .descendant(
                    of: find.byType(MonetaTextField),
                    matching: find.byType(DecoratedBox),
                  )
                  .first,
            )
            .height,
        52,
        reason: 'long content changed the field body height',
      );
    });
  });

  group('glyphs', () {
    testWidgets('a leading and a trailing glyph both render', (tester) async {
      await pumpField(
        tester,
        leading: MonetaIconName.mail,
        trailing: MonetaIconName.eye,
      );
      final icons = tester
          .widgetList<MonetaIcon>(find.byType(MonetaIcon))
          .toList();
      expect(icons, hasLength(2));
      expect(icons.first.icon, MonetaIconName.mail);
      expect(icons.last.icon, MonetaIconName.eye);
    });

    testWidgets('the trailing glyph fires when enabled', (tester) async {
      var taps = 0;
      await pumpField(
        tester,
        trailing: MonetaIconName.eye,
        onTrailing: () => taps++,
      );
      await tester.tap(find.byType(MonetaIcon));
      expect(taps, 1);
    });
  });
}
