import 'package:flutter/material.dart';

class StatusChip extends StatelessWidget {
  final String status;
  
  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    IconData? icon;

    switch (status) {
      case 'Açık':
        bgColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        icon = Icons.check_circle;
        break;
      case 'Bugün kampanya var':
        bgColor = Colors.orange.shade100;
        textColor = Colors.orange.shade900;
        icon = Icons.local_offer;
        break;
      case 'Yeni ürünler geldi':
        bgColor = Colors.blue.shade100;
        textColor = Colors.blue.shade900;
        icon = Icons.new_releases;
        break;
      case 'Stok sınırlı':
        bgColor = Colors.red.shade100;
        textColor = Colors.red.shade900;
        icon = Icons.warning_amber;
        break;
      default:
        bgColor = Colors.grey.shade200;
        textColor = Colors.black87;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: textColor),
            const SizedBox(width: 6),
          ],
          Text(
            status,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
