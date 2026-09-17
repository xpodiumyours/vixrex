# Plan

## Ölçüm

Onay bugün yalnız teslimatta ölçülüyor; yazma anında engel yok. Resmî doküman
metin kuralın bağlam olduğunu, gerçek engelin yazma öncesi kanca olduğunu
söylüyor.

## Çözüm

1. `.claude/hooks/onay-kapisi.sh` — yazma öncesi çalışır. Hedef yolun korunan
   klasörlerden birinde olup olmadığına bakar; değilse hiç karışmaz. Açık işi
   Spec Kit'in kendi işaretçisinden, yoksa en son değişen iş klasöründen bulur.
   Sebep kaydı varsa geçirir; keşif kaydında onay satırı varsa geçirir; yoksa
   durdurur ve eksiği yazar.
2. `.claude/settings.json` — kanca hem dosya yazma hem kabuk komutu yolunda
   devreye alındı.

## Deneme

Dokuz senaryo ayrı bir kopyada çalıştırıldı: onaysız yazma, onaylı yazma, hata
işinde yazma, keşif kaydının kendisini yazma, ürün kodu olmayan dosya, kabuktan
yazma, kabuktan okuma, kabuktan göç dosyası değiştirme ve ortak şema dosyası.

## Geri alma

Tek commit; kanca ayardan çıkarıldığında eski davranışa dönülür.
