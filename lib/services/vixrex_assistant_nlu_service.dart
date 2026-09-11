import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vixrex/config/business_category_config.dart';
import 'package:vixrex/config/vixrex_mesajlar.g.dart';
import 'package:vixrex/services/vixrex_assistant_nlu_types.dart';

/// Supabase Edge Function üzerinden gerçek OpenAI alan önerisi alır.
/// Anahtar Flutter'a gelmez; yalnız Function'ın Supabase secret'ındadır.
class VixRexAssistantNluService {
  /// Gerçek OpenAI özelliği bilinçli olarak askıda.
  /// Kod ve Supabase Function korunur; `true` yapılana kadar istek gönderilmez.
  static const bool isEnabled = false;

  static const _clientIdKey = 'vixrex_assistant_client_id';

  Future<VixRexNluRemoteResult> propose(String input) async {
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'vixrex-assistant-nlu',
        body: {
          'input': input,
          'client_id': await _clientId(),
          'allowed_categories':
              BusinessCategoryConfig.categories
                  .map((item) => {'id': item.id, 'label': item.label})
                  .toList(),
        },
      );
      if (response.status != 200) {
        return VixRexNluRemoteResult.unavailable();
      }

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        return VixRexNluRemoteResult.unavailable();
      }
      final proposal = data['proposal'];
      if (proposal is! Map<String, dynamic>) {
        return VixRexNluRemoteResult.unavailable();
      }

      final reply = proposal['reply'];
      if (reply is! String || reply.trim().isEmpty) {
        return VixRexNluRemoteResult.unavailable();
      }
      final fieldName = proposal['field'];
      final value = proposal['value'];
      final field = VixRexNluField.values.where(
        (item) => item.remoteName == fieldName,
      );

      return VixRexNluRemoteResult(
        reply: reply.trim(),
        field: field.isEmpty ? null : field.first,
        value: value is String && value.trim().isNotEmpty ? value.trim() : null,
      );
    } catch (_) {
      return VixRexNluRemoteResult.unavailable();
    }
  }

  Future<String> _clientId() async {
    final preferences = await SharedPreferences.getInstance();
    final current = preferences.getString(_clientIdKey);
    if (current != null && current.isNotEmpty) return current;

    final random = Random.secure();
    final value =
        List.generate(32, (_) => random.nextInt(16).toRadixString(16)).join();
    await preferences.setString(_clientIdKey, value);
    return value;
  }
}

class VixRexNluRemoteResult {
  final String reply;
  final VixRexNluField? field;
  final String? value;
  final bool isAvailable;

  const VixRexNluRemoteResult({
    required this.reply,
    required this.field,
    required this.value,
    this.isAvailable = true,
  });

  /// Cerrahi 2026-09-11 (Risk 1): erişim-yok cümlesi katalogdan
  /// (nlu_kisa_erisim_yok), görsel aynı. const değil — katalog okur.
  factory VixRexNluRemoteResult.unavailable() {
    return VixRexNluRemoteResult(
      reply:
          vixRexMesajlari['nlu_kisa_erisim_yok'] ??
          'Asistan şu an yanıt veremiyor. Lütfen biraz sonra tekrar dene.',
      field: null,
      value: null,
      isAvailable: false,
    );
  }

  static String get erisimYokMesaji =>
      vixRexMesajlari['nlu_kisa_erisim_yok'] ??
      'Asistan şu an yanıt veremiyor. Lütfen biraz sonra tekrar dene.';
}
