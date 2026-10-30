# Vixrex × OpenRouter — Takip

Durum sözlüğü: **BEKLİYOR · YAPILIYOR · BİTTİ · SENDE**

| # | İş | Durum |
|---|---|---|
| 0 | Presetlerin içinde gerçekten ne olduğunu okumak (ücretsiz, kod değişmez) | BİTTİ — 5 preset okundu, hepsinin modeli/araçları/istemleri ölçüldü |
| 1 | İki karar: ürün fotoğrafı nereden gelecek + arama kilidi nerede duracak | BİTTİ — fotoğraf yalnız açılan resmî sayfadan (yoksa boş), arama kilidi istek seviyesinde; ikisi de sınırı bozmadı |
| 2 | Kart şemasını makineye zorunlu hale getirmek | BİTTİ — şema OpenRouter'da zorlanıyor; Vixrex'teki son satır da temizlendi, kilit artık presetin kendisinde |
| 3 | Satır başına iş: tek satırın hatası tüm faturayı düşürmesin | BİTTİ — kurtarılan satır kartını alır, kurtarılamayan fatura verisiyle "Araştırılamadı" olarak kalır; tek satır faturayı düşürmez (PR #698 birleşti, canlı ölçüldü: 4078bc04) |
| 4 | Araştırmayı tek yere toplamak: çift ücret ve çelişki bitsin | BİTTİ — okuma presetinde araç yok, araştırma yalnız kartta; yeni içerik canlı adlara da yüklendi (okuma v19, kart v8 — depoyla birebir, eski sürümler panelde duruyor) |
| 5 | Kanıt kapısı: uydurma ürün sayfası "resmî kaynak" olamasın | BİTTİ — kural kart presetinde: yalnız web_fetch ile gerçekten açılan resmî sayfa kanıttır; firma tespiti + dijital iz + pazar yeri gri listesi de aynı presette (canlı kart v8, depoyla birebir) |
| 6 | Para sayacı ve süre bütçesi | BEKLİYOR |
| 7 | Gerçek faturayla canlı deneme — yalnız senin onayınla | BEKLİYOR |
| 8 | Görev metinlerine aşama etiketleri: okuma "oku–grupla", kart "siteyi bul–sayfayı aç–doğrula–kartı yaz" | BİTTİ — test kopyaları v4/v5, canlı adlar dahil her yerde depoyla birebir |
| 9 | Esnaf bekleme ekranı: animasyonlu, adım adım ilerleyen (fatura okunuyor → ürünler araştırılıyor → kartlar hazır) | BİTTİ — adımlar gerçek aşamayla yanıyor; PR #697 birleşti ve canlıya çıktı (bkz. 12) |
| 10 | Gerçek modellerle (qwen + deepseek) uçtan uca test | BİTTİ — krediyle koşuldu (yalnız foto girdisi): okuma %98,08 (13/13 satır, 6.034,00 TL birebir), kartlar 13/13 gerçek araştırma üretti (üretici firma + gerçekten açılan resmî sayfalar, durumlar dürüst: 4 doğrulandı / 5 belirsiz / 4 bulunamadı); masraf 0,17 $ |
| 11 | Yol üstünde bulunan: fatura-otomatik-taslak-kaydi.test.ts kırmızı | BİTTİ — test #694'ten sonraki davranışı bekliyor: parçayı başlatan artık üç kart sınırı değil zaman bütçesi; savlar aynı kaldı, dosyanın 8/8'i yeşil |
| 12 | Canlıya çıkış (commit → ana dal → vixrex.com) | BİTTİ — PR #697 birleşti, canlı ölçüldü: vixrex.com yeni commit'i sunuyor (geri alma: PR'ı revert et; presetlerde panelde eski sürüme tek tık) |

| 13 | Ücretsiz puan kartı koşusu (ücretli test öncesi ön kontrol) | BİTTİ — gerçek fiş verisiyle (13 satır/75 adet/6.034 TL) ölçüldü: okuma 13/13 satır + tutar birebir, kart fatura değerlerini 13/13 korudu, fiyat uydurmadı; tek kusur renk/beden karışması + ücretsiz modelde araştırma olmaması ([tool/puan-karti.py](tool/puan-karti.py)) |
| 14 | Okuma presetinde varyant/beden ayrımı tanımsız: renk+beden tek alana yazılıyor (ölçümde 0/13) | BİTTİ — kategori detaylı varyant kuralı yazıldı (tekstil: renk/kalıp; gıda: lezzet/paket; beden ve gramaj kendi alanında); canlı okuma v20 + ayna v5, depoyla birebir; ölçüm 0/13 → 13/13 |
| 15 | Gerçek senaryo testi: yalnız fatura fotoğrafı → ürün kartları (ücretsiz) | BİTTİ — foto girdisiyle ölçüldü: okuma %97,12 (13/13 satır, 6.034,00 TL birebir, varyant 13/13), kart 13/13 satır + fatura değerleri korundu + fiyat uydurma yok; ücretsiz modelde şema/araştırma yok ([tool/puan-karti.py](tool/puan-karti.py)) |

| 16 | Kart modeli şemayı düz/karma yazıyor (iç içe alanlar köke serilmiş): bu biçim eski ayrıştırıcıda 13 kartın hepsini reddederdi | BİTTİ — ayrıştırıcı iki biçimi de kabul edecek esnetildi (faturaKartPreset.ts), gerçek model biçimi testlerle kilitlendi (sözleşme testi 10/10); kapılar yeşil, tek kırmızı #11'in bilinen eski testi |

| 17 | Kart görselleri 13/13 boş geliyor: web_fetch modele yalnız metin döndürüyor, görsel adresi hiç ulaşmıyor | BİTTİ — görsel artık modelin gerçekten açtığı resmî sayfadan Vixrex tarafından çıkarılıyor (og:image); güvenlik kapıları aynı (yalnız https, özel adres yok, süre sınırı, Bulunamadı satırına fotoğraf yapışmaz); PR #699 birleşti ve canlı ölçüldü: vixrex.com 8c162aa7 sunuyor; testler 13/13 yeşil, kapılar yeşil, tek kırmızı #11'in bilinen eski testi |

| 18 | T1+K3 durum dili + yanlış çakışma alarmı: taslakta hiçbir şey yokken "Canlı vitrin değişmiş" bandı çıkıyor, "CANLI" kelimesi iki anlamda, taslak bandı yayındaki vitrinde bile "henüz yayında değil" diyor | BİTTİ — kök düzeltme göçü + dil tekilleştirmesi (10 dosya), kapılar yeşil (2109 test + tsc + lint + build + Flutter şema); PR #700 birleşti ve canlı ölçüldü: vixrex.com fb55f85e sunuyor, /kesfet "AÇIK" rozetini servis ediyor; göç canlı veritabanına bu yayında uygulandı |

| 19 | Ürün kartlarında mağaza konumu zorunluluğu + yerel SEO ("en yakın X nereden" sorguları) | BİTTİ — konum altyapısı yerindeydi (kartlarda konum butonu, vitrinde LocalBusiness+GPS); eksik kalan ürün sayfasının arama verisine satıcı konumu (adres+GPS) bağlandı, vitrine hasMap eklendi; esnaf akışı yavaşlamadı, görünür değişiklik yok; kapılar yeşil (2111 test + tsc + lint + build); commit/Casper onayı bekliyor |

Kural: aynı anda tek iş. Her iş bitince tek cümle rapor. Canlıya çıkış yalnız Casper'ın onayıyla.
