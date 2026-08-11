import 'package:countrify/countrify.dart';
import 'package:countrify/src/widgets/shared/countrify_check_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('keeps the country caret centered and uses the icon color', (
    tester,
  ) async {
    final theme = CountryPickerTheme.darkTheme();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              child: CountryDropdownField(
                initialCountryCode: CountryCode.tr,
                pickerMode: CountryPickerMode.none,
                showPhoneCode: false,
                theme: theme,
                style: CountrifyFieldStyle.darkStyle().copyWith(
                  suffixIconConstraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 56,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final caret = tester.widget<CountrifyDownArrowIcon>(
      find.byType(CountrifyDownArrowIcon),
    );

    expect(caret.color, theme.headerIconColor);
    expect(
      tester.getSize(find.byType(CountryDropdownField)).height,
      lessThan(80),
    );
    expect(tester.widget<CountryFlag>(find.byType(CountryFlag)).borderWidth, 0);
  });
}
