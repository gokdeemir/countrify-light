import 'package:countrify_light/countrify_light.dart';
import 'package:countrify_light/src/widgets/shared/countrify_check_icon.dart';
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

  testWidgets('moves its focus listener when focusNode changes',
      (tester) async {
    final first = _InspectableFocusNode();
    final second = _InspectableFocusNode();
    final focusNode = ValueNotifier<FocusNode>(first);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ValueListenableBuilder<FocusNode>(
            valueListenable: focusNode,
            builder: (_, value, __) => CountryDropdownField(
              initialCountryCode: CountryCode.tr,
              pickerMode: CountryPickerMode.none,
              focusNode: value,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(first.hasRegisteredListeners, isTrue);

    focusNode.value = second;
    await tester.pumpAndSettle();

    expect(first.hasRegisteredListeners, isFalse);
    expect(second.hasRegisteredListeners, isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
    focusNode.dispose();
    first.dispose();
    second.dispose();
  });

  testWidgets('respects style icons over generated flag and caret',
      (tester) async {
    const prefix = SizedBox(key: Key('custom-prefix'), width: 20, height: 20);
    const suffix = SizedBox(key: Key('custom-suffix'), width: 20, height: 20);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CountryDropdownField(
            initialCountryCode: CountryCode.tr,
            pickerMode: CountryPickerMode.none,
            style: CountrifyFieldStyle.defaultStyle().copyWith(
              prefixIcon: prefix,
              suffixIcon: suffix,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final decoration =
        tester.widget<InputDecorator>(find.byType(InputDecorator)).decoration;
    expect(decoration.prefixIcon, same(prefix));
    expect(decoration.suffixIcon, same(suffix));
    expect(find.byType(CountryFlag), findsNothing);
    expect(find.byType(CountrifyDownArrowIcon), findsNothing);
  });

  testWidgets('hides generated globe and caret when explicitly disabled',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CountryDropdownField(
            pickerMode: CountryPickerMode.none,
            showFlag: false,
            showDropdownIcon: false,
          ),
        ),
      ),
    );

    final decoration =
        tester.widget<InputDecorator>(find.byType(InputDecorator)).decoration;
    expect(decoration.prefixIcon, isNull);
    expect(decoration.suffixIcon, isNull);
    expect(find.byType(CountryFlag), findsNothing);
    expect(find.byType(CountrifyDownArrowIcon), findsNothing);
  });

  for (final mode in [
    CountryPickerMode.bottomSheet,
    CountryPickerMode.dialog,
    CountryPickerMode.fullScreen,
    CountryPickerMode.dropdown,
  ]) {
    testWidgets('forwards custom picker builders in ${mode.name} mode',
        (tester) async {
      Widget itemBuilder(
        BuildContext context,
        Country country,
        // The picker callback API requires selection as a positional boolean.
        // ignore: avoid_positional_boolean_parameters
        bool isSelected,
      ) {
        return Text(
          country.name,
          key: ValueKey('custom-${country.alpha2Code}'),
        );
      }

      Widget headerBuilder(BuildContext context) => const Text('Custom header');
      Widget searchBuilder(
        BuildContext context,
        TextEditingController controller,
        ValueChanged<String> onChanged,
      ) {
        return const SizedBox(key: Key('custom-search'));
      }

      Widget filterBuilder(
        BuildContext context,
        CountryFilter filter,
        ValueChanged<CountryFilter> onChanged,
      ) {
        return const SizedBox(key: Key('custom-filter'));
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CountryDropdownField(
              initialCountryCode: CountryCode.tr,
              pickerMode: mode,
              filterEnabled: true,
              customCountryBuilder: itemBuilder,
              customHeaderBuilder: headerBuilder,
              customSearchBuilder: searchBuilder,
              customFilterBuilder: filterBuilder,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(CountryDropdownField));
      await tester.pumpAndSettle();

      final picker = tester.widget<CountryPicker>(find.byType(CountryPicker));
      expect(picker.customCountryBuilder, isNotNull);
      expect(picker.customHeaderBuilder, same(headerBuilder));
      expect(picker.customSearchBuilder, same(searchBuilder));
      expect(picker.customFilterBuilder, same(filterBuilder));
      expect(find.text('Custom header'), findsOneWidget);
      expect(find.byKey(const Key('custom-search')), findsOneWidget);
      expect(find.byKey(const Key('custom-filter')), findsOneWidget);
    });
  }

  testWidgets('dropdown mode opens an anchored picker and returns selection',
      (tester) async {
    Country? selected;
    final target = CountryUtils.getCountryByAlpha2Code('AF')!;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CountryDropdownField(
            initialCountryCode: CountryCode.tr,
            pickerMode: CountryPickerMode.dropdown,
            searchEnabled: false,
            showPhoneCode: false,
            onChanged: (country) => selected = country,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(CountryDropdownField));
    await tester.pumpAndSettle();

    expect(
      tester.widget<CountryPicker>(find.byType(CountryPicker)).pickerType,
      CountryPickerType.inline,
    );
    await tester.tap(find.text(target.name));
    await tester.pumpAndSettle();

    expect(selected?.alpha2Code, 'AF');
    expect(find.text(target.name), findsOneWidget);
  });
}

class _InspectableFocusNode extends FocusNode {
  bool get hasRegisteredListeners => hasListeners;
}
