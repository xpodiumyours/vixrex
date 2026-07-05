import 'package:flutter/material.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/theme/vitrin_theme_preset.dart';
import 'package:vixrex/widgets/booking_wizard_sheet.dart';

class VitrinBookingCTA extends StatelessWidget {
  final StoreData storeData;
  final VitrinThemePreset preset;
  final bool isEmbedded;
  final bool publicMode;

  const VitrinBookingCTA({
    super.key,
    required this.storeData,
    required this.preset,
    this.isEmbedded = false,
    this.publicMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasBooking = storeData.bookingSettings?.isEnabled == true;
    if (!hasBooking) return const SizedBox();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isEmbedded ? 18.0 : 24.0),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: () {
            if (!publicMode) {
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Müşteriler bu butona basarak randevu alabilirler.',
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              return;
            }
            _openBookingWizard(context);
          },
          icon: const Icon(Icons.calendar_month_rounded, size: 20),
          label: const Text(
            'Randevu Al',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: preset.accent,
            foregroundColor: preset.buttonText,
            elevation: 0.5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }

  void _openBookingWizard(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => BookingWizardSheet(storeData: storeData),
    );
  }
}
