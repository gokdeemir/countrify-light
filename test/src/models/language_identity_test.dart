import 'package:countrify_light/countrify_light.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('languages without ISO 639-1 codes remain distinct', () {
    const dari = Language(
      iso6391: '',
      iso6392: 'prs',
      name: 'Dari',
      nativeName: 'Dari',
    );
    const bavarian = Language(
      iso6391: '',
      iso6392: 'bar',
      name: 'Bavarian',
      nativeName: 'Bavarian',
    );

    expect(dari, isNot(equals(bavarian)));
    expect({dari, bavarian}, hasLength(2));
  });

  test('language utilities use the source-backed three-letter identity', () {
    final languages = CountryUtils.getAllLanguages();

    expect(languages.map((language) => language.iso6392), contains('prs'));
    expect(languages.map((language) => language.iso6392), contains('bar'));
    expect(CountryUtils.getCountriesByLanguageCode(' PRS '), isNotEmpty);
    expect(CountryUtils.getCountriesByLanguageCode(''), isEmpty);
  });
}
