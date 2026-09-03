# Canlı Doğrulama — 3 Akış Yan Yana (03)

> **Kapsam:** Landing + Keşfet + niyet sorusu. `/v/:slug` bilerek DIŞARIDA (kullanıcı kararı). Eşitleme bu raporla bitiyor.
> **Tarih:** 2026-09-03 · Dal: `feat/sayfa-esitleme` (25fae60 üstü)
> **Yöntem:** `dev.ps1` düzeni — Flutter `web-server` debug (`:5001`) + Next dev (`:3000`), Playwright chromium, taze profil (giriş yok), desktop 1440×900 + mobil 390×844.

## Ortam notları (sonuçları etkiler)

- `:5000` doluydu (aynı makinede başka proje — ProductFinder, dokunulmadı) → Flutter `:5001`'de koştu.
- Debug derleme (release değil) + Next dev modu: "1 Issue" rozeti dev-overlay'dir, ürün değil.
- Flutter web canvas'tır: dışarıdan sentetik tık ulaşmıyor (iki deneme + Kapat düğmesi de yanıtsız). Niyet adımının piksel kanıtı yalnız web'de; Flutter karşılığı widget testiyle (`onboarding_niyet_akis_test.dart` 4/4).
- Web'de maskot, çerez onayı verilmeden DOM'a girmiyor (bilinçli — `MascotFab.tsx`). Kareler için önce "Tümünü kabul et"e basıldı.

## Kareler (`03-canli-dogrulama/`)

| # | Dosya | İçerik |
|---|---|---|
| 1 | `fl-landing-desktop.png` | Flutter hero |
| 2 | `web-landing-desktop.png` | Web hero |
| 3 | `fl-landing-mobile.png` | Flutter hero mobil |
| 4 | `web-landing-mobile.png` | Web hero mobil |
| 5 | `fl-welcome-desktop.png` | Flutter karşılama hapları |
| 6 | `web-niyet-desktop.png` | Web niyet sorusu (maskot→soru) |
| 7 | `fl-kesfet-desktop.png` | Flutter Keşfet sekmesi |
| 8 | `web-kesfet-desktop.png` | Web Keşfet sayfası |
| 9 | `fl-niyet-desktop.png` | Deneme karesi (karşılamada kaldı — bkz. kısıt) |

## Hükümler

### Landing — GEÇTİ
Rozet, H1 (3 satır kırılımı dahil), açıklama, URL kutusu + CTA, 4 güven rozeti, telefon mockup'ı, maskot balonu iki tarafta da aynı. Mobil: aynı iskelet, rozetler iki tarafta da 2+2'ye yakın sarıyor.
Bilinçli farklar (iş değil): nav etiketi `Çıkış Yap` vs `Giriş Yap` (uygulama açılışta anonim oturum kuruyor, web kurmuyor — mimari); URL öneki `vixrex.com/v/` (dekoratif, genişlik-bağımlı) vs gerçek origin; mockup slayt içeriği (tanıtım verisi); çerez bandı yalnız web'de.

### Akış 1 niyet sorusu — GEÇTİ (piksel web + işlev Flutter)
Web: maskot → `Hızlı Seçenekler` → soru + kategori ızgarası (emojili) + `veya` + serbest metin + `‹ Geri` — karede. Flutter: karşılama hapları karede (`Hazır Vitrin Seç / Sıfırdan Oluştur / Bakınıyorum`); soru adımı widget testiyle kilitli (soru balonu, `KategoriSecici`, `veya`, ipucu, `‹ Geri`, kategoriye dokununca ön-filtreli Keşfet). Mikro-fark: anlat-butonu Flutter'da kutunun üstünde (spec'te kayıtlı).

### Keşfet — GEÇTİ
Yan menü, başlık + alt başlık, arama, grup + kategori çipleri, kartlar (KİRALIK şeridi, `Aylık 299 TL · 14 gün ücretsiz dene`, `İncele/Kirala`) — aynı mağazalarla birebir. Başlık şeridi oturuma göre farklı (`Misafir girişi…` vs `Yayında değil…` — durum, tasarım değil). Mikro: Flutter butonlarında ikon var, web'de yalnız metin.

### Akış 2 & 3 — piksel yok, sözleşme var
Köprü (`/rent-demo`) ve bağlama paneli kiralık/hesap durumları istiyor — canlı kare çekilmedi; `kiralama_kopru_contract` (6) + `kirala-kopru-senkron` (4) + `landing-hesap-baglama-paritesi` + `hesap_baglama_test` kilitliyor.

## Kapsam-dışı gözlemler (iş açılmadı)

- `AppEmptyState` 800×600'de 129px taşıyor (widget denemesinde yakalandı) — hata/boş durum, küçük pencere.
- Web sol-alttaki "N" rozeti (üçüncü parti bildirimi sandık) Flutter'da yok — çerez bandıyla aynı aileden, bakılmadı.
- `vixrex.com/v/` öneki sabit metin (`landing_hero_section.dart:511`) — dekoratif, link üretimi `PublicSiteConfig`'te.
