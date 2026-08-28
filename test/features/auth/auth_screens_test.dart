import 'package:flutter/material.dart' show MaterialApp;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/design_system/atoms/moneta_button.dart';
import 'package:moneta/design_system/atoms/moneta_checkbox.dart';
import 'package:moneta/design_system/atoms/moneta_icon_name.dart';
import 'package:moneta/design_system/molecules/moneta_otp_field.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';
import 'package:moneta/features/auth/presentation/forgot_password_screen.dart';
import 'package:moneta/features/auth/presentation/log_in_screen.dart';
import 'package:moneta/features/auth/presentation/reset_success_screen.dart';
import 'package:moneta/features/auth/presentation/setup_screens.dart';
import 'package:moneta/features/auth/presentation/sign_up_screen.dart';
import 'package:moneta/features/auth/presentation/verify_code_screen.dart';

import '../../support/pump.dart';

void main() {
  Future<void> pumpScreen(WidgetTester tester, Widget screen) =>
      pumpMonetaWidget(
        tester,
        SizedBox(width: 393, height: 852, child: screen),
        surfaceSize: const Size(393, 852),
      );

  group('01.06 Log in', () {
    testWidgets('will not submit an invalid email', (tester) async {
      var submissions = 0;
      await pumpScreen(
        tester,
        LogInScreen(
          onSubmit: (_, _) => submissions++,
          onForgotPassword: () {},
          onCreateAccount: () {},
        ),
      );

      await tester.enterText(find.byType(EditableText).first, 'nope');
      await tester.tap(find.byKey(LogInScreen.submitKey));
      await tester.pump();

      expect(submissions, 0);
      expect(find.text('Enter a valid email address'), findsOneWidget);
    });

    testWidgets('submits a trimmed email and the password', (tester) async {
      String? email;
      String? password;
      await pumpScreen(
        tester,
        LogInScreen(
          onSubmit: (e, p) {
            email = e;
            password = p;
          },
          onForgotPassword: () {},
          onCreateAccount: () {},
        ),
      );

      final fields = find.byType(EditableText);
      await tester.enterText(fields.at(0), '  user@example.com  ');
      await tester.enterText(fields.at(1), 'longenoughpassword');
      await tester.tap(find.byKey(LogInScreen.submitKey));
      await tester.pump();

      expect(email, 'user@example.com');
      expect(password, 'longenoughpassword');
    });

    testWidgets('errors appear only after a submission attempt', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        LogInScreen(
          onSubmit: (_, _) {},
          onForgotPassword: () {},
          onCreateAccount: () {},
        ),
      );
      // Shouting at someone before they have typed anything is hostile.
      expect(find.text('Enter a valid email address'), findsNothing);
    });

    testWidgets('the biometric affordance is absent unless offered', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        LogInScreen(
          onSubmit: (_, _) {},
          onForgotPassword: () {},
          onCreateAccount: () {},
        ),
      );
      expect(find.text('Use Face ID'), findsNothing);

      await pumpScreen(
        tester,
        LogInScreen(
          onSubmit: (_, _) {},
          onForgotPassword: () {},
          onCreateAccount: () {},
          onBiometric: () {},
        ),
      );
      expect(find.text('Use Face ID'), findsOneWidget);
    });
  });

  group('01.05 Sign up', () {
    testWidgets('will not submit until the terms are accepted', (
      tester,
    ) async {
      var submissions = 0;
      await pumpScreen(
        tester,
        SignUpScreen(onSubmit: (_, _) => submissions++, onLogIn: () {}),
      );

      final fields = find.byType(EditableText);
      await tester.enterText(fields.at(0), 'user@example.com');
      await tester.enterText(fields.at(1), 'longenoughpassword');
      await tester.tap(find.byKey(SignUpScreen.submitKey));
      await tester.pump();

      expect(submissions, 0);
      expect(find.text('Accept the terms to continue'), findsOneWidget);

      await tester.tap(find.byKey(SignUpScreen.termsKey));
      await tester.pump();
      await tester.tap(find.byKey(SignUpScreen.submitKey));
      await tester.pump();

      expect(submissions, 1);
    });

    testWidgets('the terms checkbox starts unchecked', (tester) async {
      await pumpScreen(
        tester,
        SignUpScreen(onSubmit: (_, _) {}, onLogIn: () {}),
      );
      expect(
        tester.widget<MonetaCheckbox>(find.byKey(SignUpScreen.termsKey)).state,
        MonetaCheckboxState.unchecked,
      );
    });
  });

  group('01.08 Forgot password', () {
    testWidgets('submits only a valid address', (tester) async {
      String? asked;
      await pumpScreen(
        tester,
        ForgotPasswordScreen(onSubmit: (e) => asked = e, onBack: () {}),
      );

      await tester.enterText(find.byType(EditableText).first, 'nope');
      await tester.tap(find.byKey(ForgotPasswordScreen.submitKey));
      await tester.pump();
      expect(asked, isNull);

      await tester.enterText(
        find.byType(EditableText).first,
        'user@example.com',
      );
      await tester.tap(find.byKey(ForgotPasswordScreen.submitKey));
      await tester.pump();
      expect(asked, 'user@example.com');
    });
  });

  group('01.07 Verify code', () {
    testWidgets('the action is disabled until the code is complete', (
      tester,
    ) async {
      var submissions = 0;
      await pumpScreen(
        tester,
        VerifyCodeScreen(
          email: 'user@example.com',
          onSubmit: (_) => submissions++,
          onBack: () {},
          onResend: () {},
        ),
      );

      MonetaButton button() =>
          tester.widget<MonetaButton>(find.byKey(VerifyCodeScreen.submitKey));

      expect(button().state, MonetaButtonState.disabled);
      await tester.tap(find.byKey(VerifyCodeScreen.submitKey));
      await tester.pump();
      expect(submissions, 0);

      await tester.enterText(find.byType(EditableText).first, '48291');
      await tester.pump();
      expect(
        button().state,
        MonetaButtonState.disabled,
        reason: 'five of six digits enabled the action',
      );

      await tester.enterText(find.byType(EditableText).first, '482915');
      await tester.pump();
      expect(button().state, MonetaButtonState.normal);

      await tester.tap(find.byKey(VerifyCodeScreen.submitKey));
      await tester.pump();
      expect(submissions, 1);
    });

    testWidgets('the boxes follow what is typed', (tester) async {
      await pumpScreen(
        tester,
        VerifyCodeScreen(
          email: 'user@example.com',
          onSubmit: (_) {},
          onBack: () {},
          onResend: () {},
        ),
      );
      await tester.enterText(find.byType(EditableText).first, '482');
      await tester.pump();

      final field = tester.widget<MonetaOtpField>(find.byType(MonetaOtpField));
      expect(field.code, '482');
      expect(field.state, MonetaOtpFillState.partial);
    });

    testWidgets('it names the address the code went to', (tester) async {
      await pumpScreen(
        tester,
        VerifyCodeScreen(
          email: 'minh@example.com',
          onSubmit: (_) {},
          onBack: () {},
          onResend: () {},
        ),
      );
      // A typo in the address is only catchable here.
      expect(find.textContaining('minh@example.com'), findsOneWidget);
    });
  });

  group('01.09 Reset success', () {
    testWidgets('offers exactly one way forward', (tester) async {
      var continues = 0;
      await pumpScreen(
        tester,
        ResetSuccessScreen(onContinue: () => continues++),
      );
      expect(find.byType(MonetaButton), findsOneWidget);
      await tester.tap(find.byKey(ResetSuccessScreen.continueKey));
      expect(continues, 1);
    });
  });

  group('01.10 Setup currency', () {
    testWidgets('continue is disabled until both are chosen', (tester) async {
      await pumpScreen(
        tester,
        SetupCurrencyScreen(
          currency: null,
          country: null,
          onPickCurrency: () {},
          onPickCountry: () {},
          onContinue: () {},
          onBack: () {},
        ),
      );
      expect(
        tester
            .widget<MonetaButton>(find.byKey(SetupCurrencyScreen.continueKey))
            .state,
        MonetaButtonState.disabled,
      );
    });
  });

  group('01.11 Setup biometric', () {
    testWidgets('declining is offered as plainly as enabling', (tester) async {
      var enabled = 0;
      var skipped = 0;
      await pumpScreen(
        tester,
        SetupBiometricScreen(
          onEnable: () => enabled++,
          onSkip: () => skipped++,
        ),
      );
      await tester.tap(find.byKey(SetupBiometricScreen.enableKey));
      await tester.tap(find.byKey(SetupBiometricScreen.skipKey));
      expect(enabled, 1);
      expect(skipped, 1);
    });
  });

  group('01.12 Setup link account', () {
    const kinds = <AccountKind>[
      (
        icon: MonetaIconName.creditCard,
        label: 'Bank account',
        subtitle: 'Vietcombank and others',
      ),
      (
        icon: MonetaIconName.dollarSign,
        label: 'Cash',
        subtitle: 'What is in your pocket',
      ),
    ];

    testWidgets('every offered kind is shown and pickable', (tester) async {
      AccountKind? picked;
      await pumpScreen(
        tester,
        SetupLinkAccountScreen(
          kinds: kinds,
          onPick: (k) => picked = k,
          onSkip: () {},
          onBack: () {},
        ),
      );

      for (final kind in kinds) {
        expect(find.text(kind.label), findsOneWidget, reason: kind.label);
      }

      await tester.tap(find.text('Cash'));
      expect(picked?.label, 'Cash');
    });

    testWidgets('setup can be deferred', (tester) async {
      // A setup step that cannot be skipped is a wall: the app works with no
      // account linked.
      var skipped = 0;
      await pumpScreen(
        tester,
        SetupLinkAccountScreen(
          kinds: kinds,
          onPick: (_) {},
          onSkip: () => skipped++,
          onBack: () {},
        ),
      );
      await tester.tap(find.byKey(SetupLinkAccountScreen.skipKey));
      expect(skipped, 1);
    });
  });

  group('the screens stand on their own', () {
    // Every screen here renders OUTSIDE the app shell, so nothing above it
    // provides a Material ancestor. `pumpMonetaWidget` wraps its child in
    // MaterialApp + Scaffold, which supplies one — so the whole suite passed
    // while the real app showed a red "No Material widget found" box over the
    // log-in form. This pumps the bare minimum the router actually provides.
    Future<void> pumpBare(WidgetTester tester, Widget screen) async {
      await tester.binding.setSurfaceSize(const Size(393, 852));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      // MaterialApp but no Scaffold — precisely what `MaterialApp.router` hands
      // a route that is not inside the app shell. It supplies Theme and
      // MaterialLocalizations, which the app really does have, and supplies no
      // Material, which the app really does not.
      await tester.pumpWidget(
        MaterialApp(
          theme: MonetaTheme.dark().toThemeData(),
          home: screen,
        ),
      );
      await tester.pump();
    }

    testWidgets('log in renders with no Material ancestor', (tester) async {
      await pumpBare(
        tester,
        LogInScreen(
          onSubmit: (_, _) {},
          onForgotPassword: () {},
          onCreateAccount: () {},
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Welcome back'), findsOneWidget);
    });

    testWidgets('sign up renders with no Material ancestor', (tester) async {
      await pumpBare(
        tester,
        SignUpScreen(onSubmit: (_, _) {}, onLogIn: () {}),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('verify renders with no Material ancestor', (tester) async {
      await pumpBare(
        tester,
        VerifyCodeScreen(
          email: 'user@example.com',
          onSubmit: (_) {},
          onBack: () {},
          onResend: () {},
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
