import 'dart:async';

import 'package:countrify_light/src/data/geo_repository.dart';
import 'package:countrify_light/src/models/city.dart';
import 'package:countrify_light/src/widgets/city_dropdown_field/city_dropdown_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/in_memory_bundle.dart';

void main() {
  group('CityDropdownField', () {
    Widget wrap({
      required int? stateId,
      required GeoRepository repo,
      ValueChanged<City?>? onChanged,
      bool searchable = false,
      int? initialCityId,
      FocusNode? focusNode,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: CityDropdownField(
            stateId: stateId,
            repository: repo,
            onChanged: onChanged,
            searchable: searchable,
            initialCityId: initialCityId,
            focusNode: focusNode,
          ),
        ),
      );
    }

    testWidgets('shows placeholder when no state is set', (tester) async {
      await tester
          .pumpWidget(wrap(stateId: null, repo: buildFixtureRepository()));
      await tester.pumpAndSettle();
      expect(find.text('Select city'), findsOneWidget);
    });

    testWidgets('opens picker and emits city selection', (tester) async {
      City? picked;
      await tester.pumpWidget(
        wrap(
          stateId: 3172,
          repo: buildFixtureRepository(),
          onChanged: (c) => picked = c,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(CityDropdownField));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Karachi'));
      await tester.pumpAndSettle();

      expect(picked?.name, 'Karachi');
      expect(find.text('Karachi'), findsOneWidget);
    });

    testWidgets('clears city when stateId changes', (tester) async {
      final repo = buildFixtureRepository();
      final notifier = ValueNotifier<int?>(3172);
      City? last;
      addTearDown(notifier.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValueListenableBuilder<int?>(
              valueListenable: notifier,
              builder: (_, value, __) => CityDropdownField(
                stateId: value,
                repository: repo,
                searchable: false,
                onChanged: (c) => last = c,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(CityDropdownField));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Karachi'));
      await tester.pumpAndSettle();
      expect(last?.name, 'Karachi');

      last = const City(id: -1, name: 'sentinel', stateId: 0);
      notifier.value = 3173;
      await tester.pumpAndSettle();
      expect(last, isNull);
    });

    testWidgets('ignores a late hydration result from the old repository',
        (tester) async {
      final oldRepo = _ControlledCityRepository();
      final newRepo = _ControlledCityRepository();
      final repository = ValueNotifier<GeoRepository>(oldRepo);
      addTearDown(repository.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValueListenableBuilder<GeoRepository>(
              valueListenable: repository,
              builder: (_, value, __) => CityDropdownField(
                stateId: 7,
                repository: value,
                searchable: false,
                initialCityId: 2,
              ),
            ),
          ),
        ),
      );

      repository.value = newRepo;
      await tester.pump();
      newRepo.complete(7, const [
        City(id: 2, name: 'Current City', stateId: 7),
      ]);
      await tester.pump();
      expect(find.text('Current City'), findsOneWidget);

      oldRepo.complete(7, const [
        City(id: 1, name: 'Stale City', stateId: 7),
      ]);
      await tester.pump();

      expect(find.text('Current City'), findsOneWidget);
      expect(find.text('Select city'), findsNothing);
    });

    testWidgets('moves its focus listener when focusNode changes',
        (tester) async {
      final first = _InspectableFocusNode();
      final second = _InspectableFocusNode();
      final focusNode = ValueNotifier<FocusNode>(first);

      await tester.pumpWidget(
        ValueListenableBuilder<FocusNode>(
          valueListenable: focusNode,
          builder: (_, value, __) => wrap(
            stateId: 1,
            repo: buildFixtureRepository(),
            searchable: true,
            focusNode: value,
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
  });
}

class _ControlledCityRepository extends GeoRepository {
  _ControlledCityRepository() : super(bundle: InMemoryBundle(const {}));

  final Map<int, Completer<List<City>>> _requests = {};

  @override
  Future<List<City>> citiesOf(int stateId) {
    return _requests.putIfAbsent(stateId, Completer.new).future;
  }

  void complete(int stateId, List<City> cities) {
    _requests[stateId]!.complete(cities);
  }
}

class _InspectableFocusNode extends FocusNode {
  bool get hasRegisteredListeners => hasListeners;
}
