import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vixrex/config/chatbot_config.dart';
import 'package:vixrex/models/chat_message.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/services/chatbot_service.dart';
import 'package:vixrex/services/store_local_storage_service.dart';
import 'package:vixrex/services/vixrex_guidance_service.dart';
import 'package:vixrex/services/vixrex_profile_snapshot.dart';

void main() {
  group('ChatbotConfig setup invite', () {
    test('yayınlanmamış rehber davet metni ve Evet CTA', () {
      final snapshot = VixRexProfileSnapshot.from(StoreData(), null);
      final msg = ChatbotConfig.snapshotWelcome(snapshot, hasShared: false);
      expect(msg.snapshotStateKey, ChatbotConfig.setupInviteStateKey);
      expect(msg.text, contains('oluşturmamı ister misin'));
      expect(msg.quickReplies, hasLength(1));
      expect(msg.quickReplies.single.label, 'Evet, Oluşturalım');
      expect(msg.quickReplies.single.action, VixRexAction.openVitrim);
      expect(msg.text, isNot(contains('İşletme Adı Ekle')));
    });

    test('eski field-setup tip stale sayılır', () {
      final stale = ChatMessage.bot(
        'İşletme adınızı girin.',
        quickReplies: const [
          QuickReply(
            label: 'İşletme Adı Ekle',
            payload: 'action_step',
            action: VixRexAction.openVitrim,
          ),
        ],
        snapshotStateKey: 'setup_name',
      );
      expect(ChatbotConfig.isStaleUnpublishedSetupTip(stale), isTrue);
      expect(
        ChatbotConfig.isStaleUnpublishedSetupTip(
          ChatbotConfig.setupInviteMessage,
        ),
        isFalse,
      );
    });
  });

  group('VixRexGuidanceService setup', () {
    test('yayınlanmamış kurulum CTA onboarding kapısına gider (openVitrim)', () {
      final snapshot = VixRexProfileSnapshot.from(StoreData(), null);
      final rec = VixRexGuidanceService.recommendationFor(
        snapshot: snapshot,
        hasShared: false,
      );
      expect(rec.id, 'setup_name');
      expect(rec.action, VixRexAction.openVitrim);
    });

    test('yayınlı ama kategorisi eksikse önce kategorini seç önerisi', () {
      final store = StoreData().copyWith(
        name: 'Test',
        whatsapp: '05551234567',
        address: 'Adres',
        provinceName: 'Istanbul',
        districtName: 'Kadikoy',
        privacyNoticeAcknowledged: true,
        privacyNoticeVersion: '1.0',
        termsAccepted: true,
        termsVersion: '1.0',
        publicationConsentAccepted: true,
        publicationConsentVersion: '1.0',
      );
      const published = PublishedVitrinInfo(
        slug: 'test',
        publicLink: 'https://vixrex-public.vercel.app/v/test',
        name: 'Test',
        editToken: 'token',
      );
      final snapshot = VixRexProfileSnapshot.from(store, published);
      final rec = VixRexGuidanceService.recommendationFor(
        snapshot: snapshot,
        hasShared: false,
      );
      expect(rec.id, 'improve_category');
      expect(rec.action, VixRexAction.scrollToCategory);
    });

    test('yayınlı ve kategorisi tam ama kapak eksikse şablon picker aksiyonu', () {
      final store = StoreData().copyWith(
        name: 'Test',
        whatsapp: '05551234567',
        address: 'Adres',
        provinceName: 'Istanbul',
        districtName: 'Kadikoy',
        kategori: 'giyim',
        privacyNoticeAcknowledged: true,
        privacyNoticeVersion: '1.0',
        termsAccepted: true,
        termsVersion: '1.0',
        publicationConsentAccepted: true,
        publicationConsentVersion: '1.0',
      );
      const published = PublishedVitrinInfo(
        slug: 'test',
        publicLink: 'https://vixrex-public.vercel.app/v/test',
        name: 'Test',
        editToken: 'token',
      );
      final snapshot = VixRexProfileSnapshot.from(store, published);
      final rec = VixRexGuidanceService.recommendationFor(
        snapshot: snapshot,
        hasShared: false,
      );
      expect(rec.id, 'improve_cover');
      expect(rec.action, VixRexAction.openCoverTemplatePicker);
    });
  });

  group('VixRexProfileSnapshot', () {
    test('Bos magaza icin name beklenmeli', () {
      final store = StoreData();
      final snapshot = VixRexProfileSnapshot.from(store, null);
      
      expect(snapshot.nameCompleted, isFalse);
      expect(snapshot.nextMissingField, VixRexNextStep.name);
    });

    test('Name dolu ise whatsapp beklenmeli', () {
      final store = StoreData().copyWith(name: 'Test Store');
      final snapshot = VixRexProfileSnapshot.from(store, null);
      
      expect(snapshot.nameCompleted, isTrue);
      expect(snapshot.whatsappCompleted, isFalse);
      expect(snapshot.nextMissingField, VixRexNextStep.whatsapp);
    });

    test('Legal eksik ise legal beklenmeli', () {
      final store = StoreData().copyWith(
        name: 'Test Store',
        whatsapp: '05551234567',
        address: 'Test Adres',
        provinceName: 'Istanbul',
        districtName: 'Kadikoy',
      );
      final snapshot = VixRexProfileSnapshot.from(store, null);
      
      expect(snapshot.nameCompleted, isTrue);
      expect(snapshot.whatsappCompleted, isTrue);
      expect(snapshot.addressCompleted, isTrue);
      expect(snapshot.legalCompleted, isFalse);
      expect(snapshot.nextMissingField, VixRexNextStep.legal);
    });

    test('IsReadyToPublish legal dahil her sey tamamsa true olmali', () {
      final store = StoreData().copyWith(
        name: 'Test Store',
        whatsapp: '05551234567',
        address: 'Test Adres',
        provinceName: 'Istanbul',
        districtName: 'Kadikoy',
        privacyNoticeAcknowledged: true,
        privacyNoticeVersion: '1.0',
        privacyNoticeHash: 'hash',
        termsAccepted: true,
        termsVersion: '1.0',
        termsHash: 'hash',
        publicationConsentAccepted: true,
        publicationConsentVersion: '1.0',
        publicationConsentHash: 'hash',
      );
      final snapshot = VixRexProfileSnapshot.from(store, null);
      
      expect(snapshot.legalCompleted, isTrue);
      expect(snapshot.isReadyToPublish, isTrue);
      expect(snapshot.isPublished, isFalse);
      expect(snapshot.nextMissingField, VixRexNextStep.publish);
    });
  });

  group('ChatbotService history management', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('aralikli eski rehber mesajlarini siler, sohbeti korur', () {
      final service = ChatbotService();
      final userMessage = ChatMessage.user('Kullanici sorusu');
      final normalBotReply = ChatMessage.bot('Normal asistan cevabi');
      final handoff = ChatMessage.bot(
        'Kurulum tamamlandi',
        snapshotStateKey: 'onboarding_handoff_v1',
      );
      final currentGuidance = ChatMessage.bot(
        'Guncel siradaki adim',
        snapshotStateKey: 'improve_cover',
      );

      final reconciled = service.reconcileGuidanceHistory(
        history: [
          ChatMessage.bot('Eski adim', snapshotStateKey: 'setup_name'),
          userMessage,
          ChatMessage.bot('Eski adim', snapshotStateKey: 'setup_name'),
          normalBotReply,
          handoff,
        ],
        currentGuidance: currentGuidance,
        handoffMarker: 'onboarding_handoff_v1',
      );

      expect(reconciled, [
        userMessage,
        normalBotReply,
        handoff,
        currentGuidance,
      ]);
    });

    test('iki vitrinin sohbet gecmisini birbirinden ayirir', () async {
      final service = ChatbotService();
      final firstMessage = ChatMessage.user('Birinci vitrin');
      final secondMessage = ChatMessage.user('Ikinci vitrin');

      await service.saveHistory(
        [firstMessage],
        scope: 'https://vixrex-public.vercel.app/v/birinci',
      );
      await service.saveHistory(
        [secondMessage],
        scope: 'https://vixrex-public.vercel.app/v/ikinci',
      );

      expect(
        (await service.loadHistory(
          scope: 'https://vixrex-public.vercel.app/v/birinci',
        )).single.text,
        firstMessage.text,
      );
      expect(
        (await service.loadHistory(
          scope: 'https://vixrex-public.vercel.app/v/ikinci',
        )).single.text,
        secondMessage.text,
      );
    });

    test('eski global gecmisi yalniz aktif vitrin linki eslesirse tasir', () async {
      final service = ChatbotService();
      const firstLink = 'https://vixrex-public.vercel.app/v/birinci';
      const secondLink = 'https://vixrex-public.vercel.app/v/ikinci';
      final legacyMessage = ChatMessage.bot('Vitrinin hazir\n\n$firstLink');

      await service.saveHistory([legacyMessage]);
      expect(
        await service.loadHistory(
          scope: secondLink,
          legacyIdentity: secondLink,
        ),
        isEmpty,
      );
      expect(await service.loadHistory(), isEmpty);

      await service.saveHistory([legacyMessage]);
      final migrated = await service.loadHistory(
        scope: firstLink,
        legacyIdentity: firstLink,
      );
      expect(migrated.single.text, legacyMessage.text);
      expect(await service.loadHistory(), isEmpty);
      expect(
        (await service.loadHistory(scope: firstLink)).single.text,
        legacyMessage.text,
      );
    });
  });

}
