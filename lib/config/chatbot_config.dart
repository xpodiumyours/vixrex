import 'package:vitrinx/models/chat_message.dart';
import 'package:vitrinx/services/xrex_profile_snapshot.dart';

/// Xrex — VitrinX'in yapay zeka destekli asistan chatbot'u.
/// Tüm yanıtlar Türkçedir. API bağlantısı yoktur; kural tabanlı çalışır.
abstract final class ChatbotConfig {
  static const String botName = 'Xrex';
  static const String botSubtitle = 'VitrinX Asistanı';
  static const String systemStatus = 'AKTİF';

  // ─── Genel Karşılama (snapshot yokken) ──────────────────────────────────
  static ChatMessage get welcomeMessage => ChatMessage.bot(
        'Merhaba! Ben **$botName**, VitrinX\'in dijital asistanıyım. 👋\n\n'
        'Dijital vitrin oluşturmanıza, ürünlerinizi paylaşmanıza ve\n'
        'müşterilerinize ulaşmanıza yardımcı olabilirim.\n\n'
        'Size nasıl yardımcı olayım?',
        quickReplies: mainMenuReplies,
      );

  // ─── Snapshot Tabanlı Karşılama Mesajları ────────────────────────────────

  /// Vitrin durumuna göre kişiselleştirilmiş karşılama mesajı üretir.
  static ChatMessage snapshotWelcome(XrexProfileSnapshot snapshot) {
    if (snapshot.isPublished) {
      return _publishedMessage(snapshot);
    } else if (snapshot.isReadyToPublish) {
      return _readyToPublishMessage(snapshot);
    } else if (snapshot.healthScore >= 50) {
      return _halfwayMessage(snapshot);
    } else {
      return _incompleteMessage(snapshot);
    }
  }

  static ChatMessage _incompleteMessage(XrexProfileSnapshot snapshot) {
    final missing = snapshot.prioritizedMissing;
    final top3 = missing.take(3).toList();
    final rest = missing.length > 3 ? missing.length - 3 : 0;

    final namePrefix = snapshot.nameCompleted ? '' : 'İşletme adını gir, ';
    final missingList = top3
        .map((f) => '  • ${f.label}')
        .join('\n');
    final restText = rest > 0 ? '\n  ...ve $rest alan daha' : '';

    return ChatMessage.bot(
      'Merhaba! Vitrinin %${snapshot.healthScore} hazır. 🔧\n\n'
      '${namePrefix}Yayına çıkmak için eksikler:\n'
      '$missingList$restText\n\n'
      'Hangisinden başlayalım?',
      quickReplies: [
        const QuickReply(
          label: '▶ Vitrinim\'e Git',
          payload: 'goto_vitrim',
          action: XrexAction.openVitrim,
        ),
        ...top3.take(2).map((f) => QuickReply(
          label: '> ${f.label} Ekle',
          payload: 'goto_vitrim',
          action: XrexAction.openVitrim,
        )),
        const QuickReply(label: '> Nasıl Yapılır?', payload: 'vitrin_kurulum'),
      ],
      snapshotScore: snapshot.healthScore,
    );
  }

  static ChatMessage _halfwayMessage(XrexProfileSnapshot snapshot) {
    final missing = snapshot.prioritizedMissing;
    final top2 = missing.take(2).toList();

    final missingList = top2.map((f) => '  • ${f.label}').join('\n');

    return ChatMessage.bot(
      'Harika gidiyorsun! Vitrininin %${snapshot.healthScore} hazır. 💪\n\n'
      'Yayına çıkmak için ${missing.length} adım kaldı:\n'
      '$missingList${missing.length > 2 ? '\n  ...ve ${missing.length - 2} alan daha' : ''}\n\n'
      'Hızlıca tamamlayalım mı?',
      quickReplies: [
        const QuickReply(
          label: '▶ Vitrinim\'e Git',
          payload: 'goto_vitrim',
          action: XrexAction.openVitrim,
        ),
        const QuickReply(label: '> Yardım Al', payload: 'vitrin_kurulum'),
        const QuickReply(label: '> Ana Menü', payload: 'merhaba'),
      ],
      snapshotScore: snapshot.healthScore,
    );
  }

  static ChatMessage _readyToPublishMessage(XrexProfileSnapshot snapshot) {
    return ChatMessage.bot(
      'Süper! Vitrininin %${snapshot.healthScore} hazır, yayına çıkmak için\n'
      'artık sadece "Yayınla" butonuna basman yeterli! 🚀\n\n'
      'Vitrinim sekmesine gidip yayınlayabilirsin.',
      quickReplies: [
        const QuickReply(
          label: '▶ Vitrinim\'e Git & Yayınla',
          payload: 'goto_vitrim',
          action: XrexAction.openVitrim,
        ),
        const QuickReply(label: '> QR & Link Hakkında', payload: 'qr'),
        const QuickReply(label: '> Ana Menü', payload: 'merhaba'),
      ],
      snapshotScore: snapshot.healthScore,
    );
  }

  static ChatMessage _publishedMessage(XrexProfileSnapshot snapshot) {
    return ChatMessage.bot(
      'Vitrinin yayında! 🎉 Artık müşterilerin seni bulabilir.\n\n'
      'Şimdi sıra paylaşımda — linkinizi QR kodunuzu\n'
      've WhatsApp\'ınızı aktif kullanın.',
      quickReplies: [
        const QuickReply(
          label: '▶ Linki Kopyala',
          payload: 'copy_link',
          action: XrexAction.copyLink,
        ),
        const QuickReply(
          label: '▶ QR Kodu Göster',
          payload: 'show_qr',
          action: XrexAction.showQr,
        ),
        const QuickReply(
          label: '▶ WhatsApp\'ta Paylaş',
          payload: 'share_whatsapp',
          action: XrexAction.shareWhatsapp,
        ),
        const QuickReply(
          label: '> Keşfet\'te Gör',
          payload: 'goto_explore',
          action: XrexAction.openExplore,
        ),
      ],
      snapshotScore: snapshot.healthScore,
    );
  }



  // ─── Ana Menü Quick Reply'ları ───────────────────────────────────────────
  static const List<QuickReply> mainMenuReplies = [
    QuickReply(label: '> Vitrin Nasıl Kurulur?', payload: 'vitrin_kurulum'),
    QuickReply(label: '> Fotoğraf Ekle', payload: 'fotograf'),
    QuickReply(label: '> QR Kod & Link', payload: 'qr'),
    QuickReply(label: '> Randevu Sistemi', payload: 'randevu'),
    QuickReply(label: '> Blog Yaz', payload: 'blog'),
  ];

  static const List<QuickReply> helpReplies = [
    QuickReply(label: '> Ana Menü', payload: 'merhaba'),
    QuickReply(label: '> QR Kod', payload: 'qr'),
    QuickReply(label: '> Ücretli mi?', payload: 'ucret'),
  ];

  // ─── Intent Tanımları ────────────────────────────────────────────────────
  static const List<ChatbotIntent> intents = [
    ChatbotIntent(
      keywords: ['merhaba', 'selam', 'nasil', 'baslat', 'baslayalim', 'yardim', 'ne yapabilirsin'],
      payload: 'merhaba',
    ),
    ChatbotIntent(
      keywords: ['vitrin', 'kur', 'olustur', 'nasil yapilir', 'nasil acilir', 'baslangic', 'adim'],
      payload: 'vitrin_kurulum',
    ),
    ChatbotIntent(
      keywords: ['fotograf', 'resim', 'foto', 'galeri', 'gorsel', 'yukle'],
      payload: 'fotograf',
    ),
    ChatbotIntent(
      keywords: ['qr', 'kod', 'link', 'paylas', 'baglanti', 'url'],
      payload: 'qr',
    ),
    ChatbotIntent(
      keywords: ['randevu', 'rezervasyon', 'saat', 'takvim', 'musteri kabul'],
      payload: 'randevu',
    ),
    ChatbotIntent(
      keywords: ['blog', 'yazi', 'makale', 'icerik', 'yayinla'],
      payload: 'blog',
    ),
    ChatbotIntent(
      keywords: ['whatsapp', 'telefon', 'numara', 'iletisim', 'mesaj'],
      payload: 'whatsapp',
    ),
    ChatbotIntent(
      keywords: ['adres', 'konum', 'harita', 'nerede', 'yol tarifi', 'lokasyon'],
      payload: 'adres',
    ),
    ChatbotIntent(
      keywords: ['yayinla', 'canli', 'aktif', 'yayinda', 'goster', 'acik'],
      payload: 'yayinla',
    ),
    ChatbotIntent(
      keywords: ['ucret', 'fiyat', 'para', 'komisyon', 'ucretsiz', 'odeme', 'bedava'],
      payload: 'ucret',
    ),
  ];

  // ─── Intent → Yanıt Tablosu ─────────────────────────────────────────────
  static ChatMessage responseFor(String payload) {
    switch (payload) {
      case 'merhaba':
        return welcomeMessage;

      case 'vitrin_kurulum':
        return ChatMessage.bot(
          '» Vitrin kurulumu 5 kolay adımda:\n\n'
          '  1. İşletme adı ve kategorinizi girin\n'
          '  2. WhatsApp numaranızı ekleyin\n'
          '  3. Adres ve konum bilgilerinizi girin\n'
          '  4. Ürün/hizmet fotoğraflarınızı yükleyin\n'
          '  5. "Yayınla" butonuna basın — vitriniz canlıda!\n\n'
          'Vitrinim sekmesinden başlayabilirsiniz.',
          quickReplies: [
            const QuickReply(label: '> Fotoğraf Nasıl Eklenir?', payload: 'fotograf'),
            const QuickReply(label: '> QR Kodum Nerede?', payload: 'qr'),
            const QuickReply(label: '> Ana Menü', payload: 'merhaba'),
          ],
        );

      case 'fotograf':
        return ChatMessage.bot(
          '» Fotoğraf ekleme:\n\n'
          '  • Vitrinim → Galeri bölümüne gidin\n'
          '  • "+" butonuna dokunun\n'
          '  • Galeriden fotoğraf seçin\n'
          '  • Fotoğraflar otomatik optimize edilir\n\n'
          'Birden fazla fotoğraf ekleyebilirsiniz.',
          quickReplies: [
            const QuickReply(label: '> Vitrin Kur', payload: 'vitrin_kurulum'),
            const QuickReply(label: '> Ana Menü', payload: 'merhaba'),
          ],
        );

      case 'qr':
        return ChatMessage.bot(
          '» QR Kod ve Paylaşım Linkiniz:\n\n'
          '  • Vitrinim → sağ üst köşe paylaş ikonuna tıklayın\n'
          '  • QR kodunuzu indirin veya ekrana gösterin\n'
          '  • Vitrin linkinizi kopyalayıp her yere paylaşın\n\n'
          'Link formatı: vitrinx.app/isletmeniz',
          quickReplies: [
            const QuickReply(label: '> WhatsApp Ayarla', payload: 'whatsapp'),
            const QuickReply(label: '> Ana Menü', payload: 'merhaba'),
          ],
        );

      case 'randevu':
        return ChatMessage.bot(
          '» Randevu Sistemi:\n\n'
          '  • Vitrinim → Randevu Yönetimi bölümüne gidin\n'
          '  • Çalışma saatlerinizi ayarlayın\n'
          '  • Müşterileriniz online randevu alabilir\n'
          '  • Gelen randevuları panelden onaylayın\n\n'
          'Randevu bağlantısını vitrin linkinizde paylaşabilirsiniz.',
          quickReplies: [
            const QuickReply(label: '> QR & Link', payload: 'qr'),
            const QuickReply(label: '> Ana Menü', payload: 'merhaba'),
          ],
        );

      case 'blog':
        return ChatMessage.bot(
          '» Blog Yazısı Yayınlama:\n\n'
          '  • Vitrinim → Blog bölümüne gidin\n'
          '  • "Yeni Yazı" butonuna tıklayın\n'
          '  • Başlık, özet ve içerik girin\n'
          '  • İl/ilçe ve kategori seçin\n'
          '  • Kaydedin — onaydan sonra yayınlanır\n\n'
          'Blog yazıları Google\'da vitrininizi öne taşır.',
          quickReplies: [
            const QuickReply(label: '> Vitrin Kur', payload: 'vitrin_kurulum'),
            const QuickReply(label: '> Ana Menü', payload: 'merhaba'),
          ],
        );

      case 'whatsapp':
        return ChatMessage.bot(
          '» WhatsApp Hattı Ayarlama:\n\n'
          '  • Vitrinim → İletişim bölümüne gidin\n'
          '  • WhatsApp numaranızı girin (05xx...)\n'
          '  • Kaydedin\n\n'
          'Müşterileriniz vitrininizdeki butona tıklayarak\n'
          'doğrudan size mesaj atabilir.',
          quickReplies: [
            const QuickReply(label: '> Adres Ekle', payload: 'adres'),
            const QuickReply(label: '> Ana Menü', payload: 'merhaba'),
          ],
        );

      case 'adres':
        return ChatMessage.bot(
          '» Adres ve Konum Ekleme:\n\n'
          '  • Vitrinim → Konum bölümüne gidin\n'
          '  • "Konumumu Kullan" ile otomatik tespit edin\n'
          '    veya manuel adres girin\n'
          '  • Kaydedin\n\n'
          'Müşterileriniz tek tıkla Google Haritalar\'a yönlendirilir.',
          quickReplies: [
            const QuickReply(label: '> WhatsApp Ayarla', payload: 'whatsapp'),
            const QuickReply(label: '> Ana Menü', payload: 'merhaba'),
          ],
        );

      case 'yayinla':
        return ChatMessage.bot(
          '» Vitrininizi Yayına Almak:\n\n'
          '  • Bilgileri ve fotoğrafları ekleyin\n'
          '  • Vitrinim sayfasındaki "Yayınla" butonuna basın\n'
          '  • Vitriniz anında canlıya alınır\n\n'
          'Yayınlandıktan sonra linkinizi ve QR kodunuzu\n'
          'müşterilerinizle paylaşmaya başlayabilirsiniz.',
          quickReplies: [
            const QuickReply(label: '> QR & Link Al', payload: 'qr'),
            const QuickReply(label: '> Ana Menü', payload: 'merhaba'),
          ],
        );

      case 'ucret':
        return ChatMessage.bot(
          '» VitrinX Fiyatlandırma:\n\n'
          '  ✓ Vitrin oluşturma — Ücretsiz\n'
          '  ✓ Fotoğraf yükleme — Ücretsiz\n'
          '  ✓ WhatsApp entegrasyonu — Ücretsiz\n'
          '  ✓ QR kod ve link — Ücretsiz\n'
          '  ✓ Satıştan komisyon — Yok\n\n'
          'Kredi kartı gerekmez. Sürpriz ücret yoktur.',
          quickReplies: [
            const QuickReply(label: '> Vitrin Kur', payload: 'vitrin_kurulum'),
            const QuickReply(label: '> Ana Menü', payload: 'merhaba'),
          ],
        );

      default:
        return ChatMessage.bot(
          '» Üzgünüm, bunu tam anlayamadım.\n\n'
          'Aşağıdaki konulardan birini seçebilir\n'
          'ya da farklı bir şekilde sorabilirsiniz:',
          quickReplies: helpReplies,
        );
    }
  }
}

// ─── Intent sınıfı ─────────────────────────────────────────────────────────
class ChatbotIntent {
  final List<String> keywords;
  final String payload;
  const ChatbotIntent({required this.keywords, required this.payload});
}
