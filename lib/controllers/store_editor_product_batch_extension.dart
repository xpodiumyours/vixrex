import 'package:vixrex/controllers/store_editor_controller.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/services/product_batch_import_service.dart';
import 'package:vixrex/services/product_category_sync_service.dart';

/// Toplu ürün girişlerini StoreEditorController'ın mevcut uzak/yerel durum
/// zincirine bağlar. Uzak yazımdan sonra aynı Product CORE tekrar okunur;
/// açık editörde geçici local kimlik bırakılmaz.
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

    await refreshProductCatalogFromRemote();
    return result;
  }

  /// XML gibi yazmayı kendi içinde tamamlayan girişlerden sonra açık editörü
  /// yeniden Product CORE gerçeğiyle hizalar. Bu metot yalnız okuma + yerel
  /// cache yenilemesi yapar; ikinci kez ürün yazmaz.
  Future<void> refreshProductCatalogFromRemote() async {
    final ready = await ensureRemoteStoreId();
    final storeId = data.id?.trim() ?? '';
    if (!ready || storeId.isEmpty) return;

    final remoteProducts = await productService.fetchProducts(storeId);
    if (remoteProducts.isNotEmpty) {
      // Listeyi yerinde değiştir: ProductManagementSheet'e daha önce verilmiş
      // referanslar da canonical DB id/slug değerlerini görsün.
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
      // Ürün okuması başarılıysa kategori listesini geçici okuma hatası yüzünden
      // silme. Mevcut kategori listesi korunur.
    }

    await saveLocally();
    notifyStoreDataChanged();
  }
}
