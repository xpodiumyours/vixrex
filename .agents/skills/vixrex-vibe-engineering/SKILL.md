---
name: vixrex-vibe-engineering
description: VixRex'te fatura→ürün kartı→vitrin→sipariş hattını bozmadan, tek adımda ve kanıtlı değişiklik yapma döngüsü. Casper "geliştir", "düzelt", "yeni özellik", "vibe engineering", "canlıyı koru" dediğinde veya her üretim değişikliğinden önce yükle.
---

# VixRex — tek adım, kanıtlı geliştirme

Bu dosya kural kitabı değil. Kurallar `AGENTS.md`'de, sahibin değişmez kararları
`CALISMA-DEFTERI.md`'de, açık bulgular `docs/ANA-DENETIM-KAYDI.md`'de durur.
Burada yalnız bu ürüne özel **döngü, komut ve tuzak** var. Kural tekrarlanmaz,
adresi verilir.

## 1. Önce ölç — yerel git yalan söyler

```
gh api repos/xpodiumyours/vixrex/commits/main --jq .sha
curl -s https://vixrex-public.vercel.app/deploy-info.json
gh pr list --state open --limit 20
```

Üç şeyi karşılaştır: ana dal · canlı · senin dalının tabanı. Ayrıysa önce tabanı
`origin/main`'e al, sonra konuş. 2026-10-31'de yerel `origin/main` 5dd0a3be
gösteriyordu, canlı 1706522b idi; yanlış teşhis buradan çıktı.

## 2. Korunacak hat — dokunulmaz

Fatura zinciri, aksi kanıtlanana kadar çalışıyor sayılır:

- `public_web/src/lib/fatura*.ts` — okuma, satır ayıklama, eşleştirme, kart durumu, yetki
- yayın kapısı beş şartı: kanıt + satış fiyatı + stok onayı + en az 1 fotoğraf + esnaf onayı
- yalnız `source_type='invoice'` ürünler; manual / demo / kiralık vitrinler etkilenmez

İzin katmanı zincirin **çıktısına** bakar, zincirin içine girmez. Her davranış
değişikliği bayrak arkasında: `IZIN_KATMANI = kapali | gozlem | aktif`.
Geri alma = bayrağı kapatmak; kod geri alınmaz.

## 3. Tek adım döngüsü

**a) SPEC — 5 satır.** Kim, hangi ekranda, neyi görecek; kabul ölçütü makineyle
ölçülen cümle; kapsam dışı listesi; hangi kanıtı göstereceğim.

**b) KIRMIZI.** Önce test. Beklenen davranış için düştüğünü göster. Testi yazan
ile kodu yazan ayrı olsun (kural 12). Kırmızı görülmeden yeşil kabul edilmez.

**c) UYGULA.** Yalnız onaylanan dosyalar. Yolda başka hata görürsen dokunma, söyle.

**d) KAPI.** Hepsi `public_web` içinde:

```
npx vitest run
npx tsc --noEmit --skipLibCheck
npx eslint <değişen dosyalar>
npm run build
```

CI bu depoda çalışmıyor (bkz. `kapilar`); kapı yerelde koşulur. Merge kapısı
ayrıca `bash tool/merge-hazir.sh`. Son düzenlemeden **sonra** hepsini tekrar koş.

**e) KANIT.** Commit SHA · `deploy-info.json` commit · ekran (390×844, 2x) ·
kapı çıktısı. Görünen her değişiklikte öncesi/sonrası; gösteremiyorsan
"gösteremedim" de.

**f) GERİ AL.** Tek komut. Bayrak varsa bayrak.

## 4. Rapor — altı satır, fazlası yok

```
DEĞİŞTİ:         dosya:satır — ne
KİM ÇAĞIRIYOR:   bu fonksiyonu/props'u kullanan yerler
BOZULABİLİR:     en fazla 3 madde
CANLI KORUNUYOR: bayrak / dokunulmadı / eski yol aynı
GERİ AL:         komut
KAPI:            vitest n/n · tsc temiz · build OK
```

"Bitti", "düzeldi", "tamamlandı" bu altı satır olmadan yazılmaz.

## 5. Dur — onay iste

`main` merge · Vercel deploy · migration · para/PayTR · veri silme · hukuki metin ·
yeni tablo · yeni dış servis. Bunlarda dur, tek cümleyle sor, cevabı bekle.

## 6. Bu projede yasak desenler

1. Yerel `origin/main`'i kanıt saymak — bayat ref.
2. Kapı çıktısı yokken "bitti" demek.
3. Görsel hakkını kendi başına değiştirmek. Canlı kod üretici görselini indirip
   `shelf-images`'a yazıyor (`faturaGorsel.ts:217-238`) ve `usage_status` kaydı
   tutuyor (`faturaIslemKaydi.ts:121-129`). `unknown` bilinçli olarak karta girer,
   yalnız `denied` süzülür (`faturaUrunBaglantisi.ts:48-62`). Bu bir kapsam kilidi;
   kaldırmak Casper'ın kararı, ajanın değil.
4. Esnafa ürün fotoğrafı çektirmek, barkod eklemek — sahibin değişmez kararı.
5. Üretici ürün havuzu / katalog dosyası açmak (kural 20).
6. İkinci defter veya ikinci iş listesi açmak (ADKK tek kayıt).
7. Yorum satırı eklemek (kural 5).
8. Arka arkaya push; düzeltmeler tek push'ta toplanır (kural 23).
9. Aynı klasörde ikinci ajan veya ikinci dev sunucusu (kural 8).
10. Ölçüsüz eşik/ayar değiştirmek (kural 2).

## 7. Dil

Casper kodu okumuyor. Dükkân dili: tezgâh, vitrin, fatura, kayıt defteri.
Jargon zorunluysa parantezde düz karşılığı. Cevap 8–12 satır; derinlik dosyada.

## 8. Yayın kapısı — birleştirmeden önce

Vercel kotası dolduğunda birleştirme yapılmaz: ana dal canlıdan ayrı düşer ve
"düzelttim" cümlesi yalana döner (2026-11-01: #731 birleşti, canlı 24 saat geride kaldı).

1. Birleştirmeden önce yayın kapısına bak: son üretim yayını başarılı mı, birleşecek
   commit'in durumunda "rate limited" yazıyor mu.
2. Kapı kapalıysa PR bekler; birleştirme yok.
3. Bir iş = bir dal = bir PR = bir gönderim. Her gönderim bir deneme yayını harcar.
4. Birleştirdikten sonra `deploy-info.json` commit'i ana dalla aynı mı diye bak.
   Aynı değilse "canlıda" denmez; "ana dalda, canlıda değil" denir.
5. Açık taslak PR'lar kotayı yer; kullanılmayanlar kapatılır.
