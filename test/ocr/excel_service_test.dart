import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/services/excel/excel_service.dart';

void main() {
  group('ExcelService', () {
    const service = ExcelService();

    test('ExcelService oluşturulabilir', () {
      expect(service, isNotNull);
    });

    test('Template dosyası oluşturabilir', () {
      final template = service.generateTemplate();
      expect(template.isNotEmpty, true);
      expect(template.length, greaterThan(100));
    });

    test('Geçersiz dosya yolu için hata döner', () async {
      final result = await service.readFromFile('C:\\invalid\\path.xlsx');
      expect(result.isFailure, true);
    });
  });
}
