---
paths:
  - "lib/**/*.dart"
  - "public_web/**/*.ts"
  - "public_web/**/*.tsx"
---

# Güvenlik Kuralları

## Auth & Erişim
- Service role anahtarı asla client-side'da kullanma
- RLS politikalarını devre dışı bırakma
- Her endpoint'te auth check zorunlu
- Anonim erişim yasak (public vitrin hariç)

## Input & Validation
- Tüm user input'unu validate et
- SQL injection koruması (parameterized queries)
- XSS koruması (output encoding)
- CORS whitelist kullan (`*` değil)

## API & Network
- Rate limiting: 100 req/min başlangıç
- API key'leri hardcoded olmamalı
- Environment variables kullan
- HTTPS zorunlu

## Veri Gizliliği
- PII verileri encrypt et (telefon, email)
- GDPR/KVKK uyumu sağla
- Veri silme endpoint'i hazır olmalı
- Veri saklama süresi politikası tanımla

## Depolama
- Dosya boyutu kontrolü (15MB max)
- MIME türü doğrulama
- Kullanıcı yüklemelerini sanitiz et
- Storage bucket politikalarını koru
