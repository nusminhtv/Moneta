import 'package:equatable/equatable.dart';
import 'package:moneta/design_system/atoms/moneta_icon_name.dart';

/// What produced a notification, and therefore whether it leads anywhere.
///
/// The kinds are taken from the five rows authored on `57:622`. Three of them
/// are derivable from features this app has; two are not, and are listed here
/// as documentation rather than implemented, so that the gap is visible in the
/// type rather than only in a commit message.
enum NotificationKind {
  /// A budget has passed its limit — `57:662`, `icon/alert-triangle`.
  ///
  /// Actionable: it opens that budget.
  budgetOverLimit(isActionable: true),

  /// Money came in — `57:688`, glyph from the transaction's own category.
  ///
  /// Actionable: it opens the transactions list.
  incomeReceived(isActionable: true),

  /// The current budget period is ending — `57:773`, `icon/calendar`.
  ///
  /// Informational. There is nothing to do about a date.
  budgetPeriodEnding(isActionable: false);

  const NotificationKind({required this.isActionable});

  /// Whether acting on this notification leads somewhere.
  ///
  /// This drives the row's trailing accessory. Annotation `57:830`:
  /// *"actionable notifications get a chevron; informational ones do not."*
  /// Deriving it from the kind rather than passing it per row is what makes a
  /// chevron over nothing unrepresentable.
  final bool isActionable;
}

/// One entry in the notification centre, from `57:622`.
///
/// A pure value type over `core` and icon names. It carries no repository, no
/// database row and no read state — `home-overview`'s design decision D3 keeps
/// persistence out of this change, so these are **derived on demand** from
/// budgets and the ledger and are not durable.
///
/// ### Two authored kinds are missing, and are not faked
///
/// `57:622` also shows *"Vietcombank sync failed"* (`57:718`) and *"Japan trip
/// is 62% funded"* (`57:740`). Both are omitted, because the features behind
/// them do not exist: there is no account syncing (page 05) and no goals
/// (page 06). Seeding them as fixtures would put invented facts about the
/// user's own money on screen, which is worse than a shorter list.
///
/// They are the reason [NotificationKind] is an enum rather than a bool: when
/// Accounts and Goals land, each adds a case here and a derivation in
/// `lib/app`, and nothing else about this screen changes.
final class HomeNotification extends Equatable {
  /// Creates a notification.
  const HomeNotification({
    required this.id,
    required this.kind,
    required this.title,
    required this.detail,
    required this.icon,
    required this.occurredAt,
    this.targetId,
  });

  /// Stable identity, so the list can key its rows.
  final String id;

  /// What produced this, which fixes whether it is actionable.
  final NotificationKind kind;

  /// The row's title — "Shopping is over budget".
  final String title;

  /// The row's subtitle, including its "… ago" tail.
  final String detail;

  /// The leading glyph.
  final MonetaIconName icon;

  /// When the underlying event happened, in UTC.
  ///
  /// Drives both the Today/Earlier grouping and the "… ago" tail, and it is the
  /// event's own instant — not the moment the list was built. A notification
  /// that reset its age every time the screen opened would always read "just
  /// now".
  final DateTime occurredAt;

  /// What to open, when this notification leads somewhere.
  ///
  /// The budget's id for [NotificationKind.budgetOverLimit]; null for kinds
  /// whose destination needs no argument.
  final String? targetId;

  /// Whether acting on this leads somewhere.
  bool get isActionable => kind.isActionable;

  @override
  List<Object?> get props => [
    id,
    kind,
    title,
    detail,
    icon,
    occurredAt,
    targetId,
  ];
}
