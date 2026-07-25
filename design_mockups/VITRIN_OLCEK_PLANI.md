# Vitrin ölçek eşitleme (mobil + masaüstü + APK WebView)

## Tespit
| Öğe | Eski (mobil sorun) | Hedef mobil | Hedef ≥640px |
|-----|-------------------|-------------|--------------|
| Kapak | `88vh` — ekranı yiyor | `min(48vh, 340px)` | `min(70vh, 640px)` |
| Avatar | 84px | 64px | 96px |
| Başlık | ~2.2–3.6rem | ~1.7–2.1rem | ~2.2–3.4rem |
| CTA | dağınık | 44px yükseklik | 48px |
| Kart oranı | 4/5 (uzun) | 1/1 | aile oranı (4/5 veya 1/1) |
| Kart gap/pad | 10/12px | 8/10px | 10/12px |
| QR | 112 | 88 | 112 |
| Galeri büyük hücre | 220 | 140 | 220 |

## Yöntem
Tek kaynak: `.vitrin-shell` CSS değişkenleri (`globals.css`).  
Chrome / Flutter WebView / APK aynı CSS’i alır — ayrı APK layout yok.

## Uygulama
- [x] `globals.css` — `.vitrin-shell` token’ları
- [x] `layout.tsx` — `viewport` (device-width, APK WebView)
- [x] `VitrinProfileView` — kapak / avatar / tipografi / CTA / galeri / QR
- [x] `ProductCatalog` — mobil 1:1 kart, masaüstü aile oranı
