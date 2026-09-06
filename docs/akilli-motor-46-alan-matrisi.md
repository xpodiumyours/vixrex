# Vixrex Akıllı Motor — 46/46 Davranış Matrisi

> Amaç: Bir alanın yalnız sözlükte bulunmasını değil, esnaf mesajından güvenli biçimde anlaşılmasını ve gerçek kayıt sonucuna kadar doğru davranmasını doğrulamak.

Durum: 🔄 araştırma. Bu belge BUILD izni vermez.

## Sınıflar

- **D — Doğrudan aday:** Metin/değer doğrulandıktan sonra typed action üretilebilir.
- **S — Özel akış:** Esnafa ham teknik değer yazdırmak yerine mevcut seçim/yükleme/GPS gibi UX'e delege edilmeli.
- **P — Parity açığı:** Flutter ve Next aynı girdide bugün aynı sonucu garanti etmiyor.
- **T — İşletme gerçeği hassas:** Motor kullanıcı söylemeden değer uyduramaz/otomatik üretemez.
- **B — Storefront Blog başlığı:** Blog domain'i değildir; vitrindeki Blog bölümünün kozmetik alanıdır.

## Alanlar

| # | Anahtar | Tip | Hedef sınıf | Mevcut doğrulanmış durum / LOCK notu |
|---:|---|---|---|---|
| 1 | `isletmeAdi` | metin | D/T | Zorunlu. Kullanıcı gerçeği; otomatik uydurulmaz. |
| 2 | `heroRozet` | metin | D | Doğrudan metin adayı. |
| 3 | `kisaTanitim` | uzunMetin | D | Doğrudan metin adayı; uzunluk doğrulanır. |
| 4 | `konumMetni` | metin | D | Görünen kısa konum yazısı; gerçek il/ilçe alanından ayrıdır. |
| 5 | `kategori` | seçim | S/P | Hazır kategori listesinden seçilmeli. Flutter case-insensitive label/id kabul ediyor; Next validator exact seçenek eşleşmesi kullanıyor. |
| 6 | `isletmeTuru` | metin | D/T | İnce işletme tanımı; kullanıcı söylemeden uydurulmaz. |
| 7 | `logo` | görsel | S | Esnaf ana akışında URL değil yükleme/hazır görsel. Flutter companion upload özel akışına bağlı değil. |
| 8 | `kapakGorseli` | görsel | S | Upload/hazır görsel özel akışı. |
| 9 | `whatsapp` | telefon | D | TR mobil normalizasyonu var; 46/46 fixture ile iki runtime eşitliği ayrıca kilitlenecek. |
| 10 | `telefon` | telefon | D | 10–13 rakam kuralı mevcut. |
| 11 | `eposta` | eposta | D | E-posta format doğrulaması mevcut. |
| 12 | `adres` | uzunMetin | P/S | Flutter `AddressValidator` kullanıyor; Next genel validator aynı semantik kontrolü yapmıyor. GPS/adres UX'iyle uyumlandırılmalı. |
| 13 | `il` | metin | S | Flutter mevcut akışta listeden seçim özel akışı. |
| 14 | `ilce` | metin | S | Flutter mevcut akışta listeden seçim özel akışı. |
| 15 | `mahalle` | metin | D | Doğrudan aday; il/ilçe bağlamıyla tutarlılık ayrıca doğrulanacak. |
| 16 | `haritaEtiketi` | metin | D | Doğrudan kısa metin adayı. |
| 17 | `calismaSaatleri` | metin | S/P | Public açık/kapalı hesabı geçerli saat aralığı bekliyor; 46-alan validator bugün yalnız metin sınırı uyguluyor. Yapısal saat doğrulaması gerekir. |
| 18 | `instagram` | metin | D | Doğrudan aday; şema ipucundaki `@ olmadan` davranışının validator kontratı ayrıca doğrulanacak. |
| 19 | `website` | url | D | Güvenli http/https URL. |
| 20 | `haritaLinki` | url | D | URL doğrulaması var; Google/Maps alanına özel domain kuralı henüz yok. |
| 21 | `enlem` | sayı | S | Next'te mevcut GPS konum akışı var; ham koordinat esnaf ana UX'i olmayacak. |
| 22 | `boylam` | sayı | S | Next'te mevcut GPS konum akışı var; ham koordinat esnaf ana UX'i olmayacak. |
| 23 | `kategoriBolumBaslik` | metin | D | Doğrudan kozmetik alan. |
| 24 | `urunBolumBaslik` | metin | D | Doğrudan kozmetik alan. |
| 25 | `bantEtiket` | metin | D/T | Kampanya gerçeği; kullanıcı söylemeden uydurulmaz. |
| 26 | `bantBaslik` | metin | D/T | Kampanya gerçeği; kullanıcı söylemeden uydurulmaz. |
| 27 | `bantAciklama` | uzunMetin | D/T | Kampanya gerçeği; kullanıcı söylemeden uydurulmaz. |
| 28 | `bantGorsel` | görsel | S/T | Upload/hazır görsel; kampanya yoksa otomatik üretilmez. |
| 29 | `bantFiyat` | metin | D/T | Fiyat/kampanya bilgisi kullanıcı gerçeğidir. |
| 30 | `hakkindaUstBaslik` | metin | D | Doğrudan kozmetik alan. |
| 31 | `hakkindaBaslik` | metin | D | Doğrudan alan; otomatik doldurma ayrı sistem politikasına tabidir. |
| 32 | `hakkindaMetin` | uzunMetin | D/T | İşletme hikâyesi; kullanıcı gerçeği, motor uyduramaz. |
| 33 | `hakkindaGorsel` | görsel | S/T | Upload/hazır görsel özel akışı. |
| 34 | `hakkindaGorselAlt` | metin | D | Doğrudan metin adayı. |
| 35 | `galeriUstBaslik` | metin | D | Doğrudan kozmetik alan. |
| 36 | `galeriBaslik` | metin | D | Doğrudan kozmetik alan. |
| 37 | `galeriAksiyonMetni` | metin | D | Doğrudan kozmetik alan. |
| 38 | `galeriAksiyonLinki` | url | D | http/https veya sayfa içi çapa destekli bağlantı alanı. |
| 39 | `blogUstBaslik` | metin | D/B | Yalnız public vitrindeki Blog bölüm başlığı; Blog içerik domain'i değildir. |
| 40 | `blogBaslik` | metin | D/B | Yalnız public vitrindeki Blog bölüm başlığı; Blog içerik domain'i değildir. |
| 41 | `sssUstBaslik` | metin | D | Doğrudan kozmetik alan. |
| 42 | `sssBaslik` | metin | D | Doğrudan kozmetik alan. |
| 43 | `sssAciklama` | uzunMetin | D | Doğrudan açıklama alanı. |
| 44 | `puanGoster` | açık/kapalı | P/S | Flutter doğal dil varyantını boolean'a çeviriyor; Next validator yalnız boolean kabul ediyor. Ortak toggle parser gerekir. |
| 45 | `yolTarifiGoster` | açık/kapalı | P/S | Aynı toggle parity açığı. |
| 46 | `referansLinki` | url | D | Doğrudan güvenli bağlantı alanı. |

## Alanlar üstü kanıtlanmış ortak açıklar

1. **Intent matcher:** Flutter ve Next serbest substring (`contains/includes`) kullanıyor. `tel` → `otel` gibi yanlış pozitif mümkün.
2. **Gerçek parity:** Mevcut “parity” testleri iki runtime'ı aynı fixture setinde gerçek sonuç karşılaştırmasıyla çalıştırmıyor.
3. **Niyet sözlüğü drift'i:** Next ortak JSON'u doğrudan okuyor; Flutter generated kopya aynı kaynağı işaretliyor fakat generator script henüz doğrulanamadı.
4. **Görsel URL kontratı:** Genel URL helper `#...` çapasını kabul ettiği için görsel tiplerinde de çapa geçerli sayılabiliyor; görsel için ayrı kural gerekir.
5. **Başarı semantiği:** Flutter companion/HomeShell kalıcı kayıt Future'ını beklemeden “Kaydettim/Kaydedildi” gösterebiliyor.
6. **Multi-field işlem:** Next alanları sırayla kaydediyor; tek doğal dil komutu atomik değil. Kısmi başarı kullanıcıya gösteriliyor, fakat LOCK'ta nihai politika seçilecek.
7. **State:** Flutter pending state hâlâ SharedPreferences; Next Supabase pending RPC kullanıyor.

## 46/46 geçiş kriteri

Her satır şu fixture sınıflarından geçmeden ✅ olmaz:

1. normal günlük Türkçe
2. Türkçe ekli alan adı (`telefonumu`, `adresimi` vb.)
3. bilinen yazım hatası
4. ilgisiz cümle / yanlış pozitif koruması
5. değer eksik → netleştirme
6. geçersiz değer → mutation yok
7. doğru değer → aynı normalized value
8. Flutter = Next intent/value/validation/action
9. gerçek persistence başarısı sonrası başarı mesajı
10. tekrar gönderim → ikinci mutation yok
11. uygun alanlarda undo
12. cihaz değişimi/pending devamlılığı
