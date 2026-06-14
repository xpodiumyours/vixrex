import 'package:vitrinx/models/store_data.dart';
import 'seo_helper_mobile.dart' if (dart.library.html) 'seo_helper_web.dart';

void injectStoreJsonLd(StoreData store) {
  injectStoreJsonLdImpl(store);
}
