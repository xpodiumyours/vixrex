# Vixrex Haritası - İş Durumu

> 25 Eylül 2026, commit `08f03553`. Üst not: [[Vixrex Haritası]].

## Güncel çalışma

- Açık dal: `faz1/kiralik-vitrin-kalite` — **kiralık vitrin** (teknik işaret `stores.is_demo`) ürün kartı kalitesi.
- İlgili notlar: [[GOREV-vitrin-kalite]], [[KIRALIK-VITRIN-KALITE-PLANI]], [[KIRALIK-VITRIN-TAMAMLAMA-PLANI]], [[ILERLEME-TABLOSU]].
- Ölçüm aracı: `node tool/canli_durum.ts` (salt okunur canlı ölçüm).
- Depoda ek `git worktree` kopyaları kayıtlı (`.claude/worktrees`, `.codex-worktrees`); Obsidian bunları grafikten gizliyor.

## Bu haritanın görmediği şeyler

- **Canlı veritabanı şeması** — 127 migration dosyası okundu ([[Vixrex Haritası - Supabase]]); canlı Supabase'te hangi migration'ın uygulandığı ayrıca doğrulanmalı.
- **Canlıya çıkış durumu** — kod var ≠ canlıda çalışıyor. Dal / ana dal / canlı ayrı şeyler.
- `node_modules` içeriği ve worktree kopyaları (9.600+ md) — haritanın parçası değil, depo artığı. Grafikte gizlendi.

---

İlgili notlar: [[Vixrex Haritası]], [[Vixrex Haritası - Dağıtım ve CI]]
