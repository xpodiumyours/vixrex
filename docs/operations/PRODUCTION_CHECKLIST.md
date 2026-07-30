# Production Deployment Kontrol Listesi

## On Kontroller (Deploy oncesi)

### Guvenlik
- [ ] RLS politikalari aktif ve dogru
- [ ] Service role key sadece backend'de kullaniliyor
- [ ] Anon key public alanda kullaniliyor
- [ ] HTTPS zorunlu (Supabase varsayilan)
- [ ] CORS ayarlari dogru

### Kod Kalitesi
- [ ] CI/CD pipeline basarili (tum workflow'lar green)
- [ ] Code review tamamlandi
- [ ] Test coverage yeterli
- [ ] Lint hatalari giderildi
- [ ] Type check basarili

### Deployment
- [ ] Flutter web build basarili
- [ ] Public web build basarili
- [ ] Supabase migration'lari uygulandi
- [ ] Edge function'lar deploy edildi
- [ ] Storage bucket'lari olusturuldu

## Deployment Sirasi

### 1. Supabase (Backend)
1. Migration'lari uygula: `supabase db push`
2. Edge function'lari deploy et: `supabase functions deploy`
3. RLS politikalarini dogrula
4. Backup al

### 2. Public Web (Frontend)
1. Build olustur: `cd public_web && npm run build`
2. Deploy et: `vercel --prod`
3. SEO ayarlarini dogrula
4. Performance testi calistir

### 3. Flutter (Admin Panel)
1. Build olustur: `flutter build web --release`
2. Deploy et: `vercel --prod`
3. Tum sayfalari kontrol et
4. API baglantilarini dogrula

## Post-Deployment Kontrolleri

### Fonksiyonel
- [ ] Kullanici giris/cikis calisiyor
- [ ] Dukkan olusturma calisiyor
- [ ] Urun CRUD calisiyor
- [ ] Siparis akisi calisiyor
- [ ] Push notification calisiyor

### Teknik
- [ ] Hata loglari temiz
- [ ] Performance metrikleri normal
- [ ] Uptime monitoring aktif
- [ ] Alert'ler calisiyor

### Geri Donus
- [ ] Rollback plani hazir
- [ ] Backup alindi
- [ ] Database dump mevcut
- [ ] Eski versiyona donus test edildi

## Rollback Proseduru

### Kritik Hata Durumunda
1. **Dur**: Tum yeni depoylar durdur
2. **Degerlendir**: Hatanin etkisini olc
3. **Geri Don**: `ROLLBACK_RUNBOOK.md`'i takip et
4. **Bildirim**: Kullaniciya durumu bildir
5. **Duzelt**: Hatayi duzelt, tekrar deploy et

### Rollback Komutlari
```bash
# Supabase rollback
supabase db reset --linked=false

# Vercel rollback
vercel rollback

# Flutter rollback
git checkout <onceki-tag>
flutter build web --release
vercel --prod
```

## Deployment Sonrasi Dogrulama

### Monitoring Dashboard
- [ ] Supabase dashboard acik
- [ ] Vercel analytics acik
- [ ] Error tracking acik
- [ ] Performance monitoring acik

### Kullanici Bildirimi
- [ ] Deployment bildirimi gonderildi
- [ ] Degisiklik logu guncellendi
- [ ] Kullanici rehberi guncellendi
