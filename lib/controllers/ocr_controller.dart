import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:vixrex/models/detected_product.dart';
import 'package:vixrex/models/ocr_catalog_result.dart';
import 'package:vixrex/models/product_rich_data.dart';
import 'package:vixrex/models/invoice_product_draft.dart';
import 'package:vixrex/models/store_product.dart';
import 'package:vixrex/services/invoice_catalog/fatura_islem_servisi.dart';
import 'package:vixrex/services/invoice_catalog/fatura_oku_servisi.dart';
import 'package:vixrex/services/invoice_catalog/fatura_urun_kaydi_servisi.dart';
import 'package:vixrex/services/invoice_catalog/fatura_yayinla_servisi.dart';
import 'package:vixrex/services/product_conversation_logger.dart';
import 'store_editor_controller.dart';

/// OCR state yönetimi controller'ı.
class OcrController extends ChangeNotifier {
  final StoreEditorController? _editorController;

  final FaturaUrunKaydiServisi _faturaKaydiServisi;
  final FaturaYayinlaServisi _faturaYayinServisi;
  final FaturaOkuServisi _faturaOkuServisi;
  final FaturaIslemServisi _faturaIslemServisi;

  OcrCatalogResult? _result;
  bool _isProcessing = false;
  bool _isPublishing = false;
  bool _isSaving = false;
  bool get isSaving => _isSaving;
  final Map<int, String> _savedInvoiceIds = {};
  final Map<int, String> _invoiceCategories = {};
  Timer? _stateSaveTimer;
  List<Map<String, dynamic>> invoiceHistory = [];
  String? _stateSaveError;
  Future<bool>? _stateWrite;
  String? _errorMessage;
  FaturaKaydiSonucu? _faturaKaydiSonucu;
  FaturaYayinlaSonucu? _faturaYayinSonucu;

  OcrController({
    StoreEditorController? editorController,
    FaturaUrunKaydiServisi faturaKaydiServisi = const FaturaUrunKaydiServisi(),
    FaturaYayinlaServisi faturaYayinServisi = const FaturaYayinlaServisi(),
    FaturaOkuServisi faturaOkuServisi = const FaturaOkuServisi(),
    FaturaIslemServisi faturaIslemServisi = const FaturaIslemServisi(),
  }) : _editorController = editorController,
       _faturaKaydiServisi = faturaKaydiServisi,
       _faturaYayinServisi = faturaYayinServisi,
       _faturaOkuServisi = faturaOkuServisi,
       _faturaIslemServisi = faturaIslemServisi;

  // A working draft already has a store slug and edit token, even if the
  // storefront has not been published. Invoice cards remain invisible.
  String _invoiceDraftSlug = '';
  String _invoiceDraftEditToken = '';

  ({String slug, String editToken})? get _invoiceCredentials {
    final published = _editorController?.publishedInfo;
    if (published != null &&
        published.slug.trim().isNotEmpty &&
        published.editToken.trim().isNotEmpty) {
      return (slug: published.slug.trim(), editToken: published.editToken.trim());
    }
    if (_invoiceDraftSlug.isNotEmpty && _invoiceDraftEditToken.isNotEmpty) {
      return (slug: _invoiceDraftSlug, editToken: _invoiceDraftEditToken);
    }
    return null;
  }

  Future<({String slug, String editToken})?> _ensureInvoiceCredentials() async {
    final existing = _invoiceCredentials;
    if (existing != null) return existing;
    final editor = _editorController;
    if (editor == null) return null;
    try {
      final token = await editor.ensureDraftEditToken();
      final saved = await editor.publishService.saveDraft(
        editor.data,
        editToken: token,
      );
      if (saved.isFailure) {
        _errorMessage = saved.failure?.message ?? 'Vitrin taslağı oluşturulamadı.';
        return null;
      }
      final draft = saved.data!;
      _invoiceDraftSlug = draft.slug.trim();
      _invoiceDraftEditToken = draft.editToken.trim();
      if (_invoiceDraftSlug.isEmpty || _invoiceDraftEditToken.isEmpty) return null;
      editor.data.slug = _invoiceDraftSlug;
      await editor.saveLocally();
      return (slug: _invoiceDraftSlug, editToken: _invoiceDraftEditToken);
    } catch (error) {
      _errorMessage = 'Vitrin taslağı kaydedilemedi: $error';
      return null;
    }
  }

  String _scanMode = 'invoice';
  String get scanMode => _scanMode;

  set scanMode(String mode) {
    if (_scanMode == mode ||
        _isSaving ||
        _isProcessing ||
        _isPublishing ||
        _result != null) {
      return;
    }
    _scanMode = mode;
    notifyListeners();
  }

  OcrCatalogResult? get result => _result;
  bool get isProcessing => _isProcessing;
  String? get errorMessage => _errorMessage;
  bool get hasResult => _result != null;
  bool get isPublishing => _isPublishing;
  FaturaKaydiSonucu? get faturaKaydiSonucu => _faturaKaydiSonucu;
  FaturaYayinlaSonucu? get faturaYayinSonucu => _faturaYayinSonucu;

  /// Görüntüyü analiz et.
  ///
  /// Fotoğraf her zaman `/api/fatura-oku` ucuna gider.
  Future<void> analyzeImage(Uint8List imageBytes) async {
    if (_isSaving || _isProcessing || _isPublishing) return;
    _isProcessing = true;
    if (!await persistInvoiceState()) {
      _isProcessing = false;
      notifyListeners();
      return;
    }
    _savedInvoiceIds.clear();
    _invoiceCategories.clear();
    _faturaKaydiSonucu = null;
    _faturaYayinSonucu = null;
    _isProcessing = true;
    _errorMessage = null;
    notifyListeners();

    await _faturaFotografiniOku(imageBytes);
  }

  Future<void> _faturaFotografiniOku(Uint8List imageBytes) async {
    final kimlik = await _ensureInvoiceCredentials();
    if (kimlik == null) {
      _errorMessage ??= 'Faturayı kaydetmek için bir vitrin taslağı gerekli.';
      _isProcessing = false;
      notifyListeners();
      return;
    }

    final result = await _faturaOkuServisi.oku(
      imageBytes: imageBytes,
      storeSlug: kimlik.slug,
      editToken: kimlik.editToken,
    );

    result.when(
      success: (catalog) {
        _result = catalog;
        _savedInvoiceIds.clear();
        _invoiceCategories.clear();
        for (var i = 0; i < catalog.products.length; i++) {
          final id = catalog.products[i].databaseEntryId;
          if (id != null && id.isNotEmpty) _savedInvoiceIds[i] = id;
          if (i < catalog.invoiceOwnerStates.length) {
            final category = catalog.invoiceOwnerStates[i]['kategoriId'];
            if (category is String && category.isNotEmpty) {
              _invoiceCategories[i] = category;
            }
          }
        }
        _isProcessing = false;
        notifyListeners();
        // Luna's invoice cards are saved as hidden drafts without merchant approval.
        // Merchant approval is reserved for the separate publication action.
        if (catalog.invoiceDrafts.isNotEmpty) {
          unawaited(_faturaTaslaklariniKaydet(catalog.products));
        }
      },
      failure: (failure) {
        _errorMessage = failure.message;
        _isProcessing = false;
        notifyListeners();
      },
    );
  }

  /// Ürünü onayla.
  void approveProduct(int index) {
    if (_isSaving || _isProcessing || _isPublishing) return;
    if (_result == null) return;
    if (index < 0 || index >= _result!.products.length) return;
    final product = _result!.products[index];

    if (product.isInvoiceSource) {
      if (index >= _result!.invoiceDrafts.length) {
        _errorMessage = 'Fatura kanıt taslağı bulunamadı.';
        notifyListeners();
        return;
      }
    }

    product.isApproved = true;
    if (product.isInvoiceSource) {
      _result!.invoiceDrafts[index] = _result!.invoiceDrafts[index].copyWith(
        merchantApproved: true,
      );
    }
    _invoiceStateChanged();
    notifyListeners();
  }

  /// Ürünü reddet.
  void rejectProduct(int index) {
    if (_isSaving || _isProcessing || _isPublishing) return;
    if (_result == null) return;
    if (index < 0 || index >= _result!.products.length) return;
    _result!.products[index].isApproved = false;
    if (index < _result!.invoiceDrafts.length) {
      _result!.invoiceDrafts[index] = _result!.invoiceDrafts[index].copyWith(
        merchantApproved: false,
      );
    }
    _invoiceStateChanged();
    notifyListeners();
  }

  /// Ürünü düzenle.
  void updateProduct(
    int index,
    DetectedProduct updated, {
    bool stockChanged = false,
    num? invoiceStockQuantity,
    bool clearInvoiceStockQuantity = false,
  }) {
    if (_isSaving || _isProcessing || _isPublishing) return;
    if (_result == null) return;
    if (index < 0 || index >= _result!.products.length) return;
    if (updated.isInvoiceSource) {
      updated.isApproved = false;
      final draft = _result!.invoiceDrafts[index];
      _result!.invoiceDrafts[index] = draft.copyWith(
        salePrice: updated.price,
        clearSalePrice: updated.price == null,
        merchantApproved: false,
        stockConfirmed: stockChanged ? false : draft.stockConfirmed,
        stockQuantity:
            stockChanged
                ? invoiceStockQuantity ?? updated.quantity
                : draft.stockQuantity,
        clearStockQuantity: stockChanged && clearInvoiceStockQuantity,
      );
    }
    _result!.products[index] = updated;
    _invoiceStateChanged();
    notifyListeners();
  }

  /// Tümünü onayla.
  ///
  /// Faturada doğrulama sorunu olan satırlar toplu onaya dahil edilmez;
  /// esnaf o satırı ayrıca kontrol eder.
  void approveAll() {
    if (_isSaving || _isProcessing || _isPublishing) return;
    if (_result == null) return;
    for (var index = 0; index < _result!.products.length; index++) {
      final product = _result!.products[index];
      if (!product.isInvoiceSource) {
        product.isApproved = true;
        continue;
      }
      if (product.issues.isNotEmpty || index >= _result!.invoiceDrafts.length) {
        product.isApproved = false;
        continue;
      }
      product.isApproved = true;
      _result!.invoiceDrafts[index] = _result!.invoiceDrafts[index].copyWith(
        merchantApproved: product.isApproved,
      );
    }
    _invoiceStateChanged();
    notifyListeners();
  }

  /// Tümünü reddet.
  void rejectAll() {
    if (_isSaving || _isProcessing || _isPublishing) return;
    if (_result == null) return;
    for (final product in _result!.products) {
      product.isApproved = false;
    }
    for (var i = 0; i < _result!.invoiceDrafts.length; i++) {
      _result!.invoiceDrafts[i] = _result!.invoiceDrafts[i].copyWith(
        merchantApproved: false,
      );
    }
    _invoiceStateChanged();
    notifyListeners();
  }

  /// Onaylanan ürünleri kaydet.
  Future<void> saveApprovedProducts() async {
    if (_isSaving || _isProcessing || _isPublishing) return;
    _isSaving = true;
    notifyListeners();
    try {
      await _saveApprovedProducts();
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> _saveApprovedProducts() async {
    _errorMessage = null;
    final approved = _result?.approvedProducts;
    if (approved == null || approved.isEmpty) return;

    // Validation: boş isim veya negatif fiyat filtresi
    final validProducts =
        approved.where((p) {
          if (p.name.trim().isEmpty) return false;
          if (p.price != null && p.price! < 0) return false;
          return true;
        }).toList();

    if (validProducts.isEmpty) {
      _errorMessage =
          'Kaydedilecek geçerli ürün yok. Ürün adı boş veya fiyat geçersiz.';
      notifyListeners();
      return;
    }

    if (_scanMode == 'invoice') {
      await _faturaTaslaklariniKaydet(validProducts);
      return;
    }

    try {
      final editor = _editorController;
      if (editor == null) {
        _errorMessage =
            'Vitrin düzenleyici hazır değil. Ürünler kaydedilemedi.';
        notifyListeners();
        return;
      }

      var savedCount = 0;
      for (final product in validProducts) {
        final sourceIndex = _result!.products.indexOf(product);
        final invoiceDraft =
            product.isInvoiceSource &&
                    sourceIndex >= 0 &&
                    sourceIndex < _result!.invoiceDrafts.length
                ? _result!.invoiceDrafts[sourceIndex]
                : null;
        final result = await editor.addProduct(
          _convertToProduct(product, invoiceDraft: invoiceDraft),
        );
        if (result.isFailure) {
          final detail =
              result.failure?.message ?? 'Ürün müşteri vitrine yazılamadı.';
          _errorMessage =
              savedCount > 0
                  ? '$savedCount ürün kaydedildi, sonra hata: $detail'
                  : detail;
          notifyListeners();
          return;
        }
        product.isApproved = false;
        savedCount++;
      }
      _result = null;
      notifyListeners();
      // Faz 4: ortak konuşmaya log — Next.js sahip paneli 15sn poll ile görür
      unawaited(
        ProductConversationLogger.log(
          count: savedCount,
          source: 'ocr',
          scope: editor.publishedInfo?.publicLink,
          extra: _scanMode == 'shelf_label' ? 'raf/etiket' : 'fiş/fatura',
        ),
      );
    } catch (e) {
      _errorMessage = 'Ürünler kaydedilemedi: $e';
      notifyListeners();
    }
  }

  /// Onaylanan fatura satırlarını web ile AYNI sunucu kapısına taslak yazar.
  ///
  /// Ürün burada yayınlanmaz. Sunucu satırın kanıt durumunu ve izinli
  /// görsellerini işlem kaydından yeniden okur; yayın ayrı eylemdir.
  Future<void> _faturaTaslaklariniKaydet(
    List<DetectedProduct> secilenler,
  ) async {
    final editor = _editorController;
    final sonuc = _result;
    if (editor == null || sonuc == null) {
      _errorMessage = 'Vitrin düzenleyici hazır değil. Ürünler kaydedilemedi.';
      notifyListeners();
      return;
    }

    final kimlik = _invoiceCredentials;
    if (kimlik == null) {
      _errorMessage = 'Vitrin taslağı kaydedilemedi.';
      notifyListeners();
      return;
    }

    final kategoriId = _uuidKategoriBul(editor) ?? '';

    final satirlar = <FaturaKaydiSatiri>[];
    for (final urun in secilenler) {
      final sira = sonuc.products.indexOf(urun);
      if (sira < 0 || sira >= sonuc.invoiceDrafts.length) continue;
      final taslak = sonuc.invoiceDrafts[sira];
      final islemKimligi =
          (taslak.islemKimligi ?? sonuc.islemKimligi ?? '').trim();
      if (islemKimligi.isEmpty) continue;

      final satisFiyati = urun.price;
      final kod = (urun.barcode ?? urun.sku ?? '').trim();
      final tedarikciKimligi =
          (taslak.supplierTaxOrTradeIdentifier?.value ??
                  taslak.supplierName?.value ??
                  '')
              .trim();
      final gorseller = taslak.imageCandidates
          .where((aday) => aday.selected && aday.canUse)
          .map((aday) => aday.url)
          .toList(growable: false);

      satirlar.add(
        FaturaKaydiSatiri(
          satirSirasi: sira,
          islemKimligi: islemKimligi,
          ad: (taslak.normalizedName?.value ?? urun.name).trim(),
          aciklama: (urun.description ?? '').trim(),
          fiyatMetni: satisFiyati == null ? '' : '${_fiyatYaz(satisFiyati)} TL',
          kategoriId: _invoiceCategories[sira] ?? kategoriId,
          gorseller: gorseller,
          gorselKaynagi: taslak.canonicalProductUrl?.value,
          marka: taslak.brand?.value ?? urun.brand,
          barkod: urun.barcode,
          model: urun.sku,
          varyant: urun.variant,
          beden: urun.size,
          stok: _tamFaturaStogu(taslak.stockQuantity),
          onayli: urun.isApproved,
          stokOnaylandi: true,
          kartDurumu: taslak.etkinKartDurumu.wireValue,
          disKimlik:
              kod.isEmpty
                  ? ''
                  : [
                    tedarikciKimligi,
                    kod,
                  ].where((p) => p.isNotEmpty).join(':'),
          alisFiyati: urun.purchaseUnitPrice,
        ),
      );
    }

    if (satirlar.isEmpty) {
      _errorMessage =
          'Bu faturanın işlem kaydı bulunamadı. Faturayı yeniden okut.';
      notifyListeners();
      return;
    }

    if (!await persistInvoiceState()) return;
    final kayit = await _faturaKaydiServisi.taslakKaydet(
      satirlar: satirlar,
      storeSlug: kimlik.slug,
      editToken: kimlik.editToken,
    );

    kayit.when(
      success: (ozet) {
        _faturaKaydiSonucu = ozet;
        _faturaYayinSonucu = null;
        for (final row in ozet.satirlar) {
          if (row.id == null || row.durum == 'atlandi') continue;
          final index = satirlar[row.sira].satirSirasi;
          _savedInvoiceIds[index] = row.id!;
          sonuc.products[index].databaseEntryId = row.id;
        }
        final failed = ozet.satirlar.where((row) => row.durum == 'atlandi');
        if (failed.isNotEmpty) {
          _errorMessage = failed.map((row) => row.sebep).join('\n');
        }
        if (_savedInvoiceIds.isNotEmpty) {
          unawaited(editor.reloadRemoteProducts());
        }
        notifyListeners();
      },
      failure: (failure) {
        _errorMessage = failure.message;
        notifyListeners();
      },
    );
  }

  /// Kaydedilen fatura taslaklarını AYRI Yayınla ucuyla yayınlar.
  ///
  /// Kapılar sunucuda yeniden okunur; kapısı kapalı ürün taslak kalır ve
  /// sebebi sonuçta döner. Telefon "yayınlandı" demeden önce sunucunun
  /// cevabına bakar.
  Future<void> publishSavedInvoiceDrafts() async {
    final kayit = _faturaKaydiSonucu;
    if (kayit == null || _isPublishing || _isSaving || _isProcessing) return;

    final idler =
        kayit.yayinlanabilirTaslakIdleri
            .where(
              (id) =>
                  !(_faturaYayinSonucu?.satirlar.any(
                        (row) => row.id == id && row.yayinda,
                      ) ??
                      false),
            )
            .toList();
    if (idler.isEmpty) {
      _errorMessage = 'Yayınlanacak taslak ürün yok.';
      notifyListeners();
      return;
    }

    final kimlik = _invoiceCredentials;
    final slug = kimlik?.slug ?? '';
    final editToken = kimlik?.editToken ?? '';

    _isPublishing = true;
    _errorMessage = null;
    notifyListeners();

    final sonuc = await _faturaYayinServisi.yayinla(
      productIds: idler,
      storeSlug: slug,
      editToken: editToken,
    );

    _isPublishing = false;
    sonuc.when(
      success: (ozet) {
        _faturaYayinSonucu = ozet;
        unawaited(_editorController!.reloadRemoteProducts());
        notifyListeners();
      },
      failure: (failure) {
        _errorMessage = failure.message;
        notifyListeners();
      },
    );
  }

  /// Kayıt ve yayın özetini kapatır.
  void clearFaturaSonucu() {
    _faturaKaydiSonucu = null;
    _faturaYayinSonucu = null;
    notifyListeners();
  }

  List<ProductCategory> get invoiceCategories =>
      _editorController?.data.productCategories ?? [];

  String? categoryFor(int index) => _invoiceCategories[index];

  void setInvoiceCategory(int index, String categoryId) {
    if (_isSaving || _isProcessing || _isPublishing) return;
    _invoiceCategories[index] = categoryId;
    if (_result != null) _result!.products[index].isApproved = false;
    _invoiceStateChanged();
    notifyListeners();
  }

  void _invoiceStateChanged() {
    _faturaKaydiSonucu = null;
    _faturaYayinSonucu = null;
    _stateSaveTimer?.cancel();
    if (_scanMode != 'invoice') return;
    _stateSaveTimer = Timer(const Duration(milliseconds: 350), () {
      unawaited(persistInvoiceState());
    });
  }

  Future<bool> persistInvoiceState() async {
    _stateSaveTimer?.cancel();
    _stateWrite = (_stateWrite ?? Future.value(true)).then(
      (_) => _persistInvoiceState(),
    );
    return _stateWrite!;
  }

  Future<bool> _persistInvoiceState() async {
    final catalog = _result;
    final info = _invoiceCredentials;
    if (_scanMode != 'invoice' ||
        catalog == null ||
        catalog.islemKimligi == null ||
        info == null) {
      return true;
    }
    if (catalog.products.length != catalog.invoiceDrafts.length) {
      _errorMessage = 'Fatura satırları tutarsız; işlem korunuyor.';
      notifyListeners();
      return false;
    }
    final result = await _faturaIslemServisi.kaydet(
      slug: info.slug,
      editToken: info.editToken,
      islemKimligi: catalog.islemKimligi!,
      satirlar: List.generate(catalog.products.length, (index) {
        final product = catalog.products[index];
        final owner =
            index < catalog.invoiceOwnerStates.length
                ? catalog.invoiceOwnerStates[index]
                : <String, dynamic>{};
        return {
          'satirSirasi': index,
          'sahipDurumu': {
            ...owner,
            'satisFiyati': product.price?.toString() ?? '',
            'stok':
                catalog.invoiceDrafts[index].stockQuantity?.toString() ?? '',
            'stokOnaylandi': true,
            'kategoriId':
                _invoiceCategories[index] ??
                _uuidKategoriBul(_editorController!) ??
                '',
            'onayli': product.isApproved,
            'esnafGorselleri':
                owner['esnafGorselleri'] is List
                    ? (owner['esnafGorselleri'] as List)
                        .whereType<String>()
                        .toList()
                    : <String>[],
          },
        };
      }),
    );
    if (result.isFailure) {
      _stateSaveError = result.failure!.message;
      _errorMessage = _stateSaveError;
      notifyListeners();
      return false;
    }
    if (_errorMessage == _stateSaveError) _errorMessage = null;
    _stateSaveError = null;
    return true;
  }

  Future<void> loadInvoiceHistory() async {
    final info = _invoiceCredentials;
    if (info == null) return;
    final result = await _faturaIslemServisi.listele(
      slug: info.slug,
      editToken: info.editToken,
    );
    if (result.isFailure) {
      _errorMessage = result.failure!.message;
    } else {
      final rows = result.data!['islemler'];
      if (rows is List) {
        invoiceHistory =
            rows
                .whereType<Map>()
                .map((row) => Map<String, dynamic>.from(row))
                .toList();
      }
    }
    notifyListeners();
  }

  Future<void> resumeInvoice(String islemKimligi) async {
    if (_isSaving || _isProcessing || _isPublishing) return;
    _isProcessing = true;
    if (!await persistInvoiceState()) {
      _isProcessing = false;
      notifyListeners();
      return;
    }
    final info = _invoiceCredentials;
    if (info == null) {
      _isProcessing = false;
      notifyListeners();
      return;
    }
    _isProcessing = true;
    _errorMessage = null;
    notifyListeners();
    final response = await _faturaIslemServisi.yukle(
      slug: info.slug,
      editToken: info.editToken,
      islemKimligi: islemKimligi,
    );
    _isProcessing = false;
    if (response.isFailure) {
      _errorMessage = response.failure!.message;
    } else {
      final parsed = _faturaOkuServisi.cozumle(response.data!);
      if (parsed.isFailure) {
        _errorMessage = parsed.failure!.message;
      } else {
        _result = parsed.data;
        _savedInvoiceIds.clear();
        _invoiceCategories.clear();
        final rows = response.data!['satirlar'] as List;
        for (var i = 0; i < rows.length; i++) {
          final row = rows[i] as Map;
          if (row['urunId'] is String) {
            _savedInvoiceIds[i] = row['urunId'] as String;
          }
          final owner = row['sahipDurumu'];
          if (owner is Map && owner['kategoriId'] is String) {
            _invoiceCategories[i] = owner['kategoriId'] as String;
          }
        }
        _faturaKaydiSonucu = null;
        _faturaYayinSonucu = null;
      }
    }
    notifyListeners();
  }

  Future<void> resumeInvoiceProduct(String productId) async {
    final info = _invoiceCredentials;
    if (info == null) return;
    final response = await _faturaIslemServisi.urundenBul(
      slug: info.slug,
      editToken: info.editToken,
      urunId: productId,
    );
    if (response.isFailure) {
      _errorMessage = response.failure!.message;
      notifyListeners();
      return;
    }
    await resumeInvoice((response.data!['islemKimligi'] ?? '').toString());
  }

  Future<void> correctInvoiceRow(
    int index, {
    required String ad,
    required String model,
    required String barkod,
    required String marka,
  }) async {
    final info = _invoiceCredentials;
    final catalog = _result;
    if (info == null ||
        catalog?.islemKimligi == null ||
        _isProcessing ||
        _isSaving ||
        _isPublishing) {
      return;
    }
    if (index < 0 || index >= catalog!.products.length) return;
    final product = catalog.products[index];
    product.isApproved = false;
    catalog.invoiceDrafts[index] = catalog.invoiceDrafts[index].copyWith(
      merchantApproved: false,
      stockConfirmed: false,
    );
    _invoiceStateChanged();
    if (!await persistInvoiceState()) return;
    _isProcessing = true;
    notifyListeners();
    final response = await _faturaIslemServisi.duzelt(
      slug: info.slug,
      editToken: info.editToken,
      islemKimligi: catalog.islemKimligi!,
      satirSirasi: index,
      ad: ad,
      model: model,
      barkod: barkod,
      marka: marka,
    );
    _isProcessing = false;
    if (response.isFailure) {
      _errorMessage = response.failure!.message;
      notifyListeners();
      return;
    }
    await resumeInvoice(catalog.islemKimligi!);
  }

  @override
  void dispose() {
    _stateSaveTimer?.cancel();
    super.dispose();
  }

  String? _uuidKategoriBul(StoreEditorController editor) {
    final uuid = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );
    for (final kategori in editor.data.productCategories) {
      final id = kategori.id.trim();
      if (uuid.hasMatch(id)) return id;
    }
    return null;
  }

  int? _tamFaturaStogu(num? value) {
    if (value == null || !value.isFinite || value != value.toInt()) return null;
    return value.toInt();
  }

  String _fiyatYaz(double deger) {
    return deger == deger.roundToDouble()
        ? deger.toInt().toString()
        : deger.toString();
  }

  /// DetectedProduct'ı Product'a çevir.
  ///
  /// Fatura alış fiyatı müşteriye gösterilecek satış fiyatı DEĞİLDİR.
  /// Bu nedenle purchaseUnitPrice burada Product.price alanına asla yazılmaz.
  Product _convertToProduct(
    DetectedProduct detected, {
    InvoiceProductDraft? invoiceDraft,
  }) {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final random = (timestamp * 7 + detected.name.hashCode).abs();
    final id = 'ocr_${timestamp}_$random';

    final options = <String, String>{};
    final variant = detected.variant?.trim();
    final size = detected.size?.trim();
    if (variant != null && variant.isNotEmpty) options['color'] = variant;
    if (size != null && size.isNotEmpty) options['size'] = size;

    final int stokMiktari = detected.quantity;

    final variants =
        options.isEmpty
            ? <ProductVariantData>[]
            : <ProductVariantData>[
              ProductVariantData(
                id: '$id-variant-1',
                options: options,
                sku: detected.sku,
                barcode: detected.barcode,
                priceAmount: detected.price,
                stockQuantity: stokMiktari,
                stockStatus: StockStatus.available.label,
              ),
            ];

    final normalizedName =
        invoiceDraft?.normalizedName?.value?.trim() ?? detected.name.trim();
    final usableImages =
        invoiceDraft?.imageCandidates
            .where((item) => item.selected && item.canUse)
            .map((item) => item.url)
            .toList(growable: false) ??
        const <String>[];

    return Product(
      id: id,
      name: normalizedName.isEmpty ? detected.name : normalizedName,
      price:
          invoiceDraft?.salePrice?.toStringAsFixed(2) ??
          detected.price?.toStringAsFixed(2) ??
          '',
      description: detected.description ?? '',
      imageUrls: usableImages,
      category: detected.category,
      stockStatus: StockStatus.available.label,
      // Faturadan gelen ürün doğrudan müşteriye açılmaz; önce esnaf satış
      // fiyatını ve şüpheli alanları kontrol eder.
      isVisible: !detected.isInvoiceSource,
      source: detected.source,
      barcode: detected.barcode,
      sku: detected.sku,
      stockQuantity: stokMiktari,
      variants: variants,
    );
  }

  /// Sonucu temizle.
  void clearResult() {
    if (_isSaving || _isProcessing || _isPublishing) return;
    _result = null;
    _errorMessage = null;
    notifyListeners();
  }

  /// Hata mesajını temizle.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
