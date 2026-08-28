import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';
import 'package:moneta/design_system/tokens/spacing.dart';

/// Header separating transactions by local calendar date.
///
/// From Figma node `29:71`.
class DateGroupHeader extends StatelessWidget {
  /// Creates a date group header.
  const DateGroupHeader({required this.date, this.locale, super.key});

  /// Date represented by this group. UTC instants are displayed in local time.
  final DateTime date;

  /// Optional locale override for tests.
  final String? locale;

  /// Formats [date] in the compact group-header form.
  static String formatDate(DateTime date, {String? locale}) =>
      DateFormat('d MMMM', locale).format(date.toLocal());

  @override
  Widget build(BuildContext context) {
    final theme = context.moneta;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        MonetaSpacing.spaceBase,
        MonetaSpacing.spaceXl,
        MonetaSpacing.spaceBase,
        MonetaSpacing.spaceSm,
      ),
      child: Text(
        formatDate(date, locale: locale),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        softWrap: false,
        style: theme.text.labelMd.copyWith(color: theme.colors.textSecondary),
      ),
    );
  }
}
