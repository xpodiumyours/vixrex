# Keşfet ekranı tasarım QA

- Source visual truth: `C:\Users\Casper\AppData\Local\Temp\codex-clipboard-1ceaf7a2-b622-4d27-bb23-a811e952c31a.png`
- Implementation screenshot: `C:\Projects\vixrex\public_web\design-qa\kesfet-implementation-1920x870.png`
- Combined comparison: `C:\Projects\vixrex\public_web\design-qa\kesfet-comparison.png`
- Viewport: 1920 × 870 CSS px, desktop, deviceScaleFactor 1
- Source pixels: 1920 × 1080; browser chrome and taskbar removed with a 1920 × 870 crop beginning at y=150
- Implementation capture pixels: 1905 × 864 (the in-app browser excludes its scrollbar gutter); source crop normalized to the same 1905 × 864 raster for comparison
- State: dark theme, `/kesfet`, default filters, cookie banner dismissed. The source uses the authenticated unpublished-store status; local QA uses the guest status. Their shared frame, height, alignment, typography and right CTA were compared, while state-specific copy was treated as expected.

## Findings

No actionable P0, P1 or P2 differences remain.

- Fonts and typography: Outfit family, weight hierarchy, 20 px page title, 12 px supporting copy, filter labels and card type scale visually align with the source. The longer SEO description remains available to assistive technology while the visible line matches the source copy.
- Spacing and layout rhythm: sidebar width, 61 px status bar, full-width search, two filter rows, four-column desktop grid, 12 px gutters and 320 px card height align with the source composition.
- Colors and visual tokens: existing `lp-*` dark navy, blue, muted text, border and amber rental tokens remain consistent with the source.
- Image quality and asset fidelity: existing source cover images and mascot asset are preserved with matching crops; no placeholders or replacement artwork were introduced.
- Copy and content: default Keşfet title and visible description match the source. Authentication-dependent status copy remains intentionally state-specific.
- Interaction: search, group filters and category filtering were exercised. Search returned the expected TeknoFix result, group filtering changed the card set, and category selection stayed in-page.
- Runtime: browser console contained no errors in the clean final capture.

## Focused region comparison

The combined image was inspected at full resolution. Focused attention was given to the header/search stack, both filter rows, first card row, card media crop, pricing/actions and the bottom-right assistant control. The assistant speech bubble was removed from this screen to match the source while retaining the mascot button.

## Comparison history

1. Initial comparison found P1 layout drift: the Next.js content was centered at 1200 px, the title was oversized, desktop search was absent and cards were too narrow. Fixed by removing the 1200 px cap, restoring the desktop search, using the compact title scale and expanding the four-column grid.
2. The next comparison found P2 density/order drift: “Tümü” was in the category row, filters were taller, cards were 280 px and the status bar lacked the source-style right action. Fixed by moving “Tümü” into the group row, compacting filters, setting cards to 320 px and aligning all status variants.
3. The next comparison found a P2 assistant-state mismatch: the speech bubble appeared while the source showed only the mascot. Fixed with a screen-level `mesajGoster={false}` option.
4. Final side-by-side comparison found no remaining actionable P0/P1/P2 differences. Small button-icon differences are classified as P3 polish and do not affect layout or use.

## Follow-up polish

- P3: Add the same tiny storefront/key glyphs used in the source card actions if exact micro-icon parity is desired.

final result: passed
