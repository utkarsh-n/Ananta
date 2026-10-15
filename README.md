# Hindu App

A native, offline iPhone and iPad learning atlas of Hinduism, built in SwiftUI. Start with human questions, learn the vocabulary in context, read historical source editions, and follow links between texts, people, deities, and ideas.

## Run

Open `Ananta.xcodeproj`, select the **Ananta** scheme, and run on an iOS 17 or later simulator. No API keys, backend, account, package dependencies, or network connection are needed for the app. Device signing is configured for the existing Apple development team. The visible app name is **Hindu App**; internal project identifiers remain `Ananta` and the bundle identifier remains `com.utkarsh.ananta` so updates preserve app data.

The Xcode project is generated from `project.yml` using XcodeGen:

```sh
xcodegen generate
```

If the command-line build stalls in macOS file coordination under Documents before compilation, `zsh Scripts/build_local.sh` builds a temporary copy outside Documents and writes the simulator application to `build/Hindu App.app`. It does not move or modify the source project.

## The experience

- **Journey:** twelve ordered introductions, short reflection questions, saved progress, links into the atlas and source texts, and a resume-reading card.
- **Library:** a broad catalog across the Vedas, Upanishads, epics, Puranas, philosophy, ritual, and devotional literature. Bundled texts have chapter-level contents, cited passages, bookmarks, reader typography controls, and find within a section. Coverage and edition limitations are visible before reading.
- **Cosmos:** interactive proportional yuga cycles, Brahma’s day and night, a six-stage ocean-churning narrative, and three source-specific perspectives on creation. Touch controls change the artwork and explanations. Animation can be paused and respects Reduce Motion.
- **Atlas:** linked entries for revered deities, epic figures, sages, and ideas; alternate names, tradition notes, source references, and explorable connection diagrams. Connections are thematic, not asserted genealogies.
- **Search:** a bundled SQLite FTS5 index searches passages, catalog metadata, wiki articles, and lessons. Results navigate to the exact chapter and passage. Prefix matching, filters, diacritic normalization, and common Sanskrit transliteration aliases are supported.

Bookmarks, lesson completion, reading position, and reading preferences persist locally. Source links open the relevant external website.

## Editorial model

Hinduism does not have a single universal canon. This app presents a growing, plural collection. “Catalog guide” is different from an offline source text. Introductory prose is original commentary, historical translations retain attribution, and cosmological diagrams identify their textual context. The app does not claim to contain every scripture or represent every community.

See [corpus provenance and exact coverage](Docs/CORPUS.md), [editorial principles](Docs/EDITORIAL.md), and [cosmology references](Docs/COSMOLOGY.md). Public-domain English editions may have archaic language, omissions, dated interpretations, and transcription defects; the notes preserve those distinctions.

## Content pipeline

The app ships reviewed JSON and a ready-to-use search database. Reimporting source material is optional and requires a network connection plus the importer’s documented Python dependencies.

```sh
python3 Scripts/import_corpus.py --download
python3 Scripts/build_search.py
xcodegen generate
```

After source snapshots are present, omit `--download` for deterministic offline reimports.

`build_search.py` stages a fresh index, checks database integrity and representative searches, then replaces the bundled database. Source snapshots stay outside the application’s resource directory. `library.json`, `knowledge.json`, and `lessons.json` have stable IDs so routes and bookmarks remain meaningful as content grows.

## Architecture

SwiftUI views use a root-owned Observation store. Content decoding runs off the main actor; reading uses lazy paragraph rendering. SQLite queries run in an actor using prepared statements against a read-only database. Each tab owns native navigation history. Codable routes connect search, reading, learning, saved pages, and the atlas.

`AnantaTests` checks content structure, exact source chapter counts, cross-links, quiz validity, search safety and routing, transliteration behavior, and persistence. `AnantaUITests` exercises the principal user flows on Simulator.

## Next editorial expansion

The foundation supports additional licensed editions, Sanskrit source alignment, verse-level translation comparison, regional language corpora, pronunciation audio, and specialist review. These are future additions and are not presented as working features in this build. App Store distribution and device signing are separate from the local simulator build.

## Artwork

The home illustration was generated with the built-in image-generation tool and is bundled at `Ananta/Resources/Assets.xcassets/CosmicLotus.imageset/cosmic-lotus.png`. The exact prompt and saved asset are documented in [ARTWORK.md](Docs/ARTWORK.md). The app icon and interactive diagrams are drawn from native vector paths. The illustration is interpretive artwork, not a historical artifact.


## Public snapshot

See [PUBLICATION.md](PUBLICATION.md) for publication exclusions and setup requirements.
