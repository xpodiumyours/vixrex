# Vixrex — Geri Dönüş Runbook'u (Rollback Runbook)

**Tarih:** 28 Temmuz 2026  
**Durum:** Taslak — Vercel production URL'leri doğrulanmadı  

---

## 1. Kod Hatası (Flutter / Next.js)

### Yöntem: Vercel Deployment Geri Alma

1. Vercel Dashboard'a gir.
2. İlgili projeyi seç (vixrex / vixrex-public).
3. Deployments sekmesinde son bilinen çalışan deployment'ı bul.
4. "Promote to Production" ile eski sürüme dön.
5. Canlı smoke test yap.

### Yöntem: Git Revert

```bash
git revert --no-commit <hatalı-commit>..
git commit -m "revert: <açıklama>"
git push origin main
```

## 2. Yeni Özellik Hatası

### Yöntem: Feature Flag Kapatma

- İlgili feature flag varsa Supabase veya env üzerinden kapat.
- Public site geri önceki haline döner.

## 3. Migration Hatası

### Kural
- Veri silen geri alma (`DROP COLUMN`, `DELETE`) yapılmaz.
- Önceden hazırlanmış ileri-düzeltme migration'ı uygulanır.

### Adımlar
1. Yeni migration dosyası oluştur (`supabase/migrations/`).
2. Hatalı değişikliği düzelten SQL yaz.
3. Yerelde test et.
4. Yedek al.
5. Production'a uygula.

## 4. Ödeme Hatası

### Yöntem: Checkout Kill Switch
- PayTR checkout'u geçici olarak devre dışı bırak.
- Callback kayıtları korunur, hiçbir sipariş kaybolmaz.
- Sorun çözülünce checkout tekrar açılır.

## 5. Ön Koşullar

- [ ] Vercel production deployment kimlikleri kayıtlı
- [ ] Supabase yedek son çalışması doğrulanmış
- [ ] Rollback staging ortamında en az bir kez denenmiş
- [ ] Her geri dönüş olayı audit ediliyor
