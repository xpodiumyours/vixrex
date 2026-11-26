import type { Metadata } from 'next';
import Link from 'next/link';

export const metadata: Metadata = {
  title: 'Gizlilik Politikası | Vixrex',
  description: 'Vixrex gizlilik politikası ve KVKK aydınlatma metni.',
};

export default function PrivacyPage() {
  return (
    <main style={{ maxWidth: 720, margin: '0 auto', padding: '40px 20px', color: '#EDEDED' }}>
      <h1>Gizlilik Politikası</h1>
      <p>Son güncelleme: 26 Kasım 2026</p>

      <h2>1. Veri Sorumlusu</h2>
      <p>
        <strong>Veri sorumlusu:</strong> Furkan Aksakal (Aksakal Ticaret)<br />
        Vixrex dijital vitrin ve yazılım hizmeti bu gerçek kişi işletmesi tarafından sunulmaktadır.<br />
        Adres: Esenevler Mah. Lokman Hekim Cad. No:18 İç Kapı No:10 Ümraniye/İstanbul<br />
        E-posta: <a href="mailto:destek@vixrex.com">destek@vixrex.com</a><br />
        Telefon: <a href="tel:+905421802573">0542 180 25 73</a>
      </p>

      <h2>2. Toplanan Veriler</h2>
      <ul>
        <li><strong>Hesap ve oturum bilgileri (Google OAuth):</strong> Kalıcı hesaplarda Google girişiyle (<code>openid</code>, <code>email</code>, <code>profile</code> kapsamları) alınan ad-soyad, e-posta adresi, profil fotoğrafı ve hesap kimliği; ücretsiz vitrin denemesinde anonim/misafir oturum kimliği. Vixrex kalıcı hesap açılışında kullanıcı şifresi toplamaz.</li>
        <li><strong>İşletme bilgileri:</strong> Ad, adres, telefon, sosyal medya linkleri, ürünler, fotoğraflar</li>
        <li><strong>Fatura ve yapay zekâ işleme verileri:</strong> İşletmenin yüklediği fatura fotoğrafı/PDF, tedarikçi ve belge bilgileri, vergi numarası, fatura satırları, üretilen ürün taslakları, model yanıtları ve işlem kullanım kayıtları.</li>
        <li><strong>Randevu verileri:</strong> Müşteri adı, telefonu, notları, randevu saati</li>
        <li><strong>Kullanım verileri:</strong> cihaz/tarayıcı bilgisi ve görüntülenme kayıtları. Web vitrin ölçümünde IP adresi ham olarak saklanmaz; kötüye kullanım kontrolü için tek yönlü teknik özet (hash) üretilir.</li>
        <li><strong>Vitrin etkileşim verileri:</strong> ürün görüntüleme, beğeni, yorum, sepete ekleme ve WhatsApp sipariş geçişi. İşletme sahibine ham ziyaretçi kimliği gösterilmez.</li>
        <li><strong>Sepet verisi:</strong> ürün, varyant ve adet bilgisi sipariş WhatsApp&apos;a aktarılana kadar tarayıcınızda yerel olarak tutulabilir.</li>
      </ul>

      <h2>Mobil Uygulama İzinleri ve Veri Paylaşımı</h2>
      <ul>
        <li><strong>Kamera ve Fotoğraf İzni (Mobil Uygulama — CAMERA):</strong> Ürün veya fatura fotoğrafı çekerek katalog/vitrin oluşturmak için yalnızca kullanıcının açık izniyle kullanılır; zorunlu değildir.</li>
        <li><strong>Konum İzni ve Ters Coğrafi Kodlama (Mobil Uygulama — ACCESS_FINE_LOCATION / ACCESS_COARSE_LOCATION):</strong> İşletme adresini hızlı doldurmak için yalnızca kullanıcı isteğiyle alınır; koordinatlar adres çözümlemesi amacıyla OpenStreetMap Nominatim servisine iletilir, arka planda konum takibi yapılmaz.</li>
        <li><strong>Görsel Depolama ve CDN (Cloudflare R2):</strong> Yüklenen vitrin ve ürün görselleri Cloudflare R2 (cdn.vixrex.com) ve Supabase altyapısında barındırılır.</li>
      </ul>

      <h2>3. Verilerin Kullanım Amacı</h2>
      <ul>
        <li>Google girişiyle alınan kullanıcı verilerinin yalnızca kimlik doğrulama, oturum açma ve Vixrex hesabı oluşturma/yönetme amacıyla kullanılması</li>
        <li>Hizmetin sağlanması ve işletilmesi</li>
        <li>İşletmenin yüklediği faturalardan yapay zekâ destekli ürün kartı taslakları oluşturulması ve doğrulanması</li>
        <li>Randevu yönetimi ve müşteri iletişimi</li>
        <li>SEO ve arama motoru görünürlüğü</li>
        <li>Vitrin sahibine toplulaştırılmış performans ölçümleri sunulması</li>
        <li>Yasal yükümlülüklerin yerine getirilmesi</li>
      </ul>

      <h2>4. Verilerin Paylaşılması</h2>
      <p>
        Verileriniz, hizmeti çalıştırmak için kullandığımız aşağıdaki hizmet
        sağlayıcılarla ve yasal zorunluluk hâlinde yetkili mercilerle
        paylaşılır. Bunların dışında, verileriniz satılmaz veya pazarlama
        amacıyla üçüncü taraflara aktarılmaz.
      </p>
      <ul>
        <li><strong>Supabase:</strong> veritabanı, kimlik doğrulama ve dosya depolama altyapısı. Fatura işlemleri için gerekli içerikler ayrıca OpenRouter ve yapay zekâ hizmet sağlayıcılarına iletilir.</li>
        <li><strong>Vercel:</strong> web sitemizi barındıran sunucu sağlayıcısı.</li>
        <li><strong>Google Gemini API:</strong> İşletmenin başlattığı fatura okuma, belge analizi ve ürün kartı oluşturma işlemlerinde birincil yapay zekâ motoru olarak belge ve ürün bilgileri işlenir; ürün doğrulama ve eşleştirme amacıyla Google Arama temellendirme araçları kullanılabilir.</li>
        <li><strong>OpenRouter ve seçilen yapay zekâ model sağlayıcıları:</strong> İşletmenin başlattığı fatura okuma ve ürün kartı oluşturma işleminde belge ve ürün bilgileri işlenir. Ürün eşleştirme amacıyla OpenRouter web arama/erişim araçları ve bunların altyapı sağlayıcıları kullanılabilir.</li>
        <li><strong>Google Analytics:</strong> yalnızca çerez onayı verdiyseniz, kullanım istatistikleri için (IP adresi anonimleştirilir).</li>
        <li><strong>Google reCAPTCHA:</strong> otomatik/kötüye kullanım (bot) girişlerini engellemek için.</li>
        <li><strong>Cloudflare Turnstile:</strong> bazı formlarda (ör. içerik bildirimi) bot koruması için.</li>
        <li><strong>Cloudflare R2:</strong> yüklenen vitrin ve ürün görsellerinin CDN barındırma altyapısı.</li>
        <li><strong>OpenStreetMap Nominatim:</strong> kullanıcı isteğiyle alınan koordinatların adres çözümlemesi için.</li>
        <li><strong>Sentry:</strong> uygulama hatalarını tespit edip düzeltebilmemiz için hata/performans kaydı.</li>
        <li><strong>Meta / Instagram:</strong> yalnızca Instagram hesabınızı Vixrex&apos;e bağlarsanız, ürün fotoğraflarınızı içe aktarmak için.</li>
        <li><strong>PayTR:</strong> premium abonelik ödemesi alıyorsanız, ödeme işlemini gerçekleştiren ödeme kuruluşu.</li>
        <li><strong>OneSignal:</strong> abonelik/randevu hatırlatma bildirimleri gönderebilmemiz için.</li>
      </ul>
      <p>
        Bu sağlayıcıların bir kısmı (ör. Google, Sentry, Cloudflare, OpenRouter ve model sağlayıcıları)
        yurt dışında veri işleyebilir. Kişisel verilerin yurt dışına aktarımında
        KVKK&apos;nın 9. maddesindeki şartların ayrıca karşılanması gerekir.
        Bu sayfa, aktarım için gerekli hukuki güvencelerin sağlandığını tek başına kanıtlamaz.
      </p>

      <h2>5. Veri Saklama</h2>
      <p>
        Hesap, vitrin ve diğer kişisel veriler için saklama ve silme koşulları veri türüne göre değişir.
        Yasal saklama yükümlülüğü bulunan bazı kayıtlar hesap silindikten sonra da ilgili süreler boyunca saklanabilir.
        Yürürlükteki veri işleme ve saklama açıklamaları için <Link href="/legal/privacy">KVKK Aydınlatma Metni</Link>ni inceleyebilirsiniz.
      </p>
      <p>
        Hesabınızı ve verilerinizi silmek için uygulama içindeki Hesap ve Veri Yönetimi ekranını kullanabilir,
        {" "}<Link href="/legal/data-deletion">Veri Silme Talebi</Link> sayfasındaki adımları izleyebilir veya{" "}
        <a href="mailto:destek@vixrex.com">destek@vixrex.com</a> adresine e-posta gönderebilirsiniz.
        Kimlik doğrulamasının ardından veri silme talepleri en geç 30 gün içinde sonuçlandırılır.
      </p>

      <h2>6. Haklarınız (KVKK)</h2>
      <ul>
        <li>Verilerinize erişim talep etme</li>
        <li>Verilerinizi düzeltme talep etme</li>
        <li>Verilerinizi silme talep etme</li>
        <li>Veri işlenmesine itiraz etme</li>
      </ul>

      <h2>7. İletişim</h2>
      <p>
        Gizlilikle ilgili sorularınız için: <a href="mailto:destek@vixrex.com">destek@vixrex.com</a>.
        KVKK başvuru yöntemleri için <a href="/iletisim">İletişim</a> sayfasını inceleyebilirsiniz.
      </p>

      <h2>English Summary (for Google OAuth & Play Store)</h2>
      <p>
        <strong>Data Controller:</strong> Furkan Aksakal — Aksakal Ticaret, Esenevler Mah. Lokman Hekim Cad. No:18 İç Kapı No:10 Ümraniye/İstanbul, Türkiye. Contact: destek@vixrex.com.
      </p>
      <ul>
        <li><strong>OAuth scopes used:</strong> openid, email, profile (Limited Use — used only for authentication, account creation and management; not sold, not used for ads/AI training). Vixrex&apos;s use and transfer to any other app of information received from Google APIs will adhere to the <a href="https://developers.google.com/terms/api-services-user-data-policy" target="_blank" rel="noopener noreferrer">Google API Services User Data Policy</a>, including the Limited Use requirements.</li>
        <li><strong>Mobile permissions:</strong> Camera (optional, for OCR/product photo), Location (optional, store address autofill via OpenStreetMap Nominatim), Notifications (optional, via OneSignal).</li>
        <li><strong>Account deletion:</strong> in-app Account &amp; Data Management screen or https://vixrex.com/legal/data-deletion; e-mail destek@vixrex.com. Requests fulfilled within 30 days.</li>
        <li><strong>Privacy policy:</strong> https://vixrex.com/privacy — Data deletion: https://vixrex.com/legal/data-deletion.</li>
      </ul>

      <h2>8. Google OAuth Kullanıcı Verileri ve Sınırlı Kullanım (Limited Use)</h2>
      <ul>
        <li><strong>Alınan veriler:</strong> Google ile oturum açma sırasında yalnızca <code>openid</code>, <code>email</code> ve <code>profile</code> kapsamları aracılığıyla ad-soyad, e-posta adresi, profil fotoğrafı ve hesap kimliği alınır.</li>
        <li><strong>Kullanım amacı:</strong> Alınan Google verileri yalnızca kimlik doğrulama, oturum açma ve Vixrex hesabı oluşturma/yönetme amaçlarıyla kullanılır.</li>
        <li><strong>Reklam ve satış yasağı (Limited Use):</strong> Google kullanıcı verileri reklam, kişiselleştirilmiş pazarlama, veri simsarlığı veya üçüncü taraflara satış amacıyla kullanılmaz ve aktarılmaz. Google verilerinin kullanımı Google API Hizmetleri Kullanıcı Verileri Politikası (<em>Limited Use</em>) ilkelerine tabidir.</li>
        <li><strong>Yapay Zekâ (AI/ML) Eğitim Yasağı:</strong> Google girişiyle alınan kullanıcı verileri (ad-soyad, e-posta adresi, profil fotoğrafı ve oturum bilgileri) hiçbir genel yapay zekâ veya makine öğrenmesi (AI/ML) modelini eğitmek ya da iyileştirmek için kullanılmaz ve yapay zekâ sağlayıcılarına aktarılmaz.</li>
      </ul>

      <h2>9. Veri Güvenliği</h2>
      <p>
        Tüm veri aktarımları aktarım sırasında <strong>HTTPS/TLS</strong> şifrelemesi ile korunur.
        Kullanıcı ve işletme verilerine erişim; sunucu tarafı erişim kontrolü ve veritabanında satır düzeyinde güvenlik (<strong>RLS — Row Level Security</strong>) politikaları ile sınırlandırılır.
      </p>
    </main>
  );
}
