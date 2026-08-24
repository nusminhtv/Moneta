/// The rules behind `check_design_tokens.dart`.
///
/// Extracted so the checker itself is testable. A gate nobody tests is a gate
/// that can silently stop catching things — and this one is the main defence
/// against AI-authored UI drifting away from Figma.
library;

/// A single banned construct.
class DesignTokenRule {
  /// Creates a rule.
  const DesignTokenRule(this.description, this.pattern);

  /// Human-readable name, shown in the failure output.
  final String description;

  /// What a violation looks like.
  final RegExp pattern;
}

/// Paths where raw design values are legitimate: the token definitions
/// themselves, and the theme that assembles them.
const List<String> exemptPathPrefixes = [
  'lib/design_system/tokens/',
  'lib/design_system/theme/',
];

/// Marker that allows a deliberate exception on a single line.
const String ignoreMarker = '// design-token-ignore';

/// Every rule the checker enforces.
///
/// The radius and inset rules match a **numeric literal argument only**, not any
/// use of the constructor: `BorderRadius.circular(24)` is a hard-coded design
/// value, while `BorderRadius.circular(size.fillRadius)` is a token being
/// applied, which is exactly what the token layer is for. `\b\d` is deliberate —
/// it will not fire on token names that merely contain a digit, such as
/// `spacing.x3l`.
final List<DesignTokenRule> designTokenRules = [
  DesignTokenRule('raw ARGB colour', RegExp(r'Color\(0x')),
  DesignTokenRule('Colors.* palette', RegExp(r'\bColors\.[a-zA-Z]')),
  DesignTokenRule('inline TextStyle', RegExp(r'\bTextStyle\(')),
  DesignTokenRule(
    'hard-coded EdgeInsets value',
    RegExp(r'EdgeInsets\.(all|symmetric|only|fromLTRB)\([^)]*\b\d'),
  ),
  DesignTokenRule(
    'hard-coded BorderRadius value',
    RegExp(r'BorderRadius\.circular\(\s*\d'),
  ),
];

/// Returns the rules [line] violates, or an empty list.
///
/// A comment line, or a line carrying [ignoreMarker], violates nothing.
List<DesignTokenRule> violationsIn(String line) {
  if (line.trimLeft().startsWith('//')) return const [];
  if (line.contains(ignoreMarker)) return const [];
  return [
    for (final rule in designTokenRules)
      if (rule.pattern.hasMatch(line)) rule,
  ];
}

/// Whether [path] is exempt from the rules.
bool isExempt(String path) => exemptPathPrefixes.any(path.startsWith);
