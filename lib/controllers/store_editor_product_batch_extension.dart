import 'package:vixrex/controllers/store_editor_controller.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/services/product_batch_import_service.dart';
import 'package:vixrex/services/product_category_sync_service.dart';

/// Toplu Excel/CSV importunu StoreEditorController'ın mevcut uzak/yerel
/// durum zincirine bağlar. Batch RPC tek yazma noktasıdır; başarılı yazımdan
/// sonra aynı Product CORE tekrar okunup açık editör durumu güncellenir.
extension StoreEditorProductBatchExtension on StoreEditorController {
  Future<ProductBatchImportResult> importProductBatch(
    List<Product> products,
  ) async {
    final editToken = publishedInfo?.editToken.trim() ?? '';
    if (editToken.isEmpty) {
      return ProductBatchImportResult.failure(
        'Toplu ürünleri kaydetmek için önce vitrini yayınlayın.',
      );
    }

    final ready = await ensureRemoteStoreId();
    final storeId = data.id?.trim() ?? '';
    if (!ready || storeId.isEmpty) {
      return ProductBatchImportResult.failure(
        'Mağaza kimliği bulunamadı. Yayınlayıp tekrar deneyin.',
      );
    }

    final result = await ProductBatchImportService(
      client: supabaseClient,
    ).save(
      products: products,
      storeId: storeId,
      editToken: editToken,
    );
    if (!result.isSuccess) return result;

    // Batch yazımı bittiğinde ekranda geçici local kimlik bırakma. Aynı DB
    // gerçeğini tekrar oku ve StoreData listelerini yerinde güncelle; böylece
    // ProductManagementSheet'e verilmiş liste referansları da canonical id/slug
    // değerlerini görür. Okuma geçici olarak boş dönerse mevcut yerel listeyi
    // silme; bir sonraki normal yükleme tekrar uzak gerçeği çeker.
    final remoteProducts = await productService.fetchProducts(storeId);
    if (remoteProducts.isNotEmpty ||
        (result.total == 0 && result.errors == 0)) {
      data.products
        ..clear()
        ..addAll(remoteProducts);
    }

    try {
      final remoteCategories = await ProductCategorySyncService(
        client: supabaseClient,
      ).fetchCategories(storeId);
      if (remoteCategories.isNotEmpty) {
        data.productCategories
          ..clear()
          ..addAll(remoteCategories);
      }
    } catch (_) {
      // Ürün yazımı başarılıysa kategori listesini geçici okuma hatası yüzünden
      // başarısız göstermiyoruz. Mevcut kategori listesi korunur.
    }

    await saveLocally();
    notifyStoreDataChanged();
    return result;
  }
}
