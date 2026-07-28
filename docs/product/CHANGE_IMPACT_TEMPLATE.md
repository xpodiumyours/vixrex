# Vixrex — Değişiklik Etki Şablonu (Change Impact Template)

Her iş için koddan önce doldurulması zorunlu şablondur.

---

```yaml
# .changes/<issue-numarası>-<kısa-ad>.yml

amaç: >
  Kullanıcı açısından tek sonuç.

izinli_dosyalar:
  - lib/controllers/... (en fazla 3 production dosyası)

yasak_alanlar:
  - public_web/   (aksi belirtilmedikçe)
  - supabase/migrations/ (aksi belirtilmedikçe)

korunan_davranışlar:
  - "Editörü açmak publish yapmaz"
  - "GPS manuel adresi silmez"

doğru_sonuç:
  - "Kullanıcı X yapınca Y olur"

hata_senaryoları:
  - "Kullanıcı X yapınca Z hatası gösterilir"

çalıştırılacak_kontroller:
  - flutter analyze
  - flutter test --run-skipped
  - npm run build (public_web değiştiyse)

rollback:
  commit: <önceki güvenli commit>
  feature_flag: <varsa adı>

kullanıcı_onayı:
  tarih:
  onay:
```

---

## Kullanım

1. Her yeni iş için bu şablonu `.changes/` klasörüne kopyala.
2. Tüm alanları doldur.
3. Kullanıcıya göster ve onay al.
4. Onaydan sonra feature branch aç ve uygulamaya başla.
