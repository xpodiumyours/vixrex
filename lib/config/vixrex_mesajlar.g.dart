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
      'geri don',
      'geri',
    ],
  ),
  VixRexIntentSemasi(
    payload: 'vitrin_kurulum',
    anahtarKelimeler: [
      'sifirdan olustur',
      'sifirdan',
      'kendim olustur',
      'yeni vitrin',
      'vitrin kur',
      'vitrin olustur',
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
    payload: 'qr',
    anahtarKelimeler: [
      'qr',
      'kod',
      'kodumu goster',
      'link',
      'paylas',
      'baglanti',
      'url',
    ],
  ),
  VixRexIntentSemasi(
    payload: 'randevu',
    anahtarKelimeler: [
      'randevu',
      'rezervasyon',
      'saat',
      'takvim',
      'musteri kabul',
      'kategori',
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
      'yasal',
      'onay',
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
  'blog_yayinlandi': 'Yazı yayınlandı.',
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
  'welcome_baslik': 'Merhaba, ben Vixrex Asistan.',
  'welcome_aciklama':
      'İşletmene ne kazandırıyorum?\n- Tek Link & QR Kod: Dijital vitrin sayfan.\n- WhatsApp Sipariş: Müşterilerin tek tıkla sana ulaşır.\n- Ürün & Galeri: Reyon ve ürünlerini sergilersin.\n- Konum & Adres: Dükkanına kolayca ulaşılır.\n\nSenin işletmen için de 2 dakikada beraber hazırlayalım mı?',
  'welcome_buton': 'Başla',
  'setup_name_baslik': 'İşletme adınızı girin',
  'setup_name_aciklama':
      'Vitrininizde görünecek işletme adınızı ekleyerek başlayın.',
  'setup_name_buton': 'İşletme Adı Ekle',
  'setup_whatsapp_baslik': 'WhatsApp numaranızı ekleyin',
  'setup_whatsapp_aciklama':
      'Müşterilerinizin sizi hızlıca ulaşabilmesi için WhatsApp numaranızı girin.',
  'setup_whatsapp_buton': 'WhatsApp Ekle',
  'setup_address_baslik': 'Adres ve konum bilgisi ekleyin',
  'setup_address_aciklama':
      'Müşterilerin sizi bulabilmesi için adres ve konum bilgisi ekleyin.',
  'setup_address_buton': 'Adres Ekle',
  'setup_category_baslik': 'İşletme kategorinizi seçin',
  'setup_category_aciklama':
      'Vitrininizin doğru şablon ve önerilerle kurulması için kategorinizi seçin.',
  'setup_category_buton': 'Kategori Seç',
  'setup_legal_baslik': 'Yasal onayları tamamlayın',
  'setup_legal_aciklama':
      'Vitrininizi yayınlayabilmeniz için gerekli yasal onayları vermeniz gerekiyor.',
  'setup_legal_buton': 'Onayları İncele',
  'setup_publish_baslik': 'Vitrininizi yayınlayın',
  'setup_publish_aciklama':
      'Tüm gerekli bilgileri doldurdunuz. Şimdi vitrininizi yayınlayabilirsiniz.',
  'setup_publish_buton': 'Vitrinimi Aç',
  'publish_baslik': 'Vitrininizi Yayınlayın',
  'publish_aciklama':
      'Tüm gerekli bilgileri doldurdunuz. Şimdi vitrininizi yayınlayabilirsiniz.',
  'publish_buton': 'Yayınla',
  'share_baslik': 'Vitrininizi Paylaşın',
  'share_aciklama': 'Vitrinin hazır. Müşterilerine ulaştırmak için paylaşalım.',
  'share_buton': 'Paylaş',
  'all_done_baslik': 'Tebrikler!',
  'all_done_aciklama':
      'Vitrininiz harika görünüyor. Daha fazla özellik için bize ulaşabilirsiniz.',
  'all_done_buton': 'Vitrinime Git',
  'improve_category_baslik': 'Şablonla güzelleştir',
  'improve_category_aciklama':
      'Vitrinin yayında! Şimdi hazır şablonlardan birini seçelim ki işletmene özel tasarım ve görselleri ekleyelim.',
  'improve_category_buton': 'Hazır şablonları aç',
  'improve_cover_baslik': 'Şablonla güzelleştir',
  'improve_cover_aciklama':
      'Güzel. Şimdi kategorine göre hazır şablonlardan birini seçelim — dijital vitrini hızlıca daha güzel yapalım.',
  'improve_cover_buton': 'Hazır şablonları aç',
  'improve_gallery_baslik': 'Galeri görselleri ekleyin',
  'improve_gallery_aciklama':
      'Ürün veya hizmet fotoğraflarınızı galeriye ekleyin.',
  'improve_gallery_buton': 'Galeriye Git',
  'improve_desc_baslik': 'İşletme açıklaması ekleyin',
  'improve_desc_aciklama': 'İşletmenizi tanıtan kısa bir açıklama ekleyin.',
  'improve_desc_buton': 'Açıklamaya Git',
  'improve_catalog_baslik': 'Ürünleri yükle',
  'improve_catalog_aciklama':
      'Müşterilerine gösterebilmen için ürünleri nasıl yükleyeceğimize karar verelim — tarayıcı veya elle ekleme.',
  'improve_catalog_buton': 'Ürün yükleme yolunu seç',
  'improve_hero_badge_baslik': 'Kapak rozeti ekle',
  'improve_hero_badge_aciklama':
      'Kapak fotoğrafının üstüne kısa bir rozet metni ekle — işletmeni bir bakışta anlatır. Örn: "Profesyonel Teknik Servis / Kadıköy".',
  'improve_hero_badge_buton': 'Rozet ekle',
  'improve_logo_baslik': 'Logonu ekle',
  'improve_logo_aciklama':
      'İşletme logon vitrinin üst köşesinde görünür — kurumsal bir ilk izlenim bırakır.',
  'improve_logo_buton': 'Logo ekle',
  'improve_working_hours_baslik': 'Çalışma saatlerini ekle',
  'improve_working_hours_aciklama':
      'Müşterin ne zaman açık olduğunu görsün, boşuna gelip seni kapalı bulmasın.',
  'improve_working_hours_buton': 'Saatleri ekle',
  'improve_google_link_baslik': 'Google İşletme / harita bağlantını ekle',
  'improve_google_link_aciklama':
      'Müşterin tek tıkla yol tarifi alsın veya Google\'daki işletme sayfana ulaşsın.',
  'improve_google_link_buton': 'Bağlantı ekle',
  'improve_about_title_baslik': 'Hakkımızda başlığı ekle',
  'improve_about_title_aciklama':
      'Hakkımızda bölümüne kısa, dikkat çekici bir başlık yaz.',
  'improve_about_title_buton': 'Başlık ekle',
  'improve_about_bio_baslik': 'İşletmenin hikayesini anlat',
  'improve_about_bio_aciklama':
      'Hakkımızda metnine işletmenin hikayesini, neyi farklı yaptığını yaz — müşteri seni tanısın.',
  'improve_about_bio_buton': 'Hikayeni yaz',
  'improve_booking_baslik': 'Randevu sistemi kurun',
  'improve_booking_aciklama':
      'Müşterileriniz online randevu alsın — 7/24 açık kalın.',
  'improve_booking_buton': 'Randevu ayarları',
  'improve_blog_baslik': 'Duyuru veya yazı paylaşın',
  'improve_blog_aciklama':
      'Kampanya, indirim veya haberlerinizi yazarak Google\'da üst sıralara çıkın.',
  'improve_blog_buton': 'Vitrinime git',
  'improve_seo_baslik': 'Google görünürlüğünü güçlendirin',
  'improve_seo_aciklama':
      'Meta başlık, açıklama ve anahtar kelimelerinizi girerek arama sonuçlarında öne çıkın.',
  'improve_seo_buton': 'Vitrinime git',
  'improve_account_baslik': 'Hesabınızı güvenceye alın',
  'improve_account_aciklama':
      'Giriş yaparak vitrininizi hesabınıza bağlayın — verileriniz güvende kalsın.',
  'improve_account_buton': 'Hesap',
  'landing_finish_baslik': 'Vitrinin hazır',
  'landing_finish_aciklama':
      'Verdiğin bilgilerle vitrinini kurabilirim. Hesabını açtığında kaldığın yerden devam edeceğiz.',
  'landing_finish_buton': 'Hesap Aç ve Vitrini Kur',
  'niyet_kategori_baslik': 'Ne iş yapıyorsun?',
  'niyet_kategori_aciklama':
      'İşine uygun hazır vitrinleri Keşfet\'ten göstereyim.',
  'niyet_geri_buton': '‹ Geri',
  'niyet_anlat_buton': 'Anlat ve devam et',
  'niyet_serbest_yertutucu':
      'İşini birkaç cümleyle anlat (opsiyonel) — WhatsApp\'ını, adresini, çalışma saatlerini yazarsan, vitrinini seçtiğinde otomatik dolduracağım.',
  'niyet_ack':
      'Anlattıklarını not aldım — vitrinini seçtiğinde bunlardan otomatik dolduracağım.',
  'hesap_bagla_baslik': 'Vitrinini hesabına bağla',
  'hesap_bagla_aciklama':
      'Şu an vitrinin bu cihaza bağlı. Telefonunu değiştirirsen ya da tarayıcı verilerini silersen erişimini kaybedersin.',
  'hesap_bagla_buton': 'Google ile bağla',
  'hesap_bagla_yukleniyor': 'Google açılıyor…',
  'hesap_bagla_hata': 'Google hesabı bağlanamadı.',
  'netlestirme_sor': '{etiket} için ne yazayım? Örn: {ipucu}',
  'netlestirme_sor_genel': '{etiket} için hangi değeri yazayım?',
  'netlestirme_onay':
      '{etiket} için “{deger}” mi demek istedin? Onaylıyor musun? (evet/hayır)',
  'netlestirme_basari': 'Kaydettim: {etiket} → {deger}',
  'netlestirme_hata': '{hata}',
  'netlestirme_belirsiz':
      'Hangi alanı değiştirmek istediğini netleştirebilir misin? Örn: “İşletme adını ... yap” veya “WhatsApp numaram ...”',
};

class VixRexHizliSecenek {
  final String id;
  final String etiket;
  final String ikon;

  const VixRexHizliSecenek({
    required this.id,
    required this.etiket,
    required this.ikon,
  });
}

const List<VixRexHizliSecenek> vixRexHizliSecenekler = [
  VixRexHizliSecenek(
    id: 'hazir_vitrin_sec',
    etiket: 'Hazır Vitrin Seç',
    ikon: 'storefront',
  ),
  VixRexHizliSecenek(
    id: 'sifirdan_olustur',
    etiket: 'Sıfırdan Oluştur',
    ikon: 'auto_awesome',
  ),
  VixRexHizliSecenek(
    id: 'bakiniyorum',
    etiket: 'Bakınıyorum',
    ikon: 'visibility',
  ),
];

class VixRexYanitHizli {
  final String etiket;
  final String payload;
  final String aksiyon;

  const VixRexYanitHizli({
    required this.etiket,
    required this.payload,
    required this.aksiyon,
  });
}

class VixRexYanit {
  final String payload;
  final String mesaj;
  final List<VixRexYanitHizli> hizli;

  const VixRexYanit({
    required this.payload,
    required this.mesaj,
    required this.hizli,
  });
}

/// Yanıt kablolaması (mesaj anahtarı + hızlı yanıt etiket/payload).
/// Aksiyon eşlemesi istemcide kalır; burada yalnız sabit içerik var.
const Map<String, VixRexYanit> vixRexYanitlar = {
  'kapak': VixRexYanit(
    payload: 'kapak',
    mesaj: 'kapak',
    hizli: [
      VixRexYanitHizli(
        etiket: 'Kapak şablonu seç',
        payload: 'action_cover',
        aksiyon: 'openCoverTemplatePicker',
      ),
      VixRexYanitHizli(etiket: 'Geri Dön', payload: 'merhaba', aksiyon: 'none'),
    ],
  ),
  'fotograf': VixRexYanit(
    payload: 'fotograf',
    mesaj: 'fotograf',
    hizli: [
      VixRexYanitHizli(
        etiket: 'Galeriye git',
        payload: 'action_gallery',
        aksiyon: 'scrollToGallery',
      ),
      VixRexYanitHizli(
        etiket: 'Kapak şablonu seç',
        payload: 'action_cover',
        aksiyon: 'openCoverTemplatePicker',
      ),
      VixRexYanitHizli(etiket: 'Geri Dön', payload: 'merhaba', aksiyon: 'none'),
    ],
  ),
  'aciklama': VixRexYanit(
    payload: 'aciklama',
    mesaj: 'aciklama',
    hizli: [
      VixRexYanitHizli(
        etiket: 'Açıklamaya git',
        payload: 'action_desc',
        aksiyon: 'scrollToDesc',
      ),
      VixRexYanitHizli(etiket: 'Geri Dön', payload: 'merhaba', aksiyon: 'none'),
    ],
  ),
  'urun': VixRexYanit(
    payload: 'urun',
    mesaj: 'urun',
    hizli: [
      VixRexYanitHizli(
        etiket: 'Ürün alanına git',
        payload: 'action_products',
        aksiyon: 'scrollToProducts',
      ),
      VixRexYanitHizli(
        etiket: 'Fiş ile tara',
        payload: 'action_ocr',
        aksiyon: 'openOcrScanner',
      ),
      VixRexYanitHizli(etiket: 'Geri Dön', payload: 'merhaba', aksiyon: 'none'),
    ],
  ),
  'xml_upload': VixRexYanit(
    payload: 'xml_upload',
    mesaj: 'xml_upload',
    hizli: [
      VixRexYanitHizli(
        etiket: 'XML linkini paylaş',
        payload: 'action_xml',
        aksiyon: 'openXmlUpload',
      ),
      VixRexYanitHizli(etiket: 'Geri Dön', payload: 'merhaba', aksiyon: 'none'),
    ],
  ),
  'qr_yayinda': VixRexYanit(
    payload: 'qr_yayinda',
    mesaj: 'qr_yayinda',
    hizli: [
      VixRexYanitHizli(
        etiket: 'Linki kopyala',
        payload: 'copy_link',
        aksiyon: 'copyLink',
      ),
      VixRexYanitHizli(
        etiket: 'QR göster',
        payload: 'show_qr',
        aksiyon: 'showQr',
      ),
      VixRexYanitHizli(
        etiket: 'WhatsApp’ta paylaş',
        payload: 'share_wa',
        aksiyon: 'shareWhatsapp',
      ),
      VixRexYanitHizli(etiket: 'Geri Dön', payload: 'merhaba', aksiyon: 'none'),
    ],
  ),
  'qr_yayinda_degil': VixRexYanit(
    payload: 'qr_yayinda_degil',
    mesaj: 'qr_yayinda_degil',
    hizli: [
      VixRexYanitHizli(
        etiket: 'Vitrinime git',
        payload: 'open_vitrim',
        aksiyon: 'openVitrim',
      ),
      VixRexYanitHizli(etiket: 'Geri Dön', payload: 'merhaba', aksiyon: 'none'),
    ],
  ),
  'randevu': VixRexYanit(
    payload: 'randevu',
    mesaj: 'randevu',
    hizli: [
      VixRexYanitHizli(
        etiket: 'Kategoriye git',
        payload: 'action_category',
        aksiyon: 'scrollToCategory',
      ),
      VixRexYanitHizli(etiket: 'Geri Dön', payload: 'merhaba', aksiyon: 'none'),
    ],
  ),
  'whatsapp': VixRexYanit(
    payload: 'whatsapp',
    mesaj: 'whatsapp',
    hizli: [
      VixRexYanitHizli(
        etiket: 'WhatsApp alanına git',
        payload: 'action_wa',
        aksiyon: 'scrollToWhatsapp',
      ),
      VixRexYanitHizli(etiket: 'Geri Dön', payload: 'merhaba', aksiyon: 'none'),
    ],
  ),
  'adres': VixRexYanit(
    payload: 'adres',
    mesaj: 'adres',
    hizli: [
      VixRexYanitHizli(
        etiket: 'Adrese git',
        payload: 'action_address',
        aksiyon: 'scrollToAddress',
      ),
      VixRexYanitHizli(etiket: 'Geri Dön', payload: 'merhaba', aksiyon: 'none'),
    ],
  ),
  'yayinla': VixRexYanit(
    payload: 'yayinla',
    mesaj: 'yayinla',
    hizli: [
      VixRexYanitHizli(
        etiket: 'Yasal onaylara git',
        payload: 'action_legal',
        aksiyon: 'scrollToLegal',
      ),
      VixRexYanitHizli(
        etiket: 'Vitrinime git',
        payload: 'open_vitrim',
        aksiyon: 'openVitrim',
      ),
      VixRexYanitHizli(etiket: 'Geri Dön', payload: 'merhaba', aksiyon: 'none'),
    ],
  ),
  'ocr_scan': VixRexYanit(
    payload: 'ocr_scan',
    mesaj: 'ocr_scan',
    hizli: [
      VixRexYanitHizli(
        etiket: 'Fiş/Fatura tara',
        payload: 'action_ocr',
        aksiyon: 'openOcrScanner',
      ),
      VixRexYanitHizli(
        etiket: 'Raf/Etiket tara',
        payload: 'action_ocr_shelf',
        aksiyon: 'openOcrScannerShelf',
      ),
      VixRexYanitHizli(
        etiket: 'Nasıl çalışır?',
        payload: 'ocr_info',
        aksiyon: 'none',
      ),
    ],
  ),
  'ocr_info': VixRexYanit(
    payload: 'ocr_info',
    mesaj: 'ocr_info',
    hizli: [
      VixRexYanitHizli(
        etiket: 'Premium Bilgisi',
        payload: 'ocr_premium',
        aksiyon: 'none',
      ),
      VixRexYanitHizli(etiket: 'Geri Dön', payload: 'merhaba', aksiyon: 'none'),
    ],
  ),
  'hesap': VixRexYanit(
    payload: 'hesap',
    mesaj: 'hesap',
    hizli: [
      VixRexYanitHizli(
        etiket: 'Hesabımı güvenceye al',
        payload: 'action_auth',
        aksiyon: 'openAuth',
      ),
      VixRexYanitHizli(etiket: 'Geri Dön', payload: 'merhaba', aksiyon: 'none'),
    ],
  ),
};

class VixRexAsistanAkisAdimi {
  final String id;
  final List<String> alanlar;
  final String mesaj;
  final String girdi;
  final String? yerTutucu;

  const VixRexAsistanAkisAdimi({
    required this.id,
    required this.alanlar,
    required this.mesaj,
    required this.girdi,
    this.yerTutucu,
  });
}

/// APK, landing ve sahip panelinin ortak kurulum sırası.
const List<VixRexAsistanAkisAdimi> vixRexAsistanAkisi = [
  VixRexAsistanAkisAdimi(
    id: 'name',
    alanlar: ['isletmeAdi'],
    mesaj: 'setup_name',
    girdi: 'metin',
    yerTutucu: 'Ör. Aymira Giyim',
  ),
  VixRexAsistanAkisAdimi(
    id: 'category',
    alanlar: ['kategori'],
    mesaj: 'setup_category',
    girdi: 'secim',
    yerTutucu: 'Kategori seç',
  ),
  VixRexAsistanAkisAdimi(
    id: 'whatsapp',
    alanlar: ['whatsapp'],
    mesaj: 'setup_whatsapp',
    girdi: 'telefon',
    yerTutucu: '05xx xxx xx xx',
  ),
  VixRexAsistanAkisAdimi(
    id: 'location',
    alanlar: ['adres', 'il', 'ilce'],
    mesaj: 'setup_address',
    girdi: 'konum',
    yerTutucu: 'Açık adres',
  ),
  VixRexAsistanAkisAdimi(
    id: 'legal',
    alanlar: [],
    mesaj: 'setup_legal',
    girdi: 'onay',
  ),
  VixRexAsistanAkisAdimi(
    id: 'publish',
    alanlar: [],
    mesaj: 'setup_publish',
    girdi: 'eylem',
  ),
  VixRexAsistanAkisAdimi(
    id: 'share',
    alanlar: [],
    mesaj: 'share',
    girdi: 'eylem',
  ),
];

VixRexAsistanAkisAdimi? vixRexAsistanAdimiForAlan(String anahtar) {
  for (final adim in vixRexAsistanAkisi) {
    if (adim.alanlar.contains(anahtar)) return adim;
  }
  return null;
}
