import 'package:flutter/material.dart';
import 'package:vixrex/config/public_site_config.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/theme/app_colors.dart';

import 'package:vixrex/widgets/booking/booking_service_step.dart';
import 'package:vixrex/widgets/booking/booking_date_step.dart';
import 'package:vixrex/widgets/booking/booking_slot_step.dart';
import 'package:vixrex/widgets/booking/booking_details_step.dart';
import 'package:vixrex/widgets/booking/booking_success_step.dart';

import 'package:vixrex/controllers/booking_wizard_controller.dart';

class BookingWizardSheet extends StatefulWidget {
  final StoreData storeData;

  const BookingWizardSheet({super.key, required this.storeData});

  @override
  State<BookingWizardSheet> createState() => _BookingWizardSheetState();
}

class _BookingWizardSheetState extends State<BookingWizardSheet> {
  late final BookingWizardController _controller;

  @override
  void initState() {
    super.initState();
    _controller = BookingWizardController(storeData: widget.storeData);
    _controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    final bookableServices = widget.storeData.offerings.where((o) => o.isBookable).toList();

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.disabled,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  if (_controller.currentStep > 1 && _controller.currentStep < 5)
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                      onPressed: _controller.previousStep,
                    ),
                  Expanded(
                    child: Text(
                      _stepTitle,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.darkText),
                      textAlign: _controller.currentStep == 5 ? TextAlign.center : TextAlign.start,
                    ),
                  ),
                  if (_controller.currentStep < 5)
                    Text(
                      '${_controller.currentStep}/4',
                      style: const TextStyle(color: AppColors.mutedText, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                ],
              ),
            ),
            const Divider(height: 24, color: AppColors.border),
            // Content area
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_controller.errorMsg != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _controller.errorMsg!,
                          style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    _buildStepContent(bookableServices),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _stepTitle {
    switch (_controller.currentStep) {
      case 1:
        return 'Hizmet Seçimi';
      case 2:
        return 'Tarih Seçimi';
      case 3:
        return 'Saat Seçimi';
      case 4:
        return 'İletişim Bilgileri';
      case 5:
        return 'Talep Alındı!';
      default:
        return 'Randevu Al';
    }
  }

  Widget _buildStepContent(List<StoreOffering> services) {
    switch (_controller.currentStep) {
      case 1:
        return BookingServiceStep(
          services: services,
          selectedService: _controller.selectedService,
          onServiceSelected: _controller.selectService,
        );
      case 2:
        return BookingDateStep(
          dates: _controller.availableDates,
          selectedDate: _controller.selectedDate,
          onDateSelected: _controller.selectDate,
        );
      case 3:
        return BookingSlotStep(
          isLoadingSlots: _controller.isLoadingSlots,
          availableSlots: _controller.availableSlots,
          selectedSlotTime: _controller.selectedSlotTime,
          onSlotSelected: _controller.selectSlot,
        );
      case 4:
        return BookingDetailsStep(
          selectedService: _controller.selectedService!,
          selectedDate: _controller.selectedDate!,
          selectedSlotTime: _controller.selectedSlotTime!,
          nameController: _controller.nameController,
          phoneController: _controller.phoneController,
          notesController: _controller.notesController,
          kvkkConsent: _controller.kvkkConsent,
          onKvkkConsentChanged: (val) => _controller.kvkkConsent = val,
          isSubmitting: _controller.isSubmitting,
          onSubmit: () => _controller.submitRequest(() {}),
        );
      case 5:
        final trackingLink = PublicSiteConfig.buildBookingTrackerLink(
          widget.storeData.slug,
          _controller.createdToken ?? '',
        );
        return BookingSuccessStep(
          trackingLink: trackingLink,
          onCopyPressed: _showSnackBar,
          onClose: () => Navigator.pop(context),
        );
      default:
        return const SizedBox();
    }
  }

  void _showSnackBar(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }
}
