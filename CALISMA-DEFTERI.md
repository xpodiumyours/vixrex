# VixRex Çalışma Defteri — tek gerçek kaynak adayı

Sahip: Furkan Aksakal (Casper)
Proje: C:\Projects\vixrex
Canlı: https://www.vixrex.com (vitrin var, kullanıcı yok, fatura akışı canlıda yok)
Aktif dal (2026-10-07 ölçüm): fatura/kart-kaynagi
Remote: https://github.com/xpodiumyours/vixrex.git
Son commit: 8ff0caaf feat(fatura): kart gorseli firmanin kendi sayfasindan gelir

## Kural
1. Her işlem bitiminde bu dosya güncellenir: tarih + ne yapıldı + kanıt + kalan.
2. Sohbet yenilenirse kaldığın yer: "Açık Konular" tablosundaki İŞARETLİ satırdır.
3. Eski notlara inanma: docs/, .scratch/, yedeklerdeki her şey iddia sayılır. Kanıt = dosya yolu + satır + çalıştırılan komut çıktısı.
4. Kod değişikliği yok, sormadan uygulama yok. Kural kaynağı: AGENTS.md.

## Vizyon (1 cümle)
Üretici ile küçük esnaf arası fatura-fotoğrafından ürün kartı köprüsü, esnaf ile tüketici arası otomatik dijital vitrin.

## Açık Konular — parçalanmış takip

| ID | Konu | Durum 2026-10-07 | Kanıt / Not | Sıradaki |
|----|------|------------------|-------------|----------|
| P1 | Bakkal senaryosu (barkodlu) fizibilite | KABUL — mümkün | Barkod + GTIN eşleşme standart mimari | Fatura-oku maliyetine bağla |
| P2 | Tuhafiye / iç giyim yarım vitrin | KABUL — yarım kapsama MVP olur | Dijital izi güçlü firma şartı | Kapsam dışı sayma, eksik satırı koru |
| P3 | Aktar yarı barkodlu senaryo | KABUL — yarım kapsama | Aynı kural | Aynı |
| P4 | Ajan bataklığı / çelişkili belgeler | SÜRÜYOR | AGENTS.md A.14: çelişki = eski kopya. 71 dal / 46 worktree ölçümü 2026-10-03 | Dal envanteri: tool/dal-durumu.sh koşulmadı |
| P5 | AI maliyet kavgası | KARAR BEKLİYOR | 2026-10-04 ölçüm: 6 okuma 0.58 TL. Güncel plan: arama ücreti tavana yazılmıyor (faturaMaliyet.ts:4) | Luna web_search ücreti tavana eklenecek mi? |
| P6 | İzin paradoksu (çalışmayana kim izin verir) | KABUL — sıra: önce çalışan demo | MASTER-PLAN Madde 23: teknik eksik izin arkasına saklanmaz | Işılay 16747 tam görsel yok, demo eksik |
| P7 | Teknik faz F0-F8 / Dilim 1-5 | SÜRÜYOR — dalda, canlıda değil | Güncel plan: docs/FATURA-URUN-KARTI-PLAN.md. Dilim 1-4 bu dalda yazıldı, Dilim 5 koddaydı. Canlıya alınmadı | Dilim 1: okuma-arama ayrımı + original + şemadan fotoğraf çıkarma |
| P8 | Işılay 16747 kabul örneği | EKSİK | 14544 bilgi fişi + e-Arşiv, 8 adet, 450 TL birim. Tam resmi görsel doğrulanmadı | F3-F4 işi |
| P9 | Canlıda kullanıcı yok | DOĞRULANDI | webfetch 2026-10-07: ana sayfa vitrin anlatıyor, fatura girişi yok | Önce demo, sonra esnaf denemesi |

## Son konuşma (2026-10-07)
- Furkan: ajanlarla anlaşamıyoruz, vibe-coding yığını, maliyet için memur gibi iş dağıtıldı, izin için durdurulduk, boşa mı uğraşıyorum?
- Tespit: vizyon mümkün, sıra hatası + tek kaynak yokluğu var.
- İstek: kaybolmayan defter + parça parça takip.

## Dilim-1 tespiti (2026-10-07, dokunmadan)
- faturayiOku public_web/src/lib/faturaGoru.ts:330-362 : araç yok, reasoning none, detail original, şema FATURA_SEMA:123-177 site fotoğraf/açıklama içermiyor. UZUN_KENAR_SINIRI:33 = 65535.
- Site kilidi + satır araması public_web/src/app/api/fatura-oku/route.ts:266-305 bağlı, satirSitesindeAra:273-307 low + allowed_domains.
- Artık: GoruSatiri:55-69 hala siteAciklama/siteGorsel/siteSayfa taşıyor, 420-422 boş yazılıyor. Şema temiz, tip artığı duruyor.
- Önerilen değişiklik: yalnız bu 3 alan + 420-422 + 224-226 geçişi temizlenir. Başka satıra dokunulmaz.
- Dokunulmayacak: fotografUrunCikar.ts, products/batch, şema, canlı, veritabanı.

## Sonraki adım
P7-Dilim-1'e girmeden önce P4 dal envanterini mi koşalım, yoksa direkt Dilim-1 tespitine mi geçelim?
Seçim (2026-10-07): Dilim-1 tespiti — üstte yazıldı. Onay beklenir: tip artığı temizlensin mi?
Onay (2026-10-07): evet — 9 satır silindi (faturaGoru.ts:55-69 interface, 420-422 eşleme, route.ts:224-226 geçiş).
Kapılar: tsc --noEmit temiz, vitest 3 dosya 34/34 geçti.
Konum: dal fatura/kart-kaynagi, main değil, canlı değil. Geri alma: git checkout -- public_web/src/lib/faturaGoru.ts public_web/src/app/api/fatura-oku/route.ts
Değişiklik commitlenmedi (2 dosya M). CALISMA-DEFTERI.md untracked.

## Sıradaki (2026-10-07)
Dilim-1 kod temizliği bitti. Plana göre Dilim 2-5 bu dalda yazılı görünüyor, doğrulaması yok. Mantıklı sıra: Dilim-2 tespiti (dokunmadan) → sonra commit + önizleme kanıtı.
KARAR (2026-10-07): önizleme kanıtı kuralı kaldırıldı — AGENTS §19 + merge-hazir.sh kapısı + ci.yml preview-kaniti job + preview_kaniti.py ve testi + PR şablonu satırı. Kapılar: bash -n temiz, CI script testleri 11/11 geçti.
