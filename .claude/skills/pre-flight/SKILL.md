---
description: Bind/widget task öncesi kısa kontrol. Fast-path ise atla. Kabukları düzenle/bağla; boş callback + Fake Complete kapısı.
argument-hint: bind veya yeni widget task
---

# Pre-Flight Kontrol

> **Fast-path ise bu skill'i atla** (typo, renk, tek satır, saf isim/refactor).
> Yalnızca bind / yeni widget task'ta yükle.

---

## 1. Mevcut Kod

```
□ grep ile bul (tüm dosyayı okuma)
□ offset/limit ile ilgili bölüm
□ "Bu zaten var mı?" — varsa düzenle + bağla (yeniden yazma yok)
□ Çekirdek akış bozulur mu? (Vitrinim / yayın / Keşfet) → bozma
```

## 2. Bu Task'ta Bağlama

```
□ Yeni widget öncesi benzer var mı?
□ LoadingIndicator / ErrorState / SkeletonLoader / TooltipWrapper / SkipLink
□ Bu task'ta yazdıysan aynı task'ta parent'a bağla
□ Kurtarma: kozmetikten önce çekirdek (`KURTARMA_OPERASYONU.md`)
```

## 3. Boş Callback + Sahte Tamam

```
□ onTap/onPressed/onChanged → () {} veya null yasak
□ SnackBar / nav / setState / servis — gerçek aksiyon
□ Etiket = içerik? (SSS→SSS metni; Docs→kılavuz; KVKK'ya yama = Complete DEĞİL)
□ "yakında gelecek" ile Complete iddiası yasak
```

## 4. Durum

```
□ Yeni ekran/özellikse: loading + empty + error
□ mounted kontrolü (setState öncesi)
□ Dosya >200 satır? → böl
```

---

## Gate (task kapanmadan, ~20sn)

```
1) rg ClassName lib/screens lib/widgets   → kullanım kanıtı (bu task'ın widget'ı)
2) rg boş callback / TODO stub            → değişen path
3) dosya >200?                            → böl
4) etiket=içerik?                         → yoksa Wire-only; [x] YASAK
5) Complete iddiası                         → yalnız gerçek işlev
6) Çekirdek bozuldu mu? (Vitrinim/yayın/Keşfet) → bozulduysa önce onu düzelt
```

**YASAK (yavaşlatır):** Full `flutter analyze`, full test suite, mega-plan checkbox, `/production-checklist` (release hariç).

**İş kuralı:** `KURTARMA_OPERASYONU.md` — çekirdek önce.

---

*DoD detayı CLAUDE.md'de. Bu skill yalnızca bind/widget.*
