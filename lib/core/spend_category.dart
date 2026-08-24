/// A spend or income category.
///
/// Each category is permanently bound to a chart-palette **slot** and an icon
/// name. Figma states the rule this encodes: *"Colour and glyph are baked in
/// together — pick a category, never a colour. This is what keeps a category
/// identical across lists, charts and detail screens."*
///
/// The slot is an integer, not a `Color`. This type lives in `lib/core`, which
/// must stay free of Flutter so the domain layer can use it; and a colour here
/// would also be a design value outside the token layer, which
/// `tool/check_design_tokens.dart` forbids. The design system resolves
/// [chartSlot] to a colour.
enum SpendCategory {
  /// Groceries, restaurants, coffee.
  food(chartSlot: 7, iconName: 'coffee', label: 'Food & drink'),

  /// Fuel, ride-hailing, public transport.
  transport(chartSlot: 4, iconName: 'car', label: 'Transport'),

  /// Retail and online purchases.
  shopping(chartSlot: 2, iconName: 'shopping-bag', label: 'Shopping'),

  /// Utilities, rent, subscriptions.
  bills(chartSlot: 8, iconName: 'file-text', label: 'Bills & utilities'),

  /// Medical, pharmacy, insurance.
  health(chartSlot: 3, iconName: 'heart', label: 'Health'),

  /// Streaming, cinema, games, events.
  entertainment(chartSlot: 6, iconName: 'film', label: 'Entertainment'),

  /// Wages and regular income.
  salary(chartSlot: 1, iconName: 'briefcase', label: 'Salary'),

  /// Gifts given or received.
  gift(chartSlot: 5, iconName: 'gift', label: 'Gifts');

  const SpendCategory({
    required this.chartSlot,
    required this.iconName,
    required this.label,
  });

  /// 1-based index into the eight-slot chart palette.
  final int chartSlot;

  /// Icon name in the Figma icon set, without the `icon/` prefix.
  final String iconName;

  /// Human-readable name.
  final String label;

  /// Categories that represent money coming in.
  static const Set<SpendCategory> incomeCategories = {
    SpendCategory.salary,
  };

  /// Whether this category represents money coming in.
  ///
  /// [gift] is deliberately **not** here: a gift can go either way, and the
  /// direction of a transaction is a property of the transaction, not of its
  /// category. This getter is a display hint only.
  bool get isIncome => incomeCategories.contains(this);

  /// Resolves a stored category name.
  ///
  /// Returns `null` for an unknown name rather than guessing, so a caller
  /// reading a row written by a newer schema version has to handle it.
  static SpendCategory? tryParse(String name) {
    for (final value in values) {
      if (value.name == name) return value;
    }
    return null;
  }
}
