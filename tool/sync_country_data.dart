// This CLI reports progress and emits long Dart 3.0-formatted source fragments;
// that formatter intentionally omits some analyzer-preferred trailing commas.
// ignore_for_file: avoid_print, require_trailing_commas

/// Regenerates the compile-time country catalogue from two pinned upstream
/// datasets.
///
/// dr5hn supplies population, calling codes, and IANA time zone identifiers.
/// mledoze supplies display metadata, ISO identifiers, currencies, languages,
/// borders, area, and independence/UN status. mledoze language map keys are
/// ISO 639-3 codes; they are written to the legacy `Language.iso6392` field for
/// public API
/// compatibility. Language names are English, so `Language.nativeName` falls
/// back to that value. ISO 639-1 is empty when no two-letter equivalent exists.
///
/// Usage:
///   dart run tool/sync_country_data.dart
///   dart run tool/sync_country_data.dart --check
///   dart run tool/sync_country_data.dart \
///     --dr5hn-input /path/to/countries.json \
///     --mledoze-input /path/to/countries.json
library;

import 'dart:convert';
import 'dart:io';

const _expectedCountryCount = 250;
const _dr5hnCommit = '624a208c3928937d1262ab1646d0b8fc9cacceee';
const _mledozeCommit = '9eff32e4eef26715aa59d99b200127d1ef150e7a';
const _dr5hnUrl = 'https://raw.githubusercontent.com/dr5hn/'
    'countries-states-cities-database/$_dr5hnCommit/json/countries.json';
const _mledozeUrl = 'https://raw.githubusercontent.com/mledoze/countries/'
    '$_mledozeCommit/countries.json';

const _dartReservedWords = {'as', 'do', 'in', 'is'};

// ISO 639-3 keys used by mledoze that have an ISO 639-1 equivalent.
const _iso6391ByIso6393 = <String, String>{
  'afr': 'af',
  'amh': 'am',
  'ara': 'ar',
  'aym': 'ay',
  'aze': 'az',
  'bel': 'be',
  'ben': 'bn',
  'bis': 'bi',
  'bos': 'bs',
  'bul': 'bg',
  'cat': 'ca',
  'ces': 'cs',
  'cha': 'ch',
  'dan': 'da',
  'deu': 'de',
  'div': 'dv',
  'dzo': 'dz',
  'ell': 'el',
  'eng': 'en',
  'est': 'et',
  'fao': 'fo',
  'fas': 'fa',
  'fij': 'fj',
  'fin': 'fi',
  'fra': 'fr',
  'gle': 'ga',
  'glv': 'gv',
  'grn': 'gn',
  'hat': 'ht',
  'heb': 'he',
  'her': 'hz',
  'hin': 'hi',
  'hmo': 'ho',
  'hrv': 'hr',
  'hun': 'hu',
  'hye': 'hy',
  'ind': 'id',
  'isl': 'is',
  'ita': 'it',
  'jpn': 'ja',
  'kal': 'kl',
  'kat': 'ka',
  'kaz': 'kk',
  'khm': 'km',
  'kin': 'rw',
  'kir': 'ky',
  'kon': 'kg',
  'kor': 'ko',
  'lao': 'lo',
  'lat': 'la',
  'lav': 'lv',
  'lin': 'ln',
  'lit': 'lt',
  'ltz': 'lb',
  'mah': 'mh',
  'mkd': 'mk',
  'mlg': 'mg',
  'mlt': 'mt',
  'mon': 'mn',
  'mri': 'mi',
  'msa': 'ms',
  'mya': 'my',
  'nau': 'na',
  'nbl': 'nr',
  'nde': 'nd',
  'ndo': 'ng',
  'nep': 'ne',
  'nld': 'nl',
  'nno': 'nn',
  'nob': 'nb',
  'nor': 'no',
  'nya': 'ny',
  'pol': 'pl',
  'por': 'pt',
  'pus': 'ps',
  'que': 'qu',
  'roh': 'rm',
  'ron': 'ro',
  'run': 'rn',
  'rus': 'ru',
  'sag': 'sg',
  'sin': 'si',
  'slk': 'sk',
  'slv': 'sl',
  'smo': 'sm',
  'sna': 'sn',
  'som': 'so',
  'sot': 'st',
  'spa': 'es',
  'sqi': 'sq',
  'srp': 'sr',
  'ssw': 'ss',
  'swa': 'sw',
  'swe': 'sv',
  'tam': 'ta',
  'tgk': 'tg',
  'tha': 'th',
  'tir': 'ti',
  'ton': 'to',
  'tsn': 'tn',
  'tso': 'ts',
  'tuk': 'tk',
  'tur': 'tr',
  'ukr': 'uk',
  'urd': 'ur',
  'uzb': 'uz',
  'ven': 've',
  'vie': 'vi',
  'xho': 'xh',
  'zho': 'zh',
  'zul': 'zu',
};

Future<void> main(List<String> args) async {
  final options = _Options.parse(args);
  final root = _findProjectRoot();

  final dr5hnJson = await _readSource(options.dr5hnInput, _dr5hnUrl);
  final mledozeJson = await _readSource(options.mledozeInput, _mledozeUrl);
  final dr5hn = _decodeCountries(dr5hnJson, 'dr5hn');
  final mledoze = _decodeCountries(mledozeJson, 'mledoze');
  final countries = _mergeAndValidate(dr5hn, mledoze);

  final generated = <String, String>{
    'lib/src/data/all_countries.dart': _generateAllCountries(countries),
    'lib/src/models/country_code.dart': _generateCountryCode(countries),
  };
  final formatted = await _formatGenerated(generated);

  if (options.check) {
    var stale = false;
    for (final entry in formatted.entries) {
      final destination = File('${root.path}/${entry.key}');
      final existing =
          destination.existsSync() ? await destination.readAsString() : null;
      if (existing != entry.value) {
        stderr.writeln('${entry.key} is stale; run this generator');
        stale = true;
      }
    }
    if (stale) exitCode = 1;
    if (!stale) print('country catalogue is up to date');
    return;
  }

  await _replaceGeneratedFiles(root, formatted);
  for (final path in formatted.keys) {
    print('wrote $path');
  }
  print('generated ${countries.length} countries from pinned sources');
}

class _Options {
  const _Options({
    required this.check,
    this.dr5hnInput,
    this.mledozeInput,
  });

  factory _Options.parse(List<String> args) {
    var check = false;
    String? dr5hnInput;
    String? mledozeInput;

    for (var index = 0; index < args.length; index++) {
      final argument = args[index];
      switch (argument) {
        case '--check':
          check = true;
        case '--dr5hn-input':
          dr5hnInput = _nextValue(args, ++index, argument);
        case '--mledoze-input':
          mledozeInput = _nextValue(args, ++index, argument);
        default:
          throw FormatException('Unknown argument: $argument');
      }
    }

    return _Options(
      check: check,
      dr5hnInput: dr5hnInput,
      mledozeInput: mledozeInput,
    );
  }

  final bool check;
  final String? dr5hnInput;
  final String? mledozeInput;
}

String _nextValue(List<String> args, int index, String flag) {
  if (index >= args.length || args[index].startsWith('--')) {
    throw FormatException('$flag requires a file path');
  }
  return args[index];
}

Future<String> _readSource(String? input, String url) async {
  if (input != null) {
    print('reading $input');
    return File(input).readAsString();
  }
  return _download(url);
}

List<Map<String, Object?>> _decodeCountries(String source, String label) {
  final decoded = jsonDecode(source);
  if (decoded is! List<Object?>) {
    throw FormatException('$label root must be a JSON array');
  }
  if (decoded.length != _expectedCountryCount) {
    throw FormatException(
      '$label must contain exactly $_expectedCountryCount countries; '
      'found ${decoded.length}',
    );
  }
  return decoded.indexed.map((entry) {
    final (index, value) = entry;
    if (value is! Map<String, Object?>) {
      throw FormatException('$label[$index] must be a JSON object');
    }
    return value;
  }).toList(growable: false);
}

List<_CountrySources> _mergeAndValidate(
  List<Map<String, Object?>> dr5hn,
  List<Map<String, Object?>> mledoze,
) {
  final dr5hnByIso2 = _indexUnique(
    dr5hn,
    source: 'dr5hn',
    codeKey: 'iso2',
    validate: _validateDr5hn,
  );
  final mledozeByIso2 = _indexUnique(
    mledoze,
    source: 'mledoze',
    codeKey: 'cca2',
    validate: _validateMledoze,
  );

  final dr5hnCodes = dr5hnByIso2.keys.toSet();
  final mledozeCodes = mledozeByIso2.keys.toSet();
  if (dr5hnCodes.length != _expectedCountryCount ||
      mledozeCodes.length != _expectedCountryCount ||
      !dr5hnCodes.containsAll(mledozeCodes) ||
      !mledozeCodes.containsAll(dr5hnCodes)) {
    final onlyDr5hn = dr5hnCodes.difference(mledozeCodes).toList()..sort();
    final onlyMledoze = mledozeCodes.difference(dr5hnCodes).toList()..sort();
    throw FormatException(
      'ISO-2 source mismatch; only dr5hn: $onlyDr5hn, '
      'only mledoze: $onlyMledoze',
    );
  }

  final countries = dr5hnCodes.map((iso2) {
    final dr5hnCountry = dr5hnByIso2[iso2]!;
    final mledozeCountry = mledozeByIso2[iso2]!;
    _crossCheckIso(iso2, dr5hnCountry, mledozeCountry);
    return _CountrySources(
      iso2: iso2,
      dr5hn: dr5hnCountry,
      mledoze: mledozeCountry,
    );
  }).toList()
    ..sort((left, right) => left.iso2.compareTo(right.iso2));
  _validateUniqueIdentifiers(countries);
  return countries;
}

void _validateUniqueIdentifiers(List<_CountrySources> countries) {
  final alpha3Codes = <String, String>{};
  final numericCodes = <String, String>{};
  for (final country in countries) {
    final alpha3 = country.mledoze['cca3']! as String;
    final previousAlpha3 = alpha3Codes[alpha3];
    if (previousAlpha3 != null) {
      throw FormatException(
        'Duplicate alpha-3 code $alpha3 for $previousAlpha3 and ${country.iso2}',
      );
    }
    alpha3Codes[alpha3] = country.iso2;

    final numeric = country.mledoze['ccn3']! as String;
    if (numeric.isEmpty) continue;
    final previousNumeric = numericCodes[numeric];
    if (previousNumeric != null) {
      throw FormatException(
        'Duplicate numeric code $numeric for $previousNumeric and ${country.iso2}',
      );
    }
    numericCodes[numeric] = country.iso2;
  }
}

Map<String, Map<String, Object?>> _indexUnique(
  List<Map<String, Object?>> countries, {
  required String source,
  required String codeKey,
  required void Function(Map<String, Object?>, String) validate,
}) {
  final indexed = <String, Map<String, Object?>>{};
  for (final country in countries) {
    final context = '$source.${country[codeKey] ?? '<missing>'}';
    validate(country, context);
    final iso2 = _requiredString(country, codeKey, context);
    if (!RegExp(r'^[A-Z]{2}$').hasMatch(iso2)) {
      throw FormatException('$context.$codeKey must be two uppercase letters');
    }
    if (indexed.containsKey(iso2)) {
      throw FormatException('$source contains duplicate ISO-2 code $iso2');
    }
    indexed[iso2] = country;
  }
  return indexed;
}

void _validateDr5hn(Map<String, Object?> country, String context) {
  for (final key in ['iso2', 'iso3', 'numeric_code', 'phonecode']) {
    _requiredString(country, key, context);
  }
  _requirePattern(country, 'iso3', context, RegExp(r'^[A-Z]{3}$'));
  _requirePattern(country, 'numeric_code', context, RegExp(r'^\d{3}$'));
  _requirePattern(country, 'phonecode', context, RegExp(r'^\d+(?:-\d+)?$'));
  final population = country['population'];
  if (population != null && population is! int) {
    throw FormatException('$context.population must be an integer or null');
  }
  final timezones = _requiredList(country, 'timezones', context);
  if (timezones.isEmpty) {
    throw FormatException('$context.timezones must not be empty');
  }
  for (var index = 0; index < timezones.length; index++) {
    final timezone = timezones[index];
    if (timezone is! Map<String, Object?>) {
      throw FormatException('$context.timezones[$index] must be an object');
    }
    final timezoneContext = '$context.timezones[$index]';
    _requiredString(timezone, 'zoneName', timezoneContext);
    _requirePattern(
      timezone,
      'zoneName',
      timezoneContext,
      RegExp(r'^[A-Za-z._+-]+/[A-Za-z0-9._+/-]+$'),
    );
  }
}

void _validateMledoze(Map<String, Object?> country, String context) {
  for (final key in ['cca2', 'cca3', 'ccn3']) {
    _requiredString(country, key, context, allowEmpty: key == 'ccn3');
  }
  _requirePattern(country, 'cca3', context, RegExp(r'^[A-Z]{3}$'));
  _requirePattern(country, 'ccn3', context, RegExp(r'^(?:\d{3})?$'));
  final name = _requiredMap(country, 'name', context);
  _requiredString(name, 'common', '$context.name');
  for (final key in ['region', 'subregion']) {
    _requiredString(country, key, context, allowEmpty: true);
  }
  for (final key in ['capital', 'tld']) {
    final values = _requiredList(country, key, context);
    if (values.any((value) => value is! String || value.isEmpty)) {
      throw FormatException(
          '$context.$key must contain only non-empty strings');
    }
  }
  final independent = country['independent'];
  if (independent != null && independent is! bool) {
    throw FormatException('$context.independent must be a boolean or null');
  }
  if (country['unMember'] is! bool) {
    throw FormatException('$context.unMember must be a boolean');
  }
  if (country['area'] is! num) {
    throw FormatException('$context.area must be numeric');
  }

  final currencies = _requiredMap(country, 'currencies', context);
  for (final entry in currencies.entries) {
    if (!RegExp(r'^[A-Z]{3}$').hasMatch(entry.key)) {
      throw FormatException(
          '$context.currencies has invalid code ${entry.key}');
    }
    if (entry.value is! Map<String, Object?>) {
      throw FormatException(
          '$context.currencies.${entry.key} must be an object');
    }
    final currency = entry.value! as Map<String, Object?>;
    _requiredString(currency, 'name', '$context.currencies.${entry.key}');
    _requiredString(currency, 'symbol', '$context.currencies.${entry.key}');
  }

  final languages = _requiredMap(country, 'languages', context);
  for (final entry in languages.entries) {
    if (!RegExp(r'^[a-z]{3}$').hasMatch(entry.key)) {
      throw FormatException('$context.languages has invalid code ${entry.key}');
    }
    if (entry.value is! String || (entry.value! as String).isEmpty) {
      throw FormatException('$context.languages.${entry.key} must be a string');
    }
  }

  final borders = _requiredList(country, 'borders', context);
  if (borders.any(
    (border) => border is! String || !RegExp(r'^[A-Z]{3}$').hasMatch(border),
  )) {
    throw FormatException('$context.borders must contain only strings');
  }
}

void _requirePattern(
  Map<String, Object?> object,
  String key,
  String context,
  RegExp pattern,
) {
  final value = object[key]! as String;
  if (!pattern.hasMatch(value)) {
    throw FormatException('$context.$key has invalid value $value');
  }
}

void _crossCheckIso(
  String iso2,
  Map<String, Object?> dr5hn,
  Map<String, Object?> mledoze,
) {
  final dr5hnIso3 = dr5hn['iso3']! as String;
  final mledozeIso3 = mledoze['cca3']! as String;
  final dr5hnNumeric = dr5hn['numeric_code']! as String;
  final mledozeNumeric = mledoze['ccn3']! as String;

  // mledoze represents Kosovo with the user-assigned UNK code and no numeric
  // identifier; dr5hn uses XKX/926. All officially assigned records must agree.
  if (iso2 == 'XK') {
    if (dr5hnIso3 != 'XKX' ||
        mledozeIso3 != 'UNK' ||
        dr5hnNumeric != '926' ||
        mledozeNumeric.isNotEmpty) {
      throw const FormatException('Unexpected Kosovo ISO source values');
    }
    return;
  }
  if (dr5hnIso3 != mledozeIso3 || dr5hnNumeric != mledozeNumeric) {
    throw FormatException(
      '$iso2 ISO mismatch: dr5hn $dr5hnIso3/$dr5hnNumeric, '
      'mledoze $mledozeIso3/$mledozeNumeric',
    );
  }
}

String _generateAllCountries(List<_CountrySources> countries) {
  final output = StringBuffer()
    ..writeln('// GENERATED CODE - DO NOT MODIFY BY HAND.')
    ..writeln('// Run: dart run tool/sync_country_data.dart')
    ..writeln('// Source strings intentionally use deterministic JSON quoting.')
    ..writeln(
        '// Dart 3.0 formatting omits commas in some generated data lists.')
    ..writeln(
      '// ignore_for_file: prefer_single_quotes, require_trailing_commas, use_raw_strings',
    )
    ..writeln()
    ..writeln("import 'package:countrify_light/src/models/country.dart';")
    ..writeln()
    ..writeln(
        '/// Compile-time country catalogue generated from pinned sources.')
    ..writeln('///')
    ..writeln(
        '/// dr5hn `$_dr5hnCommit` supplies population, calling codes, and IANA')
    ..writeln(
        '/// time zone identifiers. mledoze `$_mledozeCommit` supplies display')
    ..writeln(
        '/// metadata, ISO identifiers, currencies, languages, borders, area,')
    ..writeln('/// and status.')
    ..writeln(
        '/// Flag emoji are derived from ISO-2. `flagImagePath` is empty and')
    ..writeln(
        '/// `largestCity` is null for every entry. Missing source strings, lists,')
    ..writeln(
        '/// and population values remain empty or zero instead of being guessed.')
    ..writeln(
        '/// mledoze language map keys are ISO 639-3 codes. For compatibility')
    ..writeln(
        '/// they are stored in the legacy `Language.iso6392` field. Language')
    ..writeln(
        '/// names are English, so `nativeName` falls back to English. `iso6391`')
    ..writeln('/// is empty when no two-letter mapping exists.')
    ..writeln('class AllCountries {')
    ..writeln('  AllCountries._();')
    ..writeln()
    ..writeln('  static const List<Country> _allCountries = [');

  for (final sources in countries) {
    _writeCountry(output, sources);
  }

  output
    ..writeln('  ];')
    ..writeln()
    ..writeln('  static final Map<String, Country> _byAlpha2Code = {')
    ..writeln(
        '    for (final country in _allCountries) country.alpha2Code: country,')
    ..writeln('  };')
    ..writeln('  static final Map<String, Country> _byAlpha3Code = {')
    ..writeln(
        '    for (final country in _allCountries) country.alpha3Code: country,')
    ..writeln('  };')
    ..writeln('  static final Map<String, Country> _byNumericCode = {')
    ..writeln('    for (final country in _allCountries)')
    ..writeln(
        '      if (country.numericCode.isNotEmpty) country.numericCode: country,')
    ..writeln('  };')
    ..writeln()
    ..writeln('  /// All catalogue entries in alpha-2 code order.')
    ..writeln('  static List<Country> get all => _allCountries;')
    ..writeln()
    ..writeln('  /// Returns countries in [region].')
    ..writeln('  static List<Country> getByRegion(String region) {')
    ..writeln(
        '    return _allCountries.where((country) => country.region == region).toList();')
    ..writeln('  }')
    ..writeln()
    ..writeln('  /// Returns countries in [subregion].')
    ..writeln('  static List<Country> getBySubregion(String subregion) {')
    ..writeln('    return _allCountries')
    ..writeln('        .where((country) => country.subregion == subregion)')
    ..writeln('        .toList();')
    ..writeln('  }')
    ..writeln()
    ..writeln(
        '  /// Returns the country with [alpha2Code], ignoring case and whitespace.')
    ..writeln('  static Country? getByAlpha2Code(String alpha2Code) {')
    ..writeln('    return _byAlpha2Code[alpha2Code.trim().toUpperCase()];')
    ..writeln('  }')
    ..writeln()
    ..writeln(
        '  /// Returns the country with [alpha3Code], ignoring case and whitespace.')
    ..writeln('  static Country? getByAlpha3Code(String alpha3Code) {')
    ..writeln('    return _byAlpha3Code[alpha3Code.trim().toUpperCase()];')
    ..writeln('  }')
    ..writeln()
    ..writeln('  /// Returns the country with [numericCode].')
    ..writeln('  static Country? getByNumericCode(String numericCode) {')
    ..writeln('    return _byNumericCode[numericCode.trim()];')
    ..writeln('  }')
    ..writeln()
    ..writeln(
        '  /// Searches English country names and generated translations.')
    ..writeln('  static List<Country> searchByName(String query) {')
    ..writeln('    final lowercaseQuery = query.toLowerCase();')
    ..writeln('    return _allCountries.where((country) {')
    ..writeln(
        '      return country.name.toLowerCase().contains(lowercaseQuery) ||')
    ..writeln('          country.nameTranslations.values.any(')
    ..writeln(
        '            (translation) => translation.toLowerCase().contains(lowercaseQuery),')
    ..writeln('          );')
    ..writeln('    }).toList();')
    ..writeln('  }')
    ..writeln()
    ..writeln('  /// Independent countries only.')
    ..writeln('  static List<Country> get independent {')
    ..writeln(
        '    return _allCountries.where((country) => country.isIndependent).toList();')
    ..writeln('  }')
    ..writeln()
    ..writeln('  /// United Nations member countries only.')
    ..writeln('  static List<Country> get unMembers {')
    ..writeln(
        '    return _allCountries.where((country) => country.isUnMember).toList();')
    ..writeln('  }')
    ..writeln('}')
    ..writeln();
  return output.toString();
}

void _writeCountry(StringBuffer output, _CountrySources sources) {
  final dr5hn = sources.dr5hn;
  final mledoze = sources.mledoze;
  final name = _requiredMap(mledoze, 'name', sources.iso2)['common']! as String;
  final capital =
      _requiredList(mledoze, 'capital', sources.iso2).cast<String>().join(', ');
  final topLevelDomains = _requiredList(mledoze, 'tld', sources.iso2)
      .cast<String>()
      .toList(growable: false);
  final currencies = _requiredMap(mledoze, 'currencies', sources.iso2)
      .entries
      .toList()
    ..sort((left, right) => left.key.compareTo(right.key));
  final languages = _requiredMap(mledoze, 'languages', sources.iso2)
      .entries
      .toList()
    ..sort((left, right) => left.key.compareTo(right.key));
  final borders = _requiredList(mledoze, 'borders', sources.iso2)
      .cast<String>()
      .toList()
    ..sort();
  final timezoneObjects = _requiredList(dr5hn, 'timezones', sources.iso2);
  final timezones = <String>[];
  for (final value in timezoneObjects) {
    final timezone = value! as Map<String, Object?>;
    final zoneName = timezone['zoneName']! as String;
    if (!timezones.contains(zoneName)) timezones.add(zoneName);
  }
  final population = dr5hn['population'] as int? ?? 0;

  output
    ..writeln('    Country(')
    ..writeln('      name: ${_dartString(name)},')
    ..writeln('      nameTranslations: {')
    ..writeln("        'en': ${_dartString(name)},")
    ..writeln('      },')
    ..writeln('      alpha2Code: ${_dartString(mledoze['cca2']! as String)},')
    ..writeln('      alpha3Code: ${_dartString(mledoze['cca3']! as String)},')
    ..writeln('      numericCode: ${_dartString(mledoze['ccn3']! as String)},')
    ..writeln('      flagEmoji: ${_dartString(_flagEmoji(sources.iso2))},')
    ..writeln("      flagImagePath: '',")
    ..writeln('      capital: ${_dartString(capital)},')
    ..writeln('      region: ${_dartString(mledoze['region']! as String)},')
    ..writeln(
        '      subregion: ${_dartString(mledoze['subregion']! as String)},')
    ..writeln('      population: $population,')
    ..writeln('      area: ${_numberLiteral(mledoze['area']! as num)},')
    ..writeln(
      '      callingCodes: ${_nonEmptyStringListLiteral(dr5hn['phonecode']! as String)},',
    )
    ..writeln('      topLevelDomains: ${_stringListLiteral(topLevelDomains)},')
    ..writeln('      currencies: [');
  for (final entry in currencies) {
    final currency = entry.value! as Map<String, Object?>;
    output
      ..writeln('        Currency(')
      ..writeln('          code: ${_dartString(entry.key)},')
      ..writeln('          name: ${_dartString(currency['name']! as String)},')
      ..writeln(
          '          symbol: ${_dartString(currency['symbol']! as String)},')
      ..writeln('        ),');
  }
  output
    ..writeln('      ],')
    ..writeln('      languages: [');
  for (final entry in languages) {
    final englishName = entry.value! as String;
    output
      ..writeln('        Language(')
      ..writeln(
        '          iso6391: ${_dartString(_iso6391ByIso6393[entry.key] ?? '')},',
      )
      ..writeln('          iso6392: ${_dartString(entry.key)},')
      ..writeln('          name: ${_dartString(englishName)},')
      ..writeln('          nativeName: ${_dartString(englishName)},')
      ..writeln('        ),');
  }
  output
    ..writeln('      ],')
    ..writeln('      timezones: ${_stringListLiteral(timezones)},')
    ..writeln('      borders: ${_stringListLiteral(borders)},')
    ..writeln('      isIndependent: ${mledoze['independent'] == true},')
    ..writeln('      isUnMember: ${mledoze['unMember']! as bool},')
    ..writeln('    ),');
}

String _generateCountryCode(List<_CountrySources> countries) {
  final output = StringBuffer()
    ..writeln('// GENERATED CODE - DO NOT MODIFY BY HAND.')
    ..writeln('// Run: dart run tool/sync_country_data.dart')
    ..writeln(
        '// ISO enum names are self-describing; per-value docs add no context.')
    ..writeln('// ignore_for_file: public_member_api_docs')
    ..writeln()
    ..writeln("import 'package:countrify_light/src/data/all_countries.dart';")
    ..writeln("import 'package:countrify_light/src/models/country.dart';")
    ..writeln()
    ..writeln('// Kept as a typedef for backwards-compatible public API.')
    ..writeln('// ignore: camel_case_types')
    ..writeln('typedef CountryCode = CountryCodeEnum;')
    ..writeln()
    ..writeln(
        '/// The 249 ISO 3166-1 alpha-2 assignments plus user-assigned XK.')
    ..writeln('///')
    ..writeln(
        '/// A trailing underscore is added when a code is a Dart reserved word.')
    ..writeln('enum CountryCodeEnum {');
  for (final country in countries) {
    final lower = country.iso2.toLowerCase();
    final enumName = _dartReservedWords.contains(lower) ? '${lower}_' : lower;
    output.writeln('  $enumName,');
  }
  output
    ..writeln('}')
    ..writeln()
    ..writeln('extension CountryCodeExtension on CountryCodeEnum {')
    ..writeln('  static final Map<String, CountryCodeEnum> _byAlpha2Code = {')
    ..writeln(
        '    for (final code in CountryCodeEnum.values) code.alpha2Code: code,')
    ..writeln('  };')
    ..writeln()
    ..writeln('  /// Parses an ISO 3166-1 alpha-2 code.')
    ..writeln('  ///')
    ..writeln('  /// Returns null when no matching enum value exists.')
    ..writeln('  static CountryCodeEnum? fromAlpha2Code(String alpha2Code) {')
    ..writeln('    return _byAlpha2Code[alpha2Code.trim().toUpperCase()];')
    ..writeln('  }')
    ..writeln()
    ..writeln('  /// The ISO 3166-1 alpha-2 code.')
    ..writeln('  String get alpha2Code {')
    ..writeln('    final normalized =')
    ..writeln(
        "        name.endsWith('_') ? name.substring(0, name.length - 1) : name;")
    ..writeln('    return normalized.toUpperCase();')
    ..writeln('  }')
    ..writeln()
    ..writeln('  /// The matching country in the generated catalogue.')
    ..writeln(
        '  Country? get country => AllCountries.getByAlpha2Code(alpha2Code);')
    ..writeln('}')
    ..writeln();
  return output.toString();
}

String _dartString(String value) => jsonEncode(value).replaceAll(r'$', r'\$');

String _numberLiteral(num value) {
  if (value is int) return value.toString();
  return value.toString();
}

String _stringListLiteral(List<String> values) {
  if (values.isEmpty) return '[]';
  return '[${values.map(_dartString).join(', ')}]';
}

String _nonEmptyStringListLiteral(String value) {
  return value.isEmpty ? '[]' : '[${_dartString(value)}]';
}

String _flagEmoji(String iso2) {
  const regionalIndicatorOffset = 0x1F1A5;
  return String.fromCharCodes(
    iso2.codeUnits.map((codeUnit) => codeUnit + regionalIndicatorOffset),
  );
}

String _requiredString(
  Map<String, Object?> object,
  String key,
  String context, {
  bool allowEmpty = false,
}) {
  final value = object[key];
  if (value is! String || (!allowEmpty && value.isEmpty)) {
    throw FormatException('$context.$key must be a non-null string');
  }
  return value;
}

List<Object?> _requiredList(
  Map<String, Object?> object,
  String key,
  String context,
) {
  final value = object[key];
  if (value is! List<Object?>) {
    throw FormatException('$context.$key must be an array');
  }
  return value;
}

Map<String, Object?> _requiredMap(
  Map<String, Object?> object,
  String key,
  String context,
) {
  final value = object[key];
  if (value is! Map<String, Object?>) {
    throw FormatException('$context.$key must be an object');
  }
  return value;
}

Future<void> _replaceGeneratedFiles(
  Directory root,
  Map<String, String> generated,
) async {
  final transactionId =
      '$pid-${DateTime.now().microsecondsSinceEpoch.toRadixString(16)}';
  final targets = <_GeneratedFileTarget>[];

  try {
    for (final entry in generated.entries) {
      final destination = File('${root.path}/${entry.key}');
      final staging = File(
        '${destination.path}.countrify-staging-$transactionId',
      );
      final backup = File(
        '${destination.path}.countrify-backup-$transactionId',
      );
      if (staging.existsSync() || backup.existsSync()) {
        throw FileSystemException(
          'Refusing to overwrite an existing generator staging file',
          staging.path,
        );
      }
      final target = _GeneratedFileTarget(
        logicalPath: entry.key,
        destination: destination,
        staging: staging,
        backup: backup,
      );
      targets.add(target);

      await staging.writeAsString(entry.value, flush: true);
      if (await staging.readAsString() != entry.value) {
        throw FileSystemException(
          'Generated staging file failed content verification',
          staging.path,
        );
      }
    }

    final backedUp = <_GeneratedFileTarget>[];
    final installed = <_GeneratedFileTarget>[];
    try {
      for (final target in targets) {
        if (target.destination.existsSync()) {
          await target.destination.rename(target.backup.path);
          backedUp.add(target);
        }
      }
      for (final target in targets) {
        await target.staging.rename(target.destination.path);
        installed.add(target);
      }
    } on FileSystemException catch (error, stackTrace) {
      final rollbackErrors = <String>[];
      for (final target in installed.reversed) {
        try {
          if (target.destination.existsSync()) {
            await target.destination.delete();
          }
        } on FileSystemException catch (rollbackError) {
          rollbackErrors.add(
            '${target.logicalPath}: could not remove partial output '
            '($rollbackError)',
          );
        }
      }
      for (final target in backedUp.reversed) {
        try {
          if (!target.backup.existsSync()) continue;
          if (target.destination.existsSync()) {
            rollbackErrors.add(
              '${target.logicalPath}: backup remains at ${target.backup.path} '
              'because the destination could not be cleared',
            );
          } else {
            await target.backup.rename(target.destination.path);
          }
        } on FileSystemException catch (rollbackError) {
          rollbackErrors.add(
            '${target.logicalPath}: could not restore backup '
            '(${target.backup.path}; $rollbackError)',
          );
        }
      }
      if (rollbackErrors.isNotEmpty) {
        throw FileSystemException(
          'Generated-file replacement failed and rollback was incomplete. '
          '${rollbackErrors.join('; ')}. Original error: $error',
        );
      }
      Error.throwWithStackTrace(error, stackTrace);
    }

    for (final target in targets) {
      if (!target.backup.existsSync()) continue;
      try {
        await target.backup.delete();
      } on FileSystemException catch (error) {
        stderr.writeln(
          'warning: generated files were replaced, but backup cleanup failed '
          'for ${target.backup.path}: $error',
        );
      }
    }
  } finally {
    for (final target in targets) {
      if (!target.staging.existsSync()) continue;
      try {
        await target.staging.delete();
      } on FileSystemException catch (error) {
        stderr.writeln(
          'warning: could not remove staging file ${target.staging.path}: '
          '$error',
        );
      }
    }
  }
}

Future<Map<String, String>> _formatGenerated(
  Map<String, String> generated,
) async {
  final temporaryDirectory =
      await Directory.systemTemp.createTemp('countrify-country-data-');
  try {
    final files = <String, File>{};
    for (final entry in generated.entries) {
      final fileName = entry.key.replaceAll('/', '__');
      final file = File('${temporaryDirectory.path}/$fileName');
      await file.writeAsString(entry.value);
      files[entry.key] = file;
    }
    final result = await Process.run(
      Platform.resolvedExecutable,
      [
        '--suppress-analytics',
        'format',
        '--language-version',
        '3.0',
        ...files.values.map((file) => file.path),
      ],
    );
    if (result.exitCode != 0) {
      throw ProcessException(
        Platform.resolvedExecutable,
        ['--suppress-analytics', 'format'],
        '${result.stdout}\n${result.stderr}',
        result.exitCode,
      );
    }
    return {
      for (final entry in files.entries)
        entry.key: await entry.value.readAsString(),
    };
  } finally {
    await temporaryDirectory.delete(recursive: true);
  }
}

Directory _findProjectRoot() {
  var directory = Directory.current;
  while (!File('${directory.path}/pubspec.yaml').existsSync()) {
    final parent = directory.parent;
    if (parent.path == directory.path) {
      throw StateError('pubspec.yaml not found; run from the package root');
    }
    directory = parent;
  }
  return directory;
}

Future<String> _download(String url) async {
  print('downloading $url');
  final client = HttpClient();
  try {
    final request = await client.getUrl(Uri.parse(url));
    final response = await request.close();
    if (response.statusCode != HttpStatus.ok) {
      throw HttpException('GET $url returned ${response.statusCode}');
    }
    return response.transform(utf8.decoder).join();
  } finally {
    client.close();
  }
}

class _CountrySources {
  const _CountrySources({
    required this.iso2,
    required this.dr5hn,
    required this.mledoze,
  });

  final String iso2;
  final Map<String, Object?> dr5hn;
  final Map<String, Object?> mledoze;
}

class _GeneratedFileTarget {
  const _GeneratedFileTarget({
    required this.logicalPath,
    required this.destination,
    required this.staging,
    required this.backup,
  });

  final String logicalPath;
  final File destination;
  final File staging;
  final File backup;
}
