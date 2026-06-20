import 'package:vitrinx/models/store_data.dart';
import 'package:vitrinx/utils/whatsapp_link_helper.dart';

Map<String, dynamic> buildStoreSchemas(StoreData store, {String? publicUrl}) {
  final name = store.name.trim();
  final description = _effectiveDescription(store);
  final url = publicUrl?.trim() ?? '';
  final imageUrl = _effectiveImageUrl(store);
  final normalizedPhone = WhatsAppLinkHelper.normalizeTurkeyMobile(
    store.whatsapp,
  );
  final hasPhysicalLocation =
      store.address.trim().isNotEmpty &&
      store.latitude != null &&
      store.longitude != null;
  final entityId = url.isEmpty ? null : '$url#business';

  final Map<String, dynamic> entity = {
    '@type': hasPhysicalLocation ? 'LocalBusiness' : 'Organization',
    if (entityId != null) '@id': entityId,
    'name': name,
    if (description.isNotEmpty) 'description': description,
    if (url.isNotEmpty) 'url': url,
    if (imageUrl.isNotEmpty) 'image': imageUrl,
    if (store.logoUrl?.trim().isNotEmpty ?? false)
      'logo': store.logoUrl!.trim(),
    if (normalizedPhone != null) 'telephone': '+$normalizedPhone',
  };

  if (hasPhysicalLocation) {
    entity['address'] = {
      '@type': 'PostalAddress',
      'streetAddress': store.address.trim(),
      'addressCountry': 'TR',
    };
    entity['geo'] = {
      '@type': 'GeoCoordinates',
      'latitude': store.latitude,
      'longitude': store.longitude,
    };
    entity['hasMap'] =
        'https://www.google.com/maps/search/?api=1&query='
        '${store.latitude},${store.longitude}';

    final hours = _openingHours(store.workingHours);
    if (hours != null) {
      entity['openingHoursSpecification'] = hours;
    }
  }

  final graph = <Map<String, dynamic>>[entity];
  if (url.isNotEmpty) {
    graph.add({
      '@type': 'WebPage',
      '@id': '$url#webpage',
      'url': url,
      'name': name.isEmpty ? 'VitrinX' : '$name | VitrinX',
      if (description.isNotEmpty) 'description': description,
      'about': {'@id': entityId},
      if (imageUrl.isNotEmpty)
        'primaryImageOfPage': {'@type': 'ImageObject', 'url': imageUrl},
    });
  }

  return {'@context': 'https://schema.org', '@graph': graph};
}

String _effectiveDescription(StoreData store) {
  final description = store.description.trim();
  if (description.isNotEmpty) return description;
  return store.corporateBio.trim();
}

String _effectiveImageUrl(StoreData store) {
  final coverUrl = store.coverImageUrl.trim();
  if (coverUrl.isNotEmpty) return coverUrl;
  return store.logoUrl?.trim() ?? '';
}

Map<String, dynamic>? _openingHours(String rawHours) {
  final match = RegExp(
    r'^(\d{2}:\d{2})\s*-\s*(\d{2}:\d{2})$',
  ).firstMatch(rawHours.trim());
  if (match == null) return null;

  return {
    '@type': 'OpeningHoursSpecification',
    'dayOfWeek': const [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ],
    'opens': match.group(1),
    'closes': match.group(2),
  };
}
