# Public source snapshot

This repository contains a reviewed source snapshot. Original Git history, credentials, personal records, local signing identities, device diagnostics, build outputs, downloaded model weights, firmware, and unreviewed media are excluded. Existing upstream license and attribution files apply to their respective components. Publication does not grant a new license to third-party content.

Configure your own Apple signing team to run native apps on a physical device. Downloaded datasets, binary runtimes, fonts, demo media, and models may need to be obtained separately using the documented upstream sources or fetch/build tools. This publication review does not certify that this snapshot builds or runs.

## Project setup and omitted assets

The bundled `library.json`, `knowledge.json`, and `lessons.json` are fixed application content; they do not contain user bookmarks or personal reading notes. `library.json` contains 75 catalog entries, including 14 historical collections and 20,937 passages. Preserve the edition attribution and **public domain in the USA** qualification in `Docs/CORPUS.md`; this is not a claim about rights worldwide. The original development PDFs and raw source snapshots under `SourcesArchive/` are omitted, including modern prefatory/typesetting material.

`Ananta/Resources/search.sqlite` is omitted. Generate it from the retained reviewed JSON with `python3 Scripts/build_search.py` before building. An optional full corpus reimport uses `python3 Scripts/import_corpus.py --download`; review `Docs/CORPUS.md` and the pinned checksums before doing so.
