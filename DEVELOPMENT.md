# Vixrex Gelişim Sistemi

Bu sistem bir ajana veya araca özel değildir. Vixrex'te çalışan herkes aynı
Anayasa'yı, aynı kayıt biçimini ve aynı GitHub kapısını kullanır. Araçlara özel
komut dosyaları ortak kural değildir ve başka bir aracın çalışmasını
engelleyemez.

Kaynak: GitHub Spec Kit. Yeni özelliklerin çekirdek yolu Specify → Plan →
Tasks → Implement → Converge'dir. Clarify, Checklist ve Analyze ihtiyaç
duyulan kalite kapılarıdır. Vixrex'te yeni özellik ve davranış değişiklikleri
için bu kapılar birlikte kullanılır.

## 1. Yeni özellik veya davranış değişikliği

Zorunlu sıra:

1. **Anayasa** — Değişmez ürün ve güvenlik ilkelerini oku.
2. **Specify** — Ne yapılacağını, kullanıcı sonucunu ve kabul koşullarını yaz.
3. **Clarify** — Belirsizlikleri araştır; yalnız gerçek sahip kararlarını sor.
4. **Plan** — Mevcut sistemi ölç ve bütün etkilenen yüzeylerle çözümü kur.
5. **Checklist** — Gereksinimlerin eksiksiz ve ölçülebilir olduğunu kontrol et.
6. **Tasks** — İşleri bağımlılık sırasına koy.
7. **Analyze** — Anayasa, istek, plan ve görev çelişkilerini bul.
8. **Implement** — Onaylanan sonucu uygula.
9. **Converge** — Uygulama ile kayıtları karşılaştır ve eksikleri bul.
10. **Tekrar** — Eksik varsa Implement ↔ Converge döngüsünü sürdür.
11. **Review / PR** — Bağımsız inceleme ve ortak kontrollerden geçir.

Kayıtlar `specs/<iş-kimliği>/` altında tutulur: `spec.md`, `plan.md`,
`tasks.md`, `checklists/requirements.md`, `analysis.md`,
`convergence.md`, `review.md` ve `zincir.md`.

## 2. Hata düzeltmesi

Hata düzeltmesi gereksiz belge üretmez. Zorunlu sıra:

1. Anayasa sınırlarını kontrol et.
2. Hatayı yeniden gör ve kanıtını kaydet.
3. Görünen belirtiyi değil gerçek sebebi bul.
4. Düzeltme görevlerini bağımlılık sırasına koy.
5. En küçük doğru düzeltmeyi uygula.
6. Asıl hatayı ve etkilenen yolu tekrar dene.
7. Eksik varsa Implement ↔ Converge döngüsünü tekrarla.
8. Bağımsız inceleme ve PR.

Kayıtlar aynı iş klasöründe `root-cause.md`, `tasks.md`,
`convergence.md`, `review.md` ve `zincir.md` dosyalarıdır. Düzeltme yeni
kullanıcı sonucu, veri yapısı, güvenlik kuralı, ekran akışı veya yayın davranışı
doğuruyorsa tam zincire geçirilir.

## 3. Yeni fikir veya araştırma

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

## Yayın ayrı bir karardır

Ana dala alma canlı yayın değildir. Git kaynaklı otomatik yayın kapalı tutulur.
Canlı yayın ancak gelişim ve ürün kontrolleri yeşil, önizleme gerçek kullanıcı
yolunda doğrulanmış, geri alma yolu hazır ve Furkan açıkça yayın kararı vermişse
ayrıca başlatılır.
