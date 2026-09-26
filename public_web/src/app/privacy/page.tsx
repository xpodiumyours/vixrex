import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'Gizlilik Politikası | Vixrex',
  description: 'Vixrex gizlilik politikası ve KVKK aydınlatma metni.',
};

export default function PrivacyPage() {
  return (
    <main style={{ maxWidth: 720, margin: '0 auto', padding: '40px 20px', color: '#EDEDED', fontFamily: 'system-ui' }}>
      <h1>Gizlilik Politikası</h1>
      <p>Son güncelleme: 26 Eylül 2026</p>

      <h2>1. Veri Sorumlusu</h2>
      <p>
        <strong>Vixrex</strong>, Aksakal Ticaret tarafından işletilmektedir.<br />
        Adres: Ümraniye Esenevler Mahallesi Lokman Hekim Caddesi No 18, İstanbul<br />
        E-posta: vixrex.app@gmail.com
      </p>

      <h2>2. Toplanan Veriler</h2>
      <ul>
        <li><strong>Hesap bilgileri:</strong> E-posta adresi, şifre (şifrelenmiş)</li>
        <li><strong>İşletme bilgileri:</strong> Ad, adres, telefon, sosyal medya linkleri, ürünler, fotoğraflar</li>
        <li><strong>Randevu verileri:</strong> Müşteri adı, telefonu, notları, randevu saati</li>
        <li><strong>Kullanım verileri:</strong> IP adresi, cihaz bilgisi, görüntülenme kayıtları</li>
        <li><strong>Vitrin etkileşim verileri:</strong> ürün görüntüleme, beğeni, yorum, sepete ekleme ve WhatsApp sipariş geçişi. İşletme sahibine ham ziyaretçi kimliği gösterilmez.</li>
        <li><strong>Sepet verisi:</strong> ürün, varyant ve adet bilgisi sipariş WhatsApp&apos;a aktarılana kadar tarayıcınızda yerel olarak tutulabilir.</li>
      </ul>

      <h2>3. Verilerin Kullanım Amacı</h2>
      <ul>
        <li>Hizmetin sağlanması ve işletilmesi</li>
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
        <li><strong>Supabase:</strong> veritabanı, kimlik doğrulama ve dosya depolama altyapımız — tüm verileriniz burada barındırılır.</li>
        <li><strong>Vercel:</strong> web sitemizi barındıran sunucu sağlayıcısı.</li>
        <li><strong>Google Analytics:</strong> yalnızca çerez onayı verdiyseniz, kullanım istatistikleri için (IP adresi anonimleştirilir).</li>
        <li><strong>Google reCAPTCHA:</strong> otomatik/kötüye kullanım (bot) girişlerini engellemek için.</li>
        <li><strong>Cloudflare Turnstile:</strong> bazı formlarda (ör. içerik bildirimi) bot koruması için.</li>
        <li><strong>Sentry:</strong> uygulama hatalarını tespit edip düzeltebilmemiz için hata/performans kaydı.</li>
        <li><strong>Meta / Instagram:</strong> yalnızca Instagram hesabınızı VixRex&apos;e bağlarsanız, ürün fotoğraflarınızı içe aktarmak için.</li>
        <li><strong>PayTR:</strong> premium abonelik ödemesi alıyorsanız, ödeme işlemini gerçekleştiren ödeme kuruluşu.</li>
        <li><strong>OneSignal:</strong> abonelik/randevu hatırlatma bildirimleri gönderebilmemiz için.</li>
      </ul>
      <p>
        Bu sağlayıcıların bir kısmı (ör. Google, Sentry, Cloudflare) yurt
        dışında veri işleyebilir. Bu sayfa hangi verinin hangi amaçla
        paylaşıldığını gösterir; her sağlayıcıyla ayrı bir veri işleme
        sözleşmesi (DPA) süreci ayrıca yürütülmektedir.
      </p>

      <h2>5. Veri Saklama</h2>
      <p>
        Hesabınız aktif olduğu sürece verileriniz saklanır. Hesabınızı sildiğinizde tüm verileriniz kalıcı olarak silinir.
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
        Gizlilikle ilgili sorularınız için: <a href="mailto:Xpodiumyours@gmail.com">Xpodiumyours@gmail.com</a>
      </p>
    </main>
  );
}
