import 'package:flutter/widgets.dart';

/// Describes gallery variants for 📱 01 Onboarding & Auth.
///
/// **Owner: the auth agent.** Returns `null` for anything it does not own, so
/// `gallery_test.dart` can chain the describers together.
///
/// Name the properties that make a variant distinct — the check this feeds
/// fails when two variants of a component render the same widget, and it can
/// only see what the description mentions.
String? describeAuth(Widget widget) => switch (widget) {
  // --- AUTH: add cases below ---
  _ => null,
};
