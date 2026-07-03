import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vitrinx/config/chatbot_config.dart';
import 'package:vitrinx/theme/app_colors.dart';
import 'package:vitrinx/widgets/chatbot_overlay.dart';

class XrexScreen extends StatefulWidget {
  const XrexScreen({super.key});

  @override
  State<XrexScreen> createState() => _XrexScreenState();
}

class _XrexScreenState extends State<XrexScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _addBotMessage(
      'Merhaba! Ben X-rex, VitrinX yapay zeka asistanınım. '
      'Sana vitrin oluşturma, görsel seçimi ve işletme profilinle ilgili konularda yardımcı olabilirim.',
    );
  }

  void _addBotMessage(String text, {List<Widget>? actions}) {
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: false,
        actions: actions,
      ));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isTyping = true;
    });
    _controller.clear();
    _scrollToBottom();

    final recognized = ChatbotConfig.resolveIntent(text);

    await Future.delayed(const Duration(milliseconds: 800));

    setState(() => _isTyping = false);

    if (recognized != null) {
      _addBotMessage(
        ChatbotConfig.responseFor(recognized, context: context),
        actions: ChatbotConfig.actionsFor(recognized, context: context),
      );
    } else {
      _addBotMessage(
        'Anladım, bu konuda sana yardımcı olmaya çalışayım. '
        'Dilersen vitrin oluşturma, hazır görseller, SEO ayarları veya randevu sistemi hakkında sorular sorabilirsin.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgEditor,
      appBar: AppBar(
        backgroundColor: AppColors.bgEditor,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'X-rex Rehber',
                  style: TextStyle(
                    color: AppColors.darkText,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Yapay Zeka Asistanı',
                  style: TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Suggestion chips
          if (_messages.length <= 2)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nasıl yardımcı olabilirim?',
                    style: TextStyle(
                      color: AppColors.softText,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _SuggestionChip(
                        icon: Icons.storefront_rounded,
                        label: 'Vitrin araçları',
                        onTap: () {
                          _controller.text = 'Vitrin araçlarını göster';
                          _sendMessage();
                        },
                      ),
                      _SuggestionChip(
                        icon: Icons.image_rounded,
                        label: 'Hazır görseller',
                        onTap: () {
                          _controller.text = 'Hazır görselleri göster';
                          _sendMessage();
                        },
                      ),
                      _SuggestionChip(
                        icon: Icons.search_rounded,
                        label: 'SEO tavsiyeleri',
                        onTap: () {
                          _controller.text = 'SEO tavsiyeleri ver';
                          _sendMessage();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Vitrin tools section
                  _ToolCard(
                    icon: Icons.auto_awesome_rounded,
                    title: 'Kategoriye özel hazır görseller',
                    description:
                        'İşletme kategorine göre (Butik, Kuaför, Kafe vb.) hazır, telifsiz görsellerle vitrinini tek tıkla doldur.',
                    onTap: () {
                      _controller.text = 'Kategorime özel hazır görselleri kullanmak istiyorum';
                      _sendMessage();
                    },
                  ),
                  const SizedBox(height: 8),
                  _ToolCard(
                    icon: Icons.calendar_today_rounded,
                    title: 'Randevu sistemi ayarları',
                    description: 'Online randevu alma özelliğini nasıl aktif edeceğini öğren.',
                    onTap: () {
                      _controller.text = 'Randevu sistemi nasıl çalışır?';
                      _sendMessage();
                    },
                  ),
                ],
              ),
            ),
          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (_, index) => _messages[index],
            ),
          ),
          // Typing indicator
          if (_isTyping)
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: AppColors.primary,
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const _TypingIndicator(),
                ],
              ),
            ),
          // Input
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceSoft,
              border: Border(
                top: BorderSide(color: AppColors.cardBorderDark),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(
                        color: AppColors.darkText,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Bir mesaj yaz...',
                        hintStyle: TextStyle(
                          color: AppColors.mutedText.withValues(alpha: 0.6),
                          fontSize: 14,
                        ),
                        filled: true,
                        fillColor: AppColors.inputBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(999),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_upward_rounded,
                        color: Colors.black,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SuggestionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 16, color: AppColors.primary),
      label: Text(
        label,
        style: const TextStyle(
          color: AppColors.darkText,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
      backgroundColor: AppColors.surfaceSoft,
      side: BorderSide(color: AppColors.cardBorderDark),
      onPressed: onTap,
    );
  }
}

class _ToolCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _ToolCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceSoft,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorderDark),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.darkText,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: const TextStyle(
                      color: AppColors.mutedText,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.mutedText,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final offset = (i * 0.33) % 1.0;
            final value = ((_controller.value - offset) % 1.0);
            final opacity = value < 0.5 ? value * 2 : 2 - value * 2;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: AppColors.mutedText.withValues(
                  alpha: 0.3 + opacity * 0.7,
                ),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}
