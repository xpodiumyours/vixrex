import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vixrex/core/supabase_error_mapper.dart';

void main() {
  test(
    'yayın hazırlığı DB hata kodlarını anlaşılır Türkçe mesajlara çevirir',
    () {
      const expected = {
        'STORE_NAME_REQUIRED': 'işletme adını',
        'STORE_CATEGORY_REQUIRED': 'kategorisini',
        'STORE_WHATSAPP_REQUIRED': 'WhatsApp',
        'STORE_WHATSAPP_INVALID': 'Türkiye cep telefonu',
        'STORE_ADDRESS_REQUIRED': 'adresini',
        'STORE_PROVINCE_REQUIRED': 'il bilgisini',
        'STORE_DISTRICT_REQUIRED': 'ilçe bilgisini',
      };

      for (final entry in expected.entries) {
        final failure = SupabaseErrorMapper.map(
          PostgrestException(message: entry.key),
        );
        expect(failure.message, contains(entry.value), reason: entry.key);
      }
    },
  );
}
