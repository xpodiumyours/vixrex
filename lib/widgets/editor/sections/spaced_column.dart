import 'package:flutter/material.dart';

/// Form bölümlerinin ortak dikey aralıklı dizilimi.
///
/// Faz 0 kalanı (Tek Asistan planı): altı bölüm dosyası bu tek yardımcıyı
/// paylaşır; her biri kendi 14px aralığını elle tekrar yazmaz.
class SpacedColumn extends StatelessWidget {
  const SpacedColumn({super.key, required this.children, this.spacing = 14});

  final List<Widget> children;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < children.length; index++) ...[
          if (index > 0) SizedBox(height: spacing),
          children[index],
        ],
      ],
    );
  }
}
