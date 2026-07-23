import 'package:flutter/material.dart';
import 'package:vixrex/models/chat_message.dart';
import 'package:vixrex/config/chatbot_config.dart';
import 'package:vixrex/services/chatbot_service.dart';
import 'package:vixrex/services/vixrex_assistant_nlu_service.dart';
import 'package:vixrex/services/vixrex_assistant_nlu_types.dart';
import 'package:vixrex/services/vixrex_guidance_service.dart';
import 'package:vixrex/services/vixrex_profile_snapshot.dart';
import 'package:vixrex/theme/app_colors.dart';
import 'package:vixrex/widgets/vixrex_message_bubble.dart';
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

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void didUpdateWidget(covariant VixRexCompanionChat oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldScope = _historyScopeFor(oldWidget.snapshot);
    if (oldScope != _historyScope) {
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
    final history = await _service.loadHistory(
      scope: scope,
      legacyIdentity: widget.snapshot?.publicLink.trim(),
    );
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
      } else {
        bot = _service.respond(text, widget.snapshot, widget.hasShared);
      }
      setState(() {
        _typing = false;
        _messages.add(bot);
      });
      _service.saveHistory(_messages, scope: _historyScope);
      _scrollToEnd();
    });
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
      if (sepIndex != -1) {
        final fieldName = rest.substring(0, sepIndex);
        final value = rest.substring(sepIndex + 1);
        final field = VixRexNluField.values.firstWhere(
          (f) => f.name == fieldName,
          orElse: () => VixRexNluField.storeName,
        );
        widget.onSaveField(field, value);
        _appendBotAck('Kaydettim ✅');
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
          child: ListView.builder(
            controller: _scrollCtrl,
            padding: const EdgeInsets.only(top: 8, bottom: 12),
            itemCount: _messages.length + (_typing ? 1 : 0),
            itemBuilder: (context, index) {
              if (_typing && index == _messages.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Vixrex yazıyor…',
                    style: TextStyle(color: AppColors.mutedText, fontSize: 12),
                  ),
                );
              }
              final msg = _messages[index];
              if (msg.isBot) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: VixRexBotMessage(
                    msg: msg,
                    showCursor: false,
                    cursorVisible: false,
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: VixRexUserMessage(msg: msg),
              );
            },
          ),
        ),
        if (replies.isNotEmpty)
          VixRexQuickReplies(replies: replies, onTap: _onQuickReply),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _inputCtrl,
                focusNode: widget.inputFocusNode,
                style: const TextStyle(color: AppColors.darkText, fontSize: 14),
                textInputAction: TextInputAction.send,
                onSubmitted: _send,
                decoration: InputDecoration(
                  hintText: 'Vixrex’e sor…',
                  hintStyle: const TextStyle(color: AppColors.mutedText),
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _typing ? null : () => _send(_inputCtrl.text),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: const Color(0xFF041016),
                minimumSize: const Size(72, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Gönder'),
            ),
          ],
        ),
      ],
    );
  }
}
