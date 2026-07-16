enum VixRexNluField {
  storeName('store_name', 'İşletme adı'),
  whatsapp('whatsapp', 'WhatsApp numarası'),
  address('address', 'Adres'),
  description('description', 'Açıklama'),
  category('category', 'Kategori');

  const VixRexNluField(this.remoteName, this.label);

  final String remoteName;
  final String label;
}
