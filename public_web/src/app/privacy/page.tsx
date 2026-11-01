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
      <p>Son güncelleme: 1 Kasım 2026</p>

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
        <li><strong>Hesap bilgileri:</strong> E-posta adresi, şifre (şifrelenmiş)</li>
        <li><strong>İşletme bilgileri:</strong> Ad, adres, telefon, sosyal medya linkleri, ürünler, fotoğraflar</li>
        <li><strong>Randevu verileri:</strong> Müşteri adı, telefonu, notları, randevu saati</li>
        <li><strong>Fatura ve ürün verileri:</strong> Esnafın yüklediği fatura görüntüleri; faturadaki tedarikçi bilgileri, belge numarası, ürünler, miktarlar ve fiyatlar. Faturada üçüncü kişilere ait kişisel veriler de bulunabilir.</li>
        <li><strong>Kullanım verileri:</strong> cihaz/tarayıcı bilgisi ve görüntülenme kayıtları. Web vitrin ölçümünde IP adresi ham olarak saklanmaz; kötüye kullanım kontrolü için tek yönlü teknik özet (hash) üretilir.</li>
        <li><strong>Vitrin etkileşim verileri:</strong> ürün görüntüleme, beğeni, yorum, sepete ekleme ve WhatsApp sipariş geçişi. İşletme sahibine ham ziyaretçi kimliği gösterilmez.</li>
        <li><strong>Sepet verisi:</strong> ürün, varyant ve adet bilgisi sipariş WhatsApp&apos;a aktarılana kadar tarayıcınızda yerel olarak tutulabilir.</li>
      </ul>

      <h2>3. Verilerin Kullanım Amacı</h2>
      <ul>
        <li>Hizmetin sağlanması ve işletilmesi</li>
        <li>Randevu yönetimi ve müşteri iletişimi</li>
        <li>Yüklenen fatura görüntülerini yapay zekâ ile okuyarak ürün kartı taslakları hazırlamak</li>
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
        <li><strong>Supabase:</strong> veritabanı, kimlik doğrulama ve dosya depolama altyapısı.</li>
        <li><strong>OpenRouter:</strong> Yüklenen fatura görüntüleri ve ürün kartı hazırlamak için gereken fatura/ürün bilgileri, yapay zekâ modeli üzerinden işlenmek üzere OpenRouter hizmetine iletilir.</li>
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
        Bu sağlayıcıların bir kısmı (ör. OpenRouter, Google, Sentry, Cloudflare)
        yurt dışında veri işleyebilir. Kişisel verilerin yurt dışına aktarımı
        KVKK&apos;nın 9. maddesindeki şartlara tabidir. Bu bilgilendirme
        tek başına açık rıza veya yurt dışına aktarım için yeterli güvence değildir.
      </p>

      <h2>5. Veri Saklama</h2>
      <p>
        Hesap, vitrin ve diğer kişisel veriler için saklama ve silme koşulları veri türüne göre değişir.
        Yasal saklama yükümlülüğü bulunan bazı kayıtlar hesap silindikten sonra da ilgili süreler boyunca saklanabilir.
        Yürürlükteki veri işleme ve saklama açıklamaları için <Link href="/legal/privacy">KVKK Aydınlatma Metni</Link>ni inceleyebilirsiniz.
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
    </main>
  );
}
