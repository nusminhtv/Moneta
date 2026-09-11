/// Finds raw design values on a widget's **public API**, from its source.
///
/// This exists because `tool/check_design_tokens.dart` cannot see an API at
/// all: it matches five constructs in a file's body (`Color(0x`, `Colors.`,
/// `TextStyle(`, `EdgeInsets.*` with a digit, `BorderRadius.circular(` with a
/// digit), so a component that *accepts* a `Color` from its caller passes the
/// gate cleanly. The rule "design-system widgets take domain types, not raw
/// design values" is a source check or it is nothing.
///
/// **It reads field declarations, not the constructor's parameter list.** Five
/// components in `settings-components` shipped a check that sliced the
/// constructor block and asserted it contained no `'Color'` — and every
/// parameter in this repository is written `this.x`, so the *type* lives
/// outside that slice. `change-verifier` added `this.tint` plus
/// `final Color? tint;` and the whole gate stayed green. A check that cannot
/// fail against the only way the defect would actually be written is worse
/// than no check, because the spec then claims it is verified.
library;

/// The raw design-value fields declared by [className] in [source].
///
/// Returns the offending declarations, so a caller can assert the list is
/// empty **and** assert that a counterfeit produces a non-empty one — without
/// which this helper is the very thing it was written to replace.
List<String> rawDesignValueFields(String source, String className) {
  final body = _classBody(source, className);
  if (body == null) return ['<class $className not found in source>'];

  final found = <String>[];
  for (final line in _withoutComments(body).split('\n')) {
    final trimmed = line.trim();
    if (!trimmed.startsWith('final ')) continue;
    for (final type in _rawTypes) {
      // `final Color foo;` and `final Color? foo;`, but not `final ColorRole`.
      if (RegExp('^final $type\\??\\s').hasMatch(trimmed)) {
        found.add(trimmed);
        break;
      }
    }
  }
  return found;
}

/// Types a caller must never be able to hand a design-system widget.
const _rawTypes = [
  'Color',
  'TextStyle',
  'EdgeInsets',
  'EdgeInsetsGeometry',
  'BorderRadius',
  'Radius',
  'BoxDecoration',
  'Border',
];

/// [className]'s declaration body, from its opening brace to the next
/// top-level `class` or the end of the file.
String? _classBody(String source, String className) {
  final declaration = RegExp(
    '^(?:abstract )?(?:final )?class $className\\b',
    multiLine: true,
  ).firstMatch(source);
  if (declaration == null) return null;

  final from = declaration.start;
  final next = RegExp(
    '^(?:abstract )?(?:final )?class ',
    multiLine: true,
  ).firstMatch(source.substring(declaration.end));
  return next == null
      ? source.substring(from)
      : source.substring(from, declaration.end + next.start);
}

/// [source] with `///` and `//` comments removed.
///
/// Without this, a doc comment that *mentions* `final Color` would be read as
/// a declaration — the mistake two source checks in this repository already
/// made, once on a comment naming `SystemIdGenerator` and once on one quoting
/// an annotation about `StatTile`.
String _withoutComments(String source) => source
    .split('\n')
    .map((line) {
      final comment = line.indexOf('//');
      return comment == -1 ? line : line.substring(0, comment);
    })
    .join('\n');
