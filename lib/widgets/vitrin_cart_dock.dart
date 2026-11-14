import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vixrex/services/vitrin_cart_service.dart';
import 'package:vixrex/theme/app_colors.dart';

class VitrinCartDock extends StatefulWidget {
  const VitrinCartDock({
    super.key,
    required this.storeSlug,
    required this.storeName,
    required this.whatsappNumber,
  });

  final String storeSlug;
  final String storeName;
  final String whatsappNumber;

  @override
  State<VitrinCartDock> createState() => _VitrinCartDockState();
}

class _VitrinCartDockState extends State<VitrinCartDock> {
  final VitrinCartService _cart = VitrinCartService.instance;

  @override
  void initState() {
    super.initState();
    _cart.addListener(_refresh);
  }

  @override
  void dispose() {
    _cart.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() => setState(() {});

  Future<void> _send() async {
    if (_cart.items.isEmpty) return;
    final text = _cart.buildWhatsAppText(
      storeName: widget.storeName,
      storeSlug: widget.storeSlug,
    );
    final number = widget.whatsappNumber.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse(
      'https://wa.me/$number?text=${Uri.encodeComponent(text)}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final count = _cart.totalQuantity();
    if (count == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Sepet: $count ürün',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          ElevatedButton(
            onPressed: _send,
            child: const Text('Siparişi Gönder'),
          ),
        ],
      ),
    );
  }
}
