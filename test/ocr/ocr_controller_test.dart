import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/controllers/ocr_controller.dart';
import 'package:vixrex/services/ocr/ocr_service.dart';

void main() {
  group('OcrController', () {
    late OcrService ocrService;

    setUp(() {
      ocrService = const OcrService();
    });

    test('OcrController olusturulabilir', () {
      final controller = OcrController(
        ocrService: ocrService,
        editorController: null,
      );
      expect(controller, isNotNull);
      expect(controller.isProcessing, false);
      expect(controller.hasResult, false);
      expect(controller.errorMessage, isNull);
    });

    test('Sonuc yokken onaylama calismaz', () {
      final controller = OcrController(
        ocrService: ocrService,
        editorController: null,
      );

      controller.approveProduct(0);
      expect(controller.hasResult, false);
    });

    test('Sonuc yokken reddetme calismaz', () {
      final controller = OcrController(
        ocrService: ocrService,
        editorController: null,
      );

      controller.rejectProduct(0);
      expect(controller.hasResult, false);
    });

    test('Tumunu onaylama calisir', () {
      final controller = OcrController(
        ocrService: ocrService,
        editorController: null,
      );

      controller.approveAll();
      expect(controller.hasResult, false);
    });

    test('Tumunu reddetme calisir', () {
      final controller = OcrController(
        ocrService: ocrService,
        editorController: null,
      );

      controller.rejectAll();
      expect(controller.hasResult, false);
    });

    test('Sonucu temizleme calisir', () {
      final controller = OcrController(
        ocrService: ocrService,
        editorController: null,
      );

      controller.clearResult();
      expect(controller.hasResult, false);
      expect(controller.errorMessage, isNull);
    });

    test('Hata mesajini temizleme calisir', () {
      final controller = OcrController(
        ocrService: ocrService,
        editorController: null,
      );

      controller.clearError();
      expect(controller.errorMessage, isNull);
    });
  });
}
