import 'package:flutter/material.dart';
import 'package:vixrex/config/business_category_config.dart';
import 'package:vixrex/controllers/store_editor_controller.dart';
import 'package:vixrex/screens/my_vitrin/my_vitrin_state.dart';
import 'package:vixrex/theme/app_colors.dart';
import 'package:vixrex/widgets/editor/common_form_fields.dart';
import 'package:vixrex/widgets/editor/form_location_info.dart';
import 'package:vixrex/widgets/editor/sections/spaced_column.dart';
import 'package:vixrex/widgets/editor/working_hours_editor.dart';

/// Konum ve saatler bölümü — adres, yol tarifi, çalışma saatleri ve
/// (destekleyen kategorilerde) randevu editörü.
///
/// Faz 0 kalanı (Tek Asistan planı): vitrin_form_section.dart'ın altı bölüm
/// gövdesinden biri.
class KonumSaatlerBolumu extends StatelessWidget {
  const KonumSaatlerBolumu({
    super.key,
    required this.controller,
    required this.state,
    required this.addressController,
    required this.heroLocationTextController,
    required this.mapLabelController,
    required this.workingHoursController,
  });

  final StoreEditorController controller;
  final MyVitrinState state;
  final TextEditingController addressController;
  final TextEditingController heroLocationTextController;
  final TextEditingController mapLabelController;
  final TextEditingController workingHoursController;

  @override
  Widget build(BuildContext context) {
    return SpacedColumn(
      children: [
        FormLocationInfo(
          controller: controller,
          state: state,
          addressController: addressController,
          heroLocationTextController: heroLocationTextController,
          mapLabelController: mapLabelController,
        ),
        _buildDirectionsToggle(context),
        EditorTextField(
          label: 'Çalışma Saatleri',
          controller: workingHoursController,
          hint: 'Örn: Pzt — Cmt 09:00 - 20:00',
          icon: Icons.schedule_rounded,
          onChanged: (v) => controller.updateWorkingHoursText(v),
        ),
        if (BusinessCategoryConfig.supportsBookingPackage(
          controller.selectedKategori,
        ))
          WorkingHoursEditor(
            bookingIsEnabled: controller.bookingIsEnabled,
            bookingCapacity: controller.bookingCapacity,
            bookingWorkingHours: controller.bookingWorkingHours,
            bookingLunchBreak: controller.bookingLunchBreak,
            offerings: controller.offerings,
            selectedKategori: controller.selectedKategori,
            onBookingEnabledChanged: controller.setBookingIsEnabled,
            onBookingCapacityChanged: controller.setBookingCapacity,
            onStateChanged: controller.refreshBookingEditor,
            showSnackBar: (msg) => state.showSnackBar(context, msg),
          ),
      ],
    );
  }

  // ListTile türevleri mürekkep efektini en yakın Material üzerine çizer.
  // Bu, arka planı olan bir Container'ın içinde duruyor; araya Material
  // konmazsa Flutter "efektler görünmez olacak" diye assertion fırlatıyor.
  Widget _buildDirectionsToggle(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        title: const Text(
          'Yol tarifi butonu göster',
          style: TextStyle(
            color: AppColors.darkText,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: const Text(
          'Adres veya GPS varsa vitrinde yol tarifi linki çıkar.',
          style: TextStyle(color: AppColors.mutedText, fontSize: 11),
        ),
        value: controller.data.showDirectionsLink,
        activeThumbColor: AppColors.primary,
        onChanged: (value) {
          controller.updateShowDirectionsLink(value);
          controller.saveLocally();
        },
      ),
    );
  }
}
