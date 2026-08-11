# VixRex — durum ve iş kaynağı

> Aktif görevlerin kapsamı, planı ve ilerlemesi GitHub Issues içindedir. Bu not değişken PR/issue sayıları veya kısa sürede eskiyen iş listeleri tutmaz.

## Ürün durumu

VixRex, esnafın Flutter panelinden düzenlediği veriyi Supabase’e yazar ve müşteriye tek Next.js `/v/:slug` vitrini sunar. Flutter ve Next.js iki ayrı Vercel projesidir; yayın ve doğrulama sonuçları birbirinin yerine geçmez.

İlk 13 fazlık sahip önizleme/asistan çalışması tamamlanmış ve tarihsel planı [[vixrex-asistan-13-faz-plani-2026-08-06]] adıyla arşivlenmiştir. Geçmiş canlı test ve tur bulguları `docs/arsiv/` altındadır; yeni görev planı olarak kullanılmaz.

## Aktif işi bulma

- GitHub: [açık issue’lar](https://github.com/xpodiumyours/vixrex/issues)
- Komut: `gh issue list --state open`
- Issue kullanımı: [[issue-tracker]]

Bir issue uygulanırken kapsam ve kararlar issue içinde tutulur. Kök dizinde `implementation_plan.md`, `docs/` kökünde aktif `prompt*.md` tutulmaz.

## Kalıcı kaynaklar

- Ürün, güvenlik ve canlı sistem sınırları: [[VIXREX_RULES]]
- Ajan başlangıcı: [[AGENTS]]
- Teknik depo haritası: [[repository-guide]]
- Alan sözleşmesi: [[vitrin-alan-semasi]]
