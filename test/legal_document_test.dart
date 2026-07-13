import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/models/legal_document.dart';

void main() {
  test('yasal belge marka yazımını gösterim sırasında Vixrex yapar', () {
    final document = LegalDocument.fromJson({
      'document_type': 'terms',
      'version': '1.0.0',
      'title': 'VixRex Kullanım Koşulları',
      'subtitle': 'VixRex platform kuralları',
      'content_hash': 'existing-hash',
      'sections': [
        {'title': 'VixRex', 'body': 'VixRex hizmet açıklaması.'},
      ],
    });

    expect(document.title, 'Vixrex Kullanım Koşulları');
    expect(document.subtitle, 'Vixrex platform kuralları');
    expect(document.sections.single.title, 'Vixrex');
    expect(document.sections.single.body, 'Vixrex hizmet açıklaması.');
    expect(document.contentHash, 'existing-hash');
  });
}
