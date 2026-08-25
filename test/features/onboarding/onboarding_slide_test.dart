import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/design_system/atoms/moneta_icon_name.dart';
import 'package:moneta/design_system/tokens/colors.dart';
import 'package:moneta/features/onboarding/domain/onboarding_slide.dart';

void main() {
  test('there are exactly three slides, as Figma authors', () {
    expect(OnboardingSlide.values, hasLength(3));
  });

  test('each slide carries the copy transcribed from its frame', () {
    expect(OnboardingSlide.accounts.title, 'Every account in one place');
    expect(OnboardingSlide.budgets.title, 'Budgets that warn you early');
    expect(OnboardingSlide.goals.title, 'Save for what matters');

    // Bodies pinned to the frames, as the titles already were. They were only
    // asserted `isNotEmpty`, so slide 1 and slide 3's copy could be swapped with
    // the whole suite green — and the screen test read each body off the same
    // enum it was checking, so it could not catch it either.
    expect(
      OnboardingSlide.accounts.body,
      'Bank, cash, e-wallet and credit card. Moneta adds them up so you stop '
      'doing mental maths.',
    );
    expect(
      OnboardingSlide.budgets.body,
      'Set a limit per category. Moneta tells you at 80%, not after you have '
      'already gone over.',
    );
    expect(
      OnboardingSlide.goals.body,
      'Set a target and a date. Moneta works out the monthly amount and tracks '
      'it for you.',
    );
  });

  test('each slide names the Figma frame it came from', () {
    expect(OnboardingSlide.accounts.figmaNode, '71:37');
    expect(OnboardingSlide.budgets.figmaNode, '71:103');
    expect(OnboardingSlide.goals.figmaNode, '71:162');
  });

  test('the glyphs are the ones the illustrations instance', () {
    expect(OnboardingSlide.accounts.glyph, MonetaIconName.creditCard);
    expect(OnboardingSlide.budgets.glyph, MonetaIconName.target);
    expect(OnboardingSlide.goals.glyph, MonetaIconName.award);
  });

  test('the chart slots match the halo fills read from the exported SVGs', () {
    // #051A2B = chart-4-subtle, #051F18 = chart-1-subtle, #1B1931 = chart-2-subtle
    expect(OnboardingSlide.accounts.chartSlot, 4);
    expect(OnboardingSlide.budgets.chartSlot, 1);
    expect(OnboardingSlide.goals.chartSlot, 2);
  });

  test('every slot is inside the palette and distinct per slide', () {
    final slots = OnboardingSlide.values.map((s) => s.chartSlot).toList();
    expect(slots.toSet(), hasLength(slots.length));
    for (final slot in slots) {
      expect(slot, inInclusiveRange(1, MonetaChartPalette.slotCount));
    }
  });

  test('only the last slide reports itself last', () {
    expect(OnboardingSlide.accounts.isLast, isFalse);
    expect(OnboardingSlide.budgets.isLast, isFalse);
    expect(OnboardingSlide.goals.isLast, isTrue);
  });

  test('every slide uses its own glyph', () {
    expect(
      OnboardingSlide.values.map((s) => s.glyph).toSet(),
      hasLength(OnboardingSlide.values.length),
    );
  });
}
