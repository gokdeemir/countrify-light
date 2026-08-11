import 'package:countrify/src/widgets/shared/countrify_check_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('keeps the caret square and centered in tall field constraints', (
    tester,
  ) async {
    const boundsKey = ValueKey('suffix-bounds');

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              key: boundsKey,
              width: 44,
              height: 56,
              child: CountrifyDownArrowIcon(),
            ),
          ),
        ),
      ),
    );

    final caretPaint = find.descendant(
      of: find.byType(CountrifyDownArrowIcon),
      matching: find.byType(CustomPaint),
    );
    final boundsRect = tester.getRect(find.byKey(boundsKey));
    final caretRect = tester.getRect(caretPaint);

    expect(caretRect.size, const Size.square(20));
    expect(caretRect.center, boundsRect.center);
  });
}
