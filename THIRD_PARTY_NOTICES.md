# Third-Party Notices

Countrify Light's Dart and Flutter source code is licensed under the MIT
License in [`LICENSE`](LICENSE). The generated and vendored data listed below
retains its upstream license. The package's MIT license does not replace those
data licenses.

The generated databases in `assets/geo/` and `lib/src/data/` are made
available under the applicable ODbL 1.0 terms below. Redistributors should
retain this file and the referenced license texts, and review the attribution,
share-alike, and derivative-database access conditions in the ODbL.

## Countries States Cities Database

Country population, calling-code, and IANA time-zone metadata, plus the
bundled country/state/city hierarchy, are derived from **Countries States
Cities Database**.

- Source: <https://github.com/dr5hn/countries-states-cities-database>
- Pinned revision: [`624a208c3928937d1262ab1646d0b8fc9cacceee`](https://github.com/dr5hn/countries-states-cities-database/tree/624a208c3928937d1262ab1646d0b8fc9cacceee)
- Source inputs: [`json/countries.json`](https://github.com/dr5hn/countries-states-cities-database/blob/624a208c3928937d1262ab1646d0b8fc9cacceee/json/countries.json) and [`json/countries+states+cities.json`](https://github.com/dr5hn/countries-states-cities-database/blob/624a208c3928937d1262ab1646d0b8fc9cacceee/json/countries%2Bstates%2Bcities.json)
- License: Open Database License 1.0 (ODbL 1.0)
- Full license: [`LICENSES/ODbL-1.0.txt`](LICENSES/ODbL-1.0.txt)

Attribution requested by the upstream project:

> Data by Countries States Cities Database<br>
> <https://github.com/dr5hn/countries-states-cities-database> | ODbL v1.0

Contains information from Countries States Cities Database, which is made
available under the Open Database License (ODbL 1.0).

## World countries (mledoze/countries)

Display names, capitals, regions/subregions, top-level domains, ISO
identifiers, currencies, languages, borders, area, independence, and UN
membership fields in the generated country catalogue are derived from
**mledoze/countries**.

- Source: <https://github.com/mledoze/countries>
- Pinned revision: [`9eff32e4eef26715aa59d99b200127d1ef150e7a`](https://github.com/mledoze/countries/tree/9eff32e4eef26715aa59d99b200127d1ef150e7a)
- Source input: [`countries.json`](https://github.com/mledoze/countries/blob/9eff32e4eef26715aa59d99b200127d1ef150e7a/countries.json)
- License: Open Database License 1.0 (ODbL 1.0)
- Full license: [`LICENSES/mledoze-ODbL-1.0.txt`](LICENSES/mledoze-ODbL-1.0.txt)

Contains information from mledoze/countries, which is made available under
the Open Database License (ODbL 1.0). No SVG or raster flag assets from this
source are included.

## Country List translations

The compile-time country-name translations under `lib/src/l10n/` are derived
from **umpirsky/country-list**.

- Source: <https://github.com/umpirsky/country-list>
- Pinned revision: [`4d8f87526c891a7b110b530eabf910c3f7468ad6`](https://github.com/umpirsky/country-list/tree/4d8f87526c891a7b110b530eabf910c3f7468ad6)
- Source inputs: [locale JSON files under `data/`](https://github.com/umpirsky/country-list/tree/4d8f87526c891a7b110b530eabf910c3f7468ad6/data)
- License: MIT
- Full notice: [`LICENSES/umpirsky-country-list-MIT.txt`](LICENSES/umpirsky-country-list-MIT.txt)

## Lucide Icons

The `CountrifyIcons` font under `assets/fonts/` contains glyphs derived
from named Lucide icons. Lucide is ISC licensed; Lucide's license also
identifies a subset of Feather-derived icons covered by the Feather MIT
license.

- Source: <https://github.com/lucide-icons/lucide>
- Icon source revision: not recorded when the font was added to the upstream
  Countrify package
- License snapshot: [`c619ce988c895b3d76edcc9e899bbe5df5ef555e`](https://github.com/lucide-icons/lucide/tree/c619ce988c895b3d76edcc9e899bbe5df5ef555e), the latest upstream revision
  before the font entered this repository's history
- Licenses: ISC (Lucide) and MIT (listed Feather-derived icons)
- Full notice: [`LICENSES/lucide-ISC-and-feather-MIT.txt`](LICENSES/lucide-ISC-and-feather-MIT.txt)

## Rebuilding the data

The transformation code is included in the published source archive as
`tool/sync_country_data.dart` and `tool/sync_geo_data.dart`. Generated emoji
flags are Unicode regional indicator sequences; the package does not
redistribute raster or SVG flag artwork.
