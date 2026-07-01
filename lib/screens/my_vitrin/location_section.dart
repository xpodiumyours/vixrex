import 'package:flutter/material.dart';

class LocationSection extends StatelessWidget {
  final GlobalKey locationKey;
  final Widget locationField;

  const LocationSection({
    super.key,
    required this.locationKey,
    required this.locationField,
  });

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(key: locationKey, child: locationField);
  }
}
