import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vitrinx/controllers/store_editor_controller.dart';
import 'package:vitrinx/screens/my_vitrin/my_vitrin_state.dart';
import 'package:vitrinx/screens/my_vitrin/sections/vitrin_form_section.dart';
import 'package:vitrinx/screens/my_vitrin/sections/vitrin_publish_section.dart';
import 'package:vitrinx/screens/my_vitrin/sections/vitrin_danger_section.dart';
import 'package:vitrinx/theme/app_colors.dart';

class MyVitrinScreen extends StatefulWidget {
  final String? initialName;
  final VoidCallback? onPublished;
  final VoidCallback? onOpenExplore;

  const MyVitrinScreen({
    super.key,
    this.initialName,
    this.onPublished,
    this.onOpenExplore,
  });

  @override
  State<MyVitrinScreen> createState() => _MyVitrinScreenState();
}

class _MyVitrinScreenState extends State<MyVitrinScreen> {
  late final StoreEditorController _controller;
  late final MyVitrinState _state;

  final _nameController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _instagramController = TextEditingController();
  final _websiteController = TextEditingController();
  final _googleBusinessLinkController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = StoreEditorController();
    _state = MyVitrinState(controller: _controller);
    _initialize();
  }

  Future<void> _initialize() async {
    await _controller.initialize(widget.initialName);
    _syncControllers();
  }

  void _syncControllers() {
    _nameController.text = _controller.data.name;
    _whatsappController.text = _controller.data.whatsapp;
    _addressController.text = _controller.data.address;
    _descriptionController.text = _controller.data.description;
    _instagramController.text = _controller.data.instagram;
    _websiteController.text =
        _controller.publishedInfo?.publicLink ?? _controller.data.website;
    _googleBusinessLinkController.text =
        _controller.data.googleBusinessLink;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _whatsappController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    _instagramController.dispose();
    _websiteController.dispose();
    _googleBusinessLinkController.dispose();
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _state,
      builder: (context, child) {
        if (_controller.isLoading) {
          return const Scaffold(
            backgroundColor: AppColors.bgEditor,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        final hasPublished = _controller.publishedInfo?.isComplete == true;

        return Scaffold(
          backgroundColor: AppColors.bgEditor,
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth > 720;
                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 32 : 16,
                    vertical: isDesktop ? 28 : 18,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 680),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          VitrinFormSection(
                            controller: _controller,
                            state: _state,
                            textControllers: {
                              'name': _nameController,
                              'whatsapp': _whatsappController,
                              'address': _addressController,
                              'description': _descriptionController,
                              'instagram': _instagramController,
                              'website': _websiteController,
                              'googleBusiness': _googleBusinessLinkController,
                            },
                            onPublished: widget.onPublished,
                            onOpenExplore: widget.onOpenExplore,
                          ),
                          if (hasPublished)
                            VitrinPublishSection(
                              controller: _controller,
                              state: _state,
                              onOpenExplore: widget.onOpenExplore,
                            ),
                          if (hasPublished)
                            VitrinDangerSection(state: _state),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
