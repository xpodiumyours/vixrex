import 'package:flutter/material.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/screens/public_vitrin_screen.dart';
import 'package:vixrex/services/public_store_service.dart';
import 'package:vixrex/theme/app_colors.dart';
import 'package:vixrex/widgets/booking_wizard_sheet.dart';

/// Public deep link: `/v/:slug/randevu` — Next.js ile aynı path sözleşmesi.
class PublicBookingScreen extends StatefulWidget {
  final String slug;

  const PublicBookingScreen({super.key, required this.slug});

  @override
  State<PublicBookingScreen> createState() => _PublicBookingScreenState();
}

class _PublicBookingScreenState extends State<PublicBookingScreen> {
  late final Future<StoreData?> _storeFuture;

  @override
  void initState() {
    super.initState();
    _storeFuture = _loadStore();
  }

  Future<StoreData?> _loadStore() async {
    final result =
        await const PublicStoreService().fetchPublishedStoreBySlug(widget.slug);
    return result.when(
      success: (response) {
        if (response == null) return null;
        return PublicVitrinScreen.mapStoreFromSupabase(
          slug: widget.slug,
          data: response,
        );
      },
      failure: (_) => null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<StoreData?>(
      future: _storeFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: Color(0xFF071322),
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        final store = snapshot.data;
        if (store == null) {
          return Scaffold(
            backgroundColor: const Color(0xFF071322),
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
            ),
            body: const Center(
              child: Text(
                'Vitrin bulunamadı veya randevu kapalı.',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          );
        }

        final bookingEnabled = store.bookingSettings?.isEnabled == true;
        if (!bookingEnabled) {
          return Scaffold(
            backgroundColor: const Color(0xFF071322),
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
            ),
            body: const Center(
              child: Text(
                'Bu vitrinde online randevu kapalı.',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: Text('${store.name} — Randevu'),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            elevation: 0,
          ),
          body: SafeArea(
            child: BookingWizardSheet(storeData: store),
          ),
        );
      },
    );
  }
}
