import 'package:flutter/material.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/theme/app_colors.dart';

class RentalTemplateSheet extends StatefulWidget {
  final StoreData store;
  final Future<bool> Function() onStartTrial;

  const RentalTemplateSheet({
    super.key,
    required this.store,
    required this.onStartTrial,
  });

  @override
  State<RentalTemplateSheet> createState() => _RentalTemplateSheetState();
}

class _RentalTemplateSheetState extends State<RentalTemplateSheet> {
  bool _starting = false;

  Future<void> _handleStartTrial() async {
    setState(() => _starting = true);
    try {
      final started = await widget.onStartTrial();
      if (!started || !mounted) return;
      Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final category = widget.store.kategori.trim().isNotEmpty
        ? widget.store.kategori.trim()
        : widget.store.businessType.trim();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 23,
                  backgroundColor: Color(0x33F59E0B),
                  child: Icon(Icons.storefront_rounded, color: Color(0xFFF59E0B)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$category için hazır kiralık vitrin',
                        style: const TextStyle(
                          color: AppColors.darkText,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.store.name} şablonu sana bağımsız olarak kopyalanır.',
                        style: const TextStyle(
                          color: AppColors.mutedText,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _Benefit(
              icon: Icons.auto_awesome_rounded,
              text: 'Kapak, ürünler, kategoriler, Hakkımızda ve SSS hazır gelir.',
            ),
            _Benefit(
              icon: Icons.chat_rounded,
              text: 'Vixrex Asistan ile kendi işletmene göre düzenlersin.',
            ),
            _Benefit(
              icon: Icons.lock_outline_rounded,
              text: 'Ana şablon ve başka kullanıcıların vitrinleri değişmez.',
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceSoft,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '14 gün ücretsiz dene',
                    style: TextStyle(
                      color: AppColors.darkText,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Sonrasında 499 TL + KDV / ay. PayTR bağlantısı tamamlanana kadar kart bilgisi istenmez.',
                    style: TextStyle(color: AppColors.mutedText, height: 1.35),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _starting ? null : _handleStartTrial,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  foregroundColor: const Color(0xFF1C1917),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _starting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        '14 gün ücretsiz dene',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
              ),
            ),
            const SizedBox(height: 10),
            const Center(
              child: Text(
                'Ödeme adımı PayTR bağlantısı açıldığında burada görünecek.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.mutedText, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Benefit({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: AppColors.mutedText, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}
