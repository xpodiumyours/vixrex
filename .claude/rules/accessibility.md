---
paths:
  - "lib/**/*.dart"
---

# Erişilebilirlik Kuralları (WCAG 2.2 AA)

## Semantics
- Her interaktif widget'ta `Semantics` label olmalı
- Butonlar için `button: true`
- Seçili öğeler için `selected: true`
- Anlamsal gruplar için `MergeSemantics`

## Keyboard Navigation
- Tab sırası mantıklı olmalı
- Focus indicator görünür olmalı (outline, glow)
- Escape ile modal/kapat
- Enter ile onayla

## Renk & Kontrast
- Normal metin: minimum 4.5:1 kontrast
- Büyük metin: minimum 3:1 kontrast
- Sadece renge bilgi taşıma (ikon + renk)

## Touch & Input
- Touch target: minimum 44x44px (iOS) / 48x48dp (Android)
- Hover olmayan cihazlar için dokunma desteği
- Swipe gesture'ları destekle

## Motion
- `ReducedMotion` kontrolü
- Animasyonları kapatma seçeneği
- `Duration.zero` ile animasyon atla

## Text
- Font boyutu sistem ayarlarına duyarlı
- `TextScaler` kullan
- Minimum font boyutu: 12px
- Satır yüksekliği: 1.4-1.6

## Images
- Tüm görsellerde `alt` metni
- Dekoratif görseller için `ExcludeSemantics`
- Yükleme durumunda skeleton göster
