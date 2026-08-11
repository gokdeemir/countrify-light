// The sync command intentionally reports progress to developers.
// ignore_for_file: avoid_print

/// Regenerates the lightweight geo assets from a pinned upstream snapshot.
///
/// The complete source is validated and projected into the fields used by the
/// package before any existing asset is replaced. Output is first written to a
/// sibling staging directory so an invalid download cannot destroy the last
/// known-good dataset.
///
/// Usage:
///   dart run tool/sync_geo_data.dart
///   dart run tool/sync_geo_data.dart --check
///   dart run tool/sync_geo_data.dart --ref `commit-or-tag`
///   dart run tool/sync_geo_data.dart --ref `revision` --input `source.json`
library;

import 'dart:convert';
import 'dart:io';

const _repository = 'https://github.com/dr5hn/countries-states-cities-database';
const _defaultRevision = '624a208c3928937d1262ab1646d0b8fc9cacceee';
const _defaultCountryCount = 250;
const _defaultStateCount = 5308;
const _defaultCityCount = 152970;

Future<void> main(List<String> args) async {
  final options = _Options.parse(args);
  final projectRoot = _findProjectRoot();
  final output = Directory('${projectRoot.path}/assets/geo');
  final rawUrl = 'https://raw.githubusercontent.com/dr5hn/'
      'countries-states-cities-database/${options.revision}/json/'
      'countries+states+cities.json';

  final sourceJson = options.inputPath == null
      ? await _download(rawUrl)
      : await File(options.inputPath!).readAsString();
  final dataset = _parseAndValidate(
    sourceJson,
    enforcePinnedCounts: options.revision == _defaultRevision,
  );

  print(
    'validated ${dataset.countries.length} countries, '
    '${dataset.stateCount} states, and ${dataset.cityCount} cities',
  );

  final staging = Directory(
    '${output.parent.path}/.geo-sync-$pid-${DateTime.now().microsecondsSinceEpoch}',
  );
  try {
    await _writeDataset(
      staging,
      dataset,
      revision: options.revision,
      rawUrl: rawUrl,
    );

    if (options.checkOnly) {
      final difference = await _firstDifference(output, staging);
      if (difference != null) {
        throw StateError(
          'Bundled geo assets are stale or modified: $difference. '
          'Run dart run tool/sync_geo_data.dart to regenerate them.',
        );
      }
      print('bundled geo assets match ${options.revision}');
      return;
    }

    await _replaceDirectory(output, staging);
    print('updated ${output.path} from ${options.revision}');
  } finally {
    if (staging.existsSync()) {
      await staging.delete(recursive: true);
    }
  }
}

class _Options {
  const _Options({
    required this.revision,
    required this.inputPath,
    required this.checkOnly,
  });

  factory _Options.parse(List<String> args) {
    var revision = _defaultRevision;
    String? inputPath;
    var checkOnly = false;

    for (var index = 0; index < args.length; index++) {
      switch (args[index]) {
        case '--ref':
          revision = _valueAfter(args, index, '--ref');
          index++;
        case '--input':
          inputPath = _valueAfter(args, index, '--input');
          index++;
        case '--check':
          checkOnly = true;
        default:
          throw FormatException('Unknown argument: ${args[index]}');
      }
    }

    if (revision.trim().isEmpty) {
      throw const FormatException('--ref cannot be empty');
    }
    if (inputPath != null && !File(inputPath).existsSync()) {
      throw ArgumentError.value(inputPath, '--input', 'file does not exist');
    }

    return _Options(
      revision: revision,
      inputPath: inputPath,
      checkOnly: checkOnly,
    );
  }

  final String revision;
  final String? inputPath;
  final bool checkOnly;
}

String _valueAfter(List<String> args, int index, String option) {
  if (index + 1 >= args.length || args[index + 1].startsWith('--')) {
    throw FormatException('$option requires a value');
  }
  return args[index + 1];
}

class _Dataset {
  const _Dataset({
    required this.countries,
    required this.stateCount,
    required this.cityCount,
  });

  final List<_CountryProjection> countries;
  final int stateCount;
  final int cityCount;
}

class _CountryProjection {
  const _CountryProjection({
    required this.iso2,
    required this.states,
  });

  final String iso2;
  final List<_StateProjection> states;
}

class _StateProjection {
  const _StateProjection({
    required this.data,
    required this.id,
    required this.cities,
  });

  final Map<String, Object?> data;
  final int id;
  final List<Map<String, Object?>> cities;
}

_Dataset _parseAndValidate(
  String sourceJson, {
  required bool enforcePinnedCounts,
}) {
  final decoded = jsonDecode(sourceJson);
  if (decoded is! List<Object?>) {
    throw const FormatException('Upstream root must be a JSON array');
  }

  final countries = <_CountryProjection>[];
  final countryCodes = <String>{};
  final stateIds = <int>{};
  final cityIds = <int>{};
  var cityCount = 0;

  for (var countryIndex = 0; countryIndex < decoded.length; countryIndex++) {
    final country = _mapAt(decoded[countryIndex], 'country[$countryIndex]');
    final iso2 = _requiredString(country, 'iso2', 'country[$countryIndex]')
        .toUpperCase();
    if (!RegExp(r'^[A-Z]{2}$').hasMatch(iso2)) {
      throw FormatException('country[$countryIndex].iso2 is invalid: $iso2');
    }
    if (!countryCodes.add(iso2)) {
      throw FormatException('Duplicate country ISO2 code: $iso2');
    }

    final rawStates = _listAt(country, 'states', 'country $iso2');
    final states = <_StateProjection>[];
    for (var stateIndex = 0; stateIndex < rawStates.length; stateIndex++) {
      final context = 'country $iso2 state[$stateIndex]';
      final state = _mapAt(rawStates[stateIndex], context);
      final id = _requiredPositiveInt(state, 'id', context);
      if (!stateIds.add(id)) {
        throw FormatException('Duplicate state id: $id');
      }
      final name = _requiredString(state, 'name', context);
      final stateIso2 = _optionalString(state, 'iso2', context);
      final type = _optionalString(state, 'type', context);
      final rawCities = _listAt(state, 'cities', '$context ($id)');
      final cities = <Map<String, Object?>>[];

      for (var cityIndex = 0; cityIndex < rawCities.length; cityIndex++) {
        final cityContext = '$context city[$cityIndex]';
        final city = _mapAt(rawCities[cityIndex], cityContext);
        final cityId = _requiredPositiveInt(city, 'id', cityContext);
        if (!cityIds.add(cityId)) {
          throw FormatException('Duplicate city id: $cityId');
        }
        cities.add({
          'id': cityId,
          'name': _requiredString(city, 'name', cityContext),
        });
        cityCount++;
      }

      states.add(
        _StateProjection(
          id: id,
          data: {
            'id': id,
            'name': name,
            'iso2': stateIso2,
            'type': type,
          },
          cities: cities,
        ),
      );
    }
    countries.add(_CountryProjection(iso2: iso2, states: states));
  }

  countries.sort((a, b) => a.iso2.compareTo(b.iso2));
  if (countries.length != _defaultCountryCount) {
    throw FormatException(
      'Expected $_defaultCountryCount country records, '
      'found ${countries.length}',
    );
  }
  if (enforcePinnedCounts &&
      (stateIds.length != _defaultStateCount ||
          cityCount != _defaultCityCount)) {
    throw FormatException(
      'Pinned source count mismatch: expected $_defaultStateCount states and '
      '$_defaultCityCount cities, found ${stateIds.length} states and '
      '$cityCount cities',
    );
  }

  return _Dataset(
    countries: countries,
    stateCount: stateIds.length,
    cityCount: cityCount,
  );
}

Map<String, Object?> _mapAt(Object? value, String context) {
  if (value is! Map<String, Object?>) {
    throw FormatException('$context must be a JSON object');
  }
  return value;
}

List<Object?> _listAt(
  Map<String, Object?> object,
  String key,
  String context,
) {
  final value = object[key];
  if (value is! List<Object?>) {
    throw FormatException('$context.$key must be a JSON array');
  }
  return value;
}

String _requiredString(
  Map<String, Object?> object,
  String key,
  String context,
) {
  final value = object[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('$context.$key must be a non-empty string');
  }
  return value;
}

String? _optionalString(
  Map<String, Object?> object,
  String key,
  String context,
) {
  final value = object[key];
  if (value == null) return null;
  if (value is! String) {
    throw FormatException('$context.$key must be a string or null');
  }
  return value.isEmpty ? null : value;
}

int _requiredPositiveInt(
  Map<String, Object?> object,
  String key,
  String context,
) {
  final value = object[key];
  if (value is! int || value <= 0) {
    throw FormatException('$context.$key must be a positive integer');
  }
  return value;
}

Future<void> _writeDataset(
  Directory output,
  _Dataset dataset, {
  required String revision,
  required String rawUrl,
}) async {
  final statesDirectory = Directory('${output.path}/states');
  final citiesDirectory = Directory('${output.path}/cities');
  await statesDirectory.create(recursive: true);
  await citiesDirectory.create(recursive: true);

  for (final country in dataset.countries) {
    await File('${statesDirectory.path}/${country.iso2}.json').writeAsString(
      '${jsonEncode(country.states.map((state) => state.data).toList())}\n',
    );
    for (final state in country.states) {
      await File('${citiesDirectory.path}/${state.id}.json').writeAsString(
        '${jsonEncode(state.cities)}\n',
      );
    }
  }

  const encoder = JsonEncoder.withIndent('  ');
  final manifest = <String, Object?>{
    'schemaVersion': 1,
    'source': {
      'name': 'dr5hn/countries-states-cities-database',
      'repository': _repository,
      'revision': revision,
      'rawUrl': rawUrl,
      'license': 'ODbL-1.0',
    },
    'counts': {
      'countries': dataset.countries.length,
      'states': dataset.stateCount,
      'cities': dataset.cityCount,
    },
    'projection': {
      'state': ['id', 'name', 'iso2', 'type'],
      'city': ['id', 'name'],
    },
  };
  await File('${output.path}/source.json')
      .writeAsString('${encoder.convert(manifest)}\n');
}

Future<String?> _firstDifference(
  Directory expected,
  Directory actual,
) async {
  if (!expected.existsSync()) return 'assets/geo does not exist';
  final expectedFiles = await _relativeFiles(expected);
  final actualFiles = await _relativeFiles(actual);
  if (expectedFiles.length != actualFiles.length) {
    return 'file count differs (${expectedFiles.length} != '
        '${actualFiles.length})';
  }
  for (var index = 0; index < expectedFiles.length; index++) {
    if (expectedFiles[index] != actualFiles[index]) {
      return 'file set differs at ${expectedFiles[index]} / '
          '${actualFiles[index]}';
    }
    final expectedBytes =
        await File('${expected.path}/${expectedFiles[index]}').readAsBytes();
    final actualBytes =
        await File('${actual.path}/${actualFiles[index]}').readAsBytes();
    if (!_bytesEqual(expectedBytes, actualBytes)) {
      return '${expectedFiles[index]} differs';
    }
  }
  return null;
}

Future<List<String>> _relativeFiles(Directory root) async {
  final files = <String>[];
  await for (final entity in root.list(recursive: true, followLinks: false)) {
    if (entity is File) {
      files.add(entity.path.substring(root.path.length + 1));
    }
  }
  files.sort();
  return files;
}

bool _bytesEqual(List<int> first, List<int> second) {
  if (first.length != second.length) return false;
  for (var index = 0; index < first.length; index++) {
    if (first[index] != second[index]) return false;
  }
  return true;
}

Future<void> _replaceDirectory(Directory output, Directory staging) async {
  if (!output.existsSync()) {
    await staging.rename(output.path);
    return;
  }

  final backup = Directory(
    '${output.parent.path}/.geo-backup-$pid-${DateTime.now().microsecondsSinceEpoch}',
  );
  await output.rename(backup.path);
  try {
    await staging.rename(output.path);
  } on Object {
    await backup.rename(output.path);
    rethrow;
  }

  try {
    await backup.delete(recursive: true);
  } on FileSystemException catch (error) {
    print('warning: generated assets are active, but backup cleanup failed: '
        '${error.path ?? backup.path}');
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
