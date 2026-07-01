import 'package:flutter/material.dart';

class PublishLegalApprovalSection extends StatelessWidget {
  final Widget legalConsentSection;
  final Widget publishButton;
  final Widget publishHint;

  const PublishLegalApprovalSection({
    super.key,
    required this.legalConsentSection,
    required this.publishButton,
    required this.publishHint,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        legalConsentSection,
        const SizedBox(height: 16),
        publishButton,
        const SizedBox(height: 8),
        publishHint,
      ],
    );
  }
}
