import 'package:countrify_light/countrify_light.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final testCountry = CountryUtils.getCountryByAlpha2Code('US')!;

  group('CountryFlag', () {
    test('country picker config leaves emoji flags unframed by default', () {
      expect(const CountryPickerConfig().flagBorderWidth, 0);
    });

    testWidgets('renders with correct size', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CountryFlag(country: testCountry, size: const Size(32, 24)),
          ),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
      expect(sizedBox.width, 32);
      expect(sizedBox.height, 24);
    });

    testWidgets('has correct semantics label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: CountryFlag(country: testCountry)),
        ),
      );

      expect(find.bySemanticsLabel('Flag of United States'), findsOneWidget);
    });

    testWidgets('renders without a decorative frame by default', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: CountryFlag(country: testCountry)),
        ),
      );

      expect(find.byType(DecoratedBox), findsNothing);
      expect(find.byType(ClipRRect), findsNothing);
    });

    testWidgets('applies an explicitly requested border and radius', (
      tester,
    ) async {
      const radius = BorderRadius.all(Radius.circular(8));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CountryFlag(
              country: testCountry,
              borderRadius: radius,
              borderWidth: 1,
            ),
          ),
        ),
      );

      final clipRRect = tester.widget<ClipRRect>(find.byType(ClipRRect));
      expect(clipRRect.borderRadius, radius);
      expect(find.byType(DecoratedBox), findsOneWidget);
    });

    testWidgets('renders the country emoji without an image asset', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: CountryFlag(country: testCountry)),
        ),
      );

      expect(find.text(testCountry.flagEmoji), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('optically centers the emoji above its low font baseline', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: CountryFlag(country: testCountry)),
        ),
      );

      final translation = tester.widget<FractionalTranslation>(
        find.descendant(
          of: find.byType(CountryFlag),
          matching: find.byType(FractionalTranslation),
        ),
      );
      expect(translation.translation, const Offset(0, -0.08));
    });

    testWidgets('allows the optical correction to be overridden',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CountryFlag(
              country: testCountry,
              opticalOffset: Offset.zero,
            ),
          ),
        ),
      );

      final translation = tester.widget<FractionalTranslation>(
        find.descendant(
          of: find.byType(CountryFlag),
          matching: find.byType(FractionalTranslation),
        ),
      );
      expect(translation.translation, Offset.zero);
    });

    testWidgets('renders a requested shadow without adding a hairline border',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CountryFlag(
              country: testCountry,
              shadowColor: Colors.black,
              shadowBlur: 6,
              shadowOffset: const Offset(1, 2),
            ),
          ),
        ),
      );

      final decoration = tester
          .widget<DecoratedBox>(find.byType(DecoratedBox))
          .decoration as BoxDecoration;
      expect(decoration.border, isNull);
      expect(decoration.boxShadow, hasLength(1));
      expect(decoration.boxShadow!.single.blurRadius, 6);
      expect(decoration.boxShadow!.single.offset, const Offset(1, 2));
    });
  });
}
