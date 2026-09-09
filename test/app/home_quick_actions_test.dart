import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/app/home_route_screen.dart';
import 'package:moneta/design_system/atoms/moneta_icon_name.dart';

/// Home's quick-actions row, against the set Figma authors at `52:66`–`52:105`.
///
/// The shipped row was Add, History, Insights and Profile — four working
/// buttons that matched no node in the design. Annotation `52:362` names
/// `IconButton/Tonal x4` and the frames name the four actions.
void main() {
  List<({MonetaIconName icon, String label, void Function()? onPressed})>
  actions() => HomeRouteScreen.quickActions(onAdd: () {}, onBudgets: () {});

  test('the four authored actions appear in the authored order', () {
    expect(actions().map((a) => a.label), [
      'Add',
      'Transfer',
      'Budgets',
      'Goals',
    ]);
  });

  test('the row is exactly four wide, as the frame lays out', () {
    // 82.25px per column across a 353px track. A fifth entry or a dropped one
    // is a different layout, not a different label.
    expect(actions(), hasLength(4));
  });

  test('Add and Budgets are wired, because both destinations exist', () {
    final byLabel = {for (final a in actions()) a.label: a};
    expect(byLabel['Add']!.onPressed, isNotNull);
    expect(byLabel['Budgets']!.onPressed, isNotNull);
  });

  test('Transfer and Goals are present but dead, because neither feature is '
      'built', () {
    // Rendered-and-disabled, not omitted: dropping them would redesign the
    // row, and wiring them anywhere would tell the user something untrue.
    final byLabel = {for (final a in actions()) a.label: a};
    expect(byLabel['Transfer']!.onPressed, isNull);
    expect(byLabel['Goals']!.onPressed, isNull);
  });

  test('the callbacks land on the action they belong to', () {
    var added = 0;
    var budgets = 0;
    final built = HomeRouteScreen.quickActions(
      onAdd: () => added++,
      onBudgets: () => budgets++,
    );
    final byLabel = {for (final a in built) a.label: a};
    byLabel['Add']!.onPressed!();
    expect(added, 1);
    expect(budgets, 0);
    byLabel['Budgets']!.onPressed!();
    expect(budgets, 1);
    expect(added, 1);
  });

  test('every action carries a distinct glyph', () {
    // Two actions sharing an icon would make the row ambiguous at a glance.
    final icons = actions().map((a) => a.icon).toSet();
    expect(icons, hasLength(4));
  });
}
