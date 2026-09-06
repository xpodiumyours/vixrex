// Web'de aynı sekmede navigasyon — package:web implementasyonu.
// dart:html Wasm'da `dart.library.html` false olur ve stub'a düşer, bu yüzden package:web kullanılır.
import 'package:web/web.dart' as web;

void webNavigateImpl(String url) {
  web.window.location.href = url;
}
