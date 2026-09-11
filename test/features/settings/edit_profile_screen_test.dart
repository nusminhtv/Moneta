import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/core/money.dart';
import 'package:moneta/core/result.dart';
import 'package:moneta/design_system/molecules/moneta_select.dart';
import 'package:moneta/design_system/molecules/moneta_text_field.dart';
import 'package:moneta/features/settings/domain/profile.dart';
import 'package:moneta/features/settings/presentation/edit_profile_screen.dart';

import '../../support/pump.dart';

void main() {
  Future<void> pumpEdit(
    WidgetTester tester, {
    Profile profile = const Profile(name: 'Minh Tran'),
    ValueChanged<Profile>? onSave,
    AppFailure? failure,
    VoidCallback? onPickCurrency,
  }) => pumpMonetaWidget(
    tester,
    EditProfileScreen(
      profile: profile,
      onSave: onSave ?? (_) {},
      failure: failure,
      onPickCurrency: onPickCurrency,
    ),
    surfaceSize: const Size(393, 1000),
  );

  group('three editable fields and nothing else', () {
    testWidgets('two text fields and one select', (tester) async {
      await pumpEdit(tester);

      // `100:415`: "Three editable fields and nothing else." The count is the
      // requirement — the annotation exists because the obvious mistake is a
      // nine-field form.
      expect(find.byType(MonetaTextField), findsNWidgets(2));
      expect(find.byType(MonetaSelect<Currency>), findsOneWidget);
    });

    testWidgets('the fields start from the profile', (tester) async {
      await pumpEdit(
        tester,
        profile: const Profile(
          name: 'Trần Văn Minh',
          email: 'minh@example.com',
          currency: Currency.usd,
        ),
      );

      expect(find.text('Trần Văn Minh'), findsOneWidget);
      expect(find.text('minh@example.com'), findsOneWidget);
      expect(find.textContaining('USD'), findsOneWidget);
    });
  });

  group('the app bar check and the footer button do the same thing', () {
    testWidgets('both produce the same profile from one callback', (
      tester,
    ) async {
      final saved = <Profile>[];
      await pumpEdit(tester, onSave: saved.add);

      await tester.tap(find.bySemanticsLabel('Save'));
      await tester.pump();
      await tester.tap(find.byKey(EditProfileScreen.footerSaveKey));
      await tester.pump();

      expect(saved, hasLength(2));
      expect(
        saved.first,
        saved.last,
        reason: 'two controls, one action — they cannot drift apart',
      );
      expect(saved.first.name, 'Minh Tran');
    });

    testWidgets('what was typed is what is saved', (tester) async {
      final saved = <Profile>[];
      await pumpEdit(tester, onSave: saved.add);

      await tester.enterText(
        find.byType(EditableText).first,
        'Bích Ngọc',
      );
      await tester.enterText(
        find.byType(EditableText).last,
        'bich@example.com',
      );
      await tester.tap(find.byKey(EditProfileScreen.footerSaveKey));

      expect(saved.single.name, 'Bích Ngọc');
      expect(saved.single.email, 'bich@example.com');
    });
  });

  group('a failed save', () {
    testWidgets('puts the email field in error with the reason', (
      tester,
    ) async {
      await pumpEdit(
        tester,
        profile: const Profile(name: 'Minh', email: 'not-an-address'),
        failure: const AppFailure(
          FailureKind.validation,
          'Enter a valid email address',
        ),
      );

      final fields = tester.widgetList<MonetaTextField>(
        find.byType(MonetaTextField),
      );
      expect(fields.first.errorText, isNull, reason: 'the name is fine');
      expect(fields.last.errorText, 'Enter a valid email address');
    });

    testWidgets('keeps what was typed', (tester) async {
      await pumpEdit(
        tester,
        profile: const Profile(name: 'Minh', email: 'not-an-address'),
        failure: const AppFailure(FailureKind.validation, 'Enter a valid…'),
      );

      // Losing someone's typing because the save failed is worse than the
      // failure.
      expect(find.text('not-an-address'), findsOneWidget);
      expect(find.text('Minh'), findsOneWidget);
    });

    testWidgets('a storage failure is shown, not silently swallowed', (
      tester,
    ) async {
      await pumpEdit(
        tester,
        failure: const AppFailure(FailureKind.storage, 'Could not save'),
      );

      expect(find.text('Could not save'), findsOneWidget);
      // And it is not shown on the email field, which is not what went wrong.
      expect(
        tester
            .widgetList<MonetaTextField>(find.byType(MonetaTextField))
            .last
            .errorText,
        isNull,
      );
    });

    testWidgets('an empty name is reported somewhere, not nowhere', (
      tester,
    ) async {
      // The first version of this asserted only that the email field was
      // **clean** — and certified a silence. A validation failure raised while
      // the name was empty was rendered nowhere at all, which is the first-run
      // path: an empty profile, a tap on Save, and a screen that does not
      // change. `change-verifier` found it.
      await pumpEdit(
        tester,
        profile: const Profile(name: ''),
        failure: const AppFailure(FailureKind.validation, 'Enter a name'),
      );

      expect(
        tester
            .widgetList<MonetaTextField>(find.byType(MonetaTextField))
            .last
            .errorText,
        isNull,
        reason: 'the name is what is missing, not the address',
      );
      // And it is shown, which is the half that was missing.
      expect(find.byKey(EditProfileScreen.failureBannerKey), findsOneWidget);
      expect(find.text('Enter a name'), findsOneWidget);
    });

    testWidgets('every failure kind reaches the user somehow', (tester) async {
      // Written as a sweep over the kinds rather than a case per kind,
      // because what went wrong was a *gap between* two cases: one renderer
      // took `validation` when the name was filled and another took `storage`,
      // and a validation failure with an empty name matched neither.
      for (final kind in FailureKind.values) {
        for (final name in ['', 'Minh']) {
          await pumpEdit(
            tester,
            profile: Profile(name: name),
            failure: AppFailure(kind, 'Something went wrong'),
          );

          final onField = tester
              .widgetList<MonetaTextField>(find.byType(MonetaTextField))
              .last
              .errorText;
          final inBanner = find
              .byKey(EditProfileScreen.failureBannerKey)
              .evaluate()
              .isNotEmpty;

          expect(
            onField != null || inBanner,
            isTrue,
            reason: '$kind with name "$name" is reported nowhere',
          );
        }
      }
    });
  });

  group('boundaries', () {
    testWidgets('a 200-character name stays on one line', (tester) async {
      // The previous version of this asserted the field's *label* and the
      // number of `EditableText`s — both true of every render, truncating or
      // not. `change-verifier` deleted `maxLines`/`ellipsis` from `08.01` and
      // all 1859 tests stayed green.
      //
      // `08.02`'s fields are `TextField`s, which cannot carry a
      // `TextOverflow`; single-line is the mechanism they have. `08.01`'s
      // half — where the name is *displayed* — is asserted in
      // `profile_screen_test.dart`.
      final long = 'Nguyễn ' * 30;
      await pumpEdit(tester, profile: Profile(name: long));
      expect(tester.takeException(), isNull);

      for (final editable in tester.widgetList<EditableText>(
        find.byType(EditableText),
      )) {
        expect(
          editable.maxLines,
          1,
          reason: 'a name field that wraps pushes the rest of the form down',
        );
      }
    });

    testWidgets('an emoji name still renders an avatar', (tester) async {
      await pumpEdit(tester, profile: const Profile(name: '👨‍👩‍👧 family'));
      expect(tester.takeException(), isNull);
    });

    testWidgets('the currency select delegates rather than choosing', (
      tester,
    ) async {
      var asked = 0;
      await pumpEdit(tester, onPickCurrency: () => asked++);

      expect(
        tester
            .widget<MonetaSelect<Currency>>(
              find.byType(MonetaSelect<Currency>),
            )
            .enabled,
        isTrue,
      );
      await tester.tap(find.byType(MonetaSelect<Currency>));
      expect(asked, 1);
    });

    testWidgets('and reads disabled when there is nothing to open', (
      tester,
    ) async {
      // `08.10`'s call to action was made honest because an inert control is
      // worse than an absent one. The same standard, one screen over: with no
      // picker, the select says so rather than swallowing taps.
      await pumpEdit(tester);

      expect(
        tester
            .widget<MonetaSelect<Currency>>(
              find.byType(MonetaSelect<Currency>),
            )
            .enabled,
        isFalse,
      );
    });
  });
}
