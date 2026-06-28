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
        quickReplies: mainMenuReplies(null),
      );

  // ─── Snapshot Tabanlı Karşılama Mesajları ────────────────────────────────

  /// Vitrin durumuna göre kişiselleştirilmiş karşılama mesajı üretir.
  static ChatMessage snapshotWelcome(XrexProfileSnapshot snapshot) {
    if (snapshot.isPublished) {
      return _publishedMessage(snapshot);
    } else if (snapshot.isReadyToPublish) {
      return _readyToPublishMessage(snapshot);
    } else {
      return _incompleteMessage(snapshot);
    }
  }

  static XrexAction _actionForField(XrexNextStep step) {
    switch (step) {
      case XrexNextStep.name:     return XrexAction.scrollToName;
      case XrexNextStep.whatsapp: return XrexAction.scrollToWhatsapp;
      case XrexNextStep.address:  return XrexAction.scrollToAddress;
      case XrexNextStep.legal:    return XrexAction.scrollToLegal;
      case XrexNextStep.publish:  return XrexAction.openVitrim;
      case XrexNextStep.share:    return XrexAction.none; // Share shows direct buttons
    }
  }

  static ChatMessage _incompleteMessage(XrexProfileSnapshot snapshot) {
    final field = snapshot.nextMissingField;
    return ChatMessage.bot(
      'Vitrinini birlikte tamamlayalım. Sıradaki adım: ${field.label}. Bunu ekleyince müşterilerin seni daha kolay bulur.',
      quickReplies: mainMenuReplies(snapshot),
      snapshotStateKey: 'incomplete_${field.name}',
    );
  }

  static ChatMessage _readyToPublishMessage(XrexProfileSnapshot snapshot) {
    return ChatMessage.bot(
      'Vitrinin yayına hazır. Şimdi yayınla butonuna basarak müşterilerinle paylaşabilirsin.',
      quickReplies: mainMenuReplies(snapshot),
      snapshotStateKey: 'ready',
    );
  }

  static ChatMessage _publishedMessage(XrexProfileSnapshot snapshot) {
    return ChatMessage.bot(
      'Vitrinin yayında. Şimdi müşterilerine ulaştır: linkini kopyala, QR kodunu göster veya WhatsApp’ta paylaş.',
      quickReplies: mainMenuReplies(snapshot),
      snapshotStateKey: 'published',
    );
  }



  // ─── Ana Menü Quick Reply'ları ───────────────────────────────────────────
  static List<QuickReply> mainMenuReplies(XrexProfileSnapshot? snapshot) {
    if (snapshot == null) {
      return const [
        QuickReply(label: 'VitrinX Ne İşe Yarar?', payload: 'vitrinx_info'),
        QuickReply(label: 'Üyelik / Kullanım', payload: 'membership_info'),
      ];
    }
    
    if (snapshot.isPublished) {
      return const [
        QuickReply(label: 'Linki Kopyala', payload: 'copy_link', action: XrexAction.copyLink),
        QuickReply(label: 'QR Göster', payload: 'show_qr', action: XrexAction.showQr),
        QuickReply(label: 'WhatsApp\'ta Paylaş', payload: 'share_whatsapp', action: XrexAction.shareWhatsapp),
        QuickReply(label: 'Vitrinime Git', payload: 'goto_vitrim', action: XrexAction.openVitrim),
        QuickReply(label: 'VitrinX Ne İşe Yarar?', payload: 'vitrinx_info'),
        QuickReply(label: 'Üyelik / Kullanım', payload: 'membership_info'),
      ];
    } else {
      final field = snapshot.nextMissingField;
      return [
        QuickReply(label: 'Sıradaki Adımı Yap', payload: 'action_step', action: _actionForField(field)),
        const QuickReply(label: 'VitrinX Ne İşe Yarar?', payload: 'vitrinx_info'),
        const QuickReply(label: 'Üyelik / Kullanım', payload: 'membership_info'),
        const QuickReply(label: 'Vitrinime Git', payload: 'goto_vitrim', action: XrexAction.openVitrim),
      ];
    }
  }

  static List<QuickReply> get helpReplies => mainMenuReplies(null);

  // ─── Intent Tanımları ────────────────────────────────────────────────────
  static const List<ChatbotIntent> intents = [
    ChatbotIntent(
      keywords: ['merhaba', 'selam', 'nasil', 'baslat', 'baslayalim', 'yardim', 'ne yapabilirsin'],
      payload: 'merhaba',
    ),
    ChatbotIntent(
      keywords: ['vitrinx', 'nedir', 'ne işe yarar', 'nasil calisir', 'kurulum', 'vitrin'],
      payload: 'vitrinx_info',
    ),
    ChatbotIntent(
      keywords: ['ucret', 'fiyat', 'para', 'komisyon', 'ucretsiz', 'odeme', 'bedava', 'uyelik', 'kullanim'],
      payload: 'membership_info',
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
  ];

  // ─── Intent → Yanıt Tablosu ─────────────────────────────────────────────
  static ChatMessage responseFor(String payload, [XrexProfileSnapshot? snapshot]) {
    switch (payload) {
      case 'merhaba':
        return welcomeMessage;

      case 'vitrinx_info':
        return ChatMessage.bot(
          'VitrinX, işletmeni link ve QR ile paylaşılabilir dijital vitrine dönüştürür. Ürün, hizmet, konum, WhatsApp ve randevu bilgilerini tek sayfada toplar.',
          quickReplies: mainMenuReplies(snapshot),
        );
        
      case 'membership_info':
        return ChatMessage.bot(
          'Temel vitrin oluşturma şu an ücretsizdir. Gelişmiş özellikler uygulama içinde ayrıca gösterilecektir.',
          quickReplies: mainMenuReplies(snapshot),
        );

      case 'vitrin_kurulum':
        return ChatMessage.bot(
          'Vitrin kurulumu için yalnızca İşletme Adı, WhatsApp, Adres ve Yasal Onay adımlarını tamamlamanız yeterlidir.',
          quickReplies: mainMenuReplies(snapshot),
        );

      case 'fotograf':
        return ChatMessage.bot(
          'Vitrinim → Galeri veya Kapak Fotoğrafı bölümlerinden dilediğiniz fotoğrafları ekleyebilirsiniz.',
          quickReplies: mainMenuReplies(snapshot),
        );

      case 'qr':
        return ChatMessage.bot(
          'Vitrininizi yayınladıktan sonra sağ üstteki paylaş ikonundan QR kodunuza ve linkinize ulaşabilirsiniz.',
          quickReplies: mainMenuReplies(snapshot),
        );

      case 'randevu':
        return ChatMessage.bot(
          'Vitrinim → Randevu Yönetimi sayfasından randevu sisteminizi aktif edebilirsiniz.',
          quickReplies: mainMenuReplies(snapshot),
        );

      case 'whatsapp':
        return ChatMessage.bot(
          'Vitrinim → İletişim sayfasından müşterilerinizin size doğrudan ulaşmasını sağlayacak WhatsApp numaranızı girebilirsiniz.',
          quickReplies: mainMenuReplies(snapshot),
        );

      case 'adres':
        return ChatMessage.bot(
          'Vitrinim → Konum sayfasından adresinizi kaydedebilirsiniz. Müşterileriniz tek tıkla haritalarda sizi bulur.',
          quickReplies: mainMenuReplies(snapshot),
        );

      case 'yayinla':
        return ChatMessage.bot(
          'Vitrinim sayfasındaki "Yayınla" butonuna basarak dijital vitrininizi hemen müşterilerinizle buluşturabilirsiniz.',
          quickReplies: mainMenuReplies(snapshot),
        );

      default:
        return ChatMessage.bot(
          'Üzgünüm, bunu tam anlayamadım. Aşağıdaki seçeneklerden birini deneyebilirsiniz:',
          quickReplies: mainMenuReplies(snapshot),
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
