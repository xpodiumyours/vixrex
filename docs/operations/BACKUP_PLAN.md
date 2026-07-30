# Backup ve Recovery Plani

## Backup Stratejisi

### 1. Database Backup
**Supabase PostgreSQL**

| Tur | Sıklık | Saklama | Amac |
|-----|--------|---------|------|
| Otomatik | Haftalik (Pazar 03:00) | 30 gun | Gunluk koruma |
| Manuel | Gerekli oldugunda | 90 gun | Deployment oncesi |
| Transaction Log | Her saat | 7 gun | Point-in-time recovery |

### 2. Storage Backup
**Supabase Storage (dosyalar)**

| Tur | Sıklık | Saklama | Amac |
|-----|--------|---------|------|
| Tam | Haftalik | 30 gun | Dosya koruma |
| Incremental | Gunluk | 14 gun | Degisiklik takibi |

### 3. Configuration Backup
**Kod ve Ayarlar**

| Tur | Sıklık | Saklama | Amac |
|-----|--------|---------|------|
| Git Repository | Her commit | Surekli | Kod versiyonlama |
| Environment | Deployment oncesi | 90 gun | Konfigurasyon |
| Secrets | Encryption ile | Surekli | Guvenlik |

## Backup Konumlari

### Yerel Backup
```
supabase/backup/dumps/
├── vixrex_weekly_YYYYMMDD_HHMMSS.dump
├── vixrex_manual_YYYYMMDD_HHMMSS.dump
└── vixrex_daily_YYYYMMDD_HHMMSS.dump
```

### Uzak Backup
- **GitHub Artifacts**: 30 gun saklama
- **Cloud Storage**: 90 gun saklama
- **Offsite Backup**: 1 yil saklama

## Backup Komutlari

### Manuel Backup
```bash
# Haftalik backup
./supabase/backup/backup_database.sh weekly

# Manuel backup
./supabase/backup/backup_database.sh manual

# Transaction log backup
pg_dump --transaction-log --file=transaction_log.sql
```

### Backup Dogrulama
```bash
# Backup dosyasini dogrula
pg_restore --list vixrex_weekly_YYYYMMDD_HHMMSS.dump

# Boyut kontrolu
ls -lh supabase/backup/dumps/

# Icerik kontrolu
pg_restore --schema-only vixrex_weekly_YYYYMMDD_HHMMSS.dump
```

### Backup Temizleme
```bash
# 30 gun eski backup'lari temizle
find supabase/backup/dumps/ -name "*.dump" -mtime +30 -delete

# Eski versiyonlari temizle
find supabase/backup/dumps/ -name "*.dump" -mtime +90 -delete
```

## Recovery Prosedurleri

### 1. Database Recovery
**Tam Recovery**

```bash
# 1. Supabase'i durdur
supabase stop

# 2. Yeni database olustur
supabase db reset --linked=false

# 3. Backup'i yukle
pg_restore --verbose --no-owner --no-privileges \
  --dbname=postgresql://... \
  vixrex_weekly_YYYYMMDD_HHMMSS.dump

# 4. Supabase'i baslat
supabase start
```

**Point-in-Time Recovery**

```bash
# 1. Transaction log'lari uygula
pg_restore --transaction-log \
  --target-time="2026-07-28 14:30:00" \
  --dbname=postgresql://...

# 2. Dogrula
psql -c "SELECT NOW();"
```

### 2. Storage Recovery
```bash
# 1. Dosyalari yukle
supabase storage cp backup/avatars/ avatars/

# 2. Erisim politikalarini uygula
supabase storage policy apply avatars/

# 3. Dogrula
supabase storage ls avatars/
```

### 3. Configuration Recovery
```bash
# 1. Environment dosyasini yukle
cp .env.backup .env

# 2. Secrets'i guncelle
# (Manuel olarak Supabase Dashboard'dan)

# 3. Deployment yap
vercel --prod
```

## Recovery Time Objectives (RTO)

| Sistem | RTO | RPO |
|--------|-----|-----|
| Database | 4 saat | 1 saat |
| Storage | 2 saat | 24 saat |
| Configuration | 1 saat | 0 (real-time) |
| Full Application | 8 saat | 24 saat |

## Disaster Recovery Planı

### Senaryo 1: Database Silinmesi
1. **Hemen**: Supabase support ile iletisime gec
2. **1 saat**: En son backup'i bul
3. **4 saat**: Database'i geri yukle
4. **8 saat**: Uygulamayi test et
5. **24 saat**: Kullaniciyi bilgilendir

### Senaryo 2: Storage Kaybi
1. **Hemen**: Storage bucket'larini kontrol et
2. **2 saat**: Backup'lardan dosyalari geri yukle
3. **4 saat**: URL'leri guncelle
4. **8 saat**: Uygulamayi test et

### Senaryo 3: Configuration Kaybi
1. **Hemen**: Git repository'den kodu geri yukle
2. **1 saat**: Environment ayarlarini guncelle
3. **2 saat**: Deployment yap
4. **4 saat**: Test et

## Backup Monitoring

### Alert'ler
- [ ] Backup basarisiz: Hemen alert
- [ ] Backup boyutu azaldi: 24 saat icinde
- [ ] Backup suresi artti: Haftalik kontrol
- [ ] Storage quota doluyor: 7 gun once

### Dashboard
- [ ] Son backup durumu
- [ ] Backup boyutu trendi
- [ ] Recovery test sonuclari
- [ ] Storage kullanimi

## Test ve Dogrulama

### Haftalik Test
```bash
# Backup'i test ortaminda geri yukle
supabase stop
supabase start --linked=false
pg_restore --verbose --no-owner --no-privileges \
  --dbname=postgresql://... \
  vixrex_weekly_YYYYMMDD_HHMMSS.dump
```

### Aylik Test
```tam recovery senaryosu```
```bash
# 1. Production'u durdur
# 2. Backup'i yukle
# 3. Tum testleri calistir
# 4. Kullanici akislarini test et
# 5. Performance testi calistir
```

### Yillik Test
```full disaster recovery drill```
```bash
# 1. Tum sistemi yeni ortamda kur
# 2. Backup'lardan geri yukle
# 3. Tum senaryolari test et
# 4. RTO/RPO degerlerini dogrula
```

## Dokumantasyon

### Gerekli Dosyalar
- [ ] Bu dosya (BACKUP_PLAN.md)
- [ ] ROLLBACK_RUNBOOK.md
- [ ] STAGING_SETUP.md
- [ ] PRODUCTION_CHECKLIST.md

### Guncelleme Sıkligi
- Her deployment'da
- Her buyuk degisiklikte
- Aylik olarak
- Yillik olarak
