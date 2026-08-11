# Countrify - Flutter Country Picker Plugin

## Project Overview

Countrify is a **highly customizable, feature-rich Flutter package** for country selection with comprehensive country data, beautiful UI components, and extensive configuration options.

### Version & Metadata
- **Package Name**: countrify_light
- **Version**: 2.1.0
- **SDK Requirements**: 
  - Dart: ^3.0.0
  - Flutter: ^3.0.0

### Package Purpose
A production-ready country picker package that provides developers with a complete solution for country selection in Flutter applications, featuring:
- Multiple display modes (bottom sheet, dialog, full screen)
- Source-backed country data (249 ISO-assigned records plus XK/Kosovo)
- Beautiful, customizable UI
- Advanced search and filtering
- ISO 3166-1 compliance
- Phone code integration
- Flag assets for all countries

---

## Project Structure

```
countrify-light/
├── lib/
│   ├── countrify_light.dart                # Main library export file
│   ├── generated/
│   │   └── assets.dart                     # Generated asset paths
│   └── src/
│       ├── data/
│       │   ├── all_countries.dart          # AllCountries static class with country data access
│       │   ├── countries_data.dart         # Country data definitions
│       │   └── countries_data_extended.dart # Extended country data
│       ├── models/
│       │   └── country.dart                # Country, Currency, Language models
│       ├── utils/
│       │   └── country_utils.dart          # Utility functions for country operations
│       └── widgets/
│           ├── comprehensive_country_picker.dart  # Full-featured picker widget
│           ├── country_picker.dart                # Basic picker widget
│           ├── country_picker_config.dart         # Configuration classes
│           ├── country_picker_theme.dart          # Theme classes
│           ├── modal_comprehensive_picker.dart    # Modal comprehensive picker
│           ├── modal_country_picker.dart          # Modal basic picker
│           └── phone_code_picker.dart             # Phone code specific picker
├── assets/
│   └── geo/                               # Split state/city JSON + source manifest
├── example/                               # Example application
├── test/                                  # Unit tests
└── tool/
    ├── sync_country_data.dart             # Pinned country catalogue generator
    └── sync_geo_data.dart                 # Pinned state/city asset generator

```

---

## Core Architecture

### 1. Data Layer (`lib/src/data/`)

**AllCountries** - Central data access point
- Static class providing all country data
- Pre-loaded, optimized for performance
- Provides quick lookup methods by code, name, region

**Data Storage**
- Countries stored as immutable const objects
- Indexed by alpha-2, alpha-3, and numeric codes
- Support for searching and filtering

### 2. Models (`lib/src/models/`)

**Country Model**
```dart
class Country {
  final String name;
  final Map<String, String> nameTranslations;
  final String alpha2Code;        // e.g., "US"
  final String alpha3Code;        // e.g., "USA"
  final String numericCode;       // e.g., "840"
  final String flagEmoji;         // e.g., "🇺🇸"
  final String flagImagePath;
  final String capital;
  final String? largestCity;
  final String region;
  final String subregion;
  final int population;
  final double area;
  final List<String> callingCodes;
  final List<String> topLevelDomains;
  final List<Currency> currencies;
  final List<Language> languages;
  final List<String> timezones;
  final List<String> borders;
  final bool isIndependent;
  final bool isUnMember;
}
```

**Currency Model**
```dart
class Currency {
  final String code;    // e.g., "USD"
  final String name;    // e.g., "United States dollar"
  final String symbol;  // e.g., "$"
}
```

**Language Model**
```dart
class Language {
  final String iso6391;      // 2-letter code
  final String iso6392;      // 3-letter code
  final String name;
  final String nativeName;
}
```

### 3. Utilities (`lib/src/utils/`)

**CountryUtils** - Static utility class with 40+ helper methods:
- **Data Access**: `getAllCountries()`, `getCountryByAlpha2Code()`, etc.
- **Search**: `searchCountries()`, `getCountriesByRegion()`, etc.
- **Filtering**: `getIndependentCountries()`, `getUnMemberCountries()`, etc.
- **Sorting**: `getCountriesSortedByPopulation()`, etc.
- **Statistics**: `getTotalWorldPopulation()`, `getMostPopulousCountry()`, etc.
- **Formatting**: `formatPopulation()`, `formatArea()`, etc.
- **Validation**: `isValidAlpha2Code()`, etc.

### 4. Widgets (`lib/src/widgets/`)

#### Widget Hierarchy

```
Modal Pickers (Entry Points)
├── ModalCountryPicker (Basic)
│   ├── showBottomSheet()
│   ├── showDialogPicker()
│   └── showFullScreen()
└── ModalComprehensivePicker (Advanced)
    ├── showBottomSheet()
    ├── showDialog()
    └── showFullScreen()

Base Widgets
├── CountryPicker (Basic picker UI)
└── ComprehensiveCountryPicker (Advanced picker UI)

Specialized
└── PhoneCodePicker (Phone code selection)
```

#### Configuration Classes

**CountryPickerConfig** - Controls picker behavior
- Display options (what to show)
- Search and filtering
- Sorting preferences
- Grouping options
- Pagination
- Custom builders

**CountryPickerTheme** - Controls picker appearance
- Colors (background, search, items, etc.)
- Text styles
- Borders and radius
- Shadows and elevation
- Animations
- Scrollbar styling

**Predefined Themes**:
- `CountryPickerTheme.defaultTheme()`
- `CountryPickerTheme.darkTheme()`
- `CountryPickerTheme.material3Theme()`
- `CountryPickerTheme.custom(...)`

---

## Key Features

### 1. Multiple Display Modes
- **Bottom Sheet**: Slides up from bottom, partial screen
- **Dialog**: Centered popup with backdrop
- **Full Screen**: Takes entire screen with app bar

### 2. Rich Country Data
- 250 country/territory records (249 ISO-assigned plus XK/Kosovo)
- ISO 3166-1 alpha-2, alpha-3, numeric codes
- Platform emoji flags without raster assets
- Phone/calling codes
- Capitals and largest cities
- Geographic data (region, subregion)
- Demographics (population, area)
- Economic data (currencies)
- Linguistic data (languages)
- Temporal data (timezones)
- Political data (borders, independence, UN membership)

### 3. Advanced Search & Filtering
- Real-time search with debouncing
- Search by name, code, capital, region
- Filter by region/subregion
- Filter by independence/UN status
- Include/exclude specific countries
- Multi-criteria filtering

### 4. Customization Options
- **Flag Customization**: Shape (rectangular/circular/rounded), size, borders, shadows
- **Theme Customization**: Complete control over colors, typography, spacing
- **Layout Customization**: Item height, scrollbar, animations
- **Behavioral Customization**: Haptic feedback, search debounce, pagination
- **Builder Patterns**: Custom country item builder, header builder, search builder, filter builder

### 5. Performance Optimizations
- Pre-loaded country data (no async loading)
- Efficient search algorithms
- Lazy loading support
- Scrollbar with fast scroll
- Debounced search
- Optimized list rendering

### 6. Accessibility
- Full screen reader support
- Semantic labels
- Haptic feedback
- Keyboard navigation support
- High contrast theme support

---

## Technical Design Decisions

### 1. Static Data Approach
- **Decision**: Pre-load all country data as const objects
- **Rationale**: 
  - Instant access, no async overhead
  - Reduced package size vs. JSON parsing
  - Type-safe at compile time
  - Better performance
- **Trade-off**: Cannot update data without package update

### 2. Widget Composition
- **Decision**: Separate modal wrappers from base picker widgets
- **Rationale**:
  - Reusability (can embed base widget anywhere)
  - Testability (can test picker logic without modals)
  - Flexibility (users can create custom modals)
- **Pattern**: Modal widgets are factory methods that wrap base widgets

### 3. Theme & Config Separation
- **Decision**: Separate CountryPickerTheme and CountryPickerConfig
- **Rationale**:
  - Single Responsibility Principle
  - Theme = visual appearance
  - Config = behavior and data
  - Easier to reuse and compose
- **Benefit**: Can mix and match themes with configs

### 4. Utility Class Pattern
- **Decision**: Static utility class instead of extension methods
- **Rationale**:
  - Centralized functionality
  - Easier to discover (single import)
  - No namespace pollution
  - Better documentation organization

### 5. Asset Management
- **Decision**: Render ISO-derived platform emoji flags
- **Rationale**:
  - Offline support
  - No network dependencies
  - Consistent appearance
  - Fast load times
- **Trade-off**: Flag appearance depends on the platform emoji font

---

## Dependencies

### Production Dependencies
- `flutter`: SDK (required for UI components)

### Development Dependencies
- `flutter_test`: SDK (unit testing)
- `mocktail`: ^1.0.4 (mocking for tests)
- `very_good_analysis`: ^9.0.0 (linting rules)
- `flutter_lints`: ^3.0.0 (additional linting)
- `csv`: ^6.0.0 (data parsing tool)

### No External Runtime Dependencies
The package has **zero external runtime dependencies** outside of Flutter SDK, making it:
- Lightweight
- Conflict-free
- Easy to maintain
- Fast to install

---

## Testing Strategy

### Test Structure
```
test/
└── src/
    └── countrify_test.dart
```

### Test Coverage Areas
1. **Model Tests**: Country, Currency, Language equality and serialization
2. **Utility Tests**: All CountryUtils methods
3. **Widget Tests**: Picker rendering, interaction, search
4. **Integration Tests**: End-to-end picker workflows

### Testing Tools
- `flutter_test` for unit and widget tests
- `mocktail` for mocking dependencies
- Coverage tracking with `coverage` package

---

## Build & Development Tools

### Data Processing
- `tool/sync_country_data.dart` regenerates the country catalogue and ISO enum
  from pinned, validated sources.
- `tool/sync_geo_data.dart` regenerates the split state/city assets and source
  manifest from a pinned snapshot.
- Run either command with `--check` to verify committed outputs without replacing
  them.

### Linting
- Uses `very_good_analysis` - strict linting rules
- Custom rules in `analysis_options.yaml`

### CI/CD (Not included, but recommended)
- Run tests on PR
- Check code coverage
- Verify linting
- Build example app
- Publish to pub.dev on tag

---

## Common Use Cases

### 1. Basic Country Selection
```dart
final country = await ModalCountryPicker.showBottomSheet(
  context: context,
  initialCountry: selectedCountry,
);
```

### 2. Phone Code Picker
```dart
final country = await ModalComprehensivePicker.showBottomSheet(
  context: context,
  showPhoneCode: true,
  searchEnabled: true,
);
```

### 3. Regional Filtering
```dart
final country = await ModalCountryPicker.showBottomSheet(
  context: context,
  config: CountryPickerConfig(
    includeRegions: ['Europe', 'Asia'],
  ),
);
```

### 4. Custom Theme
```dart
final country = await ModalCountryPicker.showBottomSheet(
  context: context,
  theme: CountryPickerTheme.darkTheme(),
);
```

### 5. Data Access
```dart
// Get all countries
final countries = CountryUtils.getAllCountries();

// Get country by code
final usa = CountryUtils.getCountryByAlpha2Code('US');

// Search countries
final results = CountryUtils.searchCountries('united');

// Get statistics
final population = CountryUtils.getTotalWorldPopulation();
```

---

## Performance Characteristics

### Memory
- **Initial Load**: Country metadata is compiled in; geo assets load lazily
- **Runtime**: State/city results are cached after first access
- **Flag Assets**: None; flags use platform emoji

### Speed
- Picker and search performance depends on the device and selected dataset;
  benchmark the consuming application when this is release-critical.

### Bundle Size
- Measure the compressed pub archive and final application artifact for each
  release; source-tree size is not a reliable app-size estimate.

---

## Maintenance Notes

### Updating Country Data
1. Update the pinned revisions in the sync tools intentionally.
2. Run `dart run tool/sync_country_data.dart` and/or
   `dart run tool/sync_geo_data.dart`.
3. Run both tools with `--check` and verify the generated data integrity tests.
4. Update tests if needed
5. Increment package version

### Adding New Features
1. Follow existing architecture patterns
2. Add tests for new functionality
3. Update documentation
4. Add example usage
5. Ensure backward compatibility

### Flag Asset Management
- Flags located in `assets/images/flags/`
- Format: `{ALPHA2_CODE}.png` (e.g., `US.png`)
- Size: 32x24 pixels (4:3 ratio)
- Update `pubspec.yaml` if adding new flags

---

## API Stability

### Public API (Stable)
- All exported classes in `lib/countrify_light.dart`
- CountryUtils methods
- Model classes (Country, Currency, Language)
- Modal picker methods
- Theme and Config classes

### Internal API (May Change)
- Files in `lib/src/` not exported
- Private methods and classes
- Internal data structures
- Generated files

### Deprecation Policy
- Mark deprecated APIs with `@Deprecated`
- Keep deprecated APIs for at least 1 major version
- Provide migration guide in changelog
- Use semantic versioning

---

## Known Limitations

1. **Static Data**: Country data cannot be updated at runtime
2. **Bundle Size**: Offline geo data still contributes to the final app size
3. **No Network Sync**: Cannot fetch updated country data
4. **Limited Translations**: Country names have limited language support
5. **Platform Emoji**: Flag appearance varies by operating system and font

---

## Future Roadmap

### Planned Features
- [ ] SVG flag support
- [ ] More language translations
- [ ] Country grouping by custom criteria
- [ ] Export selected countries
- [ ] Save/restore picker state
- [ ] Animated flag transitions
- [ ] Voice search support
- [ ] Map view for country selection

### Under Consideration
- [ ] Dynamic data loading from API
- [ ] Custom data source support
- [ ] Offline caching strategies
- [ ] Integration with other packages
- [ ] Web-optimized version

---

## Support & Community

### Getting Help
1. Check README.md for basic usage
2. Review example app for comprehensive demos
3. Read API documentation
4. Check GitHub issues
5. Ask in Flutter community forums

### Contributing
1. Fork the repository
2. Create a feature branch
3. Write tests for new features
4. Follow existing code style
5. Submit PR with clear description

### Reporting Bugs
1. Check existing issues first
2. Provide minimal reproduction
3. Include Flutter version info
4. Describe expected vs actual behavior
5. Include relevant logs

---

## License

MIT License - See LICENSE file for details
