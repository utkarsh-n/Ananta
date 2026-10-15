# Ananta corpus: coverage, provenance, and reproducibility

This build is an English-language starting library, not a claim to contain every Hindu text or represent every Hindu community. Hindu textual traditions have no single universally agreed closed canon. Ananta distinguishes offline source text from an editorial catalog guide, and records tradition and edition at the book level.

## What is actually bundled

| Collection | Source coverage | App reading units | Passages |
| --- | --- | ---: | ---: |
| Bhagavad Gita | Ganguli’s prose translation, all 18 chapters from Mahabharata 6.25–42 | 18 chapters | 105 |
| Three Upanishads | Paramananda’s complete Isha, Katha, and Kena translations with commentary; a selection of the wider Upanishadic corpus | 3 works | 80 |
| Yoga Sutras | Johnston’s translation of all 195 aphorisms in this edition, with commentary labeled separately | 4 books | 414 |
| Ramayana | Griffith’s first six books; translation has omissions and condensation; no Uttara Kanda | 493 cantos | 1,861 |
| Mahabharata | All 18 parvas as supplied in the four Ganguli digital volumes; known source gaps retained and disclosed | 2,107 source sections | 12,786 |
| Rig Veda | Griffith translation, 1,028 hymn units across ten mandalas; known digital transcription defects | 1,028 hymns | 1,791 |
| Vishnu Purana | Dutt’s 1896 edition, based on Wilson; all six parts | 126 chapters | 803 |
| Black Yajur Veda | Keith’s 1914 Taittiriya Samhita, all seven kandas | 644 source units | 1,171 |
| White Yajur Veda | Griffith’s 1899 translation, all forty books | 40 books | 317 |
| Atharva Veda | Griffith’s twenty books in a digital witness with numbering gaps | 723 hymn headings | 1,163 |
| Sama Veda | Griffith’s translation, both parts | 15 books | 266 |
| Chandogya Upanishad | Müller’s 1879 translation | 8 prapathakas | 130 |
| Aitareya Upanishad | Müller’s translation of Aitareya Aranyaka II.4–6 | 1 work | 11 |
| Kaushitaki Upanishad | Müller’s 1879 translation | 4 adhyayas | 39 |
| **Total** | **14 offline collections** | **5,214 units** | **20,937 passages** |

The generated JSON contains about **3.733 million whitespace-delimited words**, including historical commentary. The Gita appears both on its own and in its Mahabharata setting, so that count includes that intentional duplication. JSON size is approximately 26.31 MB.

The catalog contains **75 entries**: fourteen collections and **61 guide-only entries**. Three individual Upanishad guides point readers toward the bundled collection rather than duplicating it. Guide entries have an empty `chapters` array. Their external source links do not imply an offline translation, ownership of linked material, or an in-app download feature.

## Editorial coverage

The catalog includes the four Vedas; Brahmana material; thirteen principal Upanishad guides; the epics and regional retellings; the eighteen titles in a common Mahapurana list plus major Shakta works; the six classical philosophical systems and several later works; Tamil Shaiva and Sri Vaishnava corpora; bhakti poetry; and Agama/Tantra families.

This is a reading map rather than a ranking of communities or scriptures. Purana lists vary, Agamas are families rather than single interchangeable books, and regional and oral traditions remain much wider than this release. Tirukkural is explicitly described as shared Tamil ethical literature, not exclusively Hindu scripture. Dharmashastra prescriptions are identified as historically situated and contested rather than current universal rules.

Catalog annotations, chapter summaries, and reading suggestions are original editorial orientation. They are not quotations from scripture. Contemporary specialist review, community review, wider original-language coverage, and licensed modern translations are next content milestones.

## Primary hosts and editions

The following host catalog pages and source headers were checked while building the corpus on October 4, 2026. Their copyright fields identify the listed editions as public domain in the USA:

- [Mahabharata, volume 1 — books 1–3](https://www.gutenberg.org/ebooks/15474)
- [Mahabharata, volume 2 — books 4–7, including the Gita](https://www.gutenberg.org/ebooks/15475)
- [Mahabharata, volume 3 — books 8–12](https://www.gutenberg.org/ebooks/15476)
- [Mahabharata, volume 4 — books 13–18](https://www.gutenberg.org/ebooks/15477)
- [The Yoga Sutras — Charles Johnston](https://www.gutenberg.org/ebooks/2526)
- [The Upanishads — Swami Paramananda](https://www.gutenberg.org/ebooks/3283)
- [The Ramayana — Ralph T. H. Griffith](https://www.gutenberg.org/ebooks/24869)
- [Vishnupuranam — Manmatha Nath Dutt, based on H. H. Wilson](https://www.gutenberg.org/ebooks/66208)

The [Rig Veda host index](https://archive.sacred-texts.com/hin/rigveda/index.htm) identifies Griffith’s 1896 translation. The [downloadable digital witness](https://www.mystika.cz/texty/rgveda-eng.pdf) identifies the public-domain translation, its original 1896 edition, and Ulrich Stiehl’s 2005 PDF conversion. Its introductory notice explicitly reports removal of diacritics and scanning errors. Only the translated hymn body is included in `library.json`; the modern preface and conversion instructions are not bundled in the app.

Guide links use the [Internet Sacred Text Archive Hinduism collection](https://archive.sacred-texts.com/hin/index.htm), [GRETIL at Göttingen University](https://gretil.sub.uni-goettingen.de/gretil.html), and [Project Madurai’s Tamil works catalog](https://www.projectmadurai.org/pmworks.html). Some links lead to a collection index containing the work rather than one selected translation. Rights at these destinations are edition-specific; no linked guide-only text was copied into the app.

## Rights and source handling

The [Project Gutenberg license explanation](https://www.gutenberg.org/policy/license.html) distinguishes unrestricted historical text from the Project Gutenberg trademark and license wrapper. The app's reading text excludes that wrapper and associated production credits. Source URLs here and in book metadata are acknowledgements/source references. Downloaded original source snapshots preserve their original headers and license text in `SourcesArchive`; that directory is a development archive, not an app resource directory.

The app metadata says **public domain in the USA**, not public domain worldwide. This is provenance for the chosen historical translations, not a blanket license for modern translations, commentary, editions, recordings, art, or linked websites. The Rig Veda PDF's modern prefatory material is excluded from the app and is not asserted to be public domain. The archive PDF is retained only as the original development source witness.

## Known limitations deliberately preserved

- **Edition completeness is not Sanskrit-corpus completeness.** A “Full source edition” label means the supplied digital edition was imported in full, with source defects explicitly retained. A “Complete translation” label means the translated work was imported in full, excluding front matter, notes, indexes, and license wrappers as described below. It does not mean every recension, commentary, variant reading, or ancillary text is present.
- **Mahabharata:** all eighteen parvas of the selected source are imported. Source section numbering skips 1.177, 2.67, 7.54, 7.55, 7.189, and 12.364. Book 12 has one combined section 34–35. The source also includes an explicit missing-text notice in Book 3. These gaps have not been filled by invented prose. The Harivamsha is not part of this bundle. It is not the BORI critical edition.
- **Ramayana:** 75, 119, 76, 67, 55, and 101 canto headings are imported from Books I–VI respectively. Griffith expressly omits and condenses passages. The source appendix, notes, name index, and its secondary discussion of Uttara Kanda are not included. The coverage badge therefore says “Selected translation.”
- **Paramananda collection:** the bundled Three Upanishads set contains precisely Isha, Katha, and Kena, not all principal Upanishads or the traditional 108. Chandogya, Aitareya, and Kaushitaki are bundled separately in Müller’s translations. Translation and Paramananda’s commentary are interleaved, as in the edition, and identified as such. His perspective is not presented as the only Vedanta interpretation.
- **Yoga Sutras:** 51 + 55 + 55 + 34 aphorisms = 195 in this edition. Other editions count 196. Johnston’s Theosophical commentary is explicitly distinguished from translated aphorisms.
- **Rig Veda:** ten mandala hymn counts are 191, 43, 62, 58, 87, 75, 104, 103, 114, 191. This verifies all 1,028 hymn units in this witness, not every syllable against a critical Sanskrit edition. The witness has OCR/scanning errors and stripped diacritics; errors are not silently rewritten as scripture.
- **Gita:** Ganguli’s 18 prose chapters are used. Edwin Arnold’s poetic version was examined and rejected as the primary Gita because its footnotes explicitly state that verses were omitted. Gita app paragraph numbers are reading-passage numbers, not invented Sanskrit verse references.
- Historical translations include old vocabulary, dated scholarship, and social assumptions. Ananta’s editorial summaries are separate from source words. The app is a guide to learning, not a replacement for the living traditions represented.

## Build and validation

From the project root:

```sh
python3 Scripts/import_corpus.py
```

The ordinary rebuild is entirely offline and uses only Python’s standard library (including HTML and ZIP parsing). It reads pinned source snapshots, verifies their SHA-256 digests against the versioned `Scripts/corpus_sha256.json` (falling back to `SourcesArchive/SHA256SUMS.json` only if the versioned manifest is absent), parses the source structures, validates counts and IDs, and writes `Ananta/Resources/library.json` deterministically. It exits on changed source bytes or failed structural checks.

To obtain missing originals in a fresh checkout:

```sh
python3 Scripts/import_corpus.py --download
```

The download option retrieves only the URLs declared in the script and does not overwrite existing snapshots. If the Rig Veda, Atharva Veda, or four-Veda TXT witnesses must be regenerated from their PDFs, `pypdf` is required. On the development machine, it is available in the Codex bundled Python runtime. Because text extraction can vary by library version, an altered extraction digest must be reviewed rather than silently accepted.

Importer guarantees checked during this build:

- All eighteen Mahabharata parvas and the expected per-parva source section counts are present.
- All eighteen Gita chapters occur in order in Book 6, sections 25–42.
- All four Yoga books contain the expected aphorism counts.
- All three named Upanishads and six imported Ramayana books are present.
- All ten Rig Veda mandalas contain the expected hymn counts.
- The added Vishnu Purana has 22, 16, 18, 24, 38, and 8 source chapters in its six parts.
- Black Yajur source unit counts are 145, 73, 53, 81, 120, 66, and 106; White Yajur has forty books; Sama Veda has six plus nine books.
- Atharva’s twenty book headings and 723 supplied hymn headings are present; source numbering defects remain disclosed.
- Chandogya has eight prapathakas, Kaushitaki four adhyayas, and Aitareya is bounded to Aranyaka II.4–6.
- Book, chapter, and passage identifiers are globally unique.
- Every imported reading unit has nonempty text; guide-only entries have no reading units.
- Chunking preserves every non-whitespace character after the documented cleaning step.
- Project Gutenberg wrappers do not occur in passage text.

Cleaning removes linked footnote numerals, PDF page markers, redundant Gita comparison headings, and one digitizer explanation preceding the Gita. Chapter labels remain in metadata. Translator endnotes and editorial indexes are excluded, so footnote reference markers are also removed. Print line wrapping is normalized, with paragraph boundaries retained; this is a reading/search edition rather than a facsimile. Most passages are at most 1,350 characters. Stable IDs identify the exact work, source section, and sequential app passage, supporting durable search and bookmarks.


## Additional Vedic and Puranic source witnesses

- **Vishnu Purana:** [Dutt’s 1896 edition](https://www.gutenberg.org/ebooks/66208) explicitly says it is based on Wilson. The final chapter of Part V is misprinted XXVIII in the source; the app uses its sequential position, 38, and explains that correction in the chapter summary. All 126 source chapters are included; translator endnotes are excluded.
- **Black Yajur Veda:** [Keith’s 1914 Taittiriya Samhita source index](https://original.sacred-texts.com/hin/yv/index.htm). The development witness is the openly linked historical HTML archive on [Radha.name’s Yajur Veda page](https://www.radha.name/digital-books/sastras-acharyas-and-swamis/4-vedas/yajur-veda). Seven source HTML files are parsed inside the ZIP without executing any HTML. Offline-browser banners and navigation are removed before text extraction. The source is one Samhita recension, not all Yajurvedic literature.
- **White Yajur Veda:** [Griffith’s 1899 text, hosted by Global Grey](https://www.globalgreyebooks.com/online-ebooks/ralph-t-h-griffith_texts-of-the-white-yajurveda_complete-text.html). Only the historical forty-book text is imported; modern website content is excluded.
- **Sama Veda:** source attribution is [Griffith’s translation](https://archive.sacred-texts.com/hin/sv.htm). The accessible development witness is [Four Vedas — English Translation](https://muugumuugu.github.io/bOOkshelF/literature/Four%20Vedas%20-%20English%20Translation.pdf), from which only the Sama Veda section is imported. Running headers, PDF page numbers, and the other three works in that PDF are excluded. The first part has six books, the second nine. The source labels its edition 1895; Griffith’s initial publication is also commonly dated 1893.
- **Atharva Veda:** attribution is [Griffith’s 1895–1896 translation](https://archive.sacred-texts.com/hin/av/index.htm). The [downloaded witness](https://rootshunt.com/aryans/zoroastrianandaryans/vedsinenglish/atharvved/hymns-of-the-atharv-ved.pdf) is a Global Grey 2019 typesetting of that historical translation. Only the translated body is imported, not its modern title/copyright pages. The app does not claim ownership of that typesetting. The source has missing or duplicate heading labels: gaps include 2.20–23, 3.30, 4.2, 6.7, 7.3, and 19.8; duplicated labels are retained. Therefore the badge is “Full source edition,” not a claim of a verified complete critical Atharva Veda. Text has not been invented to repair defects. Historical medical and protective charms are presented as religious literature.
- **Additional Upanishads:** [Müller’s 1879 volume, hosted by Global Grey](https://www.globalgreyebooks.com/online-ebooks/friedrich-max-muller_upanishads-part-1_complete-text.html). Chandogya and Kaushitaki are imported as complete works, with scholarly endnotes excluded. The source includes the larger Aitareya Aranyaka; the app selects precisely its second Aranyaka, adhyayas 4–6, which comprise the Aitareya Upanishad. Source internal subdivisions remain in the text. Aitareya’s opening historical editorial introduction is segmented and labeled separately from translated scripture, which begins at the invocation. The wrapper’s modern website content is excluded.

The versioned expected checksums in `Scripts/corpus_sha256.json`, original documents in the ignored source archive, metadata, and importer together make these edition boundaries reviewable. The expanded library still leaves 61 entries as explicit guides. In particular, most Puranas, Shakta scriptures, regional bhakti corpora, Agamas, and several principal Upanishads require additional source/licensing and editorial work before becoming offline texts.
