import 'package:flutter/widgets.dart';
import 'package:moneta/design_system/atoms/moneta_icon.dart';
import 'package:moneta/design_system/atoms/moneta_icon_name.dart';
import 'package:moneta/design_system/molecules/empty_state.dart';
import 'package:moneta/design_system/molecules/list_row.dart';
import 'package:moneta/design_system/molecules/moneta_search_field.dart';
import 'package:moneta/design_system/organisms/moneta_app_bar.dart';
import 'package:moneta/design_system/theme/moneta_theme.dart';
import 'package:moneta/design_system/tokens/spacing.dart';
import 'package:moneta/features/settings/domain/faq_entry.dart';

/// 08.11 — answers first, contact second.
///
/// From Figma node `102:1189`. Annotation `102:1288`: *"Answers first, contact
/// second. The first question is the one every local-first money app gets
/// asked, so it is the one already open."*
///
/// The accordion is **local**, which annotation `102:1300` explains: *"an
/// expanded and a collapsed item differ by a whole paragraph of content, which
/// a variant cannot carry. The chevron direction is the only state signal, and
/// it must match."*
class HelpScreen extends StatefulWidget {
  /// Creates the screen.
  const HelpScreen({
    this.entries = faqEntries,
    this.onBack,
    this.onContactSupport,
    super.key,
  });

  /// The questions to show. Defaults to the app's own five.
  final List<FaqEntry> entries;

  /// Leaves the screen.
  final VoidCallback? onBack;

  /// The one action that can help when nothing matches — `102:1258`'s row and
  /// the empty state's action both call it.
  final VoidCallback? onContactSupport;

  /// Content inset, from `102:1213`'s x within `102:1212`.
  static const double horizontalInset = MonetaSpacing.spaceLg;

  /// Gap between the search field and the first item, from `102:1227`.
  static const double searchGap = MonetaSpacing.spaceSm;

  /// An item's inner padding, from `102:1228`.
  static const double itemPadding = MonetaSpacing.spaceMd;

  /// Gap between the question row and its answer, from `102:1233`'s y.
  static const double answerGap = MonetaSpacing.spaceSm;

  /// Key on the list of items, so a test can look only at the accordion.
  static const Key listKey = Key('HelpScreen.list');

  /// The key for the item at [index], so a test can address one item.
  static Key itemKey(int index) => ValueKey('HelpScreen.item.$index');

  /// The key for the chevron of the item at [index].
  static Key chevronKey(int index) => ValueKey('HelpScreen.chevron.$index');

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  /// The questions currently open, by their text rather than their index.
  ///
  /// By text because filtering renumbers the list: an index-keyed set would
  /// silently expand a *different* question when a search removed one above it.
  late Set<String> _expanded = {
    if (widget.entries.isNotEmpty) widget.entries.first.question,
  };

  String _query = '';

  List<FaqEntry> get _visible => searchFaq(_query, entries: widget.entries);

  void _toggle(FaqEntry entry) => setState(() {
    if (!_expanded.remove(entry.question)) _expanded.add(entry.question);
  });

  void _search(String query) => setState(() {
    _query = query;
    // Clearing restores the opening state — the first question open and the
    // rest closed — rather than whatever was open when the search began.
    if (query.trim().isEmpty) {
      _expanded = {
        if (widget.entries.isNotEmpty) widget.entries.first.question,
      };
    }
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.moneta;
    final visible = _visible;

    return ColoredBox(
      color: theme.colors.canvas,
      child: Column(
        children: [
          MonetaAppBar(
            title: 'Help & FAQ',
            variant: MonetaAppBarVariant.titleBack,
            onBack: widget.onBack,
            actions: [
              // `102:1291`: the action is "swapped to mail".
              (
                icon: MonetaIconName.mail,
                semanticLabel: 'Email support',
                onPressed: widget.onContactSupport,
              ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: HelpScreen.horizontalInset,
                vertical: MonetaSpacing.spaceSm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  MonetaSearchField(
                    placeholder: 'Search help',
                    onChanged: _search,
                    clearSemanticLabel: 'Clear search',
                  ),
                  const SizedBox(height: HelpScreen.searchGap),
                  if (visible.isEmpty)
                    EmptyState(
                      icon: MonetaIconName.helpCircle,
                      title: 'No answer for that',
                      message:
                          'Nothing here matches your search. Email us and a '
                          'person will answer.',
                      actionLabel: 'Email support',
                      onAction: widget.onContactSupport,
                    )
                  else
                    Column(
                      key: HelpScreen.listKey,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < visible.length; i++)
                          _FaqItem(
                            key: HelpScreen.itemKey(i),
                            index: i,
                            entry: visible[i],
                            expanded: _expanded.contains(visible[i].question),
                            onTap: () => _toggle(visible[i]),
                          ),
                      ],
                    ),
                  const SizedBox(height: MonetaSpacing.spaceSm),
                  ListRow(
                    title: 'Contact support',
                    subtitle: 'We answer within a day',
                    leadingIcon: MonetaIconName.mail,
                    accessory: ListRowAccessory.chevron,
                    onTap: widget.onContactSupport,
                  ),
                  const SizedBox(height: MonetaSpacing.space2xl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One question, with its answer when it is open.
class _FaqItem extends StatelessWidget {
  const _FaqItem({
    required this.index,
    required this.entry,
    required this.expanded,
    required this.onTap,
    super.key,
  });

  final int index;
  final FaqEntry entry;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.moneta;

    return Padding(
      padding: const EdgeInsets.only(bottom: MonetaSpacing.spaceSm),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colors.surface,
          borderRadius: theme.radii.borderLg,
          border: Border.all(color: theme.colors.borderSubtle),
        ),
        child: Semantics(
          button: true,
          expanded: expanded,
          label: entry.question,
          excludeSemantics: true,
          child: GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(HelpScreen.itemPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.question,
                          style: theme.text.titleMd.copyWith(
                            color: theme.colors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: MonetaSpacing.spaceSm),
                      // The only state signal, and the one `102:1300` warns
                      // about: the chevron is derived from `expanded` here, so
                      // the two cannot disagree.
                      MonetaIcon(
                        expanded
                            ? MonetaIconName.chevronUp
                            : MonetaIconName.chevronDown,
                        key: HelpScreen.chevronKey(index),
                        color: theme.colors.textTertiary,
                      ),
                    ],
                  ),
                  if (expanded) ...[
                    const SizedBox(height: HelpScreen.answerGap),
                    Text(
                      entry.answer,
                      style: theme.text.bodyMd.copyWith(
                        color: theme.colors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
