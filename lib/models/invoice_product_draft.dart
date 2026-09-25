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

  final bool merchantApproved;
  final double? salePrice;

  /// Fatura taslağı varsayılan olarak müşteriye açık değildir.
  final bool isVisible;

  const InvoiceProductDraft({
    required this.id,
    required this.rawSourceLine,
    this.supplierName,
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
    this.merchantApproved = false,
    this.salePrice,
    this.isVisible = false,
  });

  bool get hasPositiveSalePrice => salePrice != null && salePrice! > 0;

  List<InvoiceImageCandidate> get selectedExternalImages =>
      imageCandidates
          .where((item) => item.selected && item.isExternal)
          .toList(growable: false);

  InvoiceProductDraft copyWith({
    EvidenceValue<String>? supplierName,
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
    bool? merchantApproved,
    double? salePrice,
    bool? isVisible,
  }) {
    return InvoiceProductDraft(
      id: id,
      rawSourceLine: rawSourceLine,
      supplierName: supplierName ?? this.supplierName,
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
      merchantApproved: merchantApproved ?? this.merchantApproved,
      salePrice: salePrice ?? this.salePrice,
      isVisible: isVisible ?? this.isVisible,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'raw_source_line': rawSourceLine,
    if (supplierName != null) 'supplier_name': supplierName!.toJson(),
    if (rawName != null) 'raw_name': rawName!.toJson(),
    if (normalizedName != null) 'normalized_name': normalizedName!.toJson(),
    if (gtinBarcode != null) 'gtin_barcode': gtinBarcode!.toJson(),
    if (manufacturerSku != null)
      'manufacturer_sku': manufacturerSku!.toJson(),
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
    'image_candidates':
        imageCandidates.map((item) => item.toJson()).toList(growable: false),
    'supplier_identity_strength': supplierIdentityStrength.wireValue,
    'product_identity_strength': productIdentityStrength.wireValue,
    'rights_status': rightsStatus.wireValue,
    'merchant_approved': merchantApproved,
    'sale_price': salePrice,
    'visibility': isVisible,
  };
}
