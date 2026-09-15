import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/services/xml_product_upload_service.dart';

void main() {
  const service = XmlProductUploadService();

  test('XML marka barkod SKU stok fiyat ve 11 görseli ayrı alanlarda taşır', () {
    final images = List.generate(
      11,
      (index) => '<image${index + 1}>https://cdn.example.com/${index + 1}.jpg</image${index + 1}>',
    ).join();
    final xml = '''
      <products>
        <product>
          <name>Keten Gömlek</name>
          <price>1.234,56 TL</price>
          <category>Giyim</category>
          <brand>Örnek Marka</brand>
          <barcode>8690000000005</barcode>
          <sku>KG-1</sku>
          <quantity>10</quantity>
          $images
        </product>
      </products>
    ''';

    final result = service.parse(xml);

    expect(result.isSuccess, isTrue);
    expect(result.validCount, 1);
    expect(result.errorCount, 0);
    final product = result.products.single;
    expect(product.price, '1234.56');
    expect(product.brand, 'Örnek Marka');
    expect(product.barcode, '8690000000005');
    expect(product.sku, 'KG-1');
    expect(product.stockQuantity, 10);
    expect(product.stockStatus, 'Mevcut');
    expect(product.imageUrls, hasLength(11));
  });

  test('barkod SKU alanına karışmaz', () {
    const xml = '''
      <products>
        <product>
          <name>Barkodlu Ürün</name>
          <barkod>8690000000005</barkod>
        </product>
      </products>
    ''';

    final result = service.parse(xml);
    final product = result.products.single;

    expect(product.barcode, '8690000000005');
    expect(product.sku, isNull);
  });

  test('iki görselli XML ürününü içe aktarır; minimum 3 yayın kapısına kalır', () {
    const xml = '''
      <products>
        <product>
          <name>İki Görselli Ürün</name>
          <image1>https://cdn.example.com/a.jpg</image1>
          <image2>https://cdn.example.com/b.jpg</image2>
        </product>
      </products>
    ''';

    final result = service.parse(xml);

    expect(result.isSuccess, isTrue);
    expect(result.validCount, 1);
    expect(result.errorCount, 0);
    expect(result.products.single.imageUrls, hasLength(2));
  });

  test('stok sıfırsa Tükendi, stok 10 ise Mevcut olur', () {
    const xml = '''
      <products>
        <product><name>Sıfır Stok</name><quantity>0</quantity></product>
        <product><name>Stoklu</name><quantity>10</quantity></product>
      </products>
    ''';

    final result = service.parse(xml);

    expect(result.products[0].stockQuantity, 0);
    expect(result.products[0].stockStatus, 'Tükendi');
    expect(result.products[1].stockQuantity, 10);
    expect(result.products[1].stockStatus, 'Mevcut');
  });
}
