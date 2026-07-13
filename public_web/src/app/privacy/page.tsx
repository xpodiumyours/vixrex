import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'Gizlilik Politikası | Vixrex',
  description: 'Vixrex gizlilik politikası ve KVKK aydınlatma metni.',
};

export default function PrivacyPage() {
  return (
    <main style={{ maxWidth: 720, margin: '0 auto', padding: '40px 20px', color: '#EDEDED', fontFamily: 'system-ui' }}>
      <h1>Gizlilik Politikası</h1>
      <p>Son güncelleme: 10 Temmuz 2026</p>

      <h2>1. Veri Sorumlusu</h2>
      <p>
        <strong>Vixrex</strong>, Aksakal Ticaret tarafından işletilmektedir.<br />
        Adres: Ümraniye Esenevler Mahallesi Lokman Hekim Caddesi No 18, İstanbul<br />
        E-posta: Xpodiumyours@gmail.com
      </p>

      <h2>2. Toplanan Veriler</h2>
      <ul>
        <li><strong>Hesap bilgileri:</strong> E-posta adresi, şifre (şifrelenmiş)</li>
        <li><strong>İşletme bilgileri:</strong> Ad, adres, telefon, sosyal medya linkleri, ürünler, fotoğraflar</li>
        <li><strong>Randevu verileri:</strong> Müşteri adı, telefonu, notları, randevu saati</li>
        <li><strong>Kullanım verileri:</strong> IP adresi, cihaz bilgisi, görüntülenme kayıtları</li>
      </ul>

      <h2>3. Verilerin Kullanım Amacı</h2>
      <ul>
        <li>Hizmetin sağlanması ve işletilmesi</li>
        <li>Randevu yönetimi ve müşteri iletişimi</li>
        <li>SEO ve arama motoru görünürlüğü</li>
        <li>Yasal yükümlülüklerin yerine getirilmesi</li>
      </ul>

      <h2>4. Verilerin Paylaşılması</h2>
      <p>
        Verileriniz üçüncü taraflarla paylaşılmaz. Tek istisna, yasal zorunluluklardır.
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
