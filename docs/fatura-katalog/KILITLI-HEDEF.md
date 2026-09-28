# Faturadan Güvenilir Dijital Kataloğa — Kilitli Hedef

Tarih: 2026-09-22  
Çalışma dalı: `work/fatura-katalog-e2e-20260922`

## Ana soru

> **Türk küçük esnafının faturadan güvenilir ve izinli dijital ürün kataloğuna geçişini nasıl otomatikleştiririz?**

Bu soru çalışma boyunca değişmeyecek. OCR, yapay zekâ, XML, barkod, üretici araştırması ve testler yalnız bu hedefe hizmet eden araçlardır.

## Ana çalışma kuralı

> **İzi güçlü ürünü otomatik hazırla. İzi zayıf ürünü tahmin etme. Eksik kanıtı esnafa veya tedarikçiye sor.**

Üç sonuç vardır:

1. **Güçlü iz → otomatik taslak hazırla.**
2. **Kısmi iz → yalnız eksik kritik bilgiyi sor.**
3. **Zayıf iz → ürün uydurma; dur ve neyin eksik olduğunu açıkça söyle.**

Bu kural ürün kimliği, tedarikçi kimliği, ürün açıklaması, görsel ve kullanım izni için ayrı ayrı uygulanır.

## Uçtan uca hedef akış

1. Esnaf fatura / sipariş belgesi / e-Fatura verir.
2. Vixrex belgedeki ham gerçekleri çıkarır; internetten gelen bilgi belge gerçeğinin yerine geçmez.
3. Tedarikçi kimliği doğrulanır.
4. Ürün kimliği barkod/GTIN, SKU/model, ürün adı ve diğer kanıtlarla çözülür.
5. Ürün dijital kaynağa bağlanır: önce Vixrex hafızası, sonra izinli üretici/tedarikçi XML/API/feed, ardından doğrulanmış resmî kaynaklar.
6. Her bilgi için kaynak ve güven seviyesi tutulur.
7. Ürün verisi ve görseli için kullanım dayanağı kontrol edilir.
8. Yeterli kanıt varsa yayın ürünü değil, **taslak ürün kartı** hazırlanır.
9. Esnaf satış fiyatını ve gerekli alanları kontrol eder.
10. Esnaf onaylamadan hiçbir ürün müşteriye açılmaz.
11. Onaylanan ürün mevcut Vixrex Product CORE üzerinden aynı vitrine yazılır.

## İlk kanıt hedefi

Önce bir üretici üzerinde uçtan uca çalışan gerçek kanıt kurulacak.

Bu üretici:
- faturada ürünleri kararlı biçimde ayırt edebilen bir kimlik taşımalı,
- aynı ürünler resmî dijital kaynakta bulunabilmeli,
- ürün adı/görsel/özellik eşleştirmesi kanıtlanabilmeli,
- ürün verisi ve görsellerinin kullanım izni için açık bir yol bulunmalı.

**Tutku/Seher Mensucat ilk güçlü adaydır; ancak sistem Tutku'ya özel yazılmayacak.** Üretici yalnız standardı kanıtlamak için örnek olacaktır.

Kabul kanıtı:

`gerçek fatura → tedarikçi → ürün kimliği → resmî dijital ürün → izin durumu → Vixrex taslak kartı`

zinciri tek firmaya özel parser veya sabit ürün listesi olmadan çalışmalıdır.

## Üretici havuzu ne zaman?

Şimdi üretici havuzu oluşturmak hedef değildir.

Önce:
1. üretici uyumluluk standardı,
2. ortak kanıt/izin sözleşmesi,
3. bir üreticide gerçek çalışan akış,
4. kısa gerçek demo videosu

tamamlanır.

Bundan sonra üreticiye:

> “Ürünlerinizi satan esnafların faturadan otomatik vitrin hazırlamasını sağlayan sistem hazır. Esnaflarınıza bunu sunabilmemiz için ürün verisi/görselleri için tek bir kurumsal izin adımı kaldı.”

denebilecek noktaya gelinir.

İzin veren üreticiler daha sonra doğrulanmış üretici havuzuna alınır. İlk hedef kitle, bu üreticilerden mal alan küçük esnaflardır.

## Yapılmayacaklar

- Her firmaya ayrı fatura kalıbı yazılmayacak.
- Barkod bütün faturalar için zorunlu kabul edilmeyecek.
- Zayıf dijital izde ürün tahmin edilmeyecek.
- Rastgele web görseli ürün kartına alınmayacak.
- Alış fiyatı satış fiyatına çevrilmeyecek.
- Üretici izni varsayılmayacak.
- AI çıktısı kanıt olmadan gerçek kabul edilmeyecek.
- Yeni bir Product sistemi kurulmayacak; mevcut Product CORE kullanılacak.
- Test/benchmark çalışması ürün hedefinin önüne geçirilmeyecek.
- Kullanıcı onayı olmadan PR, merge, deploy veya canlı migration yapılmayacak.

## Başarı tanımı

Esnafın elindeki gerçek bir tedarikçi belgesinde Vixrex:

- emin olduğu ürünleri kanıtlarıyla hazırlar,
- emin olmadığı ürünleri uydurmaz,
- gerekli yerde yalnız eksik bilgiyi sorar,
- izinli dijital ürün verisi/görseliyle kartı zenginleştirir,
- kartı esnafın kontrolüne sunar,
- esnaf onayından sonra mevcut vitrinde yayınlar.

Bu akış çalıştığında OCR özelliği değil, **faturadan güvenilir ve izinli dijital kataloğa geçiş ürünü** tamamlanmış sayılır.
