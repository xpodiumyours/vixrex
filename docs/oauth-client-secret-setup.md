# OAuth Client Secret Setup

## ⚠️ Güvenlik Uyarısı
`android/app/client_secret_*.json` dosyası **asla** git'e commit edilmemelidir. Bu dosya:
- Google Cloud Console'dan indirilen gerçek OAuth client secret içerir
- `.gitignore`'a eklenmiştir (satır 65: `android/app/client_secret_*.json`)
- **Diskte bile saklanmamalıdır** — V-27 güvenlik açığı

## Geliştirici Kurulumu

### 1. Yerel Geliştirme
```bash
# Google Cloud Console → APIs & Services → Credentials
# OAuth 2.0 Client IDs → "Download JSON"
# Dosyayı android/app/ altına kaydedin:
# client_secret_<CLIENT_ID>.apps.googleusercontent.com.json
```

### 2. CI/CD (GitHub Actions / Vercel / Codemagic)
Secret'ları **environment variable** olarak ekleyin:

**GitHub Actions:**
```yaml
# .github/workflows/android.yml
- name: Setup OAuth Client Secret
  run: |
    echo "${{ secrets.ANDROID_OAUTH_CLIENT_SECRET }}" > android/app/client_secret.json
  env:
    ANDROID_OAUTH_CLIENT_SECRET: ${{ secrets.ANDROID_OAUTH_CLIENT_SECRET }}
```

**Vercel:**
- Project Settings → Environment Variables
- `ANDROID_OAUTH_CLIENT_SECRET` = JSON içeriği (base64 encoded tercihen)

**Codemagic:**
- Environment variables → `ANDROID_OAUTH_CLIENT_SECRET`

### 3. Build-time Injection (flutter)
`android/app/build.gradle` veya `android/app/src/main/AndroidManifest.xml` yerine:
- `google-services.json` → `google-services.json.example`'dan kopyalanır
- `client_secret.json` → CI/CD secret'tan inject edilir

## Şablon Dosyalar
| Dosya | Amaç |
|-------|------|
| `android/app/google-services.json.example` | Şablon — kopyalayıp `google-services.json` yapın |
| `android/app/client_secret_*.json` | **YOK** — indirip yerleştirin, build sonrası silin |

## Doğrulama
```bash
# Bu dosya git'te olmamalı:
git ls-files android/app/client_secret_*.json
# Çıktı boş olmalı

# Bu dosya diskte olmamalı (güvenlik için):
ls android/app/client_secret_*.json
# "No such file or directory" olmalı
```

## Referans
- V-27: OAuth client_secret plaintext diskte — attack-vectors.md
- V-26: google-services.json git'teydi — düzeltildi