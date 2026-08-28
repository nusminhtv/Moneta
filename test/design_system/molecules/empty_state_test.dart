import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/design_system/atoms/moneta_button.dart';
import 'package:moneta/design_system/atoms/moneta_icon.dart';
import 'package:moneta/design_system/atoms/moneta_icon_name.dart';
import 'package:moneta/design_system/molecules/empty_state.dart';
import 'package:moneta/design_system/tokens/colors.dart';

import '../../support/pump.dart';

void main() {
  const colors = MonetaColors.dark();

  Future<void> pumpEmpty(
    WidgetTester tester, {
    String title = 'No transactions yet',
    String message = 'Add your first record to start tracking your month.',
    MonetaIconName icon = MonetaIconName.fileText,
    String? actionLabel,
    VoidCallback? onAction,
    double width = 353,
  }) {
    return pumpMonetaWidget(
      tester,
      SizedBox(
        width: width,
        child: EmptyState(
          title: title,
          message: message,
          icon: icon,
          actionLabel: actionLabel,
          onAction: onAction,
        ),
      ),
      surfaceSize: const Size(420, 420),
    );
  }

  testWidgets('HasAction=true renders the action and reports taps', (
    tester,
  ) async {
    var taps = 0;
    await pumpEmpty(
      tester,
      actionLabel: 'Add transaction',
      onAction: () => taps++,
    );

    expect(find.text('No transactions yet'), findsOneWidget);
    expect(find.text('Add transaction'), findsOneWidget);
    expect(find.byType(MonetaButton), findsOneWidget);

    await tester.tap(find.text('Add transaction'));
    expect(taps, 1);
  });

  testWidgets('HasAction=false omits the action affordance', (tester) async {
    await pumpEmpty(tester, icon: MonetaIconName.bell);

    expect(find.text('No transactions yet'), findsOneWidget);
    expect(find.byType(MonetaButton), findsNothing);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is MonetaIcon && widget.icon == MonetaIconName.bell,
      ),
      findsOneWidget,
    );
  });

  testWidgets('exposes which variant it is through hasAction', (tester) async {
    await pumpEmpty(tester, actionLabel: 'Add transaction');
    expect(
      tester.widget<EmptyState>(find.byType(EmptyState)).hasAction,
      isTrue,
    );

    await pumpEmpty(tester);
    expect(
      tester.widget<EmptyState>(find.byType(EmptyState)).hasAction,
      isFalse,
    );
  });

  testWidgets('uses primary and secondary text roles', (tester) async {
    await pumpEmpty(tester);

    final title = tester.widget<Text>(find.text('No transactions yet'));
    final message = tester.widget<Text>(
      find.text('Add your first record to start tracking your month.'),
    );
    expect(title.style!.color, colors.textPrimary);
    expect(message.style!.color, colors.textSecondary);
  });

  testWidgets('long copy stays inside the empty state', (tester) async {
    await pumpEmpty(
      tester,
      title: 'A very long empty state title that should stay contained',
      message:
          'A very long empty state body that should wrap or truncate without '
          'escaping the component bounds.',
      actionLabel: 'Take action',
      width: 220,
    );

    expect(tester.takeException(), isNull);
    final emptyState = tester.getRect(find.byType(EmptyState));
    for (final text in find.byType(Text).evaluate()) {
      final rect = tester.getRect(find.byWidget(text.widget));
      expect(rect.left, greaterThanOrEqualTo(emptyState.left));
      expect(rect.right, lessThanOrEqualTo(emptyState.right));
    }
  });
}
