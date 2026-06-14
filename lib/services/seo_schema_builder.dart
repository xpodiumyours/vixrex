import 'package:vitrinx/models/store_data.dart';

Map<String, dynamic> buildStoreSchemas(StoreData store, {String? publicUrl}) {
  final Map<String, dynamic> localBusiness = {
    '@context': 'https://schema.org',
    '@type': 'LocalBusiness',
    'name': store.name.trim(),
    'description': store.description.trim(),
  };

  if (store.address.trim().isNotEmpty) {
    localBusiness['address'] = {
      '@type': 'PostalAddress',
      'streetAddress': store.address.trim(),
    };
  }

  if (store.latitude != null && store.longitude != null) {
    localBusiness['geo'] = {
      '@type': 'GeoCoordinates',
      'latitude': store.latitude,
      'longitude': store.longitude,
    };
  }

  if (store.whatsapp.trim().isNotEmpty) {
    localBusiness['telephone'] = store.whatsapp.trim();
  }

  if (store.displayGalleryItems.isNotEmpty) {
    final imgUrl = store.displayGalleryItems.first.imageUrl.trim();
    if (imgUrl.isNotEmpty) {
      localBusiness['image'] = imgUrl;
    }
  }

  if (publicUrl != null && publicUrl.trim().isNotEmpty) {
    localBusiness['url'] = publicUrl.trim();
  }

  // Validate working hours
  final hoursRegex = RegExp(r'^(\d{2}:\d{2})\s*-\s*(\d{2}:\d{2})$');
  final match = hoursRegex.firstMatch(store.workingHours.trim());
  if (match != null) {
    final opens = match.group(1)!;
    final closes = match.group(2)!;
    localBusiness['openingHoursSpecification'] = {
      '@type': 'OpeningHoursSpecification',
      'dayOfWeek': [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ],
      'opens': opens,
      'closes': closes,
    };
  }

  // Detect numerical pricing for priceRange
  bool hasNumericalPrice = false;
  final digitRegex = RegExp(r'\d');
  for (final product in store.products) {
    if (digitRegex.hasMatch(product.price)) {
      hasNumericalPrice = true;
      break;
    }
  }

  if (hasNumericalPrice) {
    localBusiness['priceRange'] = r'$$';
  }

  // Generate product schemas
  final List<Map<String, dynamic>> productsList = [];
  for (final product in store.products) {
    final Map<String, dynamic> productSchema = {
      '@context': 'https://schema.org',
      '@type': 'Product',
      'name': product.name.trim(),
      'description': product.description.trim(),
    };

    if (product.imagePath != null && product.imagePath!.trim().isNotEmpty) {
      productSchema['image'] = product.imagePath!.trim();
    }

    // Extract price safely - only if it contains digits
    if (digitRegex.hasMatch(product.price)) {
      final cleanPrice = product.price
          .replaceAll(RegExp(r'[^0-9.,]'), '')
          .replaceAll(',', '.');
      if (cleanPrice.isNotEmpty) {
        final currency =
            product.price.contains('TL') || product.price.contains('₺')
                ? 'TRY'
                : 'USD';
        productSchema['offers'] = {
          '@type': 'Offer',
          'price': cleanPrice,
          'priceCurrency': currency,
          'availability':
              product.stockStatus == 'Tükendi'
                  ? 'https://schema.org/OutOfStock'
                  : 'https://schema.org/InStock',
        };
      }
    }

    productsList.add(productSchema);
  }

  if (productsList.isEmpty) {
    return localBusiness;
  }

  return {
    '@context': 'https://schema.org',
    '@graph': [localBusiness, ...productsList],
  };
}
