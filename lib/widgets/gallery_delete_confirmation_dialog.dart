import 'package:flutter/material.dart';

Future<bool> showGalleryDeleteConfirmationDialog(
  BuildContext context, {
  required bool isCover,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(isCover ? 'Kapak fotoğrafını sil?' : 'Fotoğrafı sil?'),
        content: Text(
          isCover
              ? 'Bu fotoğraf galerinin kapağı. Silersen sıradaki fotoğraf kapak olur.'
              : 'Bu fotoğraf galeriden kaldırılacak.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sil'),
          ),
        ],
      );
    },
  );

  return confirmed == true;
}
