import 'package:countrify_light/countrify_light.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('generated country catalogue', () {
    test('covers 249 ISO-assigned codes plus user-assigned XK', () {
      final countries = AllCountries.all;
      final alpha2Codes =
          countries.map((country) => country.alpha2Code).toSet();
      final alpha3Codes =
          countries.map((country) => country.alpha3Code).toSet();
      final numericCodes = countries
          .map((country) => country.numericCode)
          .where((code) => code.isNotEmpty)
          .toSet();

      expect(countries, hasLength(250));
      expect(alpha2Codes, hasLength(250));
      expect(alpha2Codes.where((code) => code != 'XK'), hasLength(249));
      expect(alpha2Codes, contains('XK'));
      expect(alpha3Codes, hasLength(250));
      expect(numericCodes, hasLength(249));
      expect(
        CountryCode.values.map((code) => code.alpha2Code).toSet(),
        alpha2Codes,
      );
    });

    test('keeps source-backed values and honest missing values', () {
      final unitedStates = AllCountries.getByAlpha2Code('US')!;
      expect(unitedStates.alpha3Code, 'USA');
      expect(unitedStates.numericCode, '840');
      expect(unitedStates.population, 340110988);
      expect(unitedStates.area, 9372610);
      expect(unitedStates.callingCodes, ['1']);
      expect(unitedStates.currencies.single.code, 'USD');
      expect(unitedStates.languages.single.iso6391, 'en');
      expect(unitedStates.languages.single.iso6392, 'eng');
      expect(unitedStates.borders, ['CAN', 'MEX']);

      final afghanistan = AllCountries.getByAlpha2Code('AF')!;
      final dari = afghanistan.languages.firstWhere(
        (language) => language.iso6392 == 'prs',
      );
      expect(afghanistan.population, 43844000);
      expect(afghanistan.area, 652230);
      expect(afghanistan.timezones, ['Asia/Kabul']);
      expect(dari.iso6391, isEmpty);
      expect(dari.nativeName, dari.name);

      final antarctica = AllCountries.getByAlpha2Code('AQ')!;
      expect(antarctica.capital, isEmpty);
      expect(antarctica.population, 0);
      expect(antarctica.currencies, isEmpty);
      expect(antarctica.languages, isEmpty);

      final kosovo = AllCountries.getByAlpha2Code('XK')!;
      expect(kosovo.alpha3Code, 'UNK');
      expect(kosovo.numericCode, isEmpty);
      expect(kosovo.isIndependent, isFalse);
      expect(kosovo.isUnMember, isFalse);

      expect(unitedStates.timezones, contains('America/New_York'));
      expect(unitedStates.timezones, contains('America/Los_Angeles'));
    });

    test('preserves display metadata rows that were previously corrupted', () {
      final brazil = AllCountries.getByAlpha2Code('BR')!;
      expect(brazil.capital, 'Brasília');
      expect(brazil.region, 'Americas');
      expect(brazil.subregion, 'South America');

      final antiguaAndBarbuda = AllCountries.getByAlpha2Code('AG')!;
      expect(antiguaAndBarbuda.region, 'Americas');

      final saoTomeAndPrincipe = AllCountries.getByAlpha2Code('ST')!;
      expect(saoTomeAndPrincipe.name, 'São Tomé and Príncipe');
      expect(saoTomeAndPrincipe.capital, 'São Tomé');

      expect(AllCountries.getByAlpha2Code('HK')?.name, 'Hong Kong');
      expect(AllCountries.getByAlpha2Code('TW')?.name, 'Taiwan');
      expect(AllCountries.getByAlpha2Code('XK')?.name, 'Kosovo');
    });

    test('keeps lightweight-only fields empty and derives emoji from ISO-2',
        () {
      for (final country in AllCountries.all) {
        expect(country.flagImagePath, isEmpty, reason: country.alpha2Code);
        expect(country.largestCity, isNull, reason: country.alpha2Code);
        expect(country.flagEmoji, _flagEmoji(country.alpha2Code));
        expect(
          country.timezones,
          everyElement(matches(RegExp('^[A-Za-z._+-]+/'))),
          reason: country.alpha2Code,
        );
      }
    });

    test('uses normalized constant-time code lookups', () {
      expect(AllCountries.getByAlpha2Code(' us ')?.name, 'United States');
      expect(AllCountries.getByAlpha3Code(' usa ')?.alpha2Code, 'US');
      expect(AllCountries.getByNumericCode(' 840 ')?.alpha2Code, 'US');
      expect(AllCountries.getByAlpha2Code('XX'), isNull);
      expect(AllCountries.getByAlpha3Code('XXX'), isNull);
      expect(AllCountries.getByNumericCode('999'), isNull);
    });

    test('suffixes Dart reserved words without changing their ISO code', () {
      expect(CountryCode.as_.alpha2Code, 'AS');
      expect(CountryCode.do_.alpha2Code, 'DO');
      expect(CountryCode.in_.alpha2Code, 'IN');
      expect(CountryCode.is_.alpha2Code, 'IS');
      expect(CountryCodeExtension.fromAlpha2Code(' as '), CountryCode.as_);
      expect(CountryCodeExtension.fromAlpha2Code('do'), CountryCode.do_);
      expect(CountryCodeExtension.fromAlpha2Code('IN'), CountryCode.in_);
      expect(CountryCodeExtension.fromAlpha2Code('is'), CountryCode.is_);
      expect(CountryCodeExtension.fromAlpha2Code('XX'), isNull);
    });
  });
}

String _flagEmoji(String iso2) {
  const regionalIndicatorOffset = 0x1F1A5;
  return String.fromCharCodes(
    iso2.codeUnits.map((codeUnit) => codeUnit + regionalIndicatorOffset),
  );
}
