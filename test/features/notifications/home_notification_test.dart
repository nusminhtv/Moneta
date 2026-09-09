import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/design_system/atoms/moneta_icon_name.dart';
import 'package:moneta/features/notifications/domain/home_notification.dart';

void main() {
  final at = DateTime.utc(2026, 9, 20, 10);

  HomeNotification notification({
    String id = 'n1',
    NotificationKind kind = NotificationKind.budgetOverLimit,
    String title = 'Shopping is over budget',
    String detail = '740,000 ₫ over · 2 hours ago',
    MonetaIconName icon = MonetaIconName.alertTriangle,
    DateTime? occurredAt,
    String? targetId = 'b1',
  }) => HomeNotification(
    id: id,
    kind: kind,
    title: title,
    detail: detail,
    icon: icon,
    occurredAt: occurredAt ?? at,
    targetId: targetId,
  );

  group('actionability comes from the kind', () {
    test('an over-limit budget leads somewhere', () {
      expect(NotificationKind.budgetOverLimit.isActionable, isTrue);
      expect(
        notification(kind: NotificationKind.budgetOverLimit).isActionable,
        isTrue,
      );
    });

    test('income received leads somewhere', () {
      expect(NotificationKind.incomeReceived.isActionable, isTrue);
    });

    test('a period ending leads nowhere', () {
      // There is nothing to do about a date.
      expect(NotificationKind.budgetPeriodEnding.isActionable, isFalse);
      expect(
        notification(kind: NotificationKind.budgetPeriodEnding).isActionable,
        isFalse,
      );
    });

    test('a caller cannot contradict the kind', () {
      // isActionable is derived, not a constructor argument, which is what
      // makes "a chevron over nothing" unrepresentable. If this ever becomes a
      // field, 57:830's rule stops being enforced by the type.
      final informational = notification(
        kind: NotificationKind.budgetPeriodEnding,
      );
      expect(
        informational.isActionable,
        NotificationKind.budgetPeriodEnding.isActionable,
      );
    });

    test('every kind declares its actionability', () {
      for (final kind in NotificationKind.values) {
        expect(kind.isActionable, isA<bool>());
      }
    });
  });

  group('the kinds that exist', () {
    test('there are exactly three, and the two unbuilt ones are absent', () {
      // 57:622 authors five rows. A failed account sync and a goal's funding
      // need Accounts and Goals, so they are documented rather than faked.
      expect(NotificationKind.values, hasLength(3));
      expect(
        NotificationKind.values.map((k) => k.name),
        containsAll(<String>[
          'budgetOverLimit',
          'incomeReceived',
          'budgetPeriodEnding',
        ]),
      );
    });
  });

  group('equality', () {
    test('two notifications with the same content are equal', () {
      expect(notification(), notification());
    });

    test('every field participates', () {
      expect(notification(), isNot(notification(id: 'other')));
      expect(
        notification(),
        isNot(notification(kind: NotificationKind.incomeReceived)),
      );
      expect(notification(), isNot(notification(title: 'other')));
      expect(notification(), isNot(notification(detail: 'other')));
      expect(
        notification(),
        isNot(notification(icon: MonetaIconName.calendar)),
      );
      expect(
        notification(),
        isNot(notification(occurredAt: at.add(const Duration(minutes: 1)))),
      );
      expect(notification(), isNot(notification(targetId: null)));
    });
  });
}
