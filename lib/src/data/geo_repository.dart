import 'dart:convert';

import 'package:countrify_light/src/models/city.dart';
import 'package:countrify_light/src/models/state.dart';
import 'package:countrify_light/src/utils/search_normalizer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// {@template geo_repository}
/// Lazy loader for the bundled state / city dataset.
///
/// Country data ships eagerly via `all_countries.dart`, but states (~5,300)
/// and cities (~154,000) are split into per-country / per-state JSON files
/// under `assets/geo/` and loaded on demand. Results are cached in memory for
/// the process lifetime so repeated lookups do not re-decode JSON.
///
/// ```dart
/// final repo = GeoRepository.instance;
/// final states = await repo.statesOf('PK');
/// final cities = await repo.citiesOf(states.first.id);
/// ```
/// {@endtemplate}
class GeoRepository {
  /// {@macro geo_repository}
  GeoRepository({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  /// Shared singleton backed by [rootBundle]. Use this in app code; construct
  /// a fresh instance only when injecting a custom [AssetBundle] for tests.
  static final GeoRepository instance = GeoRepository();

  final AssetBundle _bundle;

  final Map<String, List<CountryState>> _statesCache = {};
  final Map<int, List<City>> _citiesCache = {};
  final Map<String, Future<List<CountryState>>> _statesInflight = {};
  final Map<int, Future<List<City>>> _citiesInflight = {};

  static const _assetRoot = 'packages/countrify_light/assets/geo';
  static const _loadBatchSize = 10;

  /// Returns all states / provinces for the country identified by [iso2].
  ///
  /// [iso2] is case-insensitive. Returns an empty list if no states are
  /// available for the country (some microstates have no subdivisions).
  Future<List<CountryState>> statesOf(String iso2) {
    final key = iso2.toUpperCase();
    final cached = _statesCache[key];
    if (cached != null) return Future.value(cached);
    return _statesInflight.putIfAbsent(key, () async {
      try {
        final raw = await _bundle.loadString('$_assetRoot/states/$key.json');
        final list = (jsonDecode(raw) as List)
            .cast<Map<String, dynamic>>()
            .map((m) => CountryState.fromJson(m, countryIso2: key))
            .toList(growable: false);
        _statesCache[key] = list;
        return list;
        // AssetBundle reports a missing asset as a FlutterError. Malformed JSON
        // and schema errors intentionally propagate instead of masquerading as
        // a country without subdivisions.
        // ignore: avoid_catching_errors
      } on FlutterError {
        _statesCache[key] = const [];
        return const [];
      } finally {
        // Removing the already-running future does not create asynchronous work.
        // ignore: unawaited_futures
        _statesInflight.remove(key);
      }
    });
  }

  /// Returns all cities belonging to the state identified by [stateId].
  ///
  /// Returns an empty list if the state has no city data.
  Future<List<City>> citiesOf(int stateId) {
    final cached = _citiesCache[stateId];
    if (cached != null) return Future.value(cached);
    return _citiesInflight.putIfAbsent(stateId, () async {
      try {
        final raw =
            await _bundle.loadString('$_assetRoot/cities/$stateId.json');
        final list = (jsonDecode(raw) as List)
            .cast<Map<String, dynamic>>()
            .map((m) => City.fromJson(m, stateId: stateId))
            .toList(growable: false);
        _citiesCache[stateId] = list;
        return list;
        // See statesOf: only a genuinely missing asset is an empty dataset.
        // ignore: avoid_catching_errors
      } on FlutterError {
        _citiesCache[stateId] = const [];
        return const [];
      } finally {
        // Removing the already-running future does not create asynchronous work.
        // ignore: unawaited_futures
        _citiesInflight.remove(stateId);
      }
    });
  }

  /// Searches all cities across all states for [countryIso2].
  ///
  /// Loads state files lazily and caches them. Returns matching cities
  /// (capped at [limit]) sorted by relevance — exact prefix matches first,
  /// then contains matches, each group alphabetical.
  ///
  /// ```dart
  /// final results = await GeoRepository.instance.searchCities(
  ///   countryIso2: 'US',
  ///   query: 'san',
  /// );
  /// for (final (:city, :state) in results) {
  ///   print('${city.name}, ${state.name}');
  /// }
  /// ```
  Future<List<({City city, CountryState state})>> searchCities({
    required String countryIso2,
    required String query,
    int limit = 20,
  }) async {
    if (limit <= 0) return const [];

    final q = SearchNormalizer.foldAccents(query);
    if (q.isEmpty) return const [];

    final states = await statesOf(countryIso2);
    if (states.isEmpty) return const [];

    final results = <({City city, CountryState state})>[];

    // Load cities in batches of 10 states to avoid loading all files at once
    // on the first search. Cached states resolve instantly on subsequent calls.
    for (var i = 0; i < states.length; i += _loadBatchSize) {
      final batch = states.sublist(
        i,
        (i + _loadBatchSize).clamp(0, states.length),
      );
      final cityLists = await Future.wait(
        batch.map((s) => citiesOf(s.id)),
      );
      for (var j = 0; j < batch.length; j++) {
        final state = batch[j];
        for (final city in cityLists[j]) {
          if (SearchNormalizer.foldAccents(city.name).contains(q)) {
            results.add((city: city, state: state));
          }
        }
      }
    }

    // Sort: prefix matches first, then contains, each group alphabetical.
    results.sort((a, b) {
      final aNorm = SearchNormalizer.foldAccents(a.city.name);
      final bNorm = SearchNormalizer.foldAccents(b.city.name);
      final aPrefix = aNorm.startsWith(q);
      final bPrefix = bNorm.startsWith(q);
      if (aPrefix != bPrefix) return aPrefix ? -1 : 1;
      return aNorm.compareTo(bNorm);
    });

    return results.length > limit ? results.sublist(0, limit) : results;
  }

  /// Pre-loads all city files for [countryIso2] in the background.
  ///
  /// Call this on screen init so that subsequent [searchCities] calls are
  /// instant. Safe to call multiple times — already-cached states are skipped.
  Future<void> preloadCities(String countryIso2) async {
    final states = await statesOf(countryIso2);
    // Bound concurrency so countries with hundreds of subdivisions do not
    // issue hundreds of asset reads at once. citiesOf still deduplicates any
    // overlapping search or preload request.
    for (var i = 0; i < states.length; i += _loadBatchSize) {
      final batch = states.sublist(
        i,
        (i + _loadBatchSize).clamp(0, states.length),
      );
      await Future.wait(batch.map((state) => citiesOf(state.id)));
    }
  }

  /// Drops every cached states / cities entry. Useful in long-running tests
  /// or when memory pressure makes retaining the decoded dataset undesirable.
  void clearCache() {
    _statesCache.clear();
    _citiesCache.clear();
  }
}
