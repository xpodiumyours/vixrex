# Vixrex — Başlangıç

Bu sayfa projenin haritası. Bir şey aradığında buradan başla.

## Ne yapıyoruz

Türkiye'deki küçük işletmeler için **dijital vitrin**. Esnaf kendi vitrinini
sohbet ederek düzenliyor, kod bilmesi gerekmiyor.

Yol: 100 hazır vitrin → kiralama → satış / B2B.

Vizyonun tamamı (katman mimarisi, kurye/teslimat ve tüketici uygulaması
fikirleri, konum kuralı): [[vizyon-katman-mimarisi-2026-08-17]].

## Karar ve kurallar

- [[VIXREX_RULES]] — **değişmez kurallar.** Bir tartışma çıktığında buraya bakılır
- [[vixrex-asistan-13-faz-plani-2026-08-06]] — tamamlanmış 13 fazın tarihsel planı
- [[tek-asistan-plani]] — dört yüzey/üç beyin sorununu kapatan plan (tamamlandı, bkz. CONTEXT.md)
- [[AGENTS]] — yapay zekâ ajanlarının uyacağı kurallar
- [[repository-guide]] — modelden bağımsız teknik depo haritası
- [[store-editor-controller-parcalama]] — devam eden controller parçalama işinin durumu; buna dokunmadan önce oku
- [[triage-labels]] — issue etiket sözlüğü
- [[casper-calisma-notu-2026-08-17]] — kullanıcıyı tanıma notu; her oturum başında CONTEXT.md ile birlikte okunur

## Yayına çıkarken

- [[yayina-cikis-kontrol-listesi]] — **canlıya çıkmadan önce mutlaka**
- [[google-gorunurluk]] — Google'da nasıl bulunuruz
- [[seo-mimari-plani]] — SEO mimarisi planı

## Hukuk

- [[vixrex-hukuki-uyum-2026-08-05]] — araştırma
- [[2026-08-05-vixrex-hukuki-uyum-degerlendirme]] — değerlendirme

## Teknik ayrıntı

- [[vitrin-alan-semasi]] — esnafın düzenleyebildiği 41 alan
- [[domain]] — kavramlar
- [[issue-tracker]] — iş takibi; aktif plan ve durum GitHub Issues içindedir
- [[adresler]] — hangi adres hangi yüzey, tek kart
- [[akis-envanteri]] — Next.js akış envanteri (VAR/YARIM/YOK/BİLİNÇLİ YOK)
- [[kabul-senaryosu]] — esnafın uçtan uca yaşayacağı yol
- [[oauth-client-secret-setup]] — Google OAuth client secret kurulumu ve sızıntı geçmişi
- [[dal-durum-haritasi]] — dal durum haritası
- [[durum]] — güncel durum notları
- [[e2e-otomasyon-plani]] — E2E otomasyon planı
- [[kok-neden-arastirmasi]] — kök neden araştırmaları
- [[ui-tutarlilik-envanteri]] — Flutter panel UI tutarlılık envanteri (2026-08-08)
- [[vixrex-core-kalici-hesap-notu]] — kalıcı hesap sahipliği migration'ının kaydı (2026-08-26)
- [[vixrex-web-mobil-tamlik-denetimi-2026-08-30]] — web+mobil mimari tamlık
  denetimi (kod kanıtlı); güncel P0: ürün kategorisi Flutter'da ilişkisel
  tabloya yazmıyor. Bu, aynı konudaki eski `docs/web-mobil-tamlik-raporu-
  2026-08-27.md` raporunun yerini alır — o rapor artık kod ile çelişiyor.

## Şablon

Hedef kalite: `sablonlar/hedef-vitrin.html`

Bu dosya **hedeftir, kopyalanacak dosya değildir.** Görünüş oradan alınır,
içerik alınmaz — dosya teknik servis içeriğiyle dolu. Kategori farkları
yalnız `vitrinProfile.ts`'e satır eklenerek tanımlanır. Ayrıntı: [[VIXREX_RULES]]

---

## Bu kasa nasıl çalışıyor

Klasör projenin kendisi (`C:\Projects\vixrex`). Kod klasörleri gizlendi;
yalnız okunacak belgeler görünüyor.

- Sol üstten **arama** ile her belgede metin arayabilirsin
- Bir belgenin altındaki **backlink** bölümü, ona bağlanan diğer belgeleri gösterir
- **Graph** görünümü belgelerin birbirine nasıl bağlandığını çizer

Yeni not eklerken `docs/` içine koy ve buraya bir bağlantı ekle, kaybolmasın.
