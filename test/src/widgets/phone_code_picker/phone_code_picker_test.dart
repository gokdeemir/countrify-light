import 'package:countrify_light/countrify_light.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('keeps emoji flags unframed by default', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PhoneCodePicker(
            initialCountryCode: CountryCode.tr,
            pickerMode: CountryPickerMode.none,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.widget<CountryFlag>(find.byType(CountryFlag)).borderWidth, 0);
  });

  testWidgets('applies its public flag presentation properties',
      (tester) async {
    const emojiStyle = TextStyle(fontSize: 18);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PhoneCodePicker(
            initialCountryCode: CountryCode.tr,
            pickerMode: CountryPickerMode.none,
            flagSize: Size(30, 20),
            flagShape: FlagShape.circular,
            flagBorderColor: Colors.red,
            flagBorderWidth: 2,
            flagShadowColor: Colors.black,
            flagShadowBlur: 6,
            flagShadowOffset: Offset(2, 3),
            theme: CountryPickerTheme(
              flagEmojiTextStyle: emojiStyle,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final flag = tester.widget<CountryFlag>(find.byType(CountryFlag));
    expect(flag.borderRadius, BorderRadius.circular(15));
    expect(flag.borderColor, Colors.red);
    expect(flag.borderWidth, 2);
    expect(flag.shadowColor, Colors.black);
    expect(flag.shadowBlur, 6);
    expect(flag.shadowOffset, const Offset(2, 3));
    expect(flag.emojiTextStyle, emojiStyle);
  });
}
