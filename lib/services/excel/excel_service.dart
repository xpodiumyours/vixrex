import 'dart:io';
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:vixrex/core/result.dart';
import 'package:vixrex/core/supabase_error_mapper.dart';
import 'package:vixrex/models/product_database_entry.dart';
import 'package:vixrex/utils/failure.dart';

/// Excel dosyası okuma servisi.
class ExcelService {
  const ExcelService();

  /// Excel dosyasından ürün listesi oku.
  Future<Result<List<ProductDatabaseEntry>>> readFromFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return Result.failure(Failure('Dosya bulunamadı: $filePath'));
      }

      final bytes = await file.readAsBytes();
      return _parseExcel(bytes);
    } catch (e, s) {
      return Result.failure(SupabaseErrorMapper.map(e, s));
    }
  }

  /// Byte'lardan ürün listesi oku.
  Future<Result<List<ProductDatabaseEntry>>> readFromBytes(Uint8List bytes) async {
    try {
      return _parseExcel(bytes);
    } catch (e, s) {
      return Result.failure(SupabaseErrorMapper.map(e, s));
    }
  }

  /// Excel byte'larını ayrıştır.
  Result<List<ProductDatabaseEntry>> _parseExcel(Uint8List bytes) {
    try {
      final excel = Excel.decodeBytes(bytes);
      final entries = <ProductDatabaseEntry>[];

      for (final table in excel.tables.values) {
        if (table.rows.isEmpty) continue;

        // İlk satırı başlık olarak al
        final headers = table.rows.first
            .map((cell) => cell?.value?.toString().toLowerCase().trim() ?? '')
            .toList();

        // Veri satırlarını işle
        for (var i = 1; i < table.rows.length; i++) {
          final row = table.rows[i];
          final json = <String, dynamic>{};

          for (var j = 0; j < headers.length && j < row.length; j++) {
            final header = headers[j];
            if (header.isNotEmpty) {
              json[header] = row[j]?.value?.toString() ?? '';
            }
          }

          if (json.isNotEmpty) {
            entries.add(ProductDatabaseEntry.fromJson(json));
          }
        }
      }

      return Result.success(entries);
    } catch (e) {
      return Result.failure(Failure('Excel ayrıştırma hatası: $e'));
    }
  }

  /// Excel dosyasını template olarak indir (boş şablon).
  Uint8List generateTemplate() {
    final excel = Excel.createExcel();

    // Başlık satırı
    final sheet = excel['Ürünler'];
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value = TextCellValue('urun_adi');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 0)).value = TextCellValue('marka');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 0)).value = TextCellValue('kategori');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 0)).value = TextCellValue('aciklama');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 0)).value = TextCellValue('ocr_eslesme_kelimeleri');

    // Örnek veri
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1)).value = TextCellValue('Ülker Çikolata 80g');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 1)).value = TextCellValue('Ülker');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 1)).value = TextCellValue('Çikolata');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 1)).value = TextCellValue('80 gramlık çikolata');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 1)).value = TextCellValue('ulker,cikolata,80g');

    final fileBytes = excel.save()!;
    return Uint8List.fromList(fileBytes);
  }
}
