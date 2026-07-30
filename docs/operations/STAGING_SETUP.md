# Staging Ortamı Yapilandirmasi

## Ortam Bilgileri

| Kaynak | Deger |
|--------|-------|
| Supabase Proje | `chfulefxczbgurtgavtp` |
| Supabase Org | `cmtwwdvabgusyaylbjdt` |
| Flutter Vercel | `prj_AfdnDnAcIwSCaJuBoCQh1TP1GvWR` |
| Public Web Vercel | `prj_dCMDIaefrTHg6ysiUDT7veiWI52h` |

## Gerekli Environment Variable'lar

### GitHub Secrets (SEC-004 icin gerekli)
- `SUPABASE_ACCESS_TOKEN`: Supabase CLI icin access token
- `SUPABASE_PROJECT_REF`: `chfulefxczbgurtgavtp`
- `DATABASE_URL`: Supabase PostgreSQL connection string (pooler)
- `VERCEL_TOKEN`: Vercel deployment token

### Supabase Secrets (mevcut)
- `SUPABASE_URL`: `https://chfulefxczbgurtgavtp.supabase.co`
- `SUPABASE_ANON_KEY`: Mevcut anon key
- `SUPABASE_SERVICE_ROLE_KEY`: Mevcut service role key

## Staging Ortam Adimlari

### 1. Supabase Staging Proje (Opsiyonel)
Eger ayri bir staging proje istenirse:
1. Supabase Dashboard'da yeni proje olustur
2. `supabase link --project-ref <staging-ref>` ile bagla
3. Migration'lari uygula: `supabase db reset`

### 2. Vercel Staging Branch
1. `staging` branch'i olustur
2. Vercel'de bu branch'e otomatik deployment ayarla
3. Staging URL'yi dogrula

### 3. Flutter Staging Build
1. `flutter build web --release` ile staging build olustur
2. Vercel'de staging branch'e deploy et
3. Test kullanici hesaplari ile dogrula

### 4. Public Web Staging
1. `cd public_web && npm run build` ile staging build olustur
2. Vercel'de staging branch'e deploy et
3. Public sayfalari dogrula

## Staging Test Senaryolari

### Kullanici Akislari
- [ ] Kayit olusturma
- [ ] Giris yapma
- [ ] Dukkan olusturma
- [ ] Urun ekleme
- [ ] Siparis olusturma
- [ ] Yorum yapma

### Teknik Kontroller
- [ ] RLS politikalari dogru calisiyor
- [ ] Edge function'lar calisiyor
- [ ] Storage upload/download calisiyor
- [ ] Push notification calisiyor

## Staging Kullanim Kurallari

1. **Veri**: Staging'de gercek kullanici verisi KULLANILMAZ
2. **Test**: Staging'de test kullanici hesaplari kullanilir
3. **Deployment**: Staging'den production'a gecis onay gerektirir
4. **Monitoring**: Staging hatalari monitoring'de gorunur
