# Vixrex Gelişim Sistemi

Bu sistem bir ajana özel değildir. Vixrex'te çalışan bütün insanlar ve yapay
zekâ araçları aynı kayıtları, aynı sırayı ve aynı GitHub kapısını kullanır.

Kaynak: GitHub Spec Kit. Resmî çekirdek akış Specify → Plan → Tasks →
Implement → Converge'dir. Vixrex, geçmişte yaşanan belirsizlik, eksik yüzey,
sahte başarı ve yarım teslimat sorunları nedeniyle Clarify, Checklist, Analyze
ve Review aşamalarını her değişiklikte zorunlu tutar.

## Her değişiklikte zorunlu sıra

1. **Anayasa** — Değişmez ürün ve güvenlik ilkelerini oku.
2. **Specify** — Ne yapılacağını, kullanıcı sonucunu ve kabul koşullarını yaz.
3. **Clarify** — Belirsizlikleri araştır; yalnız gerçek sahip kararlarını sor.
4. **Plan** — Mevcut sistemi ölç ve bütün etkilenen yüzeylerle çözümü kur.
5. **Checklist** — Gereksinimlerin eksiksiz, ölçülebilir ve çelişkisiz olduğunu
   bağımsız olarak kontrol et.
6. **Tasks** — İşleri bağımlılık sırasına koy.
7. **Analyze** — Anayasa, istek, plan ve görevler arasındaki çelişkileri bul.
8. **Implement** — Yalnız onaylı kayıtları uygula.
9. **Converge** — Kod ile kayıtları karşılaştır; eksikleri görevlere ekle.
10. **Tekrar** — Eksik varsa Implement ve Converge aşamalarını yakınsayana kadar
    tekrarla.
11. **Review / PR** — Üreticiden bağımsız inceleme yap; ortak kontroller
    geçmeden teslim etme.

## Tek kayıt yeri

Her iş `specs/<iş-kimliği>/` altında şu dosyaları taşır:

- `spec.md`: görünür sonuç, kapsam ve kabul koşulları
- `plan.md`: bugünkü durum, çözüm, güvenlik, geri alma ve doğrulama
- `tasks.md`: bağımlılık sırasındaki görevler
- `checklists/requirements.md`: gereksinim kalite kontrolü
- `analysis.md`: plan ve görev çelişkileri
- `convergence.md`: uygulama sonrası eksikler ve tekrar sonuçları
- `review.md`: bağımsız inceleme ve teslim kararı
- `zincir.md`: bütün aşamaların tamamlanma ve kanıt kaydı

Bunların dışındaki sohbet, kişisel hafıza veya ajana özel dosya tamamlanma kanıtı
değildir.

## Merkezi kapı

GitHub, değişen ürün dosyalarıyla birlikte tek bir iş kaydı arar. Eksik aşama,
açık görev, çözülmemiş belirsizlik, çelişki, yakınsamamış uygulama veya başarısız
inceleme varsa teslimatı durdurur. Bu kontrol hangi aracın kod yazdığına bakmaz.

Dal koruması hesap planı nedeniyle kapalı olduğu sürece doğrudan ana dala yazım
sunucu tarafından kesin engellenemez. Bu açık, otomatik canlı yayın kapalı
tutularak sınırlandırılır; kırmızı kontrol taşıyan ana dal canlıya çıkarılamaz.

## Yayın

Ana dala alma ile canlı yayın ayrı işlemlerdir. İki Vixrex sitesinde Git
kaynaklı otomatik yayın kapalıdır. Canlı yayın ancak:

- gelişim zinciri yeşil,
- ürün kontrolleri yeşil,
- önizleme gerçek kullanıcı yolunda doğrulanmış,
- geri alma yolu hazır,
- Furkan canlı yayın kararını vermiş

ise ayrıca başlatılır.
