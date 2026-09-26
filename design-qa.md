# Design QA — Next.js Vitrinim

## Result

Passed.

## Source

Open state: `C:/Users/Casper/AppData/Local/Temp/codex-clipboard-c881a0ae-5c57-4d13-82e2-5542d14dd3da.png`

Collapsed/legal state: `C:/Users/Casper/AppData/Local/Temp/codex-clipboard-c2bc82f2-5943-495e-bcca-ab674a774d15.png`

## Implementation capture

`C:/Users/Casper/.codex/visualizations/2026/08/31/01a05a35-820f-72d3-905d-17308488307e/vitrinim-next.png`

## Checks

- Flutter source of truth: `VitrinFormSection`, `MyVitrinState`, the five `*_bolumu.dart` widgets and `YasalYayinBolumu`.
- Desktop reference viewport: 1920 × 1080.
- Main editor width, top offset, two-column accordion, field density, colors, borders and progress treatment match the Flutter reference.
- The app sidebar and publishing status bar remain aligned with the reference shell.
- Required field progress uses Flutter's 5 / 4 / 4 / 6 / 12 section totals.
- At 768 × 1024 the accordion becomes one column with no horizontal overflow.
- Form fields save to the existing owner draft; cover/gallery, about, campaign, FAQ, marketplace, products, legal consent and publishing use the existing owner APIs.
- The broken combined bootstrap RPC has a fixed migration and the page has a RLS-protected `bootstrap_owner_state` fallback, so a database rollout mismatch no longer sends an existing owner to the empty onboarding screen.
- Production build passes.
