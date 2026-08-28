import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/design_system/molecules/skeleton.dart';
import 'package:moneta/design_system/tokens/colors.dart';
import 'package:moneta/design_system/tokens/spacing.dart';

import '../../support/pump.dart';

void main() {
  const colors = MonetaColors.dark();

  Future<void> pumpSkeleton(
    WidgetTester tester,
    SkeletonShape shape, {
    double width = 353,
  }) {
    return pumpMonetaWidget(
      tester,
      SizedBox(
        width: width,
        child: Skeleton(shape: shape),
      ),
      surfaceSize: const Size(420, 320),
    );
  }

  Color firstBlockColor(WidgetTester tester) {
    final box = tester.widget<DecoratedBox>(find.byType(DecoratedBox).first);
    return (box.decoration as BoxDecoration).color!;
  }

  testWidgets('line shape fills width at line height', (tester) async {
    await pumpSkeleton(tester, SkeletonShape.line);

    expect(firstBlockColor(tester), colors.track);
    expect(tester.getSize(find.byType(Skeleton)), const Size(353, 12));
  });

  testWidgets('circle shape is a square circular block', (tester) async {
    await pumpSkeleton(tester, SkeletonShape.circle);

    expect(tester.getSize(find.byType(DecoratedBox).first), const Size(48, 48));
  });

  testWidgets('card shape fills width with card height', (tester) async {
    await pumpSkeleton(tester, SkeletonShape.card);

    expect(
      tester.getSize(find.byType(Skeleton)),
      const Size(353, MonetaSpacing.space5xl + MonetaSpacing.space5xl),
    );
  });

  testWidgets('row shape contains a leading circle and two lines', (
    tester,
  ) async {
    await pumpSkeleton(tester, SkeletonShape.row);

    expect(find.byType(Skeleton), findsNWidgets(2));
    expect(tester.getSize(find.byType(Skeleton).first).width, 353);
    expect(tester.getSize(find.byType(Skeleton).last), const Size(48, 48));
    expect(find.byType(DecoratedBox), findsNWidgets(3));
  });

  testWidgets('row shape does not overflow narrow widths', (tester) async {
    await pumpSkeleton(tester, SkeletonShape.row, width: 160);

    expect(tester.takeException(), isNull);
    final row = tester.getRect(find.byType(Skeleton).first);
    for (final block in find.byType(DecoratedBox).evaluate()) {
      final rect = tester.getRect(find.byWidget(block.widget));
      expect(rect.left, greaterThanOrEqualTo(row.left));
      expect(rect.right, lessThanOrEqualTo(row.right));
    }
  });
}
