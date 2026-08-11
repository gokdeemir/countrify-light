import 'package:countrify_light/countrify_light.dart';
import 'package:countrify_light/src/widgets/shared/countrify_check_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final testCountry = CountryUtils.getCountryByAlpha2Code('US')!;

  Widget buildSubject({
    Country? country,
    ValueChanged<Country>? onTap,
    bool isSelected = false,
    bool showFlag = true,
    bool showCountryName = true,
    bool showDialCode = true,
    String? displayName,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: CountryListTile(
          country: country ?? testCountry,
          onTap: onTap ?? (_) {},
          isSelected: isSelected,
          showFlag: showFlag,
          showCountryName: showCountryName,
          showDialCode: showDialCode,
          displayName: displayName,
        ),
      ),
    );
  }

  group('CountryListTile', () {
    testWidgets('renders country name and dial code text', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.text('United States'), findsOneWidget);
      expect(find.text('+1'), findsOneWidget);
    });

    testWidgets('shows CountryFlag widget', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.byType(CountryFlag), findsOneWidget);
      expect(
        tester
            .widget<Row>(
              find.descendant(
                of: find.byType(CountryListTile),
                matching: find.byType(Row),
              ),
            )
            .crossAxisAlignment,
        CrossAxisAlignment.center,
      );
    });

    testWidgets('shows checkmark icon when isSelected is true', (tester) async {
      await tester.pumpWidget(buildSubject(isSelected: true));

      expect(find.byType(CountrifyCheckIcon), findsOneWidget);
    });

    testWidgets('does not show checkmark icon when isSelected is false',
        (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.byType(CountrifyCheckIcon), findsNothing);
    });

    testWidgets('fires onTap callback when tapped', (tester) async {
      Country? tappedCountry;
      await tester.pumpWidget(
        buildSubject(onTap: (country) => tappedCountry = country),
      );

      await tester.tap(find.byType(InkWell));
      expect(tappedCountry, equals(testCountry));
    });

    testWidgets('has correct semantics label', (tester) async {
      await tester.pumpWidget(buildSubject());

      final semantics = tester.widget<Semantics>(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.label == 'United States, dial code +1',
        ),
      );
      expect(semantics, isNotNull);
      expect(semantics.excludeSemantics, isTrue);
      expect(semantics.properties.button, isTrue);
    });

    testWidgets('semantics only includes visible name and dial code',
        (tester) async {
      await tester.pumpWidget(
        buildSubject(showCountryName: false),
      );
      expect(find.bySemanticsLabel('dial code +1'), findsOneWidget);
      expect(
        find.bySemanticsLabel('United States, dial code +1'),
        findsNothing,
      );

      await tester.pumpWidget(
        buildSubject(showDialCode: false),
      );
      expect(find.bySemanticsLabel('United States'), findsOneWidget);
      expect(
        find.bySemanticsLabel('United States, dial code +1'),
        findsNothing,
      );
    });

    testWidgets('forwards flag shape, border, shadow and emoji style',
        (tester) async {
      const emojiStyle = TextStyle(fontSize: 19, height: 1.1);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CountryListTile(
              country: testCountry,
              onTap: (_) {},
              flagSize: const Size(30, 20),
              flagShape: FlagShape.circular,
              flagBorderColor: Colors.red,
              flagBorderWidth: 2,
              flagShadowColor: Colors.black,
              flagShadowBlur: 4,
              flagShadowOffset: const Offset(1, 2),
              flagEmojiTextStyle: emojiStyle,
              flagOpticalOffset: Offset.zero,
            ),
          ),
        ),
      );

      final flag = tester.widget<CountryFlag>(find.byType(CountryFlag));
      expect(flag.borderRadius, BorderRadius.circular(15));
      expect(flag.borderColor, Colors.red);
      expect(flag.borderWidth, 2);
      expect(flag.shadowColor, Colors.black);
      expect(flag.shadowBlur, 4);
      expect(flag.shadowOffset, const Offset(1, 2));
      expect(flag.emojiTextStyle, emojiStyle);
      expect(flag.opticalOffset, Offset.zero);
    });

    testWidgets('uses displayName when provided', (tester) async {
      await tester.pumpWidget(
        buildSubject(displayName: 'Estados Unidos'),
      );

      expect(find.text('Estados Unidos'), findsOneWidget);

      final semantics = tester.widget<Semantics>(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.label == 'Estados Unidos, dial code +1',
        ),
      );
      expect(semantics, isNotNull);
    });
  });
}
