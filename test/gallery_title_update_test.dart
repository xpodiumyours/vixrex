import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/controllers/mixins/store_media_mixin.dart';
import 'package:vixrex/models/editor_gallery_item.dart';
import 'package:flutter/foundation.dart';

class _GalleryTitleHost extends ChangeNotifier with StoreMediaMixin {}

void main() {
  test('Dilim C: galeri görsel etiketi güncellenir', () {
    final host =
        _GalleryTitleHost()..setGalleryItems([
          const EditorGalleryItem(
            id: 'g1',
            imageUrl: 'https://example.com/a.jpg',
            title: '',
          ),
        ]);

    host.updateGalleryItemTitle(0, '  Yeni sezon seçkisi  ');

    expect(host.galleryItems.single.title, 'Yeni sezon seçkisi');
  });
}
