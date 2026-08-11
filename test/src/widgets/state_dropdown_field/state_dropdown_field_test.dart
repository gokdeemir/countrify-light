import 'dart:async';

import 'package:countrify_light/src/data/geo_repository.dart';
import 'package:countrify_light/src/models/state.dart';
import 'package:countrify_light/src/widgets/state_dropdown_field/state_dropdown_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/in_memory_bundle.dart';

void main() {
  group('StateDropdownField', () {
    Widget wrap({
      required String? countryIso2,
      required GeoRepository repo,
      ValueChanged<CountryState?>? onChanged,
      bool searchable = false,
      int? initialStateId,
      FocusNode? focusNode,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: StateDropdownField(
            countryIso2: countryIso2,
            repository: repo,
            onChanged: onChanged,
            searchable: searchable,
            initialStateId: initialStateId,
            focusNode: focusNode,
          ),
        ),
      );
    }

    testWidgets('shows placeholder when no country is set', (tester) async {
      final repo = buildFixtureRepository();
      await tester.pumpWidget(wrap(countryIso2: null, repo: repo));
      await tester.pumpAndSettle();
      expect(find.text('Select state'), findsOneWidget);
    });

    testWidgets('opens bottom sheet and emits selected state on tap',
        (tester) async {
      final repo = buildFixtureRepository();
      CountryState? picked;
      await tester.pumpWidget(
        wrap(
          countryIso2: 'PK',
          repo: repo,
          onChanged: (s) => picked = s,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(StateDropdownField));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sindh'));
      await tester.pumpAndSettle();

      expect(picked, isNotNull);
      expect(picked!.name, 'Sindh');
      expect(find.text('Sindh'), findsOneWidget);
    });

    testWidgets('clears selection when countryIso2 changes', (tester) async {
      final repo = buildFixtureRepository();
      final notifier = ValueNotifier<String?>('PK');
      CountryState? last;
      addTearDown(notifier.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValueListenableBuilder<String?>(
              valueListenable: notifier,
              builder: (_, value, __) => StateDropdownField(
                countryIso2: value,
                repository: repo,
                searchable: false,
                onChanged: (s) => last = s,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open sheet, select Sindh.
      await tester.tap(find.byType(StateDropdownField));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sindh'));
      await tester.pumpAndSettle();
      expect(last?.name, 'Sindh');

      // Switch country; onChanged(null) must fire.
      last = const CountryState(id: -1, name: 'sentinel', countryIso2: '');
      notifier.value = 'US';
      await tester.pumpAndSettle();
      expect(last, isNull);
    });

    testWidgets('ignores a late hydration result from the previous country',
        (tester) async {
      final repo = _ControlledStateRepository();
      final country = ValueNotifier<String>('PK');
      addTearDown(country.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValueListenableBuilder<String>(
              valueListenable: country,
              builder: (_, value, __) => StateDropdownField(
                countryIso2: value,
                repository: repo,
                searchable: false,
                initialStateId: 2,
              ),
            ),
          ),
        ),
      );

      country.value = 'US';
      await tester.pump();
      repo.complete('US', const [
        CountryState(id: 2, name: 'Nevada', countryIso2: 'US'),
      ]);
      await tester.pump();
      expect(find.text('Nevada'), findsOneWidget);

      repo.complete('PK', const [
        CountryState(id: 1, name: 'Punjab', countryIso2: 'PK'),
      ]);
      await tester.pump();

      expect(find.text('Nevada'), findsOneWidget);
      expect(find.text('Select state'), findsNothing);
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
            countryIso2: 'US',
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

class _ControlledStateRepository extends GeoRepository {
  _ControlledStateRepository() : super(bundle: InMemoryBundle(const {}));

  final Map<String, Completer<List<CountryState>>> _requests = {};

  @override
  Future<List<CountryState>> statesOf(String iso2) {
    return _requests.putIfAbsent(iso2, Completer.new).future;
  }

  void complete(String iso2, List<CountryState> states) {
    _requests[iso2]!.complete(states);
  }
}

class _InspectableFocusNode extends FocusNode {
  bool get hasRegisteredListeners => hasListeners;
}
