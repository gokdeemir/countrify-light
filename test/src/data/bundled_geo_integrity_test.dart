import 'dart:convert';
import 'dart:io';

import 'package:countrify_light/src/data/all_countries.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('bundled geo snapshot is complete and internally consistent', () {
    final geoDirectory = Directory('assets/geo');
    final statesDirectory = Directory('${geoDirectory.path}/states');
    final citiesDirectory = Directory('${geoDirectory.path}/cities');
    final manifest = jsonDecode(
      File('${geoDirectory.path}/source.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final counts = manifest['counts'] as Map<String, dynamic>;
    final source = manifest['source'] as Map<String, dynamic>;

    expect(source['revision'], '624a208c3928937d1262ab1646d0b8fc9cacceee');
    expect(source['license'], 'ODbL-1.0');

    final stateFiles = statesDirectory
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.json'))
        .toList(growable: false);
    final cityFiles = citiesDirectory
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.json'))
        .toList(growable: false);

    expect(stateFiles, hasLength(counts['countries'] as int));
    expect(
      stateFiles.map(_fileStem).toSet(),
      AllCountries.all.map((country) => country.alpha2Code).toSet(),
      reason: 'country catalogue and geo assets must cover the same codes',
    );

    final stateIds = <int>{};
    var stateCount = 0;
    for (final file in stateFiles) {
      final states = jsonDecode(file.readAsStringSync()) as List<dynamic>;
      for (final value in states) {
        final state = value as Map<String, dynamic>;
        final id = state['id'];
        expect(id, isA<int>(), reason: file.path);
        expect(stateIds.add(id as int), isTrue, reason: 'duplicate state $id');
        expect(state['name'], isA<String>(), reason: file.path);
        expect((state['name'] as String).trim(), isNotEmpty, reason: file.path);
        expect(state.keys, unorderedEquals(['id', 'name', 'iso2', 'type']));
        stateCount++;
      }
    }

    expect(stateCount, counts['states']);
    expect(cityFiles, hasLength(stateCount));
    expect(
      cityFiles.map(_numericFileStem).toSet(),
      stateIds,
      reason: 'every state must have exactly one city asset',
    );

    final cityIds = <int>{};
    var cityCount = 0;
    for (final file in cityFiles) {
      final cities = jsonDecode(file.readAsStringSync()) as List<dynamic>;
      for (final value in cities) {
        final city = value as Map<String, dynamic>;
        final id = city['id'];
        expect(id, isA<int>(), reason: file.path);
        expect(cityIds.add(id as int), isTrue, reason: 'duplicate city $id');
        expect(city['name'], isA<String>(), reason: file.path);
        expect((city['name'] as String).trim(), isNotEmpty, reason: file.path);
        expect(city.keys, unorderedEquals(['id', 'name']));
        cityCount++;
      }
    }

    expect(cityCount, counts['cities']);
  });
}

int _numericFileStem(File file) {
  return int.parse(_fileStem(file));
}

String _fileStem(File file) {
  final name = file.uri.pathSegments.last;
  return name.substring(0, name.length - '.json'.length);
}
