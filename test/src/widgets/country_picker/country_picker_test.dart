import 'package:countrify_light/countrify_light.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders picker flags through CountryFlag with full styling',
      (tester) async {
    const emojiStyle = TextStyle(fontSize: 20);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 320,
            child: CountryPicker(
              initialCountryCode: CountryCode.tr,
              pickerType: CountryPickerType.inline,
              searchEnabled: false,
              flagSize: Size(30, 20),
              flagShape: FlagShape.circular,
              flagShadowColor: Colors.black,
              flagShadowBlur: 7,
              flagShadowOffset: Offset(2, 3),
              config: CountryPickerConfig(
                flagBorderColor: Colors.red,
                flagBorderWidth: 2,
              ),
              theme: CountryPickerTheme(
                flagEmojiTextStyle: emojiStyle,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CountryFlag), findsWidgets);
    final flag = tester.widget<CountryFlag>(find.byType(CountryFlag).first);
    expect(flag.size, const Size(30, 20));
    expect(flag.borderRadius, BorderRadius.circular(15));
    expect(flag.borderColor, Colors.red);
    expect(flag.borderWidth, 2);
    expect(flag.shadowColor, Colors.black);
    expect(flag.shadowBlur, 7);
    expect(flag.shadowOffset, const Offset(2, 3));
    expect(flag.emojiTextStyle, emojiStyle);
  });

  testWidgets('centers flag and country name when no subtitle is visible',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 320,
            child: CountryPicker(
              initialCountryCode: CountryCode.tr,
              pickerType: CountryPickerType.inline,
              searchEnabled: false,
              showPhoneCode: false,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final firstTile = find.byType(ListTile).first;
    expect(tester.widget<ListTile>(firstTile).subtitle, isNull);

    final flagCenter = tester.getRect(find.byType(CountryFlag).first).center.dy;
    final nameCenter = tester.getRect(find.text('Türkiye').first).center.dy;
    expect((flagCenter - nameCenter).abs(), lessThan(1));
  });
}
