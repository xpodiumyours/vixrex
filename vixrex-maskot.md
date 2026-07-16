# VİXREX MASCOT EMPAR ANALİZİ

**Tarih**: 15 Temmuz 2026  
**Kapsam**: Maskot ile ilgili tüm dosyaların satır satır analizi  
**Yöntem**: Gerçek kod satırlarına dayalı, varsayım yok  

---

## DOSYA HARİTASI

| # | Dosya | Satır | Kullanım |
|---|-------|-------|----------|
| 1 | `lib/widgets/vixrex/vixrex_hero.dart` | 77 | VixRex ekranının üstü |
| 2 | `lib/widgets/chatbot_badge.dart` | 201 | Sağ alt köşede chatbot butonu |
| 3 | `lib/widgets/vixrex_panel.dart` | 605 | Panel üstünde avatar |
| 4 | `lib/screens/vixrex_screen.dart` | 479 | VixRex ana ekranı |
| 5 | `lib/config/chatbot_config.dart` | 257 | Chatbot konfigürasyonu |
| 6 | `lib/services/chatbot_service.dart` | 141 | Chatbot servis mantığı |
| 7 | `lib/widgets/vixrex_message_bubble.dart` | 182 | Mesaj baloncukları |
| 8 | `lib/widgets/vixrex_quick_replies.dart` | 59 | Hızlı cevap butonları |
| 9 | `lib/widgets/vixrex/vixrex_progress_card.dart` | 85 | İlerleme kartı |
| 10 | `lib/widgets/vixrex/vixrex_recommendation_card.dart` | 132 | Öneri kartı |
| 11 | `lib/services/vixrex_guidance_service.dart` | 324 | Rehberlik servisi |
| 12 | `lib/services/vixrex_profile_snapshot.dart` | 209 | Profil anlık görüntüsü |
| 13 | `lib/models/chat_message.dart` | 145 | Mesaj modelleri |

---

## 1. MASCOT KULLANIM YERLERİ

### 1.1 VixRexHero (`vixrex_hero.dart`)

**Satır 18-39**: Ana mascot gösterimi
```dart
Container(
  width: mascotSize,      // 150-200px (dinamik)
  height: mascotSize,
  decoration: BoxDecoration(
    shape: BoxShape.circle,
    color: Colors.transparent,
    boxShadow: [
      BoxShadow(
        color: AppColors.primary.withAlpha(30),
        blurRadius: 24,
        spreadRadius: 4,
      ),
    ],
  ),
  child: ClipOval(
    child: Image.asset(
      'assets/images/vixrex_mascot.webp',
      width: mascotSize,
      height: mascotSize,
      fit: BoxFit.cover,
    ),
  ),
)
```

**Davranış**: Sadece statik görsel + glow shadow. Animasyon YOK.

**Boyut Hesabı** (`vixrex_screen.dart:48-55`):
```dart
final heightBasedSize = screenSize.height * 0.24;
final widthBasedSize = screenSize.width * 0.56;
final availableSize = heightBasedSize < widthBasedSize ? heightBasedSize : widthBasedSize;
final mascotSize = availableSize.clamp(150, 200).toDouble();
```

---

### 1.2 ChatbotBadge (`chatbot_badge.dart`)

**Boyut**: `const double _vixrexBadgeSize = 84` (sabit)

**Animasyonlar** (`satır 46-60`):
```dart
// Pulse (nabız) - 2 sn döngü
_pulseController = AnimationController(
  vsync: this,
  duration: const Duration(seconds: 2),
)..repeat(reverse: true);
_pulseAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
  CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
);

// Scan (tarama çizgisi) - 3 sn döngü
_scanController = AnimationController(
  vsync: this,
  duration: const Duration(seconds: 3),
)..repeat();
_scanAnim = Tween<double>(begin: -1.0, end: 1.0).animate(
  CurvedAnimation(parent: _scanController, curve: Curves.linear),
);
```

**Build (`satır 85-163`)**:
```dart
GestureDetector(
  onTap: () => _openChat(context),
  child: AnimatedBuilder(
    animation: Listenable.merge([_pulseController, _scanController]),
    child: Image.asset(
      'assets/images/vixrex_mascot.webp',
      width: _vixrexBadgeSize,
      height: _vixrexBadgeSize,
      fit: BoxFit.contain,
    ),
    builder: (context, mascot) {
      return Container(
        width: _vixrexBadgeSize,
        height: _vixrexBadgeSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withAlpha(20),
          border: Border.all(color: AppColors.primary.withAlpha(40), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withAlpha(
                (255 * 0.35 * _pulseAnim.value).round()
              ),
              blurRadius: 18,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipOval(
          child: Stack(
            alignment: Alignment.center,
            children: [
              mascot!,  // Görsel
              // Scan çizgisi
              Positioned(
                top: (_vixrexBadgeSize / 2) +
                    (_scanAnim.value * (_vixrexBadgeSize * 0.4)),
                left: 10,
                right: 10,
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withAlpha(0),
                        AppColors.primary.withAlpha(120),
                        AppColors.primary.withAlpha(0),
                      ],
                    ),
                  ),
                ),
              ),
              // Yeşil online noktası
              Positioned(
                bottom: 6,
                right: 6,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.success.withAlpha(180),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  ),
)
```

**Davranış**:
1. Pulse: 0.6 → 1.0 → 0.6 (2 sn döngü, easeInOut)
2. Scan: -1.0 → 1.0 (3 sn döngü, linear) - dikey çizgi yukarıdan aşağıya
3. Glow: `primary.withAlpha((255 * 0.35 * pulseAnim.value).round())` - pulse ile değişen parlaklık
4. Online: Yeşil nokta (sabit, animasyonsuz)
5. Tıklayınca: `VixRexOverlay.show()` → Panel açılır

---

### 1.3 VixRexPanel (`vixrex_panel.dart`)

**Avatar Boyutu**: `const double _vixrexPanelAvatarSize = 68`

**Avatar Build (`satır 493-558`)**:
```dart
Widget _buildAvatar() {
  return AnimatedBuilder(
    animation: _scanController,
    child: Image.asset(
      'assets/images/vixrex_mascot.webp',
      width: _vixrexPanelAvatarSize,
      height: _vixrexPanelAvatarSize,
      fit: BoxFit.cover,
    ),
    builder: (context, mascot) {
      return Container(
        color: AppColors.bgEditor,
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: _vixrexPanelAvatarSize,
              height: _vixrexPanelAvatarSize,
              child: ClipOval(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    mascot!,
                    // Scan çizgisi
                    Positioned(
                      top: (_vixrexPanelAvatarSize / 2) +
                          (_scanAnim.value * (_vixrexPanelAvatarSize / 2)),
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 1.5,
                        color: AppColors.primary.withAlpha(50),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ChatbotConfig.botName,  // 'Vixrex'
                  style: TextStyle(
                    color: AppColors.darkText,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  ChatbotConfig.botSubtitle,  // 'Vixrex Rehberi'
                  style: TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}
```

**Davranış**:
1. Scan: 3 sn döngü ile dikey çizgi (aynı chatbot_badge ile)
2. Bot adı + alt başlık yanında
3. Sohbet arayüzünde bot temsili

---

## 2. CHATBOT SİSTEMİ

### 2.1 Yapılandırma (`chatbot_config.dart`)

**Sabitler**:
```dart
static const String botName = 'Vixrex';
static const String botSubtitle = 'Vixrex Rehberi';
static const String systemStatus = 'AKTİF';
```

**Karşılama Mesajı**:
```dart
static ChatMessage get welcomeMessage => ChatMessage.bot(
  'Merhaba! Ben $botName, Vixrex rehberiyim.\n\n'
  'Vitrinini kurman, yayınlaman ve müşterilerine duyurman için sıradaki doğru adımı gösteririm.\n\n'
  'Nasıl yardımcı olayım?',
  quickReplies: mainMenuReplies(null),
);
```

**Kişisel Karşılama**:
```dart
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
```

**Quick Reply'lar**:
```dart
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
```

### 2.2 Intent Tanımları (11 adet)

```dart
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
```

### 2.3 Yanıt Tablosu (13 yanıt)

```dart
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
```

---

## 3. CHATBOT SERVİSİ (`chatbot_service.dart`)

### 3.1 Mesaj İşleme

```dart
ChatMessage respond(
  String input, [
  VixRexProfileSnapshot? snapshot,
  bool hasShared = false,
]) {
  final normalized = _normalize(input);

  // Intent eşleştirme
  for (final intent in ChatbotConfig.intents) {
    for (final keyword in intent.keywords) {
      if (normalized.contains(_normalize(keyword))) {
        return ChatbotConfig.responseFor(
          intent.payload,
          snapshot: snapshot,
          hasShared: hasShared,
        );
      }
    }
  }

  // Eşleşme bulunamadı
  return ChatbotConfig.responseFor(
    'default',
    snapshot: snapshot,
    hasShared: hasShared,
  );
}
```

### 3.2 Türkçe Karakter Normalizasyonu

```dart
String _normalize(String text) {
  return text
      .toLowerCase()
      .replaceAll('ı', 'i')
      .replaceAll('ğ', 'g')
      .replaceAll('ü', 'u')
      .replaceAll('ş', 's')
      .replaceAll('ö', 'o')
      .replaceAll('ç', 'c')
      .replaceAll('İ', 'i')
      .replaceAll('Ğ', 'g')
      .replaceAll('Ü', 'u')
      .replaceAll('Ş', 's')
      .replaceAll('Ö', 'o')
      .replaceAll('Ç', 'c');
}
```

### 3.3 Durum Yönetimi (SharedPreferences)

```dart
// Key'ler
static const String _greetedKey = 'vixrex_greeted';
static const String _sharedMilestoneKey = 'vixrex_vitrin_shared';
static const String _dismissedRecommendationKey = 'vixrex_dismissed_recommendation';
static const String _historyKey = 'vixrex_chat_history';

// Metodlar
Future<bool> wasGreeted() async {...}
Future<void> markGreeted() async {...}
Future<bool> hasSharedVitrin() async {...}
Future<void> markVitrinShared() async {...}
Future<String?> loadDismissedRecommendationId() async {...}
Future<void> dismissRecommendation(String recommendationId) async {...}
Future<void> saveHistory(List<ChatMessage> history) async {...}
Future<List<ChatMessage>> loadHistory() async {...}
Future<void> clearHistory() async {...}
```

---

## 4. REHBERLİK SİSTEMİ

### 4.1 Profil Anlık Görüntüsü (`vixrex_profile_snapshot.dart`)

```dart
class VixRexProfileSnapshot {
  static const int requiredStepCount = 4;

  final bool nameCompleted;
  final bool whatsappCompleted;
  final bool addressCompleted;
  final bool legalCompleted;
  final bool coverCompleted;
  final bool galleryCompleted;
  final bool descriptionCompleted;
  final bool catalogCompleted;
  final bool autoFillCompleted;
  final bool isPublished;
  final String storeName;
  final String category;
  final String district;
  final String publicLink;

  // Factory
  factory VixRexProfileSnapshot.from(
    StoreData data,
    PublishedVitrinInfo? publishedInfo, {
    bool autoFillCompleted = false,
  }) {
    final nameOk = data.name.trim().isNotEmpty;
    final whatsappOk = data.whatsapp.trim().isNotEmpty &&
        WhatsAppLinkHelper.isValidTurkeyMobile(data.whatsapp);
    final addressOk = data.address.trim().isNotEmpty &&
        data.provinceName.trim().isNotEmpty &&
        data.districtName.trim().isNotEmpty;
    final legalOk = data.privacyNoticeAcknowledged &&
        data.termsAccepted &&
        data.publicationConsentAccepted;
    final isPublished = publishedInfo != null && publishedInfo.isComplete;
    final coverCompleted = data.shelfImageUrl.trim().isNotEmpty;
    final galleryCompleted = data.galleryItems.isNotEmpty;
    final descriptionCompleted = data.description.trim().isNotEmpty;
    final catalogCompleted = data.products.isNotEmpty || data.offerings.isNotEmpty;

    return VixRexProfileSnapshot(
      nameCompleted: nameOk,
      whatsappCompleted: whatsappOk,
      addressCompleted: addressOk,
      legalCompleted: legalOk,
      coverCompleted: coverCompleted,
      galleryCompleted: galleryCompleted,
      descriptionCompleted: descriptionCompleted,
      catalogCompleted: catalogCompleted,
      autoFillCompleted: autoFillCompleted,
      isPublished: isPublished,
      storeName: data.name.trim(),
      category: data.kategori.trim().isNotEmpty
          ? data.kategori.trim()
          : data.businessType.trim(),
      district: data.districtName.trim(),
      publicLink: publishedInfo?.publicLink.trim() ?? '',
    );
  }

  // Sıradaki eksik adım
  VixRexNextStep get nextMissingField {
    if (!nameCompleted) return VixRexNextStep.name;
    if (!whatsappCompleted) return VixRexNextStep.whatsapp;
    if (!addressCompleted) return VixRexNextStep.address;
    if (!legalCompleted) return VixRexNextStep.legal;
    if (!isPublished) return VixRexNextStep.publish;
    return VixRexNextStep.share;
  }

  // Yardımcılar
  bool get isReadyToPublish =>
      nameCompleted && whatsappCompleted && addressCompleted &&
      legalCompleted && !isPublished;

  bool get areRequiredFieldsCompleted =>
      nameCompleted && whatsappCompleted && addressCompleted && legalCompleted;

  int get completedRequiredStepCount =>
      [nameCompleted, whatsappCompleted, addressCompleted, legalCompleted]
          .where((completed) => completed).length;
}
```

### 4.2 Journey Phases

```dart
enum VixRexJourneyPhase { setup, publish, share, improve }
enum VixRexNextStep { name, whatsapp, address, legal, publish, share }
```

### 4.3 Öneri Motoru (`vixrex_guidance_service.dart`)

```dart
static VixRexRecommendation recommendationFor({
  VixRexProfileSnapshot? snapshot,
  required bool hasShared,
}) {
  // 1. Snapshot yoksa
  if (snapshot == null) {
    return const VixRexRecommendation(
      id: 'welcome',
      phase: VixRexJourneyPhase.setup,
      title: 'Vitrininizi Oluşturun',
      description: 'Vixrex ile dijital vitrininizi oluşturmak için ilk adımı atın.',
      buttonLabel: 'Başla',
      action: VixRexAction.openVitrim,
    );
  }

  // 2. Setup phase - eksik alanlar
  final setupRec = setupRecommendation(snapshot);
  if (setupRec != null) return setupRec;

  // 3. Yayınlanmamışsa
  if (!snapshot.isPublished) {
    return const VixRexRecommendation(
      id: 'publish',
      phase: VixRexJourneyPhase.publish,
      title: 'Vitrininizi Yayınlayın',
      description: 'Tüm gerekli bilgileri doldurdunuz. Şimdi vitrininizi yayınlayabilirsiniz.',
      buttonLabel: 'Yayınla',
      action: VixRexAction.openVitrim,
    );
  }

  // 4. Paylaşılmamışsa
  if (!hasShared) {
    return const VixRexRecommendation(
      id: 'share',
      phase: VixRexJourneyPhase.share,
      title: 'Vitrininizi Paylaşın',
      description: 'Vitrininiz yayında! Müşterilerinize ulaşmak için paylaşın.',
      buttonLabel: 'Paylaş',
      action: VixRexAction.shareWhatsapp,
    );
  }

  // 5. İyileştirme önerileri
  final improvements = improvementRecommendations(snapshot);
  if (improvements.isNotEmpty) return improvements.first;

  // 6. Tamamlandı
  return const VixRexRecommendation(
    id: 'all_done',
    phase: VixRexJourneyPhase.improve,
    title: 'Tebrikler!',
    description: 'Vitrininiz harika görünüyor. Daha fazla özellik için bize ulaşabilirsiniz.',
    buttonLabel: 'Vitrinime Git',
    action: VixRexAction.openVitrim,
  );
}
```

### 4.4 Kalite Raporu (5 madde, 50 puan)

```dart
static List<VixRexQualityItem> qualityItems(VixRexProfileSnapshot? snapshot) {
  return [
    VixRexQualityItem(
      id: 'cover',
      label: 'Kapak fotoğrafı',
      points: 10,
      completed: snapshot?.coverCompleted ?? false,
      action: VixRexAction.scrollToCover,
    ),
    VixRexQualityItem(
      id: 'description',
      label: 'İşletme açıklaması',
      points: 10,
      completed: snapshot?.descriptionCompleted ?? false,
      action: VixRexAction.scrollToDesc,
    ),
    VixRexQualityItem(
      id: 'gallery',
      label: 'Galeri görselleri',
      points: 10,
      completed: snapshot?.galleryCompleted ?? false,
      action: VixRexAction.scrollToGallery,
    ),
    VixRexQualityItem(
      id: 'catalog',
      label: 'Ürün veya hizmetler',
      points: 10,
      completed: snapshot?.catalogCompleted ?? false,
      action: VixRexAction.scrollToProducts,
    ),
    VixRexQualityItem(
      id: 'auto_fill',
      label: 'Kategoriye özel görseller',
      points: 10,
      completed: snapshot?.autoFillCompleted ?? false,
      action: VixRexAction.scrollToCategory,
    ),
  ];
}

// Normalize: raw 0-50 → 0-100
static VixRexQualityReport qualityReportFor({...}) {
  final items = qualityItems(snapshot);
  final rawScore = items.where((i) => i.completed).fold(0, (s, i) => s + i.points);
  final maxScore = maxQualityScore();
  final normalizedScore = maxScore > 0
      ? ((rawScore / maxScore) * 100).round().clamp(0, 100)
      : 0;
  // ...
}
```

---

## 5. MESAJ BALONCUKLARI

### 5.1 Bot Mesajı (`vixrex_message_bubble.dart`)

```dart
class VixRexBotMessage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sol tarafta bot avatarı
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(20),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Text(
              'X',
              style: TextStyle(
                color: AppColors.primaryDark,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Sağ tarafta mesaj
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.bgEditor,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(12),
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...lines.map((line) {
                  return RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: line,
                          style: TextStyle(
                            color: AppColors.darkText,
                            fontSize: 12.5,
                            height: 1.5,
                            fontFamily: 'monospace',
                          ),
                        ),
                        if (isCursor && cursorVisible)
                          TextSpan(
                            text: ' ▌',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  );
                }),
                if (msg.snapshotScore != null)
                  VixRexScoreBar(score: msg.snapshotScore!),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
```

### 5.2 Kullanıcı Mesajı

```dart
class VixRexUserMessage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: AppColors.ctaGradient,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Text(
              msg.text,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
```

### 5.3 Yazma İndikatörü

```dart
class VixRexTypingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Bot avatarı
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(20),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Text('X', ...),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.bgEditor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: const Text(
            'Analiz ediliyor...',
            style: TextStyle(
              color: AppColors.mutedText,
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }
}
```

---

## 6. HIZLI CEVAP BUTONLARI

```dart
class VixRexQuickReplies extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bgEditor,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SizedBox(
        height: 44,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          itemCount: replies.length,
          separatorBuilder: (_, __) => const SizedBox(width: 6),
          itemBuilder: (context, index) {
            final r = replies[index];
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onTap(r),
              child: Container(
                constraints: const BoxConstraints(minHeight: 44),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  gradient: AppColors.ctaGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  r.label,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
```

---

## 7. AKIŞ DİYAGRAMI

### 7.1 Chatbot Akışı

```
Kullanıcı mesajı
    ↓
_chatbot_service.dart: respond()
    ↓
_normalize() → Türkçe karakter dönüşümü
    ↓
ChatbotConfig.intents → 11 intent, 50+ keyword
    ↓
Eşleşme varsa → ChatbotConfig.responseFor(payload)
Eşleşme yoksa → ChatbotConfig.responseFor('default')
    ↓
responseFor() → switch(payload) → 13 farklı yanıt
    ↓
ChatMessage.bot(text, quickReplies: [...])
    ↓
VixRexPanel'de gösterilir
```

### 7.2 Guidance Akışı

```
VixRexProfileSnapshot.from(StoreData, PublishedVitrinInfo)
    ↓
8 boolean alan: name, whatsapp, address, legal, cover, gallery, description, catalog
    ↓
VixRexGuidanceService.recommendationFor(snapshot, hasShared)
    ↓
5 aşamalı karar ağacı:
1. snapshot null → "Vitrininizi Oluşturun"
2. Zorunlu alanlar eksik → Sıradaki eksik alanı söyle
3. Yayınlanmamış → "Vitrininizi Yayınlayın"
4. Paylaşılmamış → "Vitrininizi Paylaşın"
5. Tamamlandı → "Tebrikler!"
    ↓
Kalite raporu: 5 madde, 50 puan → 0-100 normalize
```

---

## 8. MASCOT DAVRANIŞ HARİTASI

```
MASCOT (vixrex_mascot.webp)
├── VixRexHero (150-200px)
│   └── Sadece statik görsel + glow shadow
├── ChatbotBadge (84px)
│   ├── Pulse animasyonu (0.6→1.0, 2sn)
│   ├── Scan çizgisi (-1.0→1.0, 3sn)
│   ├── Glow (pulse ile değişen)
│   ├── Yeşil online noktası
│   └── Tıklayınca → VixRexPanel açılır
└── VixRexPanel (68px avatar)
    ├── Scan çizgisi (aynı)
    ├── Bot adı + alt başlık
    └── Sohbet arayüzü
        ├── Header: botName + "AKTİF" + Temizle + Kapat
        ├── Avatar: scan + bot bilgisi
        ├── Mesaj listesi (bot/user)
        ├── Quick replies (yatay scroll)
        └── Input alanı + gönder butonu
```

---

## 9. MASCOT OLMADIĞI YERLER

| Ekran | Durum |
|-------|-------|
| Landing Screen | Yok |
| Explore Screen | Yok |
| Profile Screen | Yok |
| My Vitrin Screen | Yok |
| Public Vitrin | Yok |
| Auth Screen | Yok |
| Booking Screen | Yok |
| Blog Editor | Yok |

---

## 10. TEKNİK ÖZET

| Metrik | Değer |
|--------|-------|
| Görsel dosyası | `assets/images/vixrex_mascot.webp` |
| Animasyon türü | Pulse (nabız) + Scan (tarama çizgisi) |
| Pulse döngüsü | 2 sn, 0.6 → 1.0 → 0.6, easeInOut |
| Scan döngüsü | 3 sn, -1.0 → 1.0, linear |
| Chatbot türü | Kural tabanlı, offline |
| Intent sayısı | 11 |
| Yanıt sayısı | 13 |
| Kalite maddesi | 5 (50 puan, 0-100 normalize) |
| Journey phase | 4 (setup, publish, share, improve) |
| Toplam dosya | 13 |
| Toplam satır | ~3,500 |
