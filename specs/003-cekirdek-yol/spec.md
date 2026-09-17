# Çekirdek yol

## Kullanıcı sonucu

Zincir işe uyar: küçük iş küçük yoldan, riskli iş kanıtlı yoldan geçer.

## Kabul koşulları

1. Yeni özellik ve davranış değişikliği beş kayıtla yürür: keşif, istek, plan,
   görevler, zincir durumu.
2. Hata düzeltmesi üç kayıtla yürür: sebep, görevler, zincir durumu.
3. Yalnız bağımlılık ve üretilen dosya değişiyorsa iş kaydı istenmez.
4. Clarify, Checklist ve Analyze zorunlu değildir; gerektiğinde açılan kapıdır.
5. Açılan her kapının kanıtı zincir durumunda yazılıdır ve boş bırakılamaz.
6. `supabase/migrations/` altında değişiklik varsa veri kapısı kendiliğinden
   zorunlu olur.
7. Yakınsama ve inceleme sonucu ayrı dosya değil, zincir durumunda tek satırdır.
8. Keşifte korunacak davranış yazılı olmadan iş geçemez.
9. Kapının önceki beş gerçek ölçümü çalışmaya devam eder.

## Kapsam dışı

Ürün kodu, veritabanı, canlı yayın ayarları.
