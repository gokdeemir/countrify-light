import 'package:countrify_light/countrify_light.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('forwards flag presentation options to each country row',
      (tester) async {
    final country = CountryUtils.getCountryByAlpha2Code('US')!;
    const emojiStyle = TextStyle(fontSize: 17);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CountryListView(
            countries: [country],
            onSelected: (_) {},
            flagShape: FlagShape.circular,
            flagBorderColor: Colors.red,
            flagBorderWidth: 2,
            flagShadowColor: Colors.black,
            flagShadowBlur: 5,
            flagShadowOffset: const Offset(2, 3),
            flagEmojiTextStyle: emojiStyle,
            flagOpticalOffset: Offset.zero,
          ),
        ),
      ),
    );

    final flag = tester.widget<CountryFlag>(find.byType(CountryFlag));
    expect(flag.borderRadius, BorderRadius.circular(12));
    expect(flag.borderColor, Colors.red);
    expect(flag.borderWidth, 2);
    expect(flag.shadowColor, Colors.black);
    expect(flag.shadowBlur, 5);
    expect(flag.shadowOffset, const Offset(2, 3));
    expect(flag.emojiTextStyle, emojiStyle);
    expect(flag.opticalOffset, Offset.zero);
  });
}
