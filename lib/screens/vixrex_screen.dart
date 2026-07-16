import 'package:flutter/material.dart';
import 'package:vixrex/models/chat_message.dart';
import 'package:vixrex/services/vixrex_assistant_nlu_types.dart';
import 'package:vixrex/services/vixrex_guidance_service.dart';
import 'package:vixrex/services/vixrex_profile_snapshot.dart';
import 'package:vixrex/theme/app_colors.dart';
import 'package:vixrex/widgets/vixrex/vixrex_companion_chat.dart';
import 'package:vixrex/widgets/vixrex/vixrex_hero.dart';
import 'package:vixrex/widgets/vixrex/vixrex_progress_card.dart';

const double _vixrexHeroAvatarSize = 34;

/// Vixrex sekmesinin tek, kalıcı sohbet yüzeyi.
///
/// Vitrin araçları ayrı kart listesi olarak gösterilmez; mevcut aksiyonlar
/// [VixRexCompanionChat] içindeki sıradaki-adım kartı ve hızlı yanıtlara bağlıdır.
class VixRexScreen extends StatefulWidget {
  final VixRexProfileSnapshot? snapshot;
  final bool hasShared;
  final String? dismissedRecommendationId;
  final ValueChanged<VixRexAction> onAction;
  final ValueChanged<String> onDismissRecommendation;
  final void Function(VixRexNluField field, String value) onSaveField;

  const VixRexScreen({
    super.key,
    required this.snapshot,
    required this.hasShared,
    required this.dismissedRecommendationId,
    required this.onAction,
    required this.onDismissRecommendation,
    required this.onSaveField,
  });

  @override
  State<VixRexScreen> createState() => _VixRexScreenState();
}

class _VixRexScreenState extends State<VixRexScreen> {
  final _chatInputFocusNode = FocusNode();

  @override
  void dispose() {
    _chatInputFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recommendation = VixRexGuidanceService.recommendationFor(
      snapshot: widget.snapshot,
      hasShared: widget.hasShared,
    );

    return Scaffold(
      backgroundColor: AppColors.bgEditor,
      appBar: AppBar(
        toolbarHeight: 58,
        automaticallyImplyLeading: false,
        title: VixRexHero(
          mascotSize: _vixrexHeroAvatarSize,
          onTap: _chatInputFocusNode.requestFocus,
        ),
        backgroundColor: AppColors.bgEditor,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          child: Column(
            children: [
              VixRexProgressCard(
                snapshot: widget.snapshot,
                phase: recommendation.phase,
                hasShared: widget.hasShared,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: VixRexCompanionChat(
                  snapshot: widget.snapshot,
                  hasShared: widget.hasShared,
                  recommendation: recommendation,
                  isRecommendationDismissed:
                      widget.dismissedRecommendationId == recommendation.id,
                  onAction: widget.onAction,
                  onDismissRecommendation: widget.onDismissRecommendation,
                  onSaveField: widget.onSaveField,
                  inputFocusNode: _chatInputFocusNode,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
