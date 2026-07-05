// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:convert';
import 'dart:html' as html;

import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/services/seo_service.dart';

void injectStoreJsonLdImpl(StoreData store, {String? publicUrl}) {
  try {
    final existing = html.document.getElementById('vixrex-jsonld-schema');
    existing?.remove();

    final schemas = SeoService.buildStoreSchemas(store, publicUrl: publicUrl);
    final script =
        html.ScriptElement()
          ..id = 'vixrex-jsonld-schema'
          ..type = 'application/ld+json'
          ..text = jsonEncode(schemas);

    html.document.head?.append(script);
  } catch (e) {
    // SEO script errors must not block public vitrin rendering.
  }
}
