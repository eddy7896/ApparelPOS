# ADR-0017: Hangtag PDF, the `pdf` package and the Noto Sans font

- **Status:** Accepted (2026-11-20, owner)
- **Origin:** Owner chose "₹499.00" on the tag (2026-11-20); package and font chosen by the assistant
- **Builds on:** ADR-0004, ADR-0016

## Context
Standard PDF fonts have no rupee sign, so a font file must be bundled. The hangtag PDF must work on Windows and in the browser preview.

## Decision
1. The hangtag PDF is drawn with the pub.dev package `pdf` (pure Dart, locked at version 3.13.1 in `packages/core_domain/pubspec.lock` on this machine; `pubspec.yaml` allows `^3.13.1`). It sits in `core_domain` behind a separate entry point, `package:core_domain/hangtag_pdf.dart`, so the main library does not import it. Geometry (`layoutHangtag`) stays free of any PDF code.
2. The font is Noto Sans Regular and Bold (copyright The Noto Project Authors, SIL Open Font License 1.1), stored in `packages/core_domain/assets/fonts/` with its `OFL.txt`. Both files were checked to contain U+20B9 (₹), digits and comma. Licence text was read from the `notofonts/latin-greek-cyrillic` repository on 2026-11-20; no Reserved Font Name is declared in its header. Not legal advice: **unverified** by a lawyer.
3. Fonts are passed to the builder as bytes; the app decides how to load them.
4. A character the font cannot draw stops the print (`MissingGlyph`) instead of printing a box. Noto Sans here covers Latin, Greek and Cyrillic, not Devanagari; this matches "Language: English only" (SSOT).
5. Sizes and spacing on the tag are the assistant's defaults and can be changed.

## Alternatives considered
- **A separate `label_pdf` package:** cleaner boundary, but a new package for one file; revisit if more printing arrives.
- **Roboto or another font:** not checked for the rupee sign; Noto Sans was checked.
- **Drawing text as images:** blurry on print and not searchable; rejected.

## Consequences
- `core_domain` now depends on `pdf` (not pure "no dependencies"). **Unverified:** that the `pdf` package works in the browser build; it is not imported by the app yet.
- About 1.2 MB of font files in the repository.
- Whether a printer and scanner read the printed tags is **unverified** (no hardware).

## Enforcement
| Rule | Check |
|---|---|
| Fonts carry a licence file and the rupee sign | `packages/core_domain/test/hangtag_pdf_test.dart` |
| Bars match Code 128 and stay inside the label | `packages/core_domain/test/hangtag_artwork_test.dart` |

## Open decisions
| ID | Question | Options | Recommended |
|---|---|---|---|
| D17 | Thermal roll label size and layout | decide when a printer is chosen | n/a |
