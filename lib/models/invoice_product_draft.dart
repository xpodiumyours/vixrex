enum EvidenceStrength { strong, partial, weak }

enum EvidenceSourceType {
  invoice,
  ublTrXml,
  supplierXml,
  supplierApi,
  officialProductPage,
  officialCatalog,
  verifiedGtinRegistry,
  merchantUpload,
  vixrexProductDatabase,
  webDiscovery,
  aiDerived,
}

enum RightsStatus {
  verifiedSupplierPermission,
  verifiedFeedTerms,
  merchantOwnedMedia,
  merchantAttestation,
  unknown,
  denied,
}

enum AutomationDecision {
  autoPrepareDraft,
  askMissing,
  stopNoGuess,
  readyForPublish,
}

extension EvidenceStrengthWire on EvidenceStrength {
  String get wireValue => switch (this) {
    EvidenceStrength.strong => 'strong',
    EvidenceStrength.partial => 'partial',
    EvidenceStrength.weak => 'weak',
  };
}

extension EvidenceSourceTypeWire on EvidenceSourceType {
  String get wireValue => switch (this) {
    EvidenceSourceType.invoice => 'invoice',
    EvidenceSourceType.ublTrXml => 'ubl_tr_xml',
    EvidenceSourceType.supplierXml => 'supplier_xml',
    EvidenceSourceType.supplierApi => 'supplier_api',
    EvidenceSourceType.officialProductPage => 'official_product_page',
    EvidenceSourceType.officialCatalog => 'official_catalog',
    EvidenceSourceType.verifiedGtinRegistry => 'verified_gtin_registry',
    EvidenceSourceType.merchantUpload => 'merchant_upload',
    EvidenceSourceType.vixrexProductDatabase => 'vixrex_product_database',
    EvidenceSourceType.webDiscovery => 'web_discovery',
    EvidenceSourceType.aiDerived => 'ai_derived',
  };
}

extension RightsStatusWire on RightsStatus {
  String get wireValue => switch (this) {
    RightsStatus.verifiedSupplierPermission => 'verified_supplier_permission',
    RightsStatus.verifiedFeedTerms => 'verified_feed_terms',
    RightsStatus.merchantOwnedMedia => 'merchant_owned_media',
    RightsStatus.merchantAttestation => 'merchant_attestation',
    RightsStatus.unknown => 'unknown',
    RightsStatus.denied => 'denied',
  };

  bool get isUsableBasis =>
      this != RightsStatus.unknown && this != RightsStatus.denied;
}

extension AutomationDecisionWire on AutomationDecision {
  String get wireValue => switch (this) {
    AutomationDecision.autoPrepareDraft => 'auto_prepare_draft',
    AutomationDecision.askMissing => 'ask_missing',
    AutomationDecision.stopNoGuess => 'stop_no_guess',
    AutomationDecision.readyForPublish => 'ready_for_publish',
  };
}

/// Kartın ekranda görünen hâli. Tam olarak dört sonuç vardır ve beşincisi
/// yoktur: kanıtlı / eksik bilgi sor / çelişkiyi çöz / iz bulunamadı.
///
/// Yalnız [kanitli] satırdan ürün kartı yayına çıkar; diğer üçü esnafın
/// inceleme kaydında kalır (web tarafındaki `faturaKartDurumu.ts` ile aynı).
enum KartDurumu { kanitli, eksik, celiski, izYok }

extension KartDurumuWire on KartDurumu {
  String get wireValue => switch (this) {
    KartDurumu.kanitli => 'kanitli',
    KartDurumu.eksik => 'eksik',
    KartDurumu.celiski => 'celiski',
    KartDurumu.izYok => 'iz-yok',
  };

  String get etiket => switch (this) {
    KartDurumu.kanitli => 'Kanıtlı',
    KartDurumu.eksik => 'Eksik bilgi',
    KartDurumu.celiski => 'Çelişki',
    KartDurumu.izYok => 'İz bulunamadı',
  };

  bool get kartYayinaUygun => this == KartDurumu.kanitli;
}

KartDurumu? kartDurumuFromWire(dynamic deger) {
  final ham = (deger ?? '').toString().trim();
  for (final durum in KartDurumu.values) {
    if (durum.wireValue == ham) return durum;
  }
  return null;
}

/// Aynı kod/barkod birden çok ürüne düştüğünde gösterilen aday.
class InvoiceConflictCandidate {
  final String ad;
  final String kaynak;

  const InvoiceConflictCandidate({required this.ad, this.kaynak = ''});

  Map<String, dynamic> toJson() => {'ad': ad, 'kaynak': kaynak};
}

/// Tek bir alanın yalnız değerini değil, nereden ve ne kadar güvenle geldiğini taşır.
class EvidenceValue<T> {
  final T? value;
  final EvidenceSourceType sourceType;
  final String sourceReference;
  final EvidenceStrength strength;
  final DateTime verifiedAt;

  const EvidenceValue({
    required this.value,
    required this.sourceType,
    required this.sourceReference,
    required this.strength,
    required this.verifiedAt,
  });

  bool get hasValue {
    final current = value;
    if (current == null) return false;
    if (current is String) return current.trim().isNotEmpty;
    return true;
  }

  Map<String, dynamic> toJson() => {
    'value': value,
    'source_type': sourceType.wireValue,
    'source_reference': sourceReference,
    'evidence_strength': strength.wireValue,
    'verified_at': verifiedAt.toUtc().toIso8601String(),
  };
}

class InvoiceImageCandidate {
  final String url;
  final EvidenceSourceType sourceType;
  final String sourceReference;
  final EvidenceStrength strength;
  final RightsStatus rightsStatus;
  final bool selected;
  final bool isExternal;

  const InvoiceImageCandidate({
    required this.url,
    required this.sourceType,
    required this.sourceReference,
    required this.strength,
    required this.rightsStatus,
    this.selected = false,
    this.isExternal = true,
  });

  bool get canUse =>
      !isExternal ||
      rightsStatus == RightsStatus.merchantOwnedMedia ||
      rightsStatus.isUsableBasis;

  Map<String, dynamic> toJson() => {
    'url': url,
    'source_type': sourceType.wireValue,
    'source_reference': sourceReference,
    'evidence_strength': strength.wireValue,
    'rights_status': rightsStatus.wireValue,
    'selected': selected,
    'is_external': isExternal,
  };
}

/// Faturadan çıkan veri doğrudan Product değildir.
/// Önce kanıtı, kimliği, kullanım hakkı ve esnaf onayı taşınır.
class InvoiceProductDraft {
  final String id;
  final String rawSourceLine;

  final EvidenceValue<String>? supplierName;
  final EvidenceValue<String>? supplierTaxOrTradeIdentifier;
  final EvidenceValue<String>? supplierAddress;
  final EvidenceValue<String>? supplierOfficialDomain;
  final EvidenceValue<String>? rawName;
  final EvidenceValue<String>? normalizedName;
  final EvidenceValue<String>? gtinBarcode;
  final EvidenceValue<String>? manufacturerSku;
  final EvidenceValue<String>? supplierSku;
  final EvidenceValue<String>? modelCode;
  final EvidenceValue<String>? brand;
  final EvidenceValue<String>? variant;
  final EvidenceValue<String>? size;
  final EvidenceValue<num>? quantity;
  final EvidenceValue<num>? purchaseUnitPrice;
  final EvidenceValue<num>? purchaseLineTotal;
  final EvidenceValue<String>? currency;

  final EvidenceValue<String>? canonicalProductId;
  final EvidenceValue<String>? canonicalProductUrl;
  final List<InvoiceImageCandidate> imageCandidates;

  final EvidenceStrength supplierIdentityStrength;
  final EvidenceStrength productIdentityStrength;
  final RightsStatus rightsStatus;

  /// Sunucunun verdiği kart hâli. Boşsa kanıt gücünden türetilir.
  final KartDurumu? kartDurumu;

  /// Çelişki hâlinde aynı koda düşen ürün adayları.
  final List<InvoiceConflictCandidate> celiskiAdaylari;

  /// Çelişkinin dayanağı: ürün kodu mu, barkod mu.
  final String? celiskiDayanak;

  /// Faturadaki adet ÖNERİDİR; esnaf onaylamadan stok yerine geçmez.
  final bool stockConfirmed;

  /// Aynı belgenin işlem kimliği (kalıcı kanıt kaydı).
  final String? islemKimligi;

  final bool merchantApproved;
  final double? salePrice;

  /// Fatura taslağı varsayılan olarak müşteriye açık değildir.
  final bool isVisible;

  const InvoiceProductDraft({
    required this.id,
    required this.rawSourceLine,
    this.supplierName,
    this.supplierTaxOrTradeIdentifier,
    this.supplierAddress,
    this.supplierOfficialDomain,
    this.rawName,
    this.normalizedName,
    this.gtinBarcode,
    this.manufacturerSku,
    this.supplierSku,
    this.modelCode,
    this.brand,
    this.variant,
    this.size,
    this.quantity,
    this.purchaseUnitPrice,
    this.purchaseLineTotal,
    this.currency,
    this.canonicalProductId,
    this.canonicalProductUrl,
    this.imageCandidates = const [],
    required this.supplierIdentityStrength,
    required this.productIdentityStrength,
    this.rightsStatus = RightsStatus.unknown,
    this.kartDurumu,
    this.celiskiAdaylari = const [],
    this.celiskiDayanak,
    this.stockConfirmed = false,
    this.islemKimligi,
    this.merchantApproved = false,
    this.salePrice,
    this.isVisible = false,
  });

  bool get hasPositiveSalePrice => salePrice != null && salePrice! > 0;

  /// Ekranda gösterilen kart hâli. Açıkça verilmediyse yalnız kanıt
  /// gücünden türetilir; ürün izi zayıfsa "iz bulunamadı" olur ve tahmin
  /// edilmez, kısmi ise "eksik bilgi" olur.
  KartDurumu get etkinKartDurumu {
    final acik = kartDurumu;
    if (acik != null) return acik;
    if (productIdentityStrength == EvidenceStrength.weak) {
      return KartDurumu.izYok;
    }
    if (productIdentityStrength == EvidenceStrength.strong &&
        supplierIdentityStrength == EvidenceStrength.strong) {
      return KartDurumu.kanitli;
    }
    return KartDurumu.eksik;
  }

  /// Faturadaki miktar stok yerine geçmez: onay yoksa stok sayılmaz.
  bool get canUseQuantityAsStock =>
      stockConfirmed && quantity != null && (quantity!.value ?? 0) > 0;

  List<InvoiceImageCandidate> get selectedExternalImages => imageCandidates
      .where((item) => item.selected && item.isExternal)
      .toList(growable: false);

  InvoiceProductDraft copyWith({
    EvidenceValue<String>? supplierName,
    EvidenceValue<String>? supplierTaxOrTradeIdentifier,
    EvidenceValue<String>? supplierAddress,
    EvidenceValue<String>? supplierOfficialDomain,
    EvidenceValue<String>? rawName,
    EvidenceValue<String>? normalizedName,
    EvidenceValue<String>? gtinBarcode,
    EvidenceValue<String>? manufacturerSku,
    EvidenceValue<String>? supplierSku,
    EvidenceValue<String>? modelCode,
    EvidenceValue<String>? brand,
    EvidenceValue<String>? variant,
    EvidenceValue<String>? size,
    EvidenceValue<num>? quantity,
    EvidenceValue<num>? purchaseUnitPrice,
    EvidenceValue<num>? purchaseLineTotal,
    EvidenceValue<String>? currency,
    EvidenceValue<String>? canonicalProductId,
    EvidenceValue<String>? canonicalProductUrl,
    List<InvoiceImageCandidate>? imageCandidates,
    EvidenceStrength? supplierIdentityStrength,
    EvidenceStrength? productIdentityStrength,
    RightsStatus? rightsStatus,
    KartDurumu? kartDurumu,
    List<InvoiceConflictCandidate>? celiskiAdaylari,
    String? celiskiDayanak,
    bool? stockConfirmed,
    String? islemKimligi,
    bool? merchantApproved,
    double? salePrice,
    bool? isVisible,
  }) {
    return InvoiceProductDraft(
      id: id,
      rawSourceLine: rawSourceLine,
      supplierName: supplierName ?? this.supplierName,
      supplierTaxOrTradeIdentifier:
          supplierTaxOrTradeIdentifier ?? this.supplierTaxOrTradeIdentifier,
      supplierAddress: supplierAddress ?? this.supplierAddress,
      supplierOfficialDomain:
          supplierOfficialDomain ?? this.supplierOfficialDomain,
      rawName: rawName ?? this.rawName,
      normalizedName: normalizedName ?? this.normalizedName,
      gtinBarcode: gtinBarcode ?? this.gtinBarcode,
      manufacturerSku: manufacturerSku ?? this.manufacturerSku,
      supplierSku: supplierSku ?? this.supplierSku,
      modelCode: modelCode ?? this.modelCode,
      brand: brand ?? this.brand,
      variant: variant ?? this.variant,
      size: size ?? this.size,
      quantity: quantity ?? this.quantity,
      purchaseUnitPrice: purchaseUnitPrice ?? this.purchaseUnitPrice,
      purchaseLineTotal: purchaseLineTotal ?? this.purchaseLineTotal,
      currency: currency ?? this.currency,
      canonicalProductId: canonicalProductId ?? this.canonicalProductId,
      canonicalProductUrl: canonicalProductUrl ?? this.canonicalProductUrl,
      imageCandidates: imageCandidates ?? this.imageCandidates,
      supplierIdentityStrength:
          supplierIdentityStrength ?? this.supplierIdentityStrength,
      productIdentityStrength:
          productIdentityStrength ?? this.productIdentityStrength,
      rightsStatus: rightsStatus ?? this.rightsStatus,
      kartDurumu: kartDurumu ?? this.kartDurumu,
      celiskiAdaylari: celiskiAdaylari ?? this.celiskiAdaylari,
      celiskiDayanak: celiskiDayanak ?? this.celiskiDayanak,
      stockConfirmed: stockConfirmed ?? this.stockConfirmed,
      islemKimligi: islemKimligi ?? this.islemKimligi,
      merchantApproved: merchantApproved ?? this.merchantApproved,
      salePrice: salePrice ?? this.salePrice,
      isVisible: isVisible ?? this.isVisible,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'raw_source_line': rawSourceLine,
    if (supplierName != null) 'supplier_name': supplierName!.toJson(),
    if (supplierTaxOrTradeIdentifier != null)
      'supplier_tax_or_trade_identifier':
          supplierTaxOrTradeIdentifier!.toJson(),
    if (supplierAddress != null) 'supplier_address': supplierAddress!.toJson(),
    if (supplierOfficialDomain != null)
      'supplier_official_domain': supplierOfficialDomain!.toJson(),
    if (rawName != null) 'raw_name': rawName!.toJson(),
    if (normalizedName != null) 'normalized_name': normalizedName!.toJson(),
    if (gtinBarcode != null) 'gtin_barcode': gtinBarcode!.toJson(),
    if (manufacturerSku != null) 'manufacturer_sku': manufacturerSku!.toJson(),
    if (supplierSku != null) 'supplier_sku': supplierSku!.toJson(),
    if (modelCode != null) 'model_code': modelCode!.toJson(),
    if (brand != null) 'brand': brand!.toJson(),
    if (variant != null) 'variant': variant!.toJson(),
    if (size != null) 'size': size!.toJson(),
    if (quantity != null) 'quantity': quantity!.toJson(),
    if (purchaseUnitPrice != null)
      'purchase_unit_price': purchaseUnitPrice!.toJson(),
    if (purchaseLineTotal != null)
      'purchase_line_total': purchaseLineTotal!.toJson(),
    if (currency != null) 'currency': currency!.toJson(),
    if (canonicalProductId != null)
      'canonical_product_id': canonicalProductId!.toJson(),
    if (canonicalProductUrl != null)
      'canonical_product_url': canonicalProductUrl!.toJson(),
    'image_candidates': imageCandidates
        .map((item) => item.toJson())
        .toList(growable: false),
    'supplier_identity_strength': supplierIdentityStrength.wireValue,
    'product_identity_strength': productIdentityStrength.wireValue,
    'rights_status': rightsStatus.wireValue,
    'card_state': etkinKartDurumu.wireValue,
    'conflict_candidates': celiskiAdaylari
        .map((aday) => aday.toJson())
        .toList(growable: false),
    if (celiskiDayanak != null) 'conflict_basis': celiskiDayanak,
    // Faturadaki adet öneri olarak taşınır; stok onayı ayrı alandır.
    'stock_confirmed': stockConfirmed,
    if (islemKimligi != null) 'operation_id': islemKimligi,
    'merchant_approved': merchantApproved,
    'sale_price': salePrice,
    'visibility': isVisible,
  };
}
