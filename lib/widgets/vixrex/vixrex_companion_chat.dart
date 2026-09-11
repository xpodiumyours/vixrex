import 'dart:async';

import 'package:flutter/material.dart';
import 'package:vixrex/config/vixrex_mesajlar.g.dart';
import 'package:vixrex/models/chat_message.dart';
import 'package:vixrex/config/chatbot_config.dart';
import 'package:vixrex/services/chatbot_service.dart';
import 'package:vixrex/services/vixrex_assistant_nlu_service.dart';
import 'package:vixrex/services/vixrex_assistant_nlu_types.dart';
import 'package:vixrex/services/vixrex_guidance_service.dart';
import 'package:vixrex/services/vixrex_profile_snapshot.dart';
import 'package:vixrex/services/vixrex_nlu/vixrex_field_validator.dart';
import 'package:vixrex/services/vixrex_nlu/vixrex_nlu_pipeline.dart';
import 'package:vixrex/widgets/chat/chat_bubble.dart';
import 'package:vixrex/widgets/chat/chat_composer.dart';
import 'package:vixrex/widgets/chat/chat_progress.dart';
import 'package:vixrex/widgets/chat/vixrex_thin_scrollbar.dart';
import 'package:vixrex/widgets/vixrex_quick_replies.dart';

const String _nluConfirmPrefix = 'nlu_confirm:';
const String _nluCancelPayload = 'nlu_cancel';

/// Uygulama içi companion sohbeti.
/// Motor: mevcut [ChatbotService] + [VixRexGuidanceService] (config üzerinden).
/// Aksiyonlar: [onAction] → HomeShell’deki mevcut handler’lar.
/// Serbest metin anlama: Supabase Function → onay kartı → [onSaveField] →
/// HomeShell’deki gerçek `StoreEditorController`. Function erişilemezse mevcut
/// kural tabanlı motor çalışmaya devam eder.
class VixRexCompanionChat extends StatefulWidget {
  final VixRexProfileSnapshot? snapshot;
  final bool hasShared;
  final VixRexRecommendation recommendation;
  final bool isRecommendationDismissed;
  final ValueChanged<VixRexAction> onAction;
  final ValueChanged<String> onDismissRecommendation;
  final void Function(VixRexNluField field, String value) onSaveField;
  final void Function(String anahtar, Object? deger)? onUpdateField;
  final FocusNode inputFocusNode;

  const VixRexCompanionChat({
    super.key,
    required this.snapshot,
    required this.hasShared,
    required this.recommendation,
    required this.isRecommendationDismissed,
    required this.onAction,
    required this.onDismissRecommendation,
    required this.onSaveField,
    this.onUpdateField,
    required this.inputFocusNode,
  });

  @override
  State<VixRexCompanionChat> createState() => _VixRexCompanionChatState();
}

class _VixRexCompanionChatState extends State<VixRexCompanionChat> {
  final _service = ChatbotService();
  final _nluService = VixRexAssistantNluService();
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _loading = true;
  bool _typing = false;
  Timer? _pollTimer;
  bool _pollActive = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
    // Faz 2/3: kalıcı hesaplarda Next.js sahip paneli ile çift yönlü senkron
    // RLS nedeniyle Realtime postgres_changes dinlenemez, 15sn RPC poll daha güvenilir
    _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) => _poll());
  }

  @override
  void didUpdateWidget(covariant VixRexCompanionChat oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldScope = _historyScopeFor(oldWidget.snapshot);
    if (oldScope != _historyScope) {
      // Scope değişince poll’u sıfırla — eski conversation’a poll etmemek için
      _pollTimer?.cancel();
      _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) => _poll());
      setState(() {
        _messages.clear();
        _loading = true;
      });
      _bootstrap();
      return;
    }
    if (oldWidget.recommendation.id != widget.recommendation.id ||
        oldWidget.hasShared != widget.hasShared) {
      _refreshGuidanceTip();
    }
  }

  Future<void> _poll() async {
    if (_loading || _pollActive || !mounted) return;
    // Kalıcı hesap değilse (anonim) poll yok — bellek modu
    if (!_service.canSync) return;
    final scope = _historyScope;
    // Scope boşsa (yayın yok) poll’a gerek yok — local scope zaten tek cihaz
    if (scope.isEmpty) return;
    _pollActive = true;
    try {
      final history = await _service.loadHistory(scope: scope);
      if (!mounted || scope != _historyScope) return;
      // Yeni mesaj var mı? (remote’dan gelen Next.js yazıları)
      if (history.length <= _messages.length) return;
      // Handoff tekilleştirme: DB varsa handoff’u ez, yoksa rehber tipini yenile
      final reconciled = _service.reconcileGuidanceHistory(
        history: history,
        currentGuidance: _currentGuidanceFor(history),
        handoffMarker: _handoffMarker,
      );
      // Sadece gerçekten yeni içerik varsa setState — gereksiz rebuild yok
      if (reconciled.length == _messages.length) return;
      setState(() {
        _messages
          ..clear()
          ..addAll(reconciled);
      });
      // Yerel önbelleği de tazele (loadHistory zaten yazdı, ama reconcile sonrası da kaydet)
      await _service.saveHistory(_messages, scope: scope);
      _scrollToEnd();
    } finally {
      _pollActive = false;
    }
  }

  String _historyScopeFor(VixRexProfileSnapshot? snapshot) =>
      snapshot?.publicLink.trim() ?? '';

  String get _historyScope => _historyScopeFor(widget.snapshot);

  bool _hasOnboardingHandoff(List<ChatMessage> history) =>
      history.any((message) => message.snapshotStateKey == _handoffMarker);

  ChatMessage _currentGuidanceFor(List<ChatMessage> history) {
    final snapshot = widget.snapshot;
    if (snapshot == null || !snapshot.isPublished) {
      return ChatbotConfig.setupInviteMessage;
    }
    return _hasOnboardingHandoff(history)
        ? ChatbotConfig.nextStepTip(snapshot, hasShared: widget.hasShared)
        : _service.respondWithSnapshot(snapshot, hasShared: widget.hasShared);
  }

  Future<void> _bootstrap() async {
    final scope = _historyScope;
    // Faz C, madde 1: yayına yeni geçilmişse yerel (henüz yayınlanmamış)
    // geçmiş bu scope'a bir kez taşınır. Hedefte zaten geçmiş varsa
    // dokunmaz — idempotent, her bootstrap'ta çağrılması güvenli.
    if (scope.isNotEmpty) {
      await _service.migrateLocalToPublishedScope(scope);
    }
    final history = await _service.loadHistory(scope: scope);
    if (!mounted || scope != _historyScope) return;

    final reconciled = _service.reconcileGuidanceHistory(
      history: history,
      currentGuidance: _currentGuidanceFor(history),
      handoffMarker: _handoffMarker,
    );

    // Companion yalnız yayın sonrası Vixrex sekmesinde; kurulum gömülü onboarding’de.
    setState(() {
      _messages
        ..clear()
        ..addAll(reconciled);
      _loading = false;
    });
    await _service.saveHistory(_messages, scope: scope);
    await _service.markGreeted();
    _scrollToEnd();
  }

  static const _handoffMarker = 'onboarding_handoff_v1';

  void _refreshGuidanceTip() {
    if (_messages.isEmpty) return;
    final reconciled = _service.reconcileGuidanceHistory(
      history: _messages,
      currentGuidance: _currentGuidanceFor(_messages),
      handoffMarker: _handoffMarker,
    );
    setState(() {
      _messages
        ..clear()
        ..addAll(reconciled);
    });
    _service.saveHistory(_messages, scope: _historyScope);
    _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  // Faz 1: 46 alan borusu – feature-flag ile eski davranışı korur.
  // Pipeline önce dener, notUnderstood ise eski ChatbotService’e düşer.
  static const _pipelineEnabled = true;
  final _pipeline = VixrexNluPipeline();

  bool _needsSpecialFlowFor(String anahtar) {
    // Faz 1 dar: il/ilce listeden seçilmeli, serbest metinle yazılmamalı.
    // gorsel alanlar da URL değilse özel akış (galeri/upload).
    if (anahtar == 'il' || anahtar == 'ilce') return true;
    if (anahtar == 'logo' ||
        anahtar == 'kapakGorseli' ||
        anahtar == 'bantGorsel' ||
        anahtar == 'hakkindaGorsel') {
      // Sadece https URL ise düz yaz, yoksa özel akış.
      return false; // şimdilik URL kabul, özel akış yok – Faz 2’de eklenecek.
    }
    return false;
  }

  void _send(String raw) {
    final text = raw.trim();
    if (text.isEmpty || _typing) return;
    final userMsg = ChatMessage.user(text);
    setState(() {
      _messages.add(userMsg);
      _typing = true;
    });
    _inputCtrl.clear();
    _service.saveHistory(_messages, scope: _historyScope);
    _scrollToEnd();

    Future<void>.delayed(const Duration(milliseconds: 450), () async {
      if (!mounted) return;
      late final ChatMessage bot;
      // 1) Eski NLU (OpenAI) hâlâ kapalı – isEnabled false, korunur.
      if (VixRexAssistantNluService.isEnabled) {
        final remote = await _nluService.propose(text);
        if (!mounted) return;
        bot =
            remote.isAvailable && remote.field != null && remote.value != null
                ? _buildNluConfirmMessage(
                  field: remote.field!,
                  value: remote.value!,
                  prompt: remote.reply,
                )
                : ChatMessage.bot(remote.reply);
      } else if (_pipelineEnabled) {
        // 2) Yeni 46 alan borusu – önce dener.
        final result = await _pipeline.handle(
          input: text,
          controller:
              null, // CompanionChat controller’a doğrudan erişmez, HomeShell onUpdateField’e delege eder.
          scope: _historyScope,
          onValidate: (alan, hamDeger) async {
            final v = VixrexFieldValidator.validate(alan, hamDeger);
            return (ok: v.ok, hata: v.hata, normalizedDeger: v.normalizedDeger);
          },
          needsSpecialFlow: (alan) => _needsSpecialFlowFor(alan.anahtar),
        );
        if (result.outcome == VixrexNluPipelineOutcome.notUnderstood) {
          // Alan bulunamadı → eski kural tabanlı sohbete düş.
          bot = _service.respond(text, widget.snapshot, widget.hasShared);
        } else if (result.outcome == VixrexNluPipelineOutcome.handled) {
          // Başarılı doğrulama ama controller yok → HomeShell’e delege et (çok-alanlı dahil).
          final anahtarlar =
              result.appliedAnahtarlar ??
              (result.appliedAnahtar != null
                  ? [result.appliedAnahtar!]
                  : <String>[]);
          final degerler =
              result.appliedDegerler ??
              (result.appliedDeger != null
                  ? [result.appliedDeger!]
                  : <Object>[]);
          if (anahtarlar.isNotEmpty && widget.onUpdateField != null) {
            for (var i = 0; i < anahtarlar.length && i < degerler.length; i++) {
              widget.onUpdateField!(anahtarlar[i], degerler[i]);
            }
            bot = result.message;
          } else if (anahtarlar.isNotEmpty) {
            // Fallback: eski 5 alan haritası (geriye uyum) – sadece ilk
            final mapped = _mapAnahtarToLegacyField(anahtarlar.first);
            if (mapped != null) {
              widget.onSaveField(mapped, degerler.first.toString());
              // Cerrahi 2026-09-11 (Risk 1): kısa onay katalogdan, görsel aynı.
              final kisaOnay =
                  vixRexMesajlari['nlu_kisa_onay_basari'] ?? 'Kaydettim ✅';
              bot = ChatMessage.bot('$kisaOnay ${result.message.text}');
            } else {
              // Cerrahi 2026-09-11 (Risk 2): kaydetmeden başarılı gösterme.
              // onUpdateField yoksa 41 alan yazılamazdı ama başarı mesajı
              // çıkıyordu. Katalogdan dürüst soruya düş, kaybı logla.
              debugPrint(
                '[vixrex-assistant] onUpdateField yok, yazılamadı: '
                '${anahtarlar.first}',
              );
              bot = ChatMessage.bot(
                vixRexMesajlari['netlestirme_belirsiz'] ??
                    result.message.text,
              );
            }
          } else {
            bot = result.message;
          }
        } else if (result.outcome ==
            VixrexNluPipelineOutcome.needsSpecialFlow) {
          // il/ilce gibi özel akış – mevcut VixrexAction’a yönlendir.
          final anahtar = result.appliedAnahtar;
          if (anahtar == 'il' || anahtar == 'ilce') {
            widget.onAction(VixRexAction.scrollToAddress);
            bot = ChatMessage.bot(
              result.message.text,
              quickReplies: const [
                QuickReply(
                  label: 'Adrese git',
                  payload: 'action_address',
                  action: VixRexAction.scrollToAddress,
                ),
              ],
            );
          } else {
            bot = result.message;
          }
        } else {
          // needsClarification / blockedLegal / notUnderstood dışındaki – netleştirme sorusu.
          bot = result.message;
        }
      } else {
        bot = _service.respond(text, widget.snapshot, widget.hasShared);
      }
      if (!mounted) return;
      setState(() {
        _typing = false;
        _messages.add(bot);
      });
      _service.saveHistory(_messages, scope: _historyScope);
      _scrollToEnd();
    });
  }

  VixRexNluField? _mapAnahtarToLegacyField(String anahtar) {
    switch (anahtar) {
      case 'isletmeAdi':
        return VixRexNluField.storeName;
      case 'whatsapp':
        return VixRexNluField.whatsapp;
      case 'adres':
        return VixRexNluField.address;
      case 'kisaTanitim':
        return VixRexNluField.description;
      case 'kategori':
        return VixRexNluField.category;
      default:
        return null;
    }
  }

  ChatMessage _buildNluConfirmMessage({
    required VixRexNluField field,
    required String value,
    required String prompt,
  }) {
    return ChatMessage.bot(
      prompt,
      quickReplies: [
        QuickReply(
          label: 'Evet, kaydet',
          payload: '$_nluConfirmPrefix${field.name}:$value',
        ),
        const QuickReply(label: 'Hayır', payload: _nluCancelPayload),
      ],
    );
  }

  void _appendBotAck(String text) {
    setState(() => _messages.add(ChatMessage.bot(text)));
    _service.saveHistory(_messages, scope: _historyScope);
    _scrollToEnd();
  }

  void _onQuickReply(QuickReply reply) {
    if (reply.payload.startsWith(_nluConfirmPrefix)) {
      final rest = reply.payload.substring(_nluConfirmPrefix.length);
      final sepIndex = rest.indexOf(':');
      if (sepIndex == -1) {
        // Cerrahi 2026-09-11 (Risk 3): bozuk onay sessizce yutulmasın.
        debugPrint('[vixrex-assistant] bozuk onay payload: ${reply.payload}');
        _appendBotAck(
          vixRexMesajlari['netlestirme_belirsiz'] ??
              'Hangi alanı değiştirmek istediğini netleştirebilir misin?',
        );
        return;
      }
      final fieldName = rest.substring(0, sepIndex);
      final value = rest.substring(sepIndex + 1);
      VixRexNluField? field;
      try {
        field = VixRexNluField.values.firstWhere((f) => f.name == fieldName);
      } catch (_) {
        field = null;
      }
      if (field == null) {
        // Cerrahi 2026-09-11 (Risk 3): bilinmeyen alan storeName'e
        // sessizce yazılıyordu. Artık yazma, katalogdan sor, logla.
        debugPrint(
          '[vixrex-assistant] bilinmeyen alan, yazılmadı: $fieldName',
        );
        _appendBotAck(
          vixRexMesajlari['netlestirme_belirsiz'] ??
              'Hangi alanı değiştirmek istediğini netleştirebilir misin?',
        );
        return;
      }
      widget.onSaveField(field, value);
      // Cerrahi 2026-09-11 (Risk 1): kısa onay katalogdan, görsel aynı.
      _appendBotAck(
        vixRexMesajlari['nlu_kisa_onay_basari'] ?? 'Kaydettim ✅',
      );
      return;
    }
    if (reply.payload == _nluCancelPayload) {
      // Cerrahi 2026-09-11 (Risk 1): iptal cümlesi katalogdan, görsel aynı.
      _appendBotAck(
        vixRexMesajlari['nlu_kisa_onay_iptal'] ??
            'Tamam, kaydetmedim. Başka nasıl yardımcı olabilirim?',
      );
      return;
    }
    if (reply.action != VixRexAction.none) {
      widget.onAction(reply.action);
      return;
    }
    final userMsg = ChatMessage.user(reply.label);
    setState(() {
      _messages.add(userMsg);
      _typing = true;
    });
    _service.saveHistory(_messages, scope: _historyScope);
    _scrollToEnd();

    Future<void>.delayed(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      final bot = _service.respondToPayload(
        reply.payload,
        widget.snapshot,
        widget.hasShared,
      );
      setState(() {
        _typing = false;
        _messages.add(bot);
      });
      _service.saveHistory(_messages, scope: _historyScope);
      _scrollToEnd();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    final last = _messages.isEmpty ? null : _messages.last;
    final replies =
        (last != null && last.isBot) ? last.quickReplies : const <QuickReply>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 2026-09-03 (Çalışma masası düzeni, web paritesi): aynı ince,
        // yüzeye uyumlu kaydırma şeridi (VixrexThinScrollbar).
        Expanded(
          child: VixrexThinScrollbar(
            controller: _scrollCtrl,
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.only(top: 8, bottom: 12),
              itemCount: _messages.length + (_typing ? 1 : 0),
              itemBuilder: (context, index) {
                if (_typing && index == _messages.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: ChatTypingIndicator(),
                  );
                }
                final msg = _messages[index];
                if (msg.isBot) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ChatBubble.bot(
                      text: msg.text,
                      footer:
                          msg.snapshotScore != null
                              ? ChatScoreBar(score: msg.snapshotScore!)
                              : null,
                    ),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ChatBubble.user(text: msg.text),
                );
              },
            ),
          ),
        ),
        if (replies.isNotEmpty)
          VixRexQuickReplies(replies: replies, onTap: _onQuickReply),
        const SizedBox(height: 6),
        ChatComposer(
          controller: _inputCtrl,
          focusNode: widget.inputFocusNode,
          hintText: 'Vixrex’e sor…',
          enabled: !_typing,
          onSubmit: _send,
        ),
      ],
    );
  }
}
