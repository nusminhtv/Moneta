import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moneta/app/budgets_route_screen.dart';
import 'package:moneta/app/router.dart';
import 'package:moneta/app/shell.dart';
import 'package:moneta/design_system/organisms/bottom_nav.dart';

void main() {
  group('every budget route resolves', () {
    for (final path in [
      BudgetRoutes.overview,
      BudgetRoutes.createCategory,
      BudgetRoutes.createAmount,
      '/budgets/detail/b1',
    ]) {
      test('$path builds a router without throwing', () {
        // A route added to BudgetRoutes and never wired into the router is a
        // dead link that no widget test would notice.
        final router = buildRouter(initialLocation: path);
        addTearDown(router.dispose);
        expect(
          router.configuration.findMatch(Uri.parse(path)).routes,
          isNotEmpty,
          reason: '$path matches no route',
        );
      });
    }
  });

  group('the detail path is built in one place', () {
    test('detailFor fills the id into the declared pattern', () {
      expect(BudgetRoutes.detailFor('b1'), '/budgets/detail/b1');
      expect(
        BudgetRoutes.detail.replaceFirst(':id', 'b1'),
        BudgetRoutes.detailFor('b1'),
      );
    });
  });

  group('the create steps sit outside the shell', () {
    for (final path in [
      BudgetRoutes.createCategory,
      BudgetRoutes.createAmount,
    ]) {
      test('$path has no bottom navigation', () {
        // 66:378 and 66:488 draw a bottom safe area and no bar. A wizard with a
        // tab bar invites the user to leave halfway through.
        final router = buildRouter(initialLocation: path);
        addTearDown(router.dispose);
        final matched = router.configuration.findMatch(Uri.parse(path)).routes;
        expect(
          matched.whereType<ShellRouteBase>(),
          isEmpty,
          reason: '$path is inside the shell',
        );
      });
    }
  });

  group('the budget screens keep Home lit', () {
    test('none of them is a destination', () {
      for (final path in [
        BudgetRoutes.overview,
        BudgetRoutes.detailFor('b1'),
      ]) {
        expect(DestinationRoutes.of(path), MonetaDestination.home);
      }
    });
  });
}
