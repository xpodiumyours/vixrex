import 'package:flutter/material.dart';
import '../store_editor_controller.dart';

class EditCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final VoidCallback? onAction;
  final Widget? headerWidget;

  const EditCard({
    super.key,
    required this.title,
    required this.children,
    this.onAction,
    this.headerWidget,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;
    const primaryColor = Color(0xFFFF4D00);
    const secondaryColor = Color(0xFFB200FF);
    const darkText = Color(0xFF111827);
    const cardBorder = Color.fromRGBO(15, 23, 42, 0.10);

    return Container(
      decoration: BoxDecoration(
        color: const Color.fromRGBO(255, 255, 255, 0.94),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cardBorder, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.04),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
          BoxShadow(
            color: Color.fromRGBO(178, 0, 255, 0.02),
            blurRadius: 38,
            offset: Offset(0, 0),
          ),
        ],
      ),
      padding: EdgeInsets.all(isWide ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: darkText,
                    letterSpacing: 0,
                  ),
                ),
              ),
              if (headerWidget != null)
                headerWidget!
              else if (onAction != null)
                IconButton(
                  onPressed: onAction,
                  icon: const Icon(
                    Icons.add_circle_outline_rounded,
                    color: primaryColor,
                  ),
                  tooltip: 'Yeni Ekle',
                ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: 52,
            height: 4,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [primaryColor, secondaryColor],
              ),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }
}

class EditorTextField extends StatelessWidget {
  final String label;
  final Function(String) onChanged;
  final int maxLines;
  final IconData? prefixIcon;
  final String? initial;
  final String? hintText;
  final TextEditingController? controller;
  final Widget? suffixIcon;

  const EditorTextField({
    super.key,
    required this.label,
    required this.onChanged,
    this.maxLines = 1,
    this.prefixIcon,
    this.initial,
    this.hintText,
    this.controller,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    const softText = Color(0xFF334155);
    const mutedText = Color(0xFF64748B);
    const cardBorder = Color.fromRGBO(15, 23, 42, 0.10);
    const inputBg = Color(0xFFF1F5F9);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: softText.withAlpha((0.78 * 255).round()),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          initialValue: controller == null ? initial : null,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 14, color: Color(0xFF111827), fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: mutedText, size: 18) : null,
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: cardBorder),
            ),
            filled: true,
            fillColor: inputBg,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            hintText: hintText ?? label,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0x66FF4D00)),
            ),
            hintStyle: TextStyle(
              color: mutedText.withAlpha((0.58 * 255).round()),
              fontSize: 14,
            ),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class EditorDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final void Function(String?) onChanged;

  const EditorDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const softText = Color(0xFF334155);
    const mutedText = Color(0xFF64748B);
    const cardBorder = Color.fromRGBO(15, 23, 42, 0.10);
    const inputBg = Color(0xFFF1F5F9);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: softText.withAlpha((0.78 * 255).round()),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: cardBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0x66FF4D00)),
            ),
            filled: true,
            fillColor: inputBg,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          dropdownColor: Colors.white,
          iconEnabledColor: mutedText,
          style: const TextStyle(
            color: Color(0xFF111827),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          items: items.map((String val) {
            return DropdownMenuItem<String>(
              value: val,
              child: Text(val),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class ScoreTargetAnchor extends StatelessWidget {
  final StoreScoreTarget target;
  final StoreEditorController controller;
  final Map<StoreScoreTarget, GlobalKey> scoreTargetKeys;
  final Widget child;

  const ScoreTargetAnchor({
    super.key,
    required this.target,
    required this.controller,
    required this.scoreTargetKeys,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isHighlighted = controller.highlightedScoreTarget == target;
    const primaryColor = Color(0xFFFF4D00);

    return AnimatedContainer(
      key: scoreTargetKeys[target],
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isHighlighted ? primaryColor.withAlpha((0.08 * 255).round()) : Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isHighlighted ? primaryColor.withAlpha((0.42 * 255).round()) : Colors.transparent,
          width: 1.4,
        ),
        boxShadow: isHighlighted
            ? [
                BoxShadow(
                  color: primaryColor.withAlpha((0.16 * 255).round()),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ]
            : null,
      ),
      child: child,
    );
  }
}
