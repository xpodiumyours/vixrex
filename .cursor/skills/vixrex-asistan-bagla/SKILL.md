---
name: vixrex-asistan-bagla
description: >-
  Görev başında bir kez okunur, HER ADIMDA uygulanır. Vixrex asistan işinde ürünü bozmayı, ölü kod bırakmayı,
  kabuk/boş işlemi, plan sapmasını ve paralel yolu engeller. Çalışan ürün
  üzerine çalışan asistan kurulur; ikinci ürün üretilmez. Use on every asistan
  step: plan, search, edit, test, report — and when user mentions asistan,
  onboarding, ChatbotBadge, VixRex, companion, publish RPC, ölü kod, vibe coding.
---

# Vixrex Asistan — Bağla, Üretme

## Görev başında oku, her adımda uygula (zorunlu)

Bu skill görev başında bir kez tamamen okunur. Asistan işinde her araç çağrısından
önce ve sonra kuralları yeniden uygula; dosya değişmedikçe veya bağlam
sıkıştırılmadıkça aynı turda dosyayı yeniden açma:

- plan / tarama / kod / test / rapor / “tamam” demeden önce

Görev başında okumadan veya kapıyı geçmeden ilerleme = kural ihlali. Gereksiz
yeniden okuma da işlem-bütçesi ihlalidir.

## Ürün gerçeği (altı üstü bu)

> Ürünü bozmayın. Geride ölü kod çıkartmayın. Kabuk boş işlem yapmayın.
> Çalışan ürün üzerine çalışan asistan kurulacak. Altı üstü bu.
> Sizin için çocuk oyuncağı.

Vixrex **çalışıyor**. Asistan onun **üstüne** bağlanır: kullanıcı mevcut
özellikleri **sohbet paneli** ile kullanır.

Yeni vitrin / editör / publish / GPS / FAQ / overlay = **ürün bozma + çöp**.

## Zorunlu okuma zinciri

1. `PROJECT_RULES.md`
2. `AGENTS.md`
3. `vixrex-asistan.md` (tek plan)
4. **Bu skill (her adım)**

Çelişki → Furkan’a sor. Sessiz seçim yok.

## Kapı (her adımdan önce VE sonra)

Biri “evet” → **DUR**, Türkçe söyle, düzeltmeden devam etme:

| Soru | Evet ise |
|------|----------|
| Çalışan ürünü bozuyor / kırıyor muyum? | DUR |
| Geride ölü kod, kullanılmayan route/overlay/panel/fallback bırakıyor muyum? | DUR — aynı adımda kaldır veya açıkça “kaldırmadım çünkü X” de |
| Kabuk / boş işlem mi? (bağlanmayan UI, çağrılmayan servis, sahte “tamam”) | DUR |
| Aynı iş için ikinci yol açıyor muyum? | DUR |
| Mevcut parça varken yenisini mi yazıyorum? (`StoreEditorController`, `StorePublishService`, `VixRexAction`, `FormLocationInfo`, `LegalConsentSection`, `ChatbotService`) | DUR |
| “Şimdilik” / “sonra temizleriz” yama mı? | DUR |
| Plandan (G0–G5 / faz) sapıyor veya atlıyor muyum? | DUR |
| Dokunulmazı bozuyor muyum? (önizleme, yerel kayıt, tema, tab, sticky, Keşfet→Düzenle) | DUR |
| Kanıt yokken “bitti / tamam” mı diyorum? | DUR |

## Tek doğru bağlama

| İhtiyaç | Mevcut parça |
|---------|----------------|
| Kurulum sohbeti | `/onboarding-chat` → controller + publish |
| Konum | `FormLocationInfo` / `LocationEditorSection` |
| Yasal | `LegalConsentSection` |
| Yayın | `StoreEditorController.publish` + RPC |
| Özellik sırası | `VixRexGuidanceService` + `ChatbotService` → `VixRexAction` |
| App rozet | VixRex sekmesi (ikinci panel/overlay yok) |
| Landing oluştur | Aynı kurulum sohbeti |

`stores.insert` / token’sız `stores.update` = yasak.

## Adım döngüsü

1. Bu skill + plan — hedefi tek cümle yaz.
2. `rg` — mevcut yol var mı? Varsa bağla; yoksa Furkan’a sor (uydurma).
3. En küçük bağlama — kopya motor yok.
4. Ölü yolu **aynı adımda** temizle.
5. Orantılı doğrula — çalışmıyorsa “hazır değil”.
6. Commit yalnız Furkan “commit” deyince.

## Yasaklar

- Ürünü bozan “hızlı” yama
- Ölü kod / kabuk ekran / boş wiring
- Paralel asistan, ikinci FAQ, ikinci publish/GPS
- Plan dışı md / faz atlama / büyük refactor
- Kullanıcıya teknik yük — belirsizse **sen sor**

## Çöp ürettiysen

> Bu çözüm ürün değil; ölü/paralel/kabuk çöp. Duruyorum. Doğru yol: [mevcut parça].

Gizleme. Düzelt veya onay bekle.

## Rapor (her adım sonu, kısa Türkçe)

- Bu adımda ne bağlandı?
- Ürün bozuldu mu? Ölü kod kaldı mı? (ikisi de hayır olmalı)
- Nasıl test? (1–3 adım)
- Bilerek yapılmayan / risk
