import 'package:flutter/material.dart';

class VitrinPublishSection extends StatelessWidget {
  final Widget publishedSummary;
  final Widget actionButtons;
  final Widget visibilityHubCard;

  const VitrinPublishSection({
    super.key,
    required this.publishedSummary,
    required this.actionButtons,
    required this.visibilityHubCard,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        publishedSummary,
        const SizedBox(height: 16),
        actionButtons,
        const SizedBox(height: 16),
        visibilityHubCard,
      ],
    );
  }
}
