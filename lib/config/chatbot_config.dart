import 'package:vixrex/models/chat_message.dart';
import 'package:vixrex/services/vixrex_guidance_service.dart';
import 'package:vixrex/services/vixrex_profile_snapshot.dart';

/// Vixrex — Vixrex'in kural tabanlı kullanıcı rehberi.
/// Tüm yanıtlar Türkçedir. API bağlantısı yoktur; kural tabanlı çalışır.
abstract final class ChatbotConfig {
  static const String botName = 'Vixrex';
  static const String botSubtitle = 'Vixrex Rehberi';
  static const String systemStatus = 'AKTİF';

  // ─── Genel Karşılama (snapshot yokken) ──────────────────────────────────
  static ChatMessage get welcomeMessage => ChatMessage.bot(
        'Merhaba! Ben $botName, Vixrex rehberiyim.\n\n'
        'Vitrinini kurman, yayınlaman ve müşterilerine duyurman için sıradaki doğru adımı gösteririm.\n\n'
        'Nasıl yardımcı olayım?',
        quickReplies: mainMenuReplies(null),
      );

  // ─── Snapshot Tabanlı Karşılama Mesajları ────────────────────────────────

  /// Vitrin durumuna göre kişiselleştirilmiş karşılama mesajı üretir.
  static ChatMessage snapshotWelcome(
    VixRexProfileSnapshot snapshot, {
    required bool hasShared,
  }) {
    final recommendation = VixRexGuidanceService.recommendationFor(
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
    VixRexProfileSnapshot? snapshot, {
    bool hasShared = false,
  }) {
    if (snapshot == null) {
      return const [
        QuickReply(label: 'Vixrex Ne İşe Yarar?', payload: 'vixrex_info'),
        QuickReply(label: 'Üyelik / Kullanım', payload: 'membership_info'),
      ];
    }
    
    final recommendation = VixRexGuidanceService.recommendationFor(
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
          action: VixRexAction.copyLink,
        ),
        QuickReply(
          label: 'QR Göster',
          payload: 'show_qr',
          action: VixRexAction.showQr,
        ),
      ],
      const QuickReply(
        label: '📷 Ürün Ekle',
        payload: 'ocr_scan',
        action: VixRexAction.openOcrScanner,
      ),
      const QuickReply(label: 'Vixrex Ne İşe Yarar?', payload: 'vixrex_info'),
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
      keywords: ['vixrex', 'nedir', 'ne işe yarar', 'nasil calisir', 'kurulum', 'vitrin'],
      payload: 'vixrex_info',
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
    ChatbotIntent(
      keywords: ['fotograf', 'fatura', 'tara', 'urun ekle', 'katalog', 'otomatik', 'ocr'],
      payload: 'ocr_scan',
    ),
    ChatbotIntent(
      keywords: ['premium', 'ucretsiz', 'sinirsiz', 'ucretli', 'odeme'],
      payload: 'ocr_premium',
    ),
  ];

  // ─── Intent → Yanıt Tablosu ─────────────────────────────────────────────
  static ChatMessage responseFor(
    String payload, {
    VixRexProfileSnapshot? snapshot,
    bool hasShared = false,
  }) {
    switch (payload) {
      case 'merhaba':
        return snapshot == null
            ? welcomeMessage
            : snapshotWelcome(snapshot, hasShared: hasShared);

      case 'vixrex_info':
        return ChatMessage.bot(
          'Vixrex ile işletme bilgilerini tek yerde toplar, vitrinini yayınlar ve link, QR veya WhatsApp ile müşterilerine duyurursun.',
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

      case 'ocr_scan':
        return ChatMessage.bot(
          'Fotoğraftan ürün çıkarma özelliği ile fiş/fatura veya raf fiyat etiketi çekerek otomatik ürün kataloğu oluşturabilirsiniz.\n\n'
          'Tarama yapmak istediğiniz yöntemi seçin:',
          quickReplies: [
            const QuickReply(
              label: '📷 Fiş/Fatura Tara',
              payload: 'action_step',
              action: VixRexAction.openOcrScanner,
            ),
            const QuickReply(
              label: '🏷️ Raf/Etiket Tara',
              payload: 'action_step',
              action: VixRexAction.openOcrScannerShelf,
            ),
            const QuickReply(label: '❓ Nasıl Çalışır?', payload: 'ocr_info'),
          ],
        );

      case 'ocr_info':
        return ChatMessage.bot(
          'Nasıl Çalışır:\n'
          '1. Fotoğrafınızı çekin veya galeriden seçin\n'
          '2. Ürünler otomatik olarak tanınır\n'
          '3. Ürünleri onaylayın veya düzenleyin\n'
          '4. Onaylanan ürünler vitrininize eklenir\n\n'
          'Not: Bu özellik premium gerektirir.',
          quickReplies: [
            const QuickReply(label: 'Premium Bilgisi', payload: 'ocr_premium'),
            const QuickReply(label: 'Geri Dön', payload: 'merhaba'),
          ],
        );

      case 'ocr_premium':
        return ChatMessage.bot(
          'Premium üyelik ile:\n'
          '• Fotoğraftan sınırsız ürün çıkarma\n'
          '• Faturadan otomatik ürün kaydı\n'
          '• Toplu Excel yükleme\n'
          '• Barkod tarama\n\n'
          'Ücretsiz deneme: Günde 3 ücretsiz OCR hakkı.\n'
          'Premium için uygulama içinden satın alma yapabilirsiniz.',
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
