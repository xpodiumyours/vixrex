// ÜRETİLMİŞ DOSYA — ELLE DÜZENLEME.
//
// Kaynak : shared/vixrex_mesajlar.json
// Üreten : tool/mesaj_semasi_uret.dart
//
// Vixrex sohbet asistanının sabit metin kataloğu. Next.js aynı
// JSON'u okur (public_web/src/lib/vixrexMesajlari.ts).

class VixRexIntentSemasi {
  final String payload;
  final List<String> anahtarKelimeler;

  const VixRexIntentSemasi({
    required this.payload,
    required this.anahtarKelimeler,
  });
}

/// Şemadan gelen intent → anahtar kelime eşlemesi. Elle liste
/// tutulmaz; yeni bir anahtar kelime şemaya yazılır.
const List<VixRexIntentSemasi> vixRexIntentSemasi = [
  VixRexIntentSemasi(
    payload: 'merhaba',
    anahtarKelimeler: [
      'merhaba',
      'selam',
      'nasil',
      'baslat',
      'baslayalim',
      'yardim',
      'ne yapabilirsin',
    ],
  ),
  VixRexIntentSemasi(
    payload: 'vixrex_info',
    anahtarKelimeler: [
      'vixrex',
      'nedir',
      'ne işe yarar',
      'nasil calisir',
      'kurulum',
      'vitrin',
    ],
  ),
  VixRexIntentSemasi(
    payload: 'membership_info',
    anahtarKelimeler: [
      'ucret',
      'fiyat',
      'para',
      'komisyon',
      'ucretsiz',
      'odeme',
      'bedava',
      'uyelik',
      'kullanim',
    ],
  ),
  VixRexIntentSemasi(
    payload: 'kapak',
    anahtarKelimeler: ['kapak', 'sablon', 'kapak foto', 'cover'],
  ),
  VixRexIntentSemasi(
    payload: 'fotograf',
    anahtarKelimeler: [
      'fotograf',
      'resim',
      'foto',
      'galeri',
      'gorsel',
      'yukle',
    ],
  ),
  VixRexIntentSemasi(
    payload: 'aciklama',
    anahtarKelimeler: ['aciklama', 'hakkinda', 'bio', 'tanitim yazisi'],
  ),
  VixRexIntentSemasi(
    payload: 'urun',
    anahtarKelimeler: ['urun', 'hizmet', 'menu', 'katalog', 'fiyat listesi'],
  ),
  VixRexIntentSemasi(
    payload: 'qr',
    anahtarKelimeler: ['qr', 'kod', 'link', 'paylas', 'baglanti', 'url'],
  ),
  VixRexIntentSemasi(
    payload: 'randevu',
    anahtarKelimeler: [
      'randevu',
      'rezervasyon',
      'saat',
      'takvim',
      'musteri kabul',
    ],
  ),
  VixRexIntentSemasi(
    payload: 'whatsapp',
    anahtarKelimeler: ['whatsapp', 'telefon', 'numara', 'iletisim', 'mesaj'],
  ),
  VixRexIntentSemasi(
    payload: 'adres',
    anahtarKelimeler: [
      'adres',
      'konum',
      'harita',
      'nerede',
      'yol tarifi',
      'lokasyon',
    ],
  ),
  VixRexIntentSemasi(
    payload: 'yayinla',
    anahtarKelimeler: [
      'yayinla',
      'canli',
      'aktif',
      'yayinda',
      'goster',
      'acik',
    ],
  ),
  VixRexIntentSemasi(
    payload: 'ocr_scan',
    anahtarKelimeler: ['fatura', 'fis', 'tara', 'etiket', 'otomatik', 'ocr'],
  ),
  VixRexIntentSemasi(
    payload: 'ocr_premium',
    anahtarKelimeler: ['premium', 'sinirsiz', 'ucretli'],
  ),
  VixRexIntentSemasi(
    payload: 'xml_upload',
    anahtarKelimeler: [
      'xml',
      'feed',
      'toplu urun',
      'toplu urun yukle',
      'tedarikci',
      'tedarik',
    ],
  ),
  VixRexIntentSemasi(
    payload: 'hesap',
    anahtarKelimeler: [
      'hesap',
      'giris',
      'uye ol',
      'kayit',
      'guvence',
      'hesabimi',
      'login',
    ],
  ),
];

/// Şemadan gelen sabit mesaj metinleri. Anahtardan hızlı erişim.
const Map<String, String> vixRexMesajlari = {
  'setup_invite':
      'Merhaba, ben Vixrex.\n\nSana dijital bir vitrin oluşturmamı ister misin?',
  'vixrex_info':
      'Vixrex ile işletme bilgilerini tek yerde toplar, vitrinini yayınlar ve link, QR veya WhatsApp ile müşterilerine duyurursun.',
  'membership_info':
      'Temel vitrin oluşturma şu an ücretsizdir. Gelişmiş özellikler uygulama içinde ayrıca gösterilecektir.',
  'vitrin_kurulum':
      'Vitrin kurulumu için yalnızca İşletme Adı, WhatsApp, Adres ve Yasal Onay adımlarını tamamlamanız yeterlidir.',
  'kapak':
      'Hazır kapak görselleri artık vitrinin kendi sayfasında: Önizle ile aç, kapak alanına tıkla, Vixrex Asistan sana kategorine özel görselleri gösterir. İstersen buradan da seçebilirsin.',
  'fotograf':
      'Galeriye görsel ekle veya kapak şablonu seç. İkisi de mevcut Vitrinim editöründen açılır.',
  'aciklama':
      'Kısa bir işletme açıklaması ekle — müşteri seni daha çabuk anlar.',
  'urun':
      'Ürün/hizmet ekle: elle yaz veya fiş/etiket tarayıcıyı kullan. İkisi de mevcut uygulama yolları.',
  'xml_upload':
      'XML ile toplu ürün yüklemek için tedarikçinin XML linkini paylaş. Sistem otomatik olarak ürünleri vitrine ekleyecek.',
  'qr_yayinda':
      'Linkini kopyala, QR göster veya WhatsApp ile paylaş — hepsi mevcut paylaşım yolları.',
  'qr_yayinda_degil': 'Önce vitrinini yayınla; sonra QR ve link hazır olur.',
  'randevu':
      'Randevu, uygun kategoride mevcut editör paketinden açılır. Kategori alanına gidip kontrol edebilirsin.',
  'whatsapp': 'WhatsApp numaran Vitrinim iletişim alanında. Oradan güncelle.',
  'adres': 'Konumunu Vitrinim adres alanından güncelle — GPS veya elle.',
  'yayinla':
      'Yayın için yasal onaylar ve Yayınla butonu Vitrinim’de. Oradan devam et.',
  'ocr_scan':
      'Fiş/fatura veya raf etiketi ile ürün aktar — mevcut tarayıcıyı aç.',
  'ocr_info':
      'Nasıl Çalışır:\n1. Fotoğrafınızı çekin veya galeriden seçin\n2. Ürünler otomatik olarak tanınır\n3. Ürünleri onaylayın veya düzenleyin\n4. Onaylanan ürünler vitrininize eklenir\n\nNot: Bu özellik premium gerektirir.',
  'ocr_premium':
      'Premium üyelik ile:\n• Fotoğraftan sınırsız ürün çıkarma\n• Faturadan otomatik ürün kaydı\n• Toplu Excel yükleme\n• Barkod tarama\n\nÜcretsiz deneme: Günde 3 ücretsiz OCR hakkı.\nPremium için uygulama içinden satın alma yapabilirsiniz.',
  'hesap':
      'Vitrinini güvenceye almak için giriş yap / üye ol. Mevcut Auth ekranı açılır; vitrin token ile hesaba bağlanır.',
  'anlasilamadi':
      'Üzgünüm, bunu tam anlayamadım. Aşağıdaki seçeneklerden birini deneyebilirsiniz:',
  'taslak_cakismasi': 'Canlı vitrin değişmiş — burada gördüğün eski hâli.',
};
