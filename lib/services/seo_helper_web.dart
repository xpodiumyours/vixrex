// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:convert';
import 'dart:html' as html;
import 'package:vitrinx/models/store_data.dart';

void injectStoreJsonLdImpl(StoreData store) {
  try {
    // 1. Remove existing script element if any
    final existing = html.document.getElementById('vitrinx-jsonld-schema');
    if (existing != null) {
      existing.remove();
    }

    final Map<String, dynamic> localBusiness = {
      '@context': 'https://schema.org',
      '@type': 'LocalBusiness',
      'name': store.name,
      'description': store.description,
    };

    if (store.address.isNotEmpty) {
      localBusiness['address'] = {
        '@type': 'PostalAddress',
        'streetAddress': store.address,
      };
    }

    if (store.latitude != null && store.longitude != null) {
      localBusiness['geo'] = {
        '@type': 'GeoCoordinates',
        'latitude': store.latitude,
        'longitude': store.longitude,
      };
    }

    if (store.whatsapp.isNotEmpty) {
      localBusiness['telephone'] = store.whatsapp;
    }

    // Set first gallery image as main image if available
    if (store.displayGalleryItems.isNotEmpty) {
      final imgUrl = store.displayGalleryItems.first.imageUrl;
      if (imgUrl.isNotEmpty) {
        localBusiness['image'] = imgUrl;
      }
    }

    // Prepare JSON-LD script content.
    final List<Map<String, dynamic>> schemas = [localBusiness];

    for (final product in store.products) {
      final Map<String, dynamic> productSchema = {
        '@context': 'https://schema.org',
        '@type': 'Product',
        'name': product.name,
        'description': product.description,
      };

      if (product.imagePath != null && product.imagePath!.isNotEmpty) {
        productSchema['image'] = product.imagePath;
      }

      // Add offers / price
      if (product.price.isNotEmpty) {
        final cleanPrice = product.price.replaceAll(RegExp(r'[^0-9.,]'), '');
        final currency = product.price.contains('TL') || product.price.contains('₺') ? 'TRY' : 'USD';
        productSchema['offers'] = {
          '@type': 'Offer',
          'price': cleanPrice.isNotEmpty ? cleanPrice : '0.00',
          'priceCurrency': currency,
          'availability': product.stockStatus == 'Tükendi'
              ? 'https://schema.org/OutOfStock'
              : 'https://schema.org/InStock',
        };
      }

      schemas.add(productSchema);
    }

    final script = html.ScriptElement()
      ..id = 'vitrinx-jsonld-schema'
      ..type = 'application/ld+json'
      ..text = jsonEncode(schemas.length == 1 ? schemas.first : schemas);

    html.document.head?.append(script);
  } catch (e) {
    // Fail silently in production
  }
}
