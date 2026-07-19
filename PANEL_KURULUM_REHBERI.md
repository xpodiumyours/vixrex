# 🔑 VİXREX GOOGLE CLOUD & SUPABASE PANEL KURULUM ADIMLARI

Bu rehber, **Google Cloud Console**, **`google-services.json`** ve **Supabase Dashboard** ayarlarını adım adım ve tıklanacak buton isimleriyle açıklar.

---

## 1. BÖLÜM: GOOGLE CLOUD CONSOLE (CLIENT ID & SHA-256)

### Adım 1.1: Proje Açma
1. [console.cloud.google.com](https://console.cloud.google.com) adresine gidin ve Google hesabınızla giriş yapın.
2. Üst menüden **"Select a project" (Proje Seçin)** butonuna tıklayıp **"New Project" (Yeni Proje)** deyin.
3. Proje Adı: `Vixrex` yazıp **"Create"** deyin.

### Adım 1.2: OAuth Onay Ekranı (OAuth Consent Screen)
1. Sol menüden **APIs & Services -> OAuth consent screen** sekmesine tıklayın.
2. User Type: **External (Harici)** seçip **"Create"** deyin.
3. App Name: `Vixrex`
4. User support email: Kendi e-postanızı seçin.
5. Developer contact information: Kendi e-postanızı yazın ve **"Save and Continue"** diyerek tamamlayın.

### Adım 1.3: Web Client ID (Supabase İçin Ana Kimlik)
1. Sol menüden **APIs & Services -> Credentials (Kimlik Bilgileri)** sekmesine geçin.
2. Üstteki **"+ CREATE CREDENTIALS" -> "OAuth client ID"** deyin.
3. Application type: **Web application** seçin.
4. Name: `Vixrex Web Client`
5. Authorized redirect URIs kısmına **"+ ADD URI"** deyip Supabase projenizin callback URL'ini ekleyin (Supabase Dashboard'dan alınır).
6. **"CREATE"** deyin. Ekranınıza gelen **Client ID** ve **Client Secret** değerlerini kopyalayın (Supabase'e yapıştırılacak).

### Adım 1.4: Android Client ID (SHA-256 Koruması)
1. Tekrar **"+ CREATE CREDENTIALS" -> "OAuth client ID"** deyin.
2. Application type: **Android** seçin.
3. Name: `Vixrex Android App`
4. Package name: `com.xpodiumyours.vixrex`
5. **SHA-1 certificate fingerprint:** Yerel bilgisayarınızın SHA-1 değerini yazın.
6. **SHA-256 certificate fingerprint:** Vixrex anayasasındaki onaylı üretim değerini yazın:
   `295af3e289e13bc9fea273f224fa7c1fcb1879472790d48ed3eea8239c0ffc24`
7. **"CREATE"** deyin.

### Adım 1.5: iOS Client ID
1. Tekrar **"+ CREATE CREDENTIALS" -> "OAuth client ID"** deyin.
2. Application type: **iOS** seçin.
3. Bundle ID: `com.xpodiumyours.vixrex`
4. **"CREATE"** deyin. Açılan pencereden `iOS Client ID` ve `Reversed Client ID` değerini alın.

---

## 2. BÖLÜM: `google-services.json` DOSYASI

1. Google Cloud Console üzerinde veya bağlantılı [console.firebase.google.com](https://console.firebase.google.com) üzerinde Android uygulamasını seçin.
2. **`google-services.json`** indirme butonuna tıklayın.
3. İnen `google-services.json` dosyasını projenizdeki şu klasörün içine sürükleyip bırakın (üzerine yazın):  
   `c:\Projects\vixrex\android\app\google-services.json`

---

## 3. BÖLÜM: SUPABASE DASHBOARD AYARLARI

1. [supabase.com/dashboard](https://supabase.com/dashboard) adresine girip Vixrex projenizi seçin.
2. Sol menüden **Authentication -> Providers** sekmesine tıklayın.
3. **Google** sağlayıcısını bulun ve tıklayın:
   - **Enabled:** `True` (Açık yapın)
   - **Client ID (for OAuth):** Google Cloud'dan aldığınız **Web Client ID** değerini yapıştırın.
   - **Client Secret (for OAuth):** Google Cloud'dan aldığınız **Web Client Secret** değerini yapıştırın.
   - **"Save"** butonuna basarak kaydedin.
4. **Authentication -> URL Configuration** sekmesine geçin:
   - **Redirect URLs** alanına `vixrex://login-callback` adresini ekleyip kaydedin.

---

## 🚀 SON ADIM: CANLI TEST

Tüm bu paneller ayarlandığında, mobil uygulamada **"Google ile Giriş Yap"** butonuna bastığınızda:
1. Doğrudan yerel Google hesap seçici açılacaktır.
2. Hesabınızı seçtiğinizde misafir olarak hazırladığınız vitrininiz kaybolmadan e-posta hesabınıza bağlanacaktır!
