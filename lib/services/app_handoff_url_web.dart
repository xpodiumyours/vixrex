import 'package:web/web.dart' as web;

void temizleAppHandoffAdresi() {
  final temizAdres = '${web.window.location.pathname}${web.window.location.search}';
  web.window.history.replaceState(null, '', temizAdres);
}
