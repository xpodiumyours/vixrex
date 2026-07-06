import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vixrex/config/chatbot_config.dart';
import 'package:vixrex/models/chat_message.dart';
import 'package:vixrex/services/chatbot_service.dart';
import 'package:vixrex/services/vixrex_profile_snapshot.dart';
import 'package:vixrex/theme/app_colors.dart';
import 'package:vixrex/widgets/vixrex_message_bubble.dart';
import 'package:vixrex/widgets/vixrex_quick_replies.dart';

const double _vixrexPanelAvatarSize = 68;

class VixRexPanelWrapper extends StatefulWidget {
  final VoidCallback onClose;
  final VixRexProfileSnapshot? snapshot;
  final List<ChatMessage>? chatHistory;
  final VoidCallback? onNavigateToVitrim;
  final VoidCallback? onNavigateToExplore;
  final VoidCallback? onCopyLink;
  final VoidCallback? onShowQr;
  final VoidCallback? onShareWhatsapp;
  final void Function(VixRexAction)? onScrollToAction;

  const VixRexPanelWrapper({
    super.key,
    required this.onClose,
    this.snapshot,
    this.chatHistory,
    this.onNavigateToVitrim,
    this.onNavigateToExplore,
    this.onCopyLink,
    this.onShowQr,
    this.onShareWhatsapp,
    this.onScrollToAction,
  });

  @override
  State<VixRexPanelWrapper> createState() => _VixRexPanelWrapperState();
}

class _VixRexPanelWrapperState extends State<VixRexPanelWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(1.0, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _close() async {
    await _slideController.reverse();
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 600;
    final panelWidth = isDesktop ? 400.0 : screenWidth;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          GestureDetector(
            onTap: _close,
            child: Container(color: AppColors.darkText.withAlpha(40)),
          ),
          SlideTransition(
            position: _slideAnim,
            child: Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: panelWidth,
                height: double.infinity,
                child: VixRexPanel(
                  onClose: _close,
                  snapshot: widget.snapshot,
                  chatHistory: widget.chatHistory,
                  onNavigateToVitrim: widget.onNavigateToVitrim,
                  onNavigateToExplore: widget.onNavigateToExplore,
                  onCopyLink: widget.onCopyLink,
                  onShowQr: widget.onShowQr,
                  onShareWhatsapp: widget.onShareWhatsapp,
                  onScrollToAction: widget.onScrollToAction,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class VixRexPanel extends StatefulWidget {
  final VoidCallback onClose;
  final VixRexProfileSnapshot? snapshot;
  final List<ChatMessage>? chatHistory;
  final VoidCallback? onNavigateToVitrim;
  final VoidCallback? onNavigateToExplore;
  final VoidCallback? onCopyLink;
  final VoidCallback? onShowQr;
  final VoidCallback? onShareWhatsapp;
  final void Function(VixRexAction)? onScrollToAction;

  const VixRexPanel({
    super.key,
    required this.onClose,
    this.snapshot,
    this.chatHistory,
    this.onNavigateToVitrim,
    this.onNavigateToExplore,
    this.onCopyLink,
    this.onShowQr,
    this.onShareWhatsapp,
    this.onScrollToAction,
  });

  @override
  State<VixRexPanel> createState() => _VixRexPanelState();
}

class _VixRexPanelState extends State<VixRexPanel> with TickerProviderStateMixin {
  final ChatbotService _service = ChatbotService();
  late final List<ChatMessage> _messages;
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  late AnimationController _scanController;
  late Animation<double> _scanAnim;
  bool _cursorVisible = true;
  Timer? _cursorTimer;
  bool _isTyping = false;
  bool _hasShared = false;

  @override
  void initState() {
    super.initState();

    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _scanAnim = Tween<double>(begin: -1.0, end: 1.0).animate(_scanController);

    _cursorTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) setState(() => _cursorVisible = !_cursorVisible);
    });

    _messages = widget.chatHistory ?? [];
    _initializeGuidance();

    if (_messages.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    }
  }

  Future<void> _initializeGuidance() async {
    final snap = widget.snapshot;
    if (snap == null) {
      if (_messages.isEmpty && mounted) {
        setState(() => _messages.add(ChatbotConfig.welcomeMessage));
      }
      return;
    }

    final hasShared = await _service.hasSharedVitrin();
    final dismissedRecommendationId =
        await _service.loadDismissedRecommendationId();
    if (!mounted) return;

    _hasShared = hasShared;
    final guidanceMessage = _service.respondWithSnapshot(
      snap,
      hasShared: hasShared,
    );
    final currentStateKey = guidanceMessage.snapshotStateKey;

    if (dismissedRecommendationId == currentStateKey) {
      if (_messages.isEmpty) {
        setState(() => _messages.add(ChatbotConfig.welcomeMessage));
      }
      return;
    }

    final alreadyAdded = _messages.any(
      (message) =>
          message.isBot && message.snapshotStateKey == currentStateKey,
    );
    if (alreadyAdded) return;

    setState(() => _messages.add(guidanceMessage));
    _service.saveHistory(_messages);
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  @override
  void dispose() {
    _scanController.dispose();
    _cursorTimer?.cancel();
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _addBotMessage(ChatMessage msg) {
    setState(() => _messages.add(msg));
    _service.saveHistory(_messages);
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    final userMsg = ChatMessage.user(text.trim());
    setState(() {
      _messages.add(userMsg);
      _isTyping = true;
    });
    _service.saveHistory(_messages);
    _inputCtrl.clear();
    _scrollToBottom();

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() => _isTyping = false);
      _addBotMessage(
        _service.respond(text.trim(), widget.snapshot, _hasShared),
      );
    });
  }

  void _onQuickReply(QuickReply reply) {
    if (reply.action != VixRexAction.none) {
      _handleAction(reply.action);
      return;
    }

    final userMsg = ChatMessage.user(reply.label);
    setState(() {
      _messages.add(userMsg);
      _isTyping = true;
    });
    _service.saveHistory(_messages);
    _scrollToBottom();

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() => _isTyping = false);
      _addBotMessage(
        _service.respondToPayload(
          reply.payload,
          widget.snapshot,
          _hasShared,
        ),
      );
    });
  }

  void _handleAction(VixRexAction action) {
    final onVitrim   = widget.onNavigateToVitrim;
    final onExplore  = widget.onNavigateToExplore;
    final onCopy     = widget.onCopyLink;
    final onQr       = widget.onShowQr;
    final onWhatsapp = widget.onShareWhatsapp;
    final onScroll   = widget.onScrollToAction;

    widget.onClose();
    Future.delayed(const Duration(milliseconds: 320), () {
      switch (action) {
        case VixRexAction.openVitrim:
          onVitrim?.call();
          break;
        case VixRexAction.openExplore:
          onExplore?.call();
          break;
        case VixRexAction.copyLink:
          onCopy?.call();
          break;
        case VixRexAction.showQr:
          onQr?.call();
          break;
        case VixRexAction.shareWhatsapp:
          onWhatsapp?.call();
          break;
        case VixRexAction.scrollToCover:
        case VixRexAction.scrollToGallery:
        case VixRexAction.scrollToName:
        case VixRexAction.scrollToWhatsapp:
        case VixRexAction.scrollToAddress:
        case VixRexAction.scrollToLegal:
        case VixRexAction.scrollToDesc:
        case VixRexAction.scrollToProducts:
        case VixRexAction.scrollToCategory:
        case VixRexAction.openCoverTemplatePicker:
          onScroll?.call(action);
          break;
        case VixRexAction.none:
          break;
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _clearHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Sohbeti Temizle', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: const Text('Tüm konuşma geçmişini silmek istediğinize emin misiniz?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('İptal', style: TextStyle(color: AppColors.mutedText)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              elevation: 0,
            ),
            child: const Text('Temizle', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _service.clearHistory();
      setState(() => _messages.clear());
      await _initializeGuidance();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lastMsg = _messages.isNotEmpty ? _messages.last : null;
    final quickReplies = (lastMsg?.isBot == true) ? lastMsg!.quickReplies : <QuickReply>[];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.darkText.withAlpha(25),
            blurRadius: 24,
            offset: const Offset(4, 0),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildAvatar(),
            const Divider(color: AppColors.border, height: 1),
            Expanded(
              child: ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                itemCount: _messages.length + (_isTyping ? 1 : 0),
                itemBuilder: (context, i) {
                  if (_isTyping && i == _messages.length) {
                    return const VixRexTypingIndicator();
                  }
                  final msg = _messages[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: msg.isBot
                        ? VixRexBotMessage(
                            msg: msg,
                            showCursor: !_isTyping,
                            cursorVisible: _cursorVisible,
                          )
                        : VixRexUserMessage(msg: msg),
                  );
                },
              ),
            ),
            if (quickReplies.isNotEmpty)
              VixRexQuickReplies(replies: quickReplies, onTap: _onQuickReply),
            const Divider(color: AppColors.border, height: 1),
            _buildInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      color: AppColors.bgEditor,
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: AppColors.success.withAlpha(180), blurRadius: 4)],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              children: [
                Text(
                  ChatbotConfig.botName,
                  style: const TextStyle(
                    color: AppColors.darkText,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(25),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    ChatbotConfig.systemStatus,
                    style: const TextStyle(
                      color: AppColors.primaryDark,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _clearHistory,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: const Text('Temizle', style: TextStyle(fontSize: 10, color: AppColors.mutedText, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: widget.onClose,
            child: Container(
              padding: const EdgeInsets.all(6),
              child: const Icon(Icons.close_rounded, color: AppColors.mutedText, size: 18),
            ),
          ),
        ],
      ),
    );
  }

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
                      Positioned(
                        top:
                            (_vixrexPanelAvatarSize / 2) +
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
                    ChatbotConfig.botName,
                    style: const TextStyle(
                      color: AppColors.darkText,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    ChatbotConfig.botSubtitle,
                    style: const TextStyle(
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

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
      color: AppColors.surface,
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.inputBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: _inputCtrl,
                style: const TextStyle(
                  color: AppColors.darkText,
                  fontSize: 12.5,
                ),
                decoration: const InputDecoration.collapsed(
                  hintText: 'Bir şey sorun...',
                  hintStyle: TextStyle(color: AppColors.mutedText, fontSize: 12.5),
                ),
                onSubmitted: _sendMessage,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _sendMessage(_inputCtrl.text),
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                gradient: AppColors.ctaGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}
