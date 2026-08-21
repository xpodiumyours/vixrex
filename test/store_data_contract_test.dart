import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/config/vitrin_alanlari.g.dart';
import 'package:vixrex/models/store_data_dto.dart';
import 'package:vixrex/services/store_publish_payload_builder.dart';
import 'package:vixrex/services/store_safe_select.dart';

void main() {
  test(
    'Flutter select bütün düzenlenebilir kolonları taşır, hassasları taşımaz',
    () {
      final selected = StoreSafeSelect.columns.split(',').toSet();
      expect(
        vitrinAlanlari
            .map((field) => field.kolon)
            .where((column) => !selected.contains(column)),
        isEmpty,
      );
      expect(selected, isNot(contains('edit_token')));
      expect(selected, isNot(contains('user_id')));
    },
  );

  test(
    'bütün düzenlenebilir alanlar buluttan yükle-kaydet turunda korunur',
    () {
      final cloudRow = <String, dynamic>{};
      for (final field in vitrinAlanlari) {
        cloudRow[field.kolon] = switch (field.tip) {
          'acikKapali' => field.kolon == 'show_directions_link',
          'sayi' => field.kolon == 'latitude' ? 41.0082 : 28.9784,
          _ => 'değer-${field.kolon}',
        };
      }

      final loaded = StoreDataDto.fromJson(cloudRow);
      final saved = const StorePublishPayloadBuilder().toStoreUpdateMap(loaded);

      for (final field in vitrinAlanlari) {
        expect(
          saved[field.kolon],
          cloudRow[field.kolon],
          reason: '${field.kolon} buluttan yüklenip yeniden yazılabilmeli',
        );
      }
    },
  );
}
