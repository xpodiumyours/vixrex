# Vixrex Gelişim Sistemi

Bu sistem bir ajana veya araca özel değildir. Vixrex'te çalışan herkes aynı
Anayasa'yı, aynı kayıt biçimini ve aynı GitHub kapısını kullanır. Araçlara özel
komut dosyaları ortak kural değildir ve başka bir aracın çalışmasını
engelleyemez.

Kaynak: GitHub Spec Kit. Yeni özelliklerin çekirdek yolu Specify → Plan →
Tasks → Implement → Converge'dir. Clarify, Checklist ve Analyze ihtiyaç
duyulan kalite kapılarıdır. Vixrex bu çekirdeğin başına kendi **Keşif**
halkasını ekler: Furkan doğal Türkçeyle isteğini söyler, üretici bugünkü
çalışan hâli ölçer ve işin nereden başlayıp nerede biteceğini, ne ve nasıl
gözükeceğini, esnafa, Vixrex'e ve tüketiciye ne katacağını yazar.

## 1. Yeni özellik veya davranış değişikliği

Zorunlu sıra:

1. **Anayasa** — Değişmez ürün ve güvenlik ilkelerini oku.
2. **Keşif** — Bugünkü çalışan hâli ölç, işin sınırlarını ve kazancını yaz,
   Furkan'ın onayını al. Onay gelmeden sonraki adım başlamaz.
3. **Specify** — Ne yapılacağını, kullanıcı sonucunu ve kabul koşullarını yaz.
4. **Clarify** — Belirsizlikleri araştır; yalnız gerçek sahip kararlarını sor.
5. **Plan** — Mevcut sistemi ölç ve bütün etkilenen yüzeylerle çözümü kur.
6. **Checklist** — Gereksinimlerin eksiksiz ve ölçülebilir olduğunu kontrol et.
7. **Tasks** — İşleri bağımlılık sırasına koy.
8. **Analyze** — Anayasa, istek, plan ve görev çelişkilerini bul.
9. **Implement** — Onaylanan sonucu uygula.
10. **Converge** — Uygulama ile kayıtları karşılaştır ve eksikleri bul.
11. **Tekrar** — Eksik varsa Implement ↔ Converge döngüsünü sürdür.
12. **Review / PR** — Bağımsız inceleme ve ortak kontrollerden geçir.

Kayıtlar `specs/<iş-kimliği>/` altında tutulur: `kesif.md`, `spec.md`,
`plan.md`, `tasks.md`, `checklists/requirements.md`, `analysis.md`,
`convergence.md`, `review.md` ve `zincir.md`.

## 2. Keşif halkası

Keşif, Vixrex'in Spec Kit'e eklediği tek halkadır ve her zaman ilk yazılan
belgedir. Şablonu `.specify/templates/kesif-template.md` dosyasındadır.

Keşif şu soruları cevaplar:

- **Bugün ne var?** Tahmin değil ölçüm. Her cümle gerçek bir dosya yoluna
  dayanır (`ÖLÇÜLDÜ:` satırları). Gösterilen yol depoda yoksa merkezi kontrol
  kırmızı verir — böylece görmeden yazılan "bugün şöyle" cümlesi geçmez.
- **Gelişim nereden başlar?** Zincirin ilk kırık halkası.
- **Nerede biter?** Hangi ekranda ne doğru göründüğünde iş bitmiş sayılır.
- **Ne gözükecek?** Kullanıcının ekranda göreceği somut bilgi.
- **Nasıl gözükecek?** Yerleşim, dil, boş ve hatalı hâller.
- **Kim ne kazanır?** Esnaf, Vixrex ve tüketici için ayrı birer satır.
- **Neye dokunulmayacak?** Kapsam dışı bırakılanlar.
- **Karar gerekiyor mu?** Yalnız gerçekten Furkan'ın kararı olan tek soru.

Keşif Furkan tarafından onaylanmadan Specify başlamaz. Onay kayda
`ONAY: alındı` satırıyla geçer ve PR'da görünür.

## 3. Hata düzeltmesi

Hata düzeltmesi gereksiz belge üretmez. Zorunlu sıra:

1. Anayasa sınırlarını kontrol et.
2. Hatayı yeniden gör ve kanıtını kaydet.
3. Görünen belirtiyi değil gerçek sebebi bul; sebebi gerçek bir dosya yoluyla
   göster (`ÖLÇÜLDÜ:` satırı).
4. Düzeltme görevlerini bağımlılık sırasına koy.
5. En küçük doğru düzeltmeyi uygula.
6. Asıl hatayı ve etkilenen yolu tekrar dene.
7. Eksik varsa Implement ↔ Converge döngüsünü tekrarla.
8. Bağımsız inceleme ve PR.

Kayıtlar aynı iş klasöründe `root-cause.md`, `tasks.md`, `convergence.md`,
`review.md` ve `zincir.md` dosyalarıdır. Düzeltme yeni kullanıcı sonucu, veri
yapısı, güvenlik kuralı, ekran akışı veya yayın davranışı doğuruyorsa tam
zincire geçirilir.

## 4. Yeni fikir veya araştırma

Önce mevcut ürün ve kanıtlar araştırılır. Sonuç “yapalım”, “yapmayalım” veya
“karar için şu bilgi eksik” olarak kaydedilir. Karar verilmeden ürün kodu,
veritabanı veya yayın ayarı değiştirilmez. Araştırma kayıtları yalnız
`specs/<iş-kimliği>/` altında kalır; uygulama kararı verilirse yeni özellik
yolu başlatılır.

## Ortak GitHub kapısı

`zincir.md` dosyasının ilk bölümünde tam olarak bir iş türü bulunur:

- `İŞ TÜRÜ: özellik`
- `İŞ TÜRÜ: değişiklik`
- `İŞ TÜRÜ: hata`

GitHub kapısı seçilen iş türünün kayıtlarını kontrol eder. Kullanılan insan,
model, firma veya editöre bakmaz. Çözülmemiş belirsizlik, açık görev,
yakınsamamış uygulama veya hazır olmayan inceleme teslimatı durdurur.

Kapının aradığı dört somut şey:

1. **Aşama satırları** — `zincir.md` içinde birebir bu yazımla:
   özellik ve değişiklik için `- [x] Anayasa`, `- [x] Keşif`, `- [x] Specify`,
   `- [x] Clarify`, `- [x] Plan`, `- [x] Checklist`, `- [x] Tasks`,
   `- [x] Analyze`, `- [x] Implement`, `- [x] Converge`, `- [x] Review / PR`;
   hata için `- [x] Anayasa`, `- [x] Hata tekrarlandı`, `- [x] Sebep bulundu`,
   `- [x] Tasks`, `- [x] Implement`, `- [x] Converge`, `- [x] Review / PR`.
2. **Gerçek yollar** — `kesif.md` (en az iki satır) ve `root-cause.md` (en az
   bir satır) içindeki `ÖLÇÜLDÜ:` yolları depoda gerçekten bulunmalıdır.
3. **Kayıtta geçmeyen değişiklik yok** — PR'da değişen her ürün dosyası iş
   kayıtlarının içinde en az bir kez geçmelidir. Üretilen dosyalar
   (`*.g.dart`, kilit dosyaları) ve görsel karşılaştırma klasörleri dışarıdadır.
4. **Kapanış cümleleri** — `analysis.md` içinde `ÇELİŞKİ: YOK`,
   `convergence.md` içinde `SONUÇ: YAKINSADI`, `review.md` içinde
   `SONUÇ: İNCELEMEYE HAZIR`, `kesif.md` içinde `ONAY: alındı`.

Kapı belgelerin varlığını ve bu işaretleri ölçer; işin doğruluğunu ölçmez.
Doğruluğun kanıtı Anayasa'nın dördüncü ilkesindedir: gerçek kullanıcı yolu,
gerçek tarayıcı, yazılı adres.

## Yayın ayrı bir karardır

Ana dala alma canlı yayın değildir. Git kaynaklı otomatik yayın kapalı tutulur.
Canlı yayın ancak gelişim ve ürün kontrolleri yeşil, önizleme gerçek kullanıcı
yolunda doğrulanmış, geri alma yolu hazır ve Furkan açıkça yayın kararı vermişse
ayrıca başlatılır.
