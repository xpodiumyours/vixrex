---
name: "vixrex-is"
description: "Vixrex gelisim kapisi. Casper bir gelistirme istegi yazdiginda zinciri baslatir: hedef tablosu, zincir olcumu, is siniri, onay duraklari. Onay alinmadan kod degismez."
compatibility: "Requires .specify/ directory and .claude/hooks/is-siniri.sh"
metadata:
  author: "vixrex"
  source: ".specify/memory/constitution.md"
user-invocable: true
disable-model-invocation: false
---

# Vixrex Is Kapisi (kontak)

Bu beceri, Casper bir gelistirme istegi yazdiginda **zinciri baslatir.**
Anayasa: `.specify/memory/constitution.md`. Kart sablonu:
`.specify/templates/overrides/giris-kapisi-karti.md`.

**Casper yazilimci degil.** Sade Turkce. Teknik terim kullanirsan yanina tek
cumlelik Turkce karsiligini yaz. Uzun rapor yok; madde madde, kisa.

## Sira (atlanmaz)

### 0. HEDEF (once bu)
Anayasa I. ilke: olcmeden once **hedef** yazilir. Su uc kolonlu tabloyu kur:

| Katman | Bugun canlida / kodda (olculdu) | Eksik | Olmasi gereken (referans) |
|---|---|---|---|

- Referans satirini **Casper'dan iste** (ornek: "Trendyol gibi", "su site gibi").
  Referans yoksa tabloyu "referans bekliyor" diye isaretle ve orada dur.
- "MVP'yiz" gerekcesi kabul degil. MVP hedefin yerine gecmez.
- Bu tablo dolmadan 1. adima gecilmez.

### 1. ZINCIR OLCUMU
Dokuz halkayi **koda bakarak** olc: kural, girdi, dogrulama, saklama, yetki,
gecis kapisi, etkilenen yuzeyler, cikti, geri alma.
Her hal icin **var / eksik / gerekmez** + **kanit** (dosya yolu, tablo adi,
kayit sayisi) yaz. Tahmin yasak; bakmadiysan "bakmadim" yaz.

Olcumu yaparken **yerel ana dala guvenme**: once `git fetch origin`, sonra
`origin/main` oku. (2026-09-17: yerel ana dal 5 kayit geride oldugu icin
"canlida degil" yanlisi yapildi.)

### 2. IS KAYDI
`docs/is-kayitlari/<gg-aa-yyyy>-<konu>.md` dosyasini kart sablonuna gore yaz.
Sonra **sinir dosyasini** yaz: `.claude/aktif-is.json`

```json
{
  "is": "tek cumle kabul kriteri",
  "tarih": "gg.aa.yyyy",
  "onayli_dosyalar": ["tam/yol/degisecek-dosya.ts"],
  "onay": "bekliyor"
}
```

- `onayli_dosyalar` isin **siniridir**. Kanca (`is-siniri.sh`) bu liste disina
  yazmayi **engeller**.
- Liste bos olamaz; is en az bir dosyayi etkiler.
- `onay` alani, Casper acikca onaylayana kadar `bekliyor` kalir.

### 3. DURAK
Casper'a **yalniz iki satir** sun:
1. Ne degisecek (tek cumle)
2. Bitince bakacagi adres

Onay gelince `onay` alanini `verildi` yap ve uygula.
Onay gelmeden kod degistirme; kanca zaten engeller.

### 4. BITTI
Bitince is kaydindaki `Durum` bolumunde **dort durumdan hangisi** oldugunu
isaretle: dalda duruyor / ana dala indi / yayina dagitildi / canlida dogrulandi.
Bunlar birbirinin yerine kullanilmaz. Sonra Casper'a:
"bakacagin adres: ..." diye **tek adres** ver.

## Yasaklar

- Isi buyutme. Onayli listede olmayan dosyaya dokunma; gerekirse **dur ve sor**.
- Ayni is icin ikinci kez bastan olcum yapma; eksik cikan **tek satiri** tamamla.
- Teknik karar sorma. Casper'a yalniz **para, gorunum, icerik** sorulur.
  Gerisini sen karara bagla ve **oneri** olarak sun.
- Ayni anda en fazla **iki** acik is. Kuyruk tikanmissa yeni is acma.
