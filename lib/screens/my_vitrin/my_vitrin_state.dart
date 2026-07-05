import 'package:flutter/material.dart';
import 'package:vixrex/config/app_router.dart';
import 'package:vixrex/controllers/store_editor_controller.dart';
import 'package:vixrex/models/chat_message.dart';
import 'package:vixrex/services/store_publish_service.dart';

/// VixRex AI asistanın scroll-to-section aksiyonları.
/// [home_shell_screen.dart] tarafından GlobalKey üzerinden çağrılır.
class MyVitrinState extends ChangeNotifier {
  final StoreEditorController controller;

  MyVitrinState({required this.controller}) {
    controller.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    notifyListeners();
  }

  // ─── Scroll-to-Section Keys ──────────────────────────────────────────────
  final GlobalKey coverPhotoKey = GlobalKey();
  final GlobalKey galleryKey = GlobalKey();
  final GlobalKey nameKey = GlobalKey();
  final GlobalKey whatsappKey = GlobalKey();
  final GlobalKey addressKey = GlobalKey();
  final GlobalKey legalKey = GlobalKey();
  final GlobalKey descriptionKey = GlobalKey();
  final GlobalKey productsKey = GlobalKey();
  final GlobalKey categoryKey = GlobalKey();

  // ─── FocusNodes ──────────────────────────────────────────────────────────
  final FocusNode nameFocusNode = FocusNode();
  final FocusNode whatsappFocusNode = FocusNode();
  final FocusNode descriptionFocusNode = FocusNode();

  // ─── SnackBar helper ─────────────────────────────────────────────────────
  void showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  // ─── Scroll to section ───────────────────────────────────────────────────
  void scrollToVixRexAction(VixRexAction action) {
    GlobalKey? key;
    FocusNode? focus;

    switch (action) {
      case VixRexAction.scrollToCover:
        key = coverPhotoKey;
        break;
      case VixRexAction.scrollToGallery:
        key = galleryKey;
        break;
      case VixRexAction.scrollToName:
        key = nameKey;
        focus = nameFocusNode;
        break;
      case VixRexAction.scrollToWhatsapp:
        key = whatsappKey;
        focus = whatsappFocusNode;
        break;
      case VixRexAction.scrollToAddress:
        key = addressKey;
        break;
      case VixRexAction.scrollToLegal:
        key = legalKey;
        break;
      case VixRexAction.scrollToDesc:
        key = descriptionKey;
        focus = descriptionFocusNode;
        break;
      case VixRexAction.scrollToProducts:
        key = productsKey;
        break;
      case VixRexAction.scrollToCategory:
        // Tümü kategori alanına scroll yapar (AutoFillBanner orada)
        key = categoryKey;
        break;
      case VixRexAction.openVitrim:
      case VixRexAction.copyLink:
      case VixRexAction.shareWhatsapp:
      case VixRexAction.showQr:
      case VixRexAction.openExplore:
      case VixRexAction.openCoverTemplatePicker:
      case VixRexAction.none:
        break;
    }

    final currentContext = key?.currentContext;
    if (currentContext != null) {
      Scrollable.ensureVisible(
        currentContext,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }

    if (focus != null) {
      Future.delayed(const Duration(milliseconds: 550), () {
        focus!.requestFocus();
      });
    }
  }

  // ─── Publish wrapper ─────────────────────────────────────────────────────
  Future<void> handlePublish(
    BuildContext context,
    VoidCallback? onPublished,
  ) async {
    try {
      final link = await controller.publish();
      if (link != null && context.mounted) {
        showSnackBar(context, "Vitrinin yayinda! Kesfet'te gorunursun.");
        onPublished?.call();
      }
    } on StorePublishException catch (e) {
      if (context.mounted) showSnackBar(context, e.message);
    } catch (e) {
      if (context.mounted) {
        showSnackBar(
          context,
          'Vitrin yayina alinamadi. Lutfen tekrar deneyin.',
        );
      }
    }
  }

  // ─── Withdraw wrapper ────────────────────────────────────────────────────
  Future<void> handleWithdraw(BuildContext context) async {
    try {
      await controller.withdrawPublicationConsent();
      if (context.mounted) {
        showSnackBar(
          context,
          'Yayinlama rizaniz geri cekildi ve vitrininiz yayindan kaldirildi.',
        );
      }
    } on StorePublishException catch (e) {
      if (context.mounted) showSnackBar(context, e.message);
    } catch (e) {
      if (context.mounted) {
        showSnackBar(
          context,
          'Vitrin yayindan kaldirilamadi. Lutfen tekrar deneyin.',
        );
      }
    }
  }

  // ─── Delete wrapper ──────────────────────────────────────────────────────
  Future<void> handleDelete(BuildContext context) async {
    try {
      await controller.deleteVitrin();
      if (context.mounted) {
        AppRouter.navigateToLanding(context);
      }
    } catch (e) {
      if (context.mounted) {
        showSnackBar(context, 'Vitrin silinirken bir hata olustu.');
      }
    }
  }

  @override
  void dispose() {
    controller.removeListener(_onControllerChanged);
    nameFocusNode.dispose();
    whatsappFocusNode.dispose();
    descriptionFocusNode.dispose();
    super.dispose();
  }
}
