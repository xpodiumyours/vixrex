import 'package:vitrinx/models/chat_message.dart';
import 'package:vitrinx/services/xrex_guidance_service.dart';
import 'package:vitrinx/services/xrex_profile_snapshot.dart';

/// Xrex — VitrinX'in kural tabanlı kullanıcı rehberi.
/// Tüm yanıtlar Türkçedir. API bağlantısı yoktur; kural tabanlı çalışır.
abstract final class ChatbotConfig {
  static const String botName = 'Xrex';
  static const String botSubtitle = 'VitrinX Rehberi';
  static const String systemStatus = 'AKTİF';

  // ─── Genel Karşılama (snapshot yokken) ──────────────────────────────────
  static ChatMessage get welcomeMessage => ChatMessage.bot(
        'Merhaba! Ben $botName, VitrinX rehberiyim.\n\n'
        'Vitrinini kurman, yayınlaman ve müşterilerine duyurman için sıradaki doğru adımı gösteririm.\n\n'
        'Nasıl yardımcı olayım?',
        quickReplies: mainMenuReplies(null),
      );

  // ─── Snapshot Tabanlı Karşılama Mesajları ────────────────────────────────

  /// Vitrin durumuna göre kişiselleştirilmiş karşılama mesajı üretir.
  static ChatMessage snapshotWelcome(
    XrexProfileSnapshot snapshot, {
    required bool hasShared,
  }) {
    final recommendation = XrexGuidanceService.recommendationFor(
      snapshot: snapshot,
      hasShared: hasShared,
    );
    return ChatMessage.bot(
      '${recommendation.title}. ${recommendation.description}',
      quickReplies: mainMenuReplies(snapshot, hasShared: hasShared),
      snapshotStateKey: recommendation.id,
    );
  }

  // ─── Ana Menü Quick Reply'ları ───────────────────────────────────────────
  static List<QuickReply> mainMenuReplies(
    XrexProfileSnapshot? snapshot, {
    bool hasShared = false,
  }) {
    if (snapshot == null) {
      return const [
        QuickReply(label: 'VitrinX Ne İşe Yarar?', payload: 'vitrinx_info'),
        QuickReply(label: 'Üyelik / Kullanım', payload: 'membership_info'),
      ];
    }
    
    final recommendation = XrexGuidanceService.recommendationFor(
      snapshot: snapshot,
      hasShared: hasShared,
    );
    return [
      QuickReply(
        label: recommendation.buttonLabel,
        payload: 'action_step',
        action: recommendation.action,
      ),
      if (snapshot.isPublished) ...const [
        QuickReply(
          label: 'Linki Kopyala',
          payload: 'copy_link',
          action: XrexAction.copyLink,
        ),
        QuickReply(
          label: 'QR Göster',
          payload: 'show_qr',
          action: XrexAction.showQr,
        ),
      ],
      const QuickReply(label: 'VitrinX Ne İşe Yarar?', payload: 'vitrinx_info'),
      const QuickReply(label: 'Üyelik / Kullanım', payload: 'membership_info'),
    ];
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
  static ChatMessage responseFor(
    String payload, [
    XrexProfileSnapshot? snapshot,
    bool hasShared = false,
  ]) {
    switch (payload) {
      case 'merhaba':
        return snapshot == null
            ? welcomeMessage
            : snapshotWelcome(snapshot, hasShared: hasShared);

      case 'vitrinx_info':
        return ChatMessage.bot(
          'VitrinX ile işletme bilgilerini tek yerde toplar, vitrinini yayınlar ve link, QR veya WhatsApp ile müşterilerine duyurursun.',
          quickReplies: mainMenuReplies(snapshot, hasShared: hasShared),
        );
        
      case 'membership_info':
        return ChatMessage.bot(
          'Temel vitrin oluşturma şu an ücretsizdir. Gelişmiş özellikler uygulama içinde ayrıca gösterilecektir.',
          quickReplies: mainMenuReplies(snapshot, hasShared: hasShared),
        );

      case 'vitrin_kurulum':
        return ChatMessage.bot(
          'Vitrin kurulumu için yalnızca İşletme Adı, WhatsApp, Adres ve Yasal Onay adımlarını tamamlamanız yeterlidir.',
          quickReplies: mainMenuReplies(snapshot, hasShared: hasShared),
        );

      case 'fotograf':
        return ChatMessage.bot(
          'Vitrinim → Galeri veya Kapak Fotoğrafı bölümlerinden dilediğiniz fotoğrafları ekleyebilirsiniz.',
          quickReplies: mainMenuReplies(snapshot, hasShared: hasShared),
        );

      case 'qr':
        return ChatMessage.bot(
          'Vitrininizi yayınladıktan sonra sağ üstteki paylaş ikonundan QR kodunuza ve linkinize ulaşabilirsiniz.',
          quickReplies: mainMenuReplies(snapshot, hasShared: hasShared),
        );

      case 'randevu':
        return ChatMessage.bot(
          'Vitrinim → Randevu Yönetimi sayfasından randevu sisteminizi aktif edebilirsiniz.',
          quickReplies: mainMenuReplies(snapshot, hasShared: hasShared),
        );

      case 'whatsapp':
        return ChatMessage.bot(
          'Vitrinim → İletişim sayfasından müşterilerinizin size doğrudan ulaşmasını sağlayacak WhatsApp numaranızı girebilirsiniz.',
          quickReplies: mainMenuReplies(snapshot, hasShared: hasShared),
        );

      case 'adres':
        return ChatMessage.bot(
          'Vitrinim → Konum sayfasından adresinizi kaydedebilirsiniz. Müşterileriniz tek tıkla haritalarda sizi bulur.',
          quickReplies: mainMenuReplies(snapshot, hasShared: hasShared),
        );

      case 'yayinla':
        return ChatMessage.bot(
          'Vitrinim sayfasındaki "Yayınla" butonuna basarak dijital vitrininizi hemen müşterilerinizle buluşturabilirsiniz.',
          quickReplies: mainMenuReplies(snapshot, hasShared: hasShared),
        );

      default:
        return ChatMessage.bot(
          'Üzgünüm, bunu tam anlayamadım. Aşağıdaki seçeneklerden birini deneyebilirsiniz:',
          quickReplies: mainMenuReplies(snapshot, hasShared: hasShared),
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
