import 'package:flutter/material.dart';
import 'package:vixrex/controllers/store_editor_controller.dart';
import 'package:vixrex/models/chat_message.dart';
import 'package:vixrex/screens/vixrex_onboarding_chat_screen.dart';
import 'package:vixrex/services/vixrex_assistant_nlu_types.dart';
import 'package:vixrex/services/vixrex_guidance_service.dart';
import 'package:vixrex/services/vixrex_profile_snapshot.dart';
import 'package:vixrex/services/working_draft/flutter_smart_engine_owner_executor.dart';
import 'package:vixrex/services/working_draft/smart_engine_working_draft_orchestrator.dart';
import 'package:vixrex/theme/app_colors.dart';
import 'package:vixrex/widgets/chat/chat_top_bar.dart';
import 'package:vixrex/widgets/common/app_screen_scaffold.dart';
import 'package:vixrex/widgets/vixrex/vixrex_companion_chat.dart';

/// Vixrex sekmesinin tek yüzeyi.
///
/// Yayın yok: landing ile aynı [VixRexOnboardingChatScreen] (sekme içinde).
/// Yayın var: [VixRexCompanionChat] rehber.
class VixRexScreen extends StatefulWidget {
  final VixRexProfileSnapshot? snapshot;
  final StoreEditorController? editorController;
  final Future<void>? editorInitialization;
  final bool hasShared;
  final String? dismissedRecommendationId;
  final ValueChanged<VixRexAction> onAction;
  final ValueChanged<String> onDismissRecommendation;

  /// Legacy remote NLU callbacks. 46-alan Akıllı Motor bunları kullanmaz.
  final void Function(VixRexNluField field, String value) onSaveField;
  final void Function(String anahtar, Object? deger)? onUpdateField;
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
    this.onUpdateField,
    this.onSetupComplete,
  });

  @override
  State<VixRexScreen> createState() => _VixRexScreenState();
}

class _VixRexScreenState extends State<VixRexScreen> {
  final _chatInputFocusNode = FocusNode();
  final _ownerExecutor = FlutterSmartEngineOwnerExecutor();

  @override
  void dispose() {
    _chatInputFocusNode.dispose();
    super.dispose();
  }

  bool get _needsSetup =>
      widget.snapshot == null || !widget.snapshot!.isPublished;

  Future<bool> _editorHazir() async {
    if (widget.editorController == null) return false;
    try {
      final initialization = widget.editorInitialization;
      if (initialization != null) await initialization;
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<FlutterSmartEngineCommandResult> _executeSmartEngine(
    List<FlutterSmartEngineAction> actions,
  ) async {
    if (!await _editorHazir()) {
      return FlutterSmartEngineCommandResult.blocked(
        draftVersion: 0,
        actions: actions,
        errorCode: 'EDITOR_NOT_READY',
        errorMessage: 'Vitrin henüz yüklenmedi.',
      );
    }
    return _ownerExecutor.execute(
      controller: widget.editorController!,
      actions: actions,
    );
  }

  Future<FlutterSmartEngineUndoExecutionResult> _undoSmartEngine(
    String commandId,
  ) async {
    if (!await _editorHazir()) {
      return FlutterSmartEngineUndoExecutionResult.failed(
        commandId: commandId,
        errorCode: 'EDITOR_NOT_READY',
        errorMessage: 'Vitrin henüz yüklenmedi.',
      );
    }
    return _ownerExecutor.undo(
      controller: widget.editorController!,
      commandId: commandId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final recommendation = VixRexGuidanceService.recommendationFor(
      snapshot: widget.snapshot,
      hasShared: widget.hasShared,
    );

    return AppScreenScaffold(
      toolbarHeight: 58,
      automaticallyImplyLeading: false,
      titleWidget: ChatTopBar(
        onTap: _needsSetup ? null : _chatInputFocusNode.requestFocus,
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColors.border),
      ),
      padding: EdgeInsets.zero,
      body: SafeArea(
        top: false,
        child:
            _needsSetup
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
                    onUpdateField: widget.onUpdateField,
                    onExecuteSmartEngine: _executeSmartEngine,
                    onUndoSmartEngine: _undoSmartEngine,
                    inputFocusNode: _chatInputFocusNode,
                  ),
                ),
      ),
    );
  }
}
