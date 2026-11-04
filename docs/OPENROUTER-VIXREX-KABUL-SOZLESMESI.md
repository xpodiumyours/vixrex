# Faturadan vitrine — OpenRouter ↔ Vixrex kabul sözleşmesi

Durum: PR #741 için bağlayıcı uygulama ve denetim ölçütü · 2026-11-04

## 1. Ürün kararı

OpenRouter faturadan kullanılabilir ürün kartını üreten akıllı üretim merkezidir. Vixrex aynı zihinsel işleri tekrarlamadan kartları teslim alır; kayıt, fiyatlandırma ve esnafın tek ekran/tek tuş yayın sürecinden sorumludur.

Çalışan canlı sistem korunur. Bu belge yayın akışını veya mağaza davranışını kendiliğinden değiştirmez.

## 2. Tek görev sahibi

| İş | Tek sahip |
|---|---|
| Faturayı okuma, özgün satırları ve fatura değerlerini çıkarma | OpenRouter okuma preset'i |
| Marka/üretici ve resmî siteyi bulma | OpenRouter kart preset'i |
| Fatura satırını resmî ürünle eşleştirme ve belirsizliği bildirme | OpenRouter kart preset'i |
| Resmî görseli araştırma ve seçme | OpenRouter kart preset'i |
| Aynı ürünü tekilleştirme ve kanonik satırı seçme | OpenRouter kart preset'i |
| Başlık, marka, kategori, varyant ve açıklamayı yazma | OpenRouter kart preset'i |
| Satır kimliği, fatura verisi ve kanonik ilişkinin taşıma bütünlüğü | Vixrex |
| Mağaza yetkisi, idempotency, hata/retry ve güvenli kayıt | Vixrex |
| Seçilen görseli güvenle indirme ve depolama | Vixrex |
| Satış fiyatı, stok, esnaf onayı ve vitrinde yayınlama | Vixrex + esnaf |
| Üretici izin durumu ve kanıt geçmişi | Vixrex + esnaf/üretici |

Vixrex'in ürün kararı vermeden yaptığı biçimsel denetimler görev tekrarı değildir. Vixrex barkod/ad/beden/doğrulama durumuna bakarak OpenRouter'ın tekilleştirme kararını ikinci kez vermez.

## 3. Üretici izni — esnafın iş kararı

- Üretici izni yayın için ön şart değildir ve çalışan sistem durdurulmaz.
- Esnaf ürünü tek ekran ve tek tuşla yayınlayabilir; izin süreci yayınlamayı engellemez.
- Kanıt yoksa iç durum **Üretici izni bekleniyor** olur.
- Bu durum yalnız esnafın yönetim/vitrin önizleme görünümünde gösterilir; tüketiciye gösterilmez.
- OpenRouter'ın `authorized` veya benzeri beyanı gerçek üretici izni kanıtı değildir.
- Model beyanı `verified_supplier_permission` olarak kaydedilmez.
- Kanıt sonradan eklenebilir; mevcut ürün ve yayın korunur. Onaylayan kişi, tarih ve kanıt kaynağı denetim geçmişine yazılır.

## 4. Zorunlu mühendislik değişmezleri

1. Okuma ve kart presetlerinin her ikisi de sürümlü, katı JSON şeması kullanır.
2. Vixrex gelen cevabı aynı şemanın zorunlu alanlarıyla doğrular; bozuk kayıtları sessizce atmaz.
3. Satış fiyatı veya stok OpenRouter'dan gelirse cevap kabul edilmez.
4. Özgün fatura satırı, barkod, ürün kodu, miktar, birim, alış fiyatı ve tutar değişirse cevap kabul edilmez.
5. Mükerrer veya fatura dışı satır kimliği sessizce kabul edilmez.
6. `duplicate_group` ve `canonical_row_id` taslak ve ürün kaydı boyunca korunur. Kanonik olmayan satırın ikinci ürünü açmadığı uçtan uca test edilir.
7. Mağazada daha önce var olan ürüne bağlanma, fatura içi tekilleştirmeden ayrı bir iştir; OpenRouter'ın kanonik kararını değiştiremez.
8. Akış bayrağı iş başında kaydedilir ve iş bitene kadar sabit kalır; okuma ve kart aşamaları farklı bayrak kullanamaz.
9. Yeni yolda Vixrex görsel araştırması/seçimi yapmaz. Güvenli indirme için yapılan teknik kontroller ürün araştırması değildir.
10. Dış URL erişimlerinde yönlendirmeler ve çözülen IP adresleri dahil özel/yerel ağ koruması uygulanır.
11. Repo preset kopyası, canlı designated sürüm kimliği ve sistem talimatı parmak iziyle eşleşir.
12. Eski `mevcut` akış geri dönüş için korunur; yeni akış açıkça ve kontrollü etkinleştirilir.

## 5. Bağımsız denetimden gelen kabul kapıları

- [ ] OpenRouter tekilleştirir; Vixrex yeniden ürün kimliği kararı vermez.
- [ ] Kanonik olmayan satır için ayrı ürün açılmadığı kanıtlanır.
- [ ] Okuma ve kart çıktıları uçtan uca katı şemayla doğrulanır.
- [ ] İş bazlı bayrak iki aşamada aynı kalır.
- [ ] Model izin beyanı doğrulanmış izne dönüşmez; yayın engellenmez.
- [ ] Dış URL güvenlik testleri geçer.
- [ ] Canlı preset sürümleri ve repo parmak izleri eşleşir.
- [ ] Aynı gerçek faturalar eski ve yeni akışla karşılaştırılır.
- [ ] Odak testleri, ilgili regresyon testleri, tip/lint ve CI başarılı olur.
- [ ] Bağımsız inceleme bulguları kapatılır veya gerekçesi yazılır.

## 6. Yayın sınırı

Bu PR'ın draft durumundan çıkarılması bütün zorunlu kapıları gerektirir. Merge, canlıda `PRESET_AKIS=yeni` açma, preset yazma/designated değiştirme, deploy, migration ve mağaza yayını ayrı onay gerektirir.
