import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/services/product_image_cleanup_service.dart';

void main() {
  const service = ProductImageCleanupService();
  const supabaseUrl = 'https://project.supabase.co';

  String managed(String store, String product, String file) =>
      '$supabaseUrl/storage/v1/object/public/shelf-images/$store/products/$product/$file';

  test('yalnız aynı vitrinin Vixrex ürün dosyasını kabul eder', () {
    expect(
      service.managedProductStoragePath(
        managed('magaza', 'urun-1', '1.webp'),
        'magaza',
        supabaseUrl: supabaseUrl,
      ),
      'magaza/products/urun-1/1.webp',
    );
    expect(
      service.managedProductStoragePath(
        'https://cdn.example.com/storage/v1/object/public/shelf-images/magaza/products/urun-1/1.webp',
        'magaza',
        supabaseUrl: supabaseUrl,
      ),
      isNull,
    );
    expect(
      service.managedProductStoragePath(
        '$supabaseUrl/storage/v1/object/public/shelf-images/magaza/owner/logo.webp',
        'magaza',
        supabaseUrl: supabaseUrl,
      ),
      isNull,
    );
    expect(
      service.managedProductStoragePath(
        managed('baska-magaza', 'urun-1', '1.webp'),
        'magaza',
        supabaseUrl: supabaseUrl,
      ),
      isNull,
    );
  });

  test('başka üründe kullanılan dosya silme listesine girmez', () {
    final shared = managed('magaza', 'new', 'shared.webp');
    final unused = managed('magaza', 'urun-1', 'unused.webp');
    final removable = service.unreferencedManagedPaths(
      candidateUrls: [shared, unused, 'https://cdn.example.com/external.webp'],
      referencedUrls: [shared],
      storeSlug: 'magaza',
      supabaseUrl: supabaseUrl,
    );

    expect(removable, ['magaza/products/urun-1/unused.webp']);
  });
}
