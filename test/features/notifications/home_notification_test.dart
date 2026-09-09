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

    test('each kind maps to the actionability 57:830 requires', () {
      // Written out by hand rather than read off the enum. Comparing
      // `notification.isActionable` to `kind.isActionable` cannot fail, because
      // the former delegates to the latter — it asserts a getter against
      // itself. This table can fail, and it is what 57:830 actually says:
      // "actionable notifications get a chevron; informational ones do not".
      const expected = <NotificationKind, bool>{
        NotificationKind.budgetOverLimit: true,
        NotificationKind.incomeReceived: true,
        NotificationKind.budgetPeriodEnding: false,
      };
      expect(
        expected.keys.toSet(),
        NotificationKind.values.toSet(),
        reason: 'a kind was added or removed without deciding its accessory',
      );
      expected.forEach((kind, isActionable) {
        expect(kind.isActionable, isActionable, reason: kind.name);
        expect(notification(kind: kind).isActionable, isActionable);
      });
    });

    test('at least one kind of each actionability exists', () {
      // Otherwise the accessory tests below could pass against a feed that only
      // ever produces one shape of row.
      expect(NotificationKind.values.where((k) => k.isActionable), isNotEmpty);
      expect(
        NotificationKind.values.where((k) => !k.isActionable),
        isNotEmpty,
      );
    });
  });

  group('the kinds that exist', () {
    test('there are exactly three, and the two unbuilt ones are absent', () {
      // 57:622 authors five rows. A failed account sync and a goal's funding
      // need Accounts and Goals, so they are documented rather than faked.
      //
      // The length check is a deliberate tripwire, not a claim: a fourth kind
      // should fail here and force whoever adds it to decide its destination
      // and update specs/notifications/spec.md.
      expect(NotificationKind.values, hasLength(3));
      expect(
        NotificationKind.values.map((k) => k.name),
        containsAll(<String>[
          'budgetOverLimit',
          'incomeReceived',
          'budgetPeriodEnding',
        ]),
      );
      // This part can actually fail on its own: it catches a seeded stand-in
      // for either unbuilt feature rather than counting.
      for (final kind in NotificationKind.values) {
        expect(
          kind.name.toLowerCase(),
          allOf(isNot(contains('sync')), isNot(contains('goal'))),
          reason: '${kind.name} looks like a faked Accounts or Goals notice',
        );
      }
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
