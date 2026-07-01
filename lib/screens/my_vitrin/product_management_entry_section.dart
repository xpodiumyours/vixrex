import 'package:flutter/material.dart';
import 'package:vitrinx/widgets/product_management_entry_card.dart';

class ProductManagementEntrySection extends StatelessWidget {
  final int productCount;
  final VoidCallback onTap;

  const ProductManagementEntrySection({
    super.key,
    required this.productCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ProductManagementEntryCard(productCount: productCount, onTap: onTap);
  }
}
