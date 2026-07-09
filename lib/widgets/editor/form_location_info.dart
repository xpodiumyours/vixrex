import 'package:flutter/material.dart';
import 'package:vixrex/controllers/store_editor_controller.dart';
import 'package:vixrex/screens/my_vitrin/my_vitrin_state.dart';
import 'package:vixrex/widgets/editor/location_editor_section.dart';

class FormLocationInfo extends StatelessWidget {
  final StoreEditorController controller;
  final MyVitrinState state;
  final TextEditingController addressController;

  const FormLocationInfo({
    super.key,
    required this.controller,
    required this.state,
    required this.addressController,
  });

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: state.addressKey,
      child: LocationEditorSection(
        selectedProvinceCode: controller.selectedProvinceCode,
        selectedProvinceName: controller.selectedProvinceName,
        selectedDistrictCode: controller.selectedDistrictCode,
        selectedDistrictName: controller.selectedDistrictName,
        provinceError: controller.provinceError,
        districtError: controller.districtError,
        addressError: controller.addressError,
        addressController: addressController,
        latitude: controller.latitude,
        longitude: controller.longitude,
        locationAccuracyMeters: controller.locationAccuracyMeters,
        locationStatusMessage: controller.locationStatusMessage,
        isLocating: controller.isLocating,
        onProvinceChanged: (code, name) => controller.selectProvince(controller.data, code, name),
        onDistrictChanged: (code, name) => controller.selectDistrict(controller.data, code, name),
        onAddressChanged: (value) => controller.updateAddress(controller.data, value),
        onLocatingStateChanged: (_) {},
        onLocationUpdated: ({
          latitude,
          longitude,
          accuracy,
          statusMessage,
          address,
          provinceCode,
          provinceName,
          districtCode,
          districtName,
        }) {
          if (address != null) {
            addressController.text = address;
            controller.updateAddress(controller.data, address);
          }
          controller.selectProvince(controller.data, provinceCode, provinceName);
          controller.selectDistrict(controller.data, districtCode, districtName);
        },
      ),
    );
  }
}
