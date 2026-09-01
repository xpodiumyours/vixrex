/// Web'de aynı sekmede navigasyon — dart:html implementasyonu.
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void webNavigateImpl(String url) {
  html.window.location.href = url;
}
