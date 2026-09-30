import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:vixrex/models/detected_product.dart';
import 'package:vixrex/models/ocr_catalog_result.dart';
import 'package:vixrex/models/product_rich_data.dart';
import 'package:vixrex/models/invoice_product_draft.dart';
import 'package:vixrex/services/invoice_catalog/invoice_draft_decision_engine.dart';
import 'package:vixrex/models/store_product.dart';
import 'package:vixrex/services/invoice_catalog/fatura_oku_servisi.dart';
import 'package:vixrex/services/invoice_catalog/fatura_urun_kaydi_servisi.dart';
import 'package:vixrex/services/invoice_catalog/fatura_yayinla_servisi.dart';
import 'package:vixrex/services/ocr/invoice_row_parser.dart';
import 'package:vixrex/services/ocr/ocr_service.dart';
import 'package:vixrex/services/ocr/ocr_feedback_service.dart';
import 'package:vixrex/services/product_conversation_logger.dart';
import 'store_editor_controller.dart';

/// OCR state yönetimi controller'ı.
class OcrController extends ChangeNotifier {
  final OcrService _ocrService;
  final StoreEditorController? _editorController;

  final FaturaUrunKaydiServisi _faturaKaydiServisi;
  final FaturaYayinlaServisi _faturaYayinServisi;

  OcrCatalogResult? _result;
  bool _isProcessing = false;
  bool _isPublishing = false;
  String? _errorMessage;
  FaturaKaydiSonucu? _faturaKaydiSonucu;
  FaturaYayinlaSonucu? _faturaYayinSonucu;

  OcrController({
    required OcrService ocrService,
    StoreEditorController? editorController,
    FaturaUrunKaydiServisi faturaKaydiServisi = const FaturaUrunKaydiServisi(),
    FaturaYayinlaServisi faturaYayinServisi = const FaturaYayinlaServisi(),
  }) : _ocrService = ocrService,
       _editorController = editorController,
       _faturaKaydiServisi = faturaKaydiServisi,
       _faturaYayinServisi = faturaYayinServisi;

  String _scanMode = 'receipt';
  String get scanMode => _scanMode;

  set scanMode(String mode) {
    if (_scanMode == mode) return;
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
  /// Fatura modu (`_scanMode == 'invoice'`) KASITLI OLARAK cihaz üstü OCR
  /// kullanmaz — fotoğraf doğrudan Vixrex'in TEK okuma ucuna
  /// (`/api/fatura-oku`) gider. Telefon ve web AYNI bu uçtan geçer; iki
  /// ayrı "okuma beyni" (yerel ML Kit zinciri + ayrı bir web zinciri) bir
  /// daha kurulmaz (2026-09-26 mimari düzeltmesi).
  ///
  /// Fiş/raf modları (`receipt`/`shelf_label`) bu değişiklikten etkilenmez,
  /// hâlâ cihaz üstü [_ocrService] kullanır — onlar üretici kataloğuyla
  /// hiç ilişkili değil.
  Future<void> analyzeImage(Uint8List imageBytes) async {
    _isProcessing = true;
    _errorMessage = null;
    notifyListeners();

    if (_scanMode == 'invoice') {
      await _faturaFotografiniOku(imageBytes);
      return;
    }

    final result = await _ocrService.analyzeImage(
      imageBytes,
      scanMode: _scanMode,
    );

    result.when(
      success: (catalog) {
        _result = catalog;
        _isProcessing = false;
        notifyListeners();
      },
      failure: (failure) {
        _errorMessage = failure.message;
        _isProcessing = false;
        notifyListeners();
      },
    );
  }

  Future<void> _faturaFotografiniOku(Uint8List imageBytes) async {
    final yayinBilgisi = _editorController?.publishedInfo;
    final slug = yayinBilgisi?.slug.trim() ?? '';
    final editToken = yayinBilgisi?.editToken.trim() ?? '';
    if (slug.isEmpty || editToken.isEmpty) {
      _errorMessage = 'Fatura okumak için önce vitrinini yayınlaman gerekiyor.';
      _isProcessing = false;
      notifyListeners();
      return;
    }

    const servis = FaturaOkuServisi();
    final result = await servis.oku(
      imageBytes: imageBytes,
      storeSlug: slug,
      editToken: editToken,
    );

    result.when(
      success: (catalog) {
        _result = catalog;
        _isProcessing = false;
        notifyListeners();
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
    if (_result == null) return;
    if (index < 0 || index >= _result!.products.length) return;
    final product = _result!.products[index];

    if (product.isInvoiceSource) {
      if (index >= _result!.invoiceDrafts.length) {
        _errorMessage = 'Fatura kanıt taslağı bulunamadı.';
        notifyListeners();
        return;
      }
      final decision = const InvoiceDraftDecisionEngine().evaluate(
        _result!.invoiceDrafts[index],
      );
      if (!decision.canPrepareDraft) {
        _errorMessage =
            decision.questions.isNotEmpty
                ? decision.questions.first
                : 'Bu ürün henüz güvenilir dijital ürünle doğrulanmadı.';
        notifyListeners();
        return;
      }
    }

    product.isApproved = true;
    notifyListeners();
  }

  /// Faturadaki adedi STOK olarak onayla.
  ///
  /// Faturadaki miktar alış adedidir; raf stoğu değildir. Esnaf bu düğmeye
  /// basmadan adet ürün kartının stoğuna yazılmaz.
  void confirmInvoiceStock(int index) {
    if (_result == null) return;
    if (index < 0 || index >= _result!.invoiceDrafts.length) return;
    final draft = _result!.invoiceDrafts[index];
    _result!.invoiceDrafts[index] = draft.copyWith(
      stockConfirmed: !draft.stockConfirmed,
    );
    notifyListeners();
  }

  /// Ürünü reddet.
  void rejectProduct(int index) {
    if (_result == null) return;
    if (index < 0 || index >= _result!.products.length) return;
    _result!.products[index].isApproved = false;
    notifyListeners();
  }

  /// Ürünü düzenle.
  void updateProduct(int index, DetectedProduct updated) {
    if (_result == null) return;
    if (index < 0 || index >= _result!.products.length) return;
    if (updated.isInvoiceSource) {
      updated.issues = InvoiceRowParser.validateProduct(updated);
    }
    _result!.products[index] = updated;
    notifyListeners();
  }

  /// Tümünü onayla.
  ///
  /// Faturada doğrulama sorunu olan satırlar toplu onaya dahil edilmez;
  /// esnaf o satırı ayrıca kontrol eder.
  void approveAll() {
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
      final decision = const InvoiceDraftDecisionEngine().evaluate(
        _result!.invoiceDrafts[index],
      );
      product.isApproved = decision.canPrepareDraft;
    }
    notifyListeners();
  }

  /// Tümünü reddet.
  void rejectAll() {
    if (_result == null) return;
    for (final product in _result!.products) {
      product.isApproved = false;
    }
    notifyListeners();
  }

  /// Onaylanan ürünleri kaydet.
  Future<void> saveApprovedProducts() async {
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
      // 1. Düzeltilmiş feedback verilerini Supabase'e gönder (Active Learning Loop)
      final feedbackList =
          _result!.products
              .map(
                (p) => {
                  'name': p.name,
                  'price': p.price,
                  'is_approved': p.isApproved,
                  'confidence': p.confidence,
                },
              )
              .toList();

      final parsedList =
          _result!.products
              .map(
                (p) => {
                  'name': p.name,
                  'price': p.price,
                  'confidence': p.confidence,
                },
              )
              .toList();

      // Fatura metni firma/tedarikçi/ticari fiyat gibi özel bilgiler
      // içerebilir. Açık bir saklama politikası kurulana kadar fatura OCR
      // ham metni feedback veri setine yazılmaz.
      if (_scanMode != 'invoice') {
        await const OcrFeedbackService().saveFeedback(
          rawOcrText: _result!.rawText,
          parsedProducts: parsedList,
          correctedProducts: feedbackList,
          scanMode: _scanMode,
          imageHash: 'hash_${_result!.rawText.hashCode.abs()}',
        );
      }

      // 2. Ürünleri editör kontrolcüsüne ekle (uzak yazma başarısızsa yerelde yok)
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

    final yayinBilgisi = editor.publishedInfo;
    final slug = yayinBilgisi?.slug.trim() ?? '';
    final editToken = yayinBilgisi?.editToken.trim() ?? '';
    if (slug.isEmpty || editToken.isEmpty) {
      _errorMessage = 'Ürünleri kaydetmek için önce vitrinini yayınlaman gerekiyor.';
      notifyListeners();
      return;
    }

    final kategoriId = _uuidKategoriBul(editor);
    if (kategoriId == null) {
      _errorMessage = 'Önce vitrinine bir ürün kategorisi ekle.';
      notifyListeners();
      return;
    }

    final satirlar = <FaturaKaydiSatiri>[];
    for (final urun in secilenler) {
      final sira = sonuc.products.indexOf(urun);
      if (sira < 0 || sira >= sonuc.invoiceDrafts.length) continue;
      final taslak = sonuc.invoiceDrafts[sira];
      final islemKimligi = (taslak.islemKimligi ?? sonuc.islemKimligi ?? '').trim();
      if (islemKimligi.isEmpty) continue;

      final satisFiyati = taslak.salePrice ?? urun.price;
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
          kategoriId: kategoriId,
          gorseller: gorseller,
          gorselKaynagi: taslak.canonicalProductUrl?.value,
          marka: taslak.brand?.value ?? urun.brand,
          barkod: urun.barcode,
          model: urun.sku,
          varyant: urun.variant,
          beden: urun.size,
          stok: taslak.stockConfirmed ? urun.documentQuantity : null,
          stokOnaylandi: taslak.stockConfirmed,
          kartDurumu: taslak.etkinKartDurumu.wireValue,
          disKimlik:
              kod.isEmpty
                  ? ''
                  : [tedarikciKimligi, kod].where((p) => p.isNotEmpty).join(':'),
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

    final kayit = await _faturaKaydiServisi.taslakKaydet(
      satirlar: satirlar,
      storeSlug: slug,
      editToken: editToken,
    );

    kayit.when(
      success: (ozet) {
        if (ozet.taslak + ozet.yayinda == 0) {
          final ilkSebep =
              ozet.satirlar.where((s) => s.sebep.isNotEmpty).isEmpty
                  ? 'Ürün kaydedilemedi.'
                  : ozet.satirlar.firstWhere((s) => s.sebep.isNotEmpty).sebep;
          _errorMessage = ilkSebep;
          notifyListeners();
          return;
        }
        _faturaKaydiSonucu = ozet;
        _faturaYayinSonucu = null;
        _result = null;
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
    if (kayit == null || _isPublishing) return;

    final idler = kayit.yayinlanabilirTaslakIdleri;
    if (idler.isEmpty) {
      _errorMessage = 'Yayınlanacak taslak ürün yok.';
      notifyListeners();
      return;
    }

    final yayinBilgisi = _editorController?.publishedInfo;
    final slug = yayinBilgisi?.slug.trim() ?? '';
    final editToken = yayinBilgisi?.editToken.trim() ?? '';

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

    // Faturadaki adet stok DEĞİLDİR. Esnaf stoğu onaylamadıysa ürün kartına
    // stok yazılmaz (bilinmiyor kalır); onayladıysa faturadaki adet yazılır.
    final faturaStok = detected.isInvoiceSource;
    final stokOnayli = invoiceDraft?.stockConfirmed == true;
    final int? stokMiktari =
        faturaStok
            ? (stokOnayli ? detected.documentQuantity : null)
            : detected.quantity;

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
