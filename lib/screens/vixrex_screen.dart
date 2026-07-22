import 'package:flutter/material.dart';
import 'package:vixrex/controllers/store_editor_controller.dart';
import 'package:vixrex/models/chat_message.dart';
import 'package:vixrex/screens/vixrex_onboarding_chat_screen.dart';
import 'package:vixrex/services/vixrex_assistant_nlu_types.dart';
import 'package:vixrex/services/vixrex_guidance_service.dart';
import 'package:vixrex/services/vixrex_profile_snapshot.dart';
import 'package:vixrex/theme/app_colors.dart';
import 'package:vixrex/widgets/vixrex/vixrex_companion_chat.dart';
import 'package:vixrex/widgets/vixrex/vixrex_hero.dart';

const double _vixrexHeroAvatarSize = 34;

/// Vixrex sekmesinin tek yüzeyi.
///
/// Yayın yok: landing ile aynı [VixRexOnboardingChatScreen] (sekme içinde).
/// Yayın var: [VixRexCompanionChat] rehber (şablon → ürün → paylaş).
class VixRexScreen extends StatefulWidget {
  final VixRexProfileSnapshot? snapshot;
  final StoreEditorController? editorController;
  final Future<void>? editorInitialization;
  final bool hasShared;
  final String? dismissedRecommendationId;
  final ValueChanged<VixRexAction> onAction;
  final ValueChanged<String> onDismissRecommendation;
  final void Function(VixRexNluField field, String value) onSaveField;
  final VoidCallback? onSetupComplete;

  const VixRexScreen({
    super.key,
    required this.snapshot,
    this.editorController,
    this.editorInitialization,
    required this.hasShared,
    required this.dismissedRecommendationId,
    required this.onAction,
    required this.onDismissRecommendation,
    required this.onSaveField,
    this.onSetupComplete,
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

  bool get _needsSetup =>
      widget.snapshot == null || !widget.snapshot!.isPublished;

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
          onTap: _needsSetup ? null : _chatInputFocusNode.requestFocus,
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
        child: _needsSetup
            ? VixRexOnboardingChatScreen(
                key: const ValueKey('vixrex_setup'),
                editorController: widget.editorController,
                editorInitialization: widget.editorInitialization,
                embeddedInShell: true,
                onSetupComplete: widget.onSetupComplete,
              )
            : Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                child: VixRexCompanionChat(
                  key: const ValueKey('vixrex_rehber'),
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
      ),
    );
  }
}
