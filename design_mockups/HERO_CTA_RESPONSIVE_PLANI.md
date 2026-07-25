# Hero CTA — mobil + masaüstü düzeltme

## Araştırma özeti
- `flex-wrap` mobilde uzun WA + kısa Yol/IG’yi **dengesiz** kırıyor (üstte 2, altta 1).
- En iyi pratik: mobilde **CSS Grid** (eşit sütun); masaüstünde **flex** (doğal genişlik).
- Mobilde max 2 sütun; birincil CTA (WhatsApp) **tam satır**.
- Dokunma: `min-h-12` (48px) korunur.

## Karar
```
Mobil (<640px):
[======== WhatsApp · … ========]   ← col-span-2 / w-full
[  Yol tarifi  ][  Instagram  ]   ← eşit 1fr
[+ Randevu / Web varsa aynı grid]

Masaüstü (≥640px):
[WhatsApp] [Yol tarifi] [Instagram] …  ← flex, w-auto, tek satır
```

## Uygulama
1. [x] `ActionButton` → opsiyonel `className` + truncate
2. [x] Hero: WA ayır; diğerleri secondary 2-col grid; `sm:contents` + flex masaüstü
3. [x] Smoke: 390px — WA tam satır, Yol | IG eşit; tsc OK
