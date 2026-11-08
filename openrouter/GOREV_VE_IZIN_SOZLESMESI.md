# OpenRouter ↔ Vixrex görev ve üretici izni sözleşmesi

## Tek sorumluluk kuralı

**OpenRouter araştırır; Vixrex araştırmayı tekrarlamaz.** OpenRouter yalnız resmî üretici kaynağından ürün bilgisi, doğrulama durumu, kaynak sayfa ve görsel kanıtı üretir.

Vixrex faturanın asıl satırını, marka/barkod/kod/fiyat/miktar bilgisini ve sıra kimliğini kendi okumasından alır. Bunları OpenRouter'dan tekrar istemez. Kart özeti, taslak durumu, satış fiyatı, stok, esnaf onayı, yayın ve izin kararı modele ait değildir.

## OpenRouter'ın vermediği kararlar

- `summary` ve `card_status`: Vixrex hesaplar.
- `invoice_data`, ham satır, marka/barkod/kod ekoları: Vixrex'in fatura kaydından gelir.
- `consumer_sale_price`, `stock_quantity`: model şemasında yoktur; Vixrex esnaftan/faturadan alır.
- `rights_status`: modelin izin iddiası kabul edilmez; üretici izin kayıtları esas alınır.

## Üretici izninin kanıt zinciri

Mevcut `supplier_permission_requests`, `supplier_permissions`, `supplier_permission_products` ve `invoice_image_rights` kayıtları kullanılır; paralel bir izin sistemi kurulmaz.

Bir görsel veya veri ancak şu bağlantılarla "doğrulanmış izinli" sayılabilir:

1. Resmî üretici ve alan adı,
2. Kapsamı (`data`, `images`, `data_and_images`) açık izin,
3. İzni veren tarafın ve cevabın kaydı,
4. Varsa geçerlilik tarihi,
5. Ürün/görsel ve fatura satırı bağlantısı,
6. Yayın sırasında yeniden veritabanı kontrolü.

Modelin veya esnafın "izin var" yazması bu zincirin yerine geçmez. `unknown` izinli sayılmaz; `denied` açık reddedilme durumudur. Taslak hazırlama ile yayın izni ayrı kapılardır.

## Denetlenebilir sürüm akışı

`openrouter/preset-kart.json` bu sözleşmenin **aday tarifidir**; canlı preset kendiliğinden değişmiş sayılmaz.

1. Kod ve aday tarif aynı testleri geçer.
2. Gerçek cevap örnekleri ve 10/20 satırlık kabul faturaları incelenir.
3. Ücretli canlı aday testi için ayrı onay alınır.
4. Canlı preset yeni bir sürüm olarak yazılır; manifest ve prompt özeti aynı değişiklikte güncellenir.
5. Preview'da yayın öncesi ve yayın sonrası sonuçlar doğrulanır.
6. Geri dönüş, eski çalışan tarifin yeni bir sürüm olarak geri yazılmasıyla yapılır; "latest" sürümünün belirsiz kalmasına izin verilmez.

## Gerçek cevap regresyon örnekleri

Aşağıdaki mevcut, ücretli çalıştırmaların cevapları test kataloğuna alınmıştır:

- `gen-1794131271-Sbqn0XwTqpsgiWcsxjIq`
- `gen-1794132362-bq6EKbZXfy28UI6AWt5H`
- `gen-1794135286-ZXtGYKueo3HntgMHYSuT`

Testler faturadaki asıl alanların korunmasını, 20 satırın birleştirilmesini, tek satır karantinasını ve modelin izin iddiasının yayın yetkisine dönüşmemesini kanıtlar. Bu örnekler canlı kabul testinin yerine geçmez.
