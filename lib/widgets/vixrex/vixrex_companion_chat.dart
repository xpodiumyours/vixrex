import 'dart:async';

import 'package:flutter/material.dart';
import 'package:vixrex/models/chat_message.dart';
import 'package:vixrex/config/chatbot_config.dart';
import 'package:vixrex/services/chatbot_service.dart';
import 'package:vixrex/services/feature_flag_service.dart';
import 'package:vixrex/services/vixrex_assistant_nlu_service.dart';
import 'package:vixrex/services/vixrex_assistant_nlu_types.dart';
import 'package:vixrex/services/vixrex_guidance_service.dart';
import 'package:vixrex/services/vixrex_profile_snapshot.dart';
import 'package:vixrex/services/vixrex_nlu/vixrex_field_validator.dart';
import 'package:vixrex/services/vixrex_nlu/vixrex_nlu_pipeline.dart';
import 'package:vixrex/services/working_draft/flutter_smart_engine_owner_executor.dart';
import 'package:vixrex/services/working_draft/smart_engine_working_draft_orchestrator.dart';
import 'package:vixrex/widgets/chat/chat_bubble.dart';
import 'package:vixrex/widgets/chat/chat_composer.dart';
import 'package:vixrex/widgets/chat/chat_progress.dart';
import 'package:vixrex/widgets/chat/vixrex_thin_scrollbar.dart';
import 'package:vixrex/widgets/vixrex_quick_replies.dart';

const String _nluConfirmPrefix = 'nlu_confirm:';
const String _nluCancelPayload = 'nlu_cancel';
const String _smartEngineUndoPrefix = 'smart_engine_undo:';

typedef FlutterSmartEngineExecute =
    Future<FlutterSmartEngineCommandResult> Function(
      List<FlutterSmartEngineAction> actions,
    );

typedef FlutterSmartEngineUndo =
    Future<FlutterSmartEngineUndoExecutionResult> Function(String commandId);

/// Uygulama içi companion sohbeti.
/// Motor: mevcut [ChatbotService] + [VixRexGuidanceService] (config üzerinden).
/// Aksiyonlar: [onAction] → HomeShell’deki mevcut handler’lar.
/// 46-alan Akıllı Motor: decision pipeline → [onExecuteSmartEngine] →
/// authoritative working draft → execution sonucu → sohbet UX.
class VixRexCompanionChat extends StatefulWidget {
  final VixRexProfileSnapshot? snapshot;
  final bool hasShared;
  final VixRexRecommendation recommendation;
  final bool isRecommendationDismissed;
  final ValueChanged<VixRexAction> onAction;
  final ValueChanged<String> onDismissRecommendation;

  /// Legacy NLU callback. Remote OpenAI NLU bugün kapalıdır; 46-alan Akıllı
  /// Motor bu callback'i kullanmaz.
  final void Function(VixRexNluField field, String value) onSaveField;

  /// Legacy per-field callback. 46-alan Akıllı Motor yazma yolu değildir.
  final void Function(String anahtar, Object? deger)? onUpdateField;

  final FlutterSmartEngineExecute? onExecuteSmartEngine;
  final FlutterSmartEngineUndo? onUndoSmartEngine;
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
    this.onExecuteSmartEngine,
    this.onUndoSmartEngine,
    required this.inputFocusNode,
  });

  @override
  State<VixRexCompanionChat> createState() => _VixRexCompanionChatState();
}

class _VixRexCompanionChatState extends State<VixRexCompanionChat> {
  final _service = ChatbotService();
  final _featureFlags = FeatureFlagService();
  final _nluService = VixRexAssistantNluService();
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _loading = true;
  bool _typing = false;
  bool _smartEngineEnabled = false;
  Timer? _pollTimer;
  bool _pollActive = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
    _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) => _poll());
  }

  @override
  void didUpdateWidget(covariant VixRexCompanionChat oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldScope = _historyScopeFor(oldWidget.snapshot);
    if (oldScope != _historyScope) {
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
    if (!_service.canSync) return;
    final scope = _historyScope;
    if (scope.isEmpty) return;
    _pollActive = true;
    try {
      final history = await _service.loadHistory(scope: scope);
      if (!mounted || scope != _historyScope) return;
      if (history.length <= _messages.length) return;
      final reconciled = _service.reconcileGuidanceHistory(
        history: history,
        currentGuidance: _currentGuidanceFor(history),
        handoffMarker: _handoffMarker,
      );
      if (reconciled.length == _messages.length) return;
      setState(() {
        _messages
          ..clear()
          ..addAll(reconciled);
      });
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
    await _featureFlags.loadFlags();
    final smartEngineEnabled = _featureFlags.isSmartEngineStorefrontEnabled;

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

    setState(() {
      _messages
        ..clear()
        ..addAll(reconciled);
      _smartEngineEnabled = smartEngineEnabled;
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

  final _pipeline = VixrexNluPipeline();

  bool _needsSpecialFlowFor(String anahtar) {
    if (anahtar == 'il' || anahtar == 'ilce') return true;
    if (anahtar == 'logo' ||
        anahtar == 'kapakGorseli' ||
        anahtar == 'bantGorsel' ||
        anahtar == 'hakkindaGorsel') {
      return false;
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
      } else if (_smartEngineEnabled) {
        final result = await _pipeline.handle(
          input: text,
          controller: null,
          scope: _historyScope,
          onValidate: (alan, hamDeger) async {
            final v = VixrexFieldValidator.validate(alan, hamDeger);
            return (
              ok: v.ok,
              hata: v.hata,
              normalizedDeger: v.normalizedDeger,
            );
          },
          needsSpecialFlow: (alan) => _needsSpecialFlowFor(alan.anahtar),
        );
        if (result.outcome == VixrexNluPipelineOutcome.notUnderstood) {
          bot = _service.respond(text, widget.snapshot, widget.hasShared);
        } else if (result.outcome == VixrexNluPipelineOutcome.handled) {
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

          if (anahtarlar.isNotEmpty &&
              degerler.isNotEmpty &&
              widget.onExecuteSmartEngine != null) {
            final actions = <FlutterSmartEngineAction>[];
            for (var i = 0; i < anahtarlar.length && i < degerler.length; i++) {
              actions.add(
                FlutterSmartEngineAction(
                  fieldKey: anahtarlar[i],
                  value: degerler[i],
                ),
              );
            }
            final execution = await widget.onExecuteSmartEngine!(actions);
            bot = _executionMessage(execution, result.message);
          } else if (anahtarlar.isNotEmpty) {
            bot = ChatMessage.bot(
              'Bu değişikliği güvenli sahiplik oturumu doğrulanmadan kaydetmedim.',
            );
          } else {
            bot = result.message;
          }
        } else if (result.outcome ==
            VixrexNluPipelineOutcome.needsSpecialFlow) {
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

  List<QuickReply> _undoReplies(FlutterSmartEngineCommandResult execution) {
    if (widget.onUndoSmartEngine == null ||
        execution.commandId.isEmpty ||
        execution.succeeded.isEmpty ||
        execution.queuedOffline.isNotEmpty) {
      return const [];
    }
    return [
      QuickReply(
        label: 'Geri al',
        payload: '$_smartEngineUndoPrefix${execution.commandId}',
      ),
    ];
  }

  ChatMessage _executionMessage(
    FlutterSmartEngineCommandResult execution,
    ChatMessage decisionMessage,
  ) {
    switch (execution.status) {
      case FlutterSmartEngineCommandStatus.noOp:
        return decisionMessage;
      case FlutterSmartEngineCommandStatus.succeeded:
        return ChatMessage.bot(
          'Kaydedildi ✅ ${decisionMessage.text}',
          quickReplies: _undoReplies(execution),
        );
      case FlutterSmartEngineCommandStatus.queuedOffline:
        return ChatMessage.bot(
          'Değişiklik sıraya alındı; henüz buluta kaydedilmedi.',
        );
      case FlutterSmartEngineCommandStatus.partialResult:
        final saved = execution.succeeded.length;
        final pending = execution.queuedOffline.length;
        final unresolved = execution.failed.length + execution.stopped.length;
        final parts = <String>[
          if (saved > 0) '$saved değişiklik kaydedildi.',
          if (pending > 0) '$pending değişiklik henüz buluta kaydedilmedi.',
          if (unresolved > 0)
            '$unresolved değişiklik güvenlik için tamamlanmadı.',
        ];
        return ChatMessage.bot(
          parts.join(' '),
          quickReplies: _undoReplies(execution),
        );
      case FlutterSmartEngineCommandStatus.failed:
        return ChatMessage.bot(_executionFailureMessage(execution));
    }
  }

  String _executionFailureMessage(FlutterSmartEngineCommandResult execution) {
    switch (execution.firstErrorCode) {
      case 'OWNER_AUTHORIZATION_REQUIRED':
        return 'Bu düzenleme için kalıcı hesabınla giriş yapmalısın.';
      case 'DRAFT_PROJECTION_STALE':
      case 'WORKING_DRAFT_STALE':
      case 'DRAFT_VERSION_CONFLICT':
        return 'Taslak başka bir yerde değişti. Güncel hâli yükleyip tekrar dene.';
      case 'SMART_ENGINE_DISABLED':
        return 'Vixrex Akıllı Motor şu anda kapalı. Manuel düzenleme kullanabilirsin.';
      case 'OWNER_EDIT_NOT_PUBLISHED':
        return 'Bu işlem yayın sonrası sahip düzenleme modunda kullanılabilir.';
      case 'WORKING_DRAFT_NOT_READY':
        return 'Çalışma taslağı hazırlanamadı. Tekrar dene.';
      case 'QUEUED_OFFLINE':
        return 'Değişiklik henüz buluta kaydedilmedi.';
      default:
        return 'Değişikliği güvenle kaydedemedim. Güncel hâli kontrol edip tekrar dene.';
    }
  }

  String _undoFailureMessage(FlutterSmartEngineUndoExecutionResult result) {
    switch (result.errorCode) {
      case 'UNDO_CONFLICT':
        return 'Vitrin bu işlemden sonra değişti. Güvenlik için geri almadım.';
      case 'UNDO_COMMAND_NOT_FOUND':
        return 'Geri alınacak işlem kaydı bulunamadı.';
      case 'OWNER_AUTHORIZATION_REQUIRED':
      case 'INVALID_SESSION_TOKEN':
        return 'Bu geri alma işlemi için sahiplik doğrulanamadı.';
      case 'SMART_ENGINE_DISABLED':
        return 'Vixrex Akıllı Motor kapalı olduğu için geri alma yapılmadı.';
      case 'NETWORK_ERROR':
      case 'NO_CLIENT':
        return 'Bağlantı kurulamadı; geri alma yapılmadı.';
      default:
        return 'Değişikliği güvenle geri alamadım.';
    }
  }

  Future<void> _executeSmartEngineUndo(String commandId) async {
    final undo = widget.onUndoSmartEngine;
    if (undo == null || commandId.trim().isEmpty || _typing) return;

    setState(() => _typing = true);
    final result = await undo(commandId.trim());
    if (!mounted) return;

    final message =
        result.succeeded
            ? (result.idempotentReplay
                ? 'Bu değişiklik zaten geri alınmış.'
                : 'Değişiklik geri alındı.')
            : _undoFailureMessage(result);

    setState(() {
      _typing = false;
      _messages.add(ChatMessage.bot(message));
    });
    await _service.saveHistory(_messages, scope: _historyScope);
    _scrollToEnd();
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
    if (!mounted) return;
    setState(() => _messages.add(ChatMessage.bot(text)));
    _service.saveHistory(_messages, scope: _historyScope);
    _scrollToEnd();
  }

  String? _legacyFieldKey(VixRexNluField field) {
    switch (field) {
      case VixRexNluField.storeName:
        return 'isletmeAdi';
      case VixRexNluField.whatsapp:
        return 'whatsapp';
      case VixRexNluField.address:
        return 'adres';
      case VixRexNluField.description:
        return 'kisaTanitim';
      case VixRexNluField.category:
        return 'kategori';
    }
  }

  Future<void> _executeLegacyNluConfirm(
    VixRexNluField field,
    String value,
  ) async {
    final fieldKey = _legacyFieldKey(field);
    final execute = widget.onExecuteSmartEngine;
    if (fieldKey == null || execute == null) {
      _appendBotAck(
        'Bu değişikliği güvenli sahiplik oturumu olmadan kaydetmedim.',
      );
      return;
    }
    final result = await execute([
      FlutterSmartEngineAction(fieldKey: fieldKey, value: value),
    ]);
    final message = _executionMessage(
      result,
      ChatMessage.bot('Değişiklik hazır.'),
    );
    if (!mounted) return;
    setState(() => _messages.add(message));
    await _service.saveHistory(_messages, scope: _historyScope);
    _scrollToEnd();
  }

  void _onQuickReply(QuickReply reply) {
    if (reply.payload.startsWith(_smartEngineUndoPrefix)) {
      final commandId = reply.payload.substring(_smartEngineUndoPrefix.length);
      unawaited(_executeSmartEngineUndo(commandId));
      return;
    }
    if (reply.payload.startsWith(_nluConfirmPrefix)) {
      final rest = reply.payload.substring(_nluConfirmPrefix.length);
      final sepIndex = rest.indexOf(':');
      if (sepIndex != -1) {
        final fieldName = rest.substring(0, sepIndex);
        final value = rest.substring(sepIndex + 1);
        final field = VixRexNluField.values.firstWhere(
          (f) => f.name == fieldName,
          orElse: () => VixRexNluField.storeName,
        );
        unawaited(_executeLegacyNluConfirm(field, value));
      }
      return;
    }
    if (reply.payload == _nluCancelPayload) {
      _appendBotAck('Tamam, kaydetmedim. Başka nasıl yardımcı olabilirim?');
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
    _featureFlags.dispose();
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
