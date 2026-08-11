import 'package:countrify_light/src/models/phone_metadata.dart';
import 'package:flutter/foundation.dart';

/// {@template country}
/// A model representing a country with all its relevant information
/// {@endtemplate}
@immutable
class Country {
  /// {@macro country}
  const Country({
    required this.name,
    required this.nameTranslations,
    required this.alpha2Code,
    required this.alpha3Code,
    required this.numericCode,
    required this.flagEmoji,
    required this.flagImagePath,
    required this.capital,
    required this.region,
    required this.subregion,
    required this.population,
    required this.area,
    required this.callingCodes,
    required this.topLevelDomains,
    required this.currencies,
    required this.languages,
    required this.timezones,
    required this.borders,
    required this.isIndependent,
    required this.isUnMember,
    this.largestCity,
    this.phoneMetadata,
  });

  /// The common name of the country
  final String name;

  /// Per-country translation overrides.
  ///
  /// Generated records contain the canonical English name only. Bundled
  /// localized display names are provided by `CountryNameL10n`.
  final Map<String, String> nameTranslations;

  /// ISO 3166-1 alpha-2 country code (2 letters)
  final String alpha2Code;

  /// ISO 3166-1 alpha-3 country code (3 letters)
  final String alpha3Code;

  /// ISO 3166-1 numeric country code (3 digits).
  ///
  /// Empty for the user-assigned `XK` entry, which has no official numeric
  /// ISO 3166-1 code.
  final String numericCode;

  /// Unicode flag emoji for the country
  final String flagEmoji;

  /// Legacy flag asset path.
  ///
  /// Empty in Countrify Light, which renders [flagEmoji] instead.
  final String flagImagePath;

  /// Capital city, or an empty string when the source has no value.
  final String capital;

  /// Largest city when supplied by a custom source.
  ///
  /// The bundled catalogue leaves this null rather than guessing.
  final String? largestCity;

  /// Geographic region of the country
  final String region;

  /// Geographic subregion, or an empty string when unavailable.
  final String subregion;

  /// Population, or zero when the pinned source has no value.
  final int population;

  /// Area in square kilometers, or zero when unavailable.
  final double area;

  /// International calling codes for the country
  final List<String> callingCodes;

  /// Top-level domains for the country
  final List<String> topLevelDomains;

  /// Currencies used in the country
  final List<Currency> currencies;

  /// Languages spoken in the country
  final List<Language> languages;

  /// IANA time zone identifiers used in the country.
  final List<String> timezones;

  /// Border countries (alpha-3 codes)
  final List<String> borders;

  /// Whether the source explicitly identifies the country as independent.
  /// Unknown source values are represented as `false` for API compatibility.
  final bool isIndependent;

  /// Whether the country is a UN member
  final bool isUnMember;

  /// Optional phone-number metadata for lightweight validation.
  ///
  /// The bundled catalogue does not currently provide this metadata, so
  /// generated countries leave it null. Supply an explicit [PhoneMetadata]
  /// only when using a separately maintained source.
  final PhoneMetadata? phoneMetadata;

  /// Creates a copy of this country with the given fields replaced
  Country copyWith({
    String? name,
    Map<String, String>? nameTranslations,
    String? alpha2Code,
    String? alpha3Code,
    String? numericCode,
    String? flagEmoji,
    String? flagImagePath,
    String? capital,
    String? region,
    String? subregion,
    int? population,
    double? area,
    List<String>? callingCodes,
    List<String>? topLevelDomains,
    List<Currency>? currencies,
    List<Language>? languages,
    List<String>? timezones,
    List<String>? borders,
    bool? isIndependent,
    bool? isUnMember,
    String? largestCity,
    PhoneMetadata? phoneMetadata,
  }) {
    return Country(
      name: name ?? this.name,
      nameTranslations: nameTranslations ?? this.nameTranslations,
      alpha2Code: alpha2Code ?? this.alpha2Code,
      alpha3Code: alpha3Code ?? this.alpha3Code,
      numericCode: numericCode ?? this.numericCode,
      flagEmoji: flagEmoji ?? this.flagEmoji,
      flagImagePath: flagImagePath ?? this.flagImagePath,
      capital: capital ?? this.capital,
      region: region ?? this.region,
      subregion: subregion ?? this.subregion,
      population: population ?? this.population,
      area: area ?? this.area,
      callingCodes: callingCodes ?? this.callingCodes,
      topLevelDomains: topLevelDomains ?? this.topLevelDomains,
      currencies: currencies ?? this.currencies,
      languages: languages ?? this.languages,
      timezones: timezones ?? this.timezones,
      borders: borders ?? this.borders,
      isIndependent: isIndependent ?? this.isIndependent,
      isUnMember: isUnMember ?? this.isUnMember,
      largestCity: largestCity ?? this.largestCity,
      phoneMetadata: phoneMetadata ?? this.phoneMetadata,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Country && other.alpha2Code == alpha2Code;
  }

  @override
  int get hashCode => alpha2Code.hashCode;

  @override
  String toString() {
    return 'Country(name: $name, alpha2Code: $alpha2Code, alpha3Code: $alpha3Code)';
  }
}

/// {@template currency}
/// A model representing a currency
/// {@endtemplate}
@immutable
class Currency {
  /// {@macro currency}
  const Currency({
    required this.code,
    required this.name,
    required this.symbol,
  });

  /// The currency code (e.g., USD, EUR)
  final String code;

  /// The full name of the currency
  final String name;

  /// The currency symbol (e.g., $, €)
  final String symbol;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Currency && other.code == code;
  }

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() {
    return 'Currency(code: $code, name: $name, symbol: $symbol)';
  }
}

/// {@template language}
/// A model representing a language
/// {@endtemplate}
@immutable
class Language {
  /// {@macro language}
  const Language({
    required this.iso6391,
    required this.iso6392,
    required this.name,
    required this.nativeName,
  });

  /// ISO 639-1 language code (2 letters), or an empty string when the
  /// language has no ISO 639-1 mapping.
  final String iso6391;

  /// Legacy three-letter language-code field.
  ///
  /// The generated catalogue stores ISO 639-3 identifiers here. Many values
  /// overlap with ISO 639-2 terminology codes, but consumers must not assume
  /// every value is an ISO 639-2 code.
  final String iso6392;

  /// The name of the language in English
  final String name;

  /// The native language name when available, otherwise the English name.
  final String nativeName;

  String get _identityCode => iso6392.isNotEmpty ? iso6392 : iso6391;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Language && other._identityCode == _identityCode;
  }

  @override
  int get hashCode => _identityCode.hashCode;

  @override
  String toString() {
    return 'Language(iso6391: $iso6391, iso6392: $iso6392, name: $name, '
        'nativeName: $nativeName)';
  }
}
