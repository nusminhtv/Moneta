import 'package:moneta/design_system/atoms/moneta_icon_name.dart';

/// One slide of the first-run introduction.
///
/// Transcribed from Figma `71:37`, `71:103` and `71:162`. Each slide is themed to
/// a chart-palette slot: the halo is that slot's subtle tint, the accent dots its
/// base colour at half opacity, the glyph its base colour. The slot is carried
/// rather than a colour, for the same reason `SpendCategory` carries one — the
/// design system resolves slots to colours, nothing else does.
enum OnboardingSlide {
  /// 01.02 — accounts. Sky.
  accounts(
    title: 'Every account in one place',
    body:
        'Bank, cash, e-wallet and credit card. Moneta adds them up so you stop '
        'doing mental maths.',
    glyph: MonetaIconName.creditCard,
    chartSlot: 4,
    figmaNode: '71:37',
  ),

  /// 01.03 — budgets. Mint.
  budgets(
    title: 'Budgets that warn you early',
    body:
        'Set a limit per category. Moneta tells you at 80%, not after you have '
        'already gone over.',
    glyph: MonetaIconName.target,
    chartSlot: 1,
    figmaNode: '71:103',
  ),

  /// 01.04 — goals. Violet.
  goals(
    title: 'Save for what matters',
    body:
        'Set a target and a date. Moneta works out the monthly amount and '
        'tracks it for you.',
    glyph: MonetaIconName.award,
    chartSlot: 2,
    figmaNode: '71:162',
  );

  const OnboardingSlide({
    required this.title,
    required this.body,
    required this.glyph,
    required this.chartSlot,
    required this.figmaNode,
  });

  /// Headline, `heading/h1`.
  final String title;

  /// Supporting copy, `body/lg`.
  final String body;

  /// The 72px glyph at the centre of the illustration.
  final MonetaIconName glyph;

  /// 1-based chart-palette slot this slide is themed to.
  final int chartSlot;

  /// The Figma frame this slide was transcribed from.
  final String figmaNode;

  /// Whether this is the last slide.
  bool get isLast => index == values.length - 1;
}
