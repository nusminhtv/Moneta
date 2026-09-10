/// Which pushes the user has left switched on.
///
/// Its own file because both `notification_providers.dart` (which filters the
/// feed with it) and `settings_route_screens.dart` (which lets the user change
/// it) need it, and a mutual import between those two would be a cycle waiting
/// to be tightened.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moneta/core/result.dart';
import 'package:moneta/data/app_providers.dart';
import 'package:moneta/data/preferences/preference_key.dart';
import 'package:moneta/features/settings/presentation/notification_settings_screen.dart';

/// Which pushes are switched on, persisted in the control database.
///
/// Read once and held, so a toggle is instant rather than awaiting a write on
/// every frame. The write happens behind it and a failure surfaces.
class NotificationPreferencesController
    extends Notifier<NotificationPreferences> {
  @override
  NotificationPreferences build() => const NotificationPreferences();

  /// Applies [next] and persists it.
  Future<Result<void>> update(NotificationPreferences next) async {
    state = next;
    final store = await ref.read(preferencesStoreProvider.future);
    for (final entry in <PreferenceKey, bool>{
      PreferenceKey.notifyBudgetNearLimit: next.budgetNearLimit,
      PreferenceKey.notifyBudgetExceeded: next.budgetExceeded,
      PreferenceKey.notifyPeriodEnding: next.periodEnding,
      PreferenceKey.notifyIncome: next.income,
    }.entries) {
      final written = await store.writeBool(entry.key, value: entry.value);
      if (written case Err(:final failure)) return Err(failure);
    }
    return const Ok(null);
  }

  /// Reads the stored set, leaving the screen's defaults where nothing is
  /// stored — absence is not `false`.
  Future<void> hydrate() async {
    try {
      final store = await ref.read(preferencesStoreProvider.future);
      Future<bool> read(PreferenceKey key, {required bool fallback}) async =>
          (await store.readBool(key)).valueOrNull ?? fallback;

      const defaults = NotificationPreferences();
      state = NotificationPreferences(
        budgetNearLimit: await read(
          PreferenceKey.notifyBudgetNearLimit,
          fallback: defaults.budgetNearLimit,
        ),
        budgetExceeded: await read(
          PreferenceKey.notifyBudgetExceeded,
          fallback: defaults.budgetExceeded,
        ),
        periodEnding: await read(
          PreferenceKey.notifyPeriodEnding,
          fallback: defaults.periodEnding,
        ),
        income: await read(
          PreferenceKey.notifyIncome,
          fallback: defaults.income,
        ),
      );
    } on Object {
      // The startup path again: a store that cannot open must not stop the app.
      // The defaults stand.
    }
  }
}

/// See [NotificationPreferencesController].
final notificationPreferencesProvider =
    NotifierProvider<
      NotificationPreferencesController,
      NotificationPreferences
    >(NotificationPreferencesController.new);
