import 'package:flutter/material.dart';
import 'package:vixrex/controllers/store_editor_controller.dart';
import 'package:vixrex/screens/my_vitrin/my_vitrin_state.dart';
import 'package:vixrex/widgets/editor/location_editor_section.dart';

class FormLocationInfo extends StatefulWidget {
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
  State<FormLocationInfo> createState() => _FormLocationInfoState();
}

class _FormLocationInfoState extends State<FormLocationInfo> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_syncAddress);
  }

  @override
  void didUpdateWidget(covariant FormLocationInfo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_syncAddress);
      widget.controller.addListener(_syncAddress);
    }
    _syncAddress();
  }

  void _syncAddress() {
    if (!mounted) return;
    final nextAddress = widget.controller.data.address;
    if (widget.addressController.text == nextAddress) return;
    widget.addressController.value = TextEditingValue(
      text: nextAddress,
      selection: TextSelection.collapsed(offset: nextAddress.length),
    );
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncAddress);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: widget.state.addressKey,
      child: LocationEditorSection(
        selectedProvinceCode: widget.controller.selectedProvinceCode,
        selectedProvinceName: widget.controller.selectedProvinceName,
        selectedDistrictCode: widget.controller.selectedDistrictCode,
        selectedDistrictName: widget.controller.selectedDistrictName,
        provinceError: widget.controller.provinceError,
        districtError: widget.controller.districtError,
        addressError: widget.controller.addressError,
        addressController: widget.addressController,
        latitude: widget.controller.latitude,
        longitude: widget.controller.longitude,
        locationAccuracyMeters: widget.controller.locationAccuracyMeters,
        locationStatusMessage: widget.controller.locationStatusMessage,
        isLocating: widget.controller.isLocating,
        onProvinceChanged:
            (code, name) => widget.controller.selectProvince(
              widget.controller.data,
              code,
              name,
            ),
        onDistrictChanged:
            (code, name) => widget.controller.selectDistrict(
              widget.controller.data,
              code,
              name,
            ),
        onAddressChanged:
            (value) =>
                widget.controller.updateAddress(widget.controller.data, value),
        onLocateRequested: widget.controller.triggerFetchLocation,
      ),
    );
  }
}
