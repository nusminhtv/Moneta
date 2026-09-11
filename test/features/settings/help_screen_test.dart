import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/design_system/atoms/moneta_icon.dart';
import 'package:moneta/design_system/atoms/moneta_icon_name.dart';
import 'package:moneta/design_system/molecules/empty_state.dart';
import 'package:moneta/design_system/molecules/moneta_search_field.dart';
import 'package:moneta/features/settings/domain/faq_entry.dart';
import 'package:moneta/features/settings/presentation/help_screen.dart';

import '../../support/pump.dart';

void main() {
  Future<void> pumpHelp(
    WidgetTester tester, {
    VoidCallback? onContactSupport,
    VoidCallback? onBack,
  }) => pumpMonetaWidget(
    tester,
    HelpScreen(onBack: onBack, onContactSupport: onContactSupport),
    surfaceSize: const Size(393, 1400),
  );

  /// The glyph the item at [index] is currently showing.
  MonetaIconName chevronAt(WidgetTester tester, int index) =>
      tester.widget<MonetaIcon>(find.byKey(HelpScreen.chevronKey(index))).icon;

  /// Whether the item at [index] is showing its answer.
  bool isOpen(WidgetTester tester, int index) => tester
      .widgetList<Text>(
        find.descendant(
          of: find.byKey(HelpScreen.itemKey(index)),
          matching: find.byType(Text),
        ),
      )
      .any((t) => t.data == faqEntries[index].answer);

  group('one open, four closed, and every chevron agrees', () {
    testWidgets('the first question is the one already open', (tester) async {
      await pumpHelp(tester);

      expect(find.text(faqEntries.first.question), findsOneWidget);
      expect(find.text(faqEntries.first.answer), findsOneWidget);
      for (var i = 1; i < faqEntries.length; i++) {
        expect(
          find.text(faqEntries[i].answer),
          findsNothing,
          reason: 'item $i should be collapsed',
        );
      }
    });

    testWidgets('each chevron matches its own item, not just one of them', (
      tester,
    ) async {
      // Per item, because "a chevron-up exists somewhere" passes for a screen
      // where every chevron points up. Annotation `102:1300` calls the
      // mismatched chevron "the most common copy-paste bug in this pattern".
      await pumpHelp(tester);

      for (var i = 0; i < faqEntries.length; i++) {
        expect(
          chevronAt(tester, i),
          isOpen(tester, i)
              ? MonetaIconName.chevronUp
              : MonetaIconName.chevronDown,
          reason: 'item $i: chevron and state disagree',
        );
      }
      // And the two states are both present, so the loop above is comparing
      // something: an all-collapsed screen would satisfy it vacuously.
      expect(isOpen(tester, 0), isTrue);
      expect(isOpen(tester, 1), isFalse);
    });
  });

  group('expanding', () {
    testWidgets('opening a second leaves the first open', (tester) async {
      await pumpHelp(tester);
      await tester.tap(find.text(faqEntries[2].question));
      await tester.pump();

      expect(isOpen(tester, 0), isTrue);
      expect(isOpen(tester, 2), isTrue);
      expect(chevronAt(tester, 0), MonetaIconName.chevronUp);
      expect(chevronAt(tester, 2), MonetaIconName.chevronUp);
    });

    testWidgets('tapping an open item closes it', (tester) async {
      await pumpHelp(tester);
      await tester.tap(find.text(faqEntries[0].question));
      await tester.pump();

      expect(isOpen(tester, 0), isFalse);
      expect(chevronAt(tester, 0), MonetaIconName.chevronDown);
    });
  });

  group('searching', () {
    testWidgets('filters to what matches', (tester) async {
      await pumpHelp(tester);
      await tester.enterText(find.byType(EditableText), 'demo');
      await tester.pump();

      expect(find.text('What is demo mode?'), findsOneWidget);
      expect(find.text(faqEntries.first.question), findsNothing);
    });

    testWidgets('no match shows the empty state, with the query kept', (
      tester,
    ) async {
      var contacted = 0;
      await pumpHelp(tester, onContactSupport: () => contacted++);
      await tester.enterText(find.byType(EditableText), 'xyzzy');
      await tester.pump();

      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.byKey(HelpScreen.listKey), findsNothing);
      // The query stays, and so does the way out of it.
      expect(find.text('xyzzy'), findsOneWidget);
      expect(find.byKey(MonetaSearchField.clearKey), findsOneWidget);

      await tester.tap(find.text('Email support'));
      expect(contacted, 1);
    });

    testWidgets('clearing restores the opening state, not what was open', (
      tester,
    ) async {
      await pumpHelp(tester);

      // Open a second item, then search and clear.
      await tester.tap(find.text(faqEntries[3].question));
      await tester.pump();
      expect(isOpen(tester, 3), isTrue);

      await tester.enterText(find.byType(EditableText), 'demo');
      await tester.pump();
      await tester.tap(find.byKey(MonetaSearchField.clearKey));
      await tester.pump();

      expect(find.byKey(HelpScreen.listKey), findsOneWidget);
      expect(isOpen(tester, 0), isTrue);
      for (var i = 1; i < faqEntries.length; i++) {
        expect(isOpen(tester, i), isFalse, reason: 'item $i should be closed');
      }
    });

    testWidgets('filtering opens the right question, not the right index', (
      tester,
    ) async {
      // The trap an index-keyed expansion set falls into: after filtering, the
      // item at index 0 is a *different* question, and a set of indices would
      // show the first result's answer whether or not it was the open one.
      await pumpHelp(tester);
      await tester.enterText(find.byType(EditableText), 'categories');
      await tester.pump();

      expect(find.text('Can I add my own categories?'), findsOneWidget);
      expect(
        find.text(faqEntries.last.answer),
        findsNothing,
        reason: 'the surviving item was closed before the search',
      );
    });
  });

  testWidgets('the support row and the mail action both reach support', (
    tester,
  ) async {
    var contacted = 0;
    await pumpHelp(tester, onContactSupport: () => contacted++);

    await tester.tap(find.text('Contact support'));
    expect(contacted, 1);

    await tester.tap(find.bySemanticsLabel('Email support'));
    expect(contacted, 2);
  });
}
