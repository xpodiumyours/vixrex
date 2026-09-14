import 'package:vixrex/config/vitrin_alanlari.g.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/services/product_image_policy.dart';
import 'package:vixrex/services/store_publish_legal_validator.dart';
import 'package:vixrex/services/store_publish_links_validator.dart';
import 'package:vixrex/services/store_publish_payload_builder.dart';
import 'package:vixrex/utils/whatsapp_link_helper.dart';

class StorePublishValidator {
  final StorePublishLegalValidator legalValidator;
  final StorePublishLinksValidator linksValidator;
  final StorePublishPayloadBuilder payloadBuilder;

  const StorePublishValidator({
    this.legalValidator = const StorePublishLegalValidator(),
    this.linksValidator = const StorePublishLinksValidator(),
    this.payloadBuilder = const StorePublishPayloadBuilder(),
  });

  String? validate(StoreData data) =>
      _validate(data, validateProducts: data.isStore);

  String? validateVitrin(StoreData data) =>
      _validate(data, validateProducts: false);

  String? validateStore(StoreData data) =>
      _validate(data, validateProducts: true);

  String? _validate(StoreData data, {required bool validateProducts}) {
    final readinessError = _validateCommonReadiness(data);
    if (readinessError != null) return readinessError;

    if (!WhatsAppLinkHelper.isValidTurkeyMobile(data.whatsapp)) {
      return WhatsAppLinkHelper.invalidNumberMessage;
    }

    if (validateProducts) {
      final productError = _validateProducts(data.products);
      if (productError != null) return productError;
    }

    final extraValidation = linksValidator.validateLinksAndOfferings(data);
    if (extraValidation != null) return extraValidation;

    return legalValidator.validateLegalAcceptance(data);
  }

  String? _validateCommonReadiness(StoreData data) {
    final missing = <String>[];
    final payload = payloadBuilder.toStoreUpdateMap(data);
    for (final field in zorunluAlanlar) {
      final value = (payload[field.kolon] ?? '').toString().trim();
      final emptyValues =
          field.bosDegerler?.map((item) => item.trim().toLowerCase()).toSet();
      if (value.isEmpty || emptyValues?.contains(value.toLowerCase()) == true) {
        missing.add(_missingFieldLabel(field.etiket));
      }
    }
    if (missing.isEmpty) return null;
    return 'Lütfen şu zorunlu alanları doldurun: ${missing.join(', ')}.';
  }

  String _missingFieldLabel(String label) {
    return label.toLowerCase().replaceFirst('whatsapp', 'WhatsApp');
  }

  String? _validateProducts(List<Product> products) {
    for (final product in products) {
      if (product.name.trim().isEmpty) {
        return 'Eklenen tüm ürünlerin adı zorunludur.';
      }
      if (product.category.trim().isEmpty) {
        return 'Eklenen tüm ürünlerin kategorisi zorunludur.';
      }
      final imageError = _validateProductImages(product);
      if (imageError != null) return imageError;
    }
    return null;
  }

  String? _validateProductImages(Product product) {
    final images = ProductImagePolicy.normalize(product.displayImageUrls);

    // Yeni ürün ve değiştirilen galeri ProductService/DB kapısında 3-11
    // sözleşmesine tabidir. UUID sahibi eski ürünler ise bu kural gelmeden
    // önce 0-2 fotoğrafla kaydedilmiş olabilir. Yalnız mağazayı tekrar
    // yayınlamak bu eski ürünü değiştirmediği halde vitrini kilitlememeli.
    if (_isRemoteProductId(product.id) &&
        images.length < ProductImagePolicy.minImages) {
      if (images.length > ProductImagePolicy.maxImages) {
        return 'Bir ürüne en fazla ${ProductImagePolicy.maxImages} fotoğraf eklenebilir.';
      }
      final invalid = images.any(
        (url) => !(url.startsWith('http://') || url.startsWith('https://')),
      );
      if (invalid) {
        return 'Ürün fotoğrafı bağlantıları http:// veya https:// ile başlamalıdır.';
      }
      return null;
    }

    return ProductImagePolicy.validate(images);
  }

  bool _isRemoteProductId(String value) {
    return RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(value.trim());
  }
}
