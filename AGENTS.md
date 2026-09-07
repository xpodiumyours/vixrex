# Vixrex — ajan çalışma standardı

Bu standart ChatGPT, Codex ve Claude'un Vixrex işlerini uygulaması ve teslim etmesi içindir. Kullanıcının güncel açık isteği önceliklidir. Kaynak: kullanıcının 7 Eylül 2026 tarihli güvenli ve verimli çalışma standardı oluşturma isteği. Bu dosya yeni ürün kararları veya geçmişe dönük kullanıcı onayları üretmez.

## Doğruluk

- Bilmediğin veya emin olmadığın bir şeyi tahmin ederek gerçekmiş gibi cevaplama. Doğrulayamıyorsan açıkça belirt; gerekli eksik bilgiyi sor.
- Gerçek bilgi, kullanıcının bildirimi ve kendi önerini ayrı tut. Çalıştırmadığın kodu veya testi çalışıyor/geçti diye sunma.
- Gereksiz övgü, özür, uzun açıklama ve tekrar ekleme. Kullanıcıdan log, ekran veya talimat taşımasını istemeden önce erişebildiğin araçları kullan.

## Ürün hedefi

- Flutter Web, görünüm ve davranış için referanstır. Next.js buna eşitlenecek hedef uygulamadır. Referansın hangi commit ve akış olduğunu işe başlarken kaydet.
- Tek uygulama ve tek veri kaynağı hedefini koru. Sırf testi geçirmek için Flutter referansını değiştirme; paralel kayıt/oturum/taslak yolu veya yeni veri kaynağı üretme.
- Mevcut `shared/` sözleşmelerini ve veri erişimini incele. Flutter ve Next farklı dillerde olduğu için ortak davranışın kendiliğinden sağlandığını varsayma.

## İşin yürütülmesi

1. Önce [çalışma akışını](docs/calisma-standardi.md) oku. İşe ait PR ve son durum kaydı varsa oradan devam et; biten işi yeniden başlatma.
2. Güncel uzak main'i doğrula. Her iş ayrı `codex/...` dalı ve ayrı temiz çalışma kopyasında yapılır. Başka ajanın dosyalarını silme, üzerine yazma veya topluca commit etme.
3. Tek aktif teslimat adayı kullan. Aynı iş için yeni PR zinciri açmadan mevcut PR'ı incele. Alt ajan kullanımı yalnız kullanıcının açık isteğiyle yapılır.
4. İstenen işi uygulamak, doğrulamak ve istek main'e teslimatı kapsıyorsa teslim etmek için tekrar tekrar izin isteme. Yeni ürün kararı, kapsam genişlemesi, açıkça yetkilendirilmemiş geri döndürülemez işlem veya gerekli erişim eksikliği varsa yalnız o noktayı sor.
5. Önce ortam/koşucu/temel sürüm kontrolü; sonra hedefli düzeltme; sonra değişen yüzeyin gerekli doğrulaması. Başarısız ön koşulu uzun testlerle aşmaya çalışma.
6. Aynı SHA + aynı ortam + aynı hata için yeni kanıt olmadan tekrar yok. Geçici altyapı hatasında en fazla bir otomatik tekrar; kalıcı kota ve çevrimdışı koşucuda tekrar yok. Gerekli testi atlayarak başarı verme.
7. Testi veya referansı değiştirerek hatayı gizleme. Kabul ölçütü değişecekse kullanıcı kararı gerekir. Testin yanlış olduğunu düşünüyorsan kanıtla.
8. Geliştirme sırasında Vercel'e her denemede yayın gönderme. Yerel build ve tarayıcı doğrulaması kullan; hazır sürümü yayınla. Var olan otomatik yayın ayarını kontrol etmeden push'un ücretsiz olduğunu varsayma.
9. PR açmayı bitiş sayma. Kontrollerin sonucunu takip et, hatayı sınıflandır, yetkili teslimatı tamamla veya somut engeli ve sonraki adımı kaydet. Çalışan bir otomasyon kurulmamışsa arka planda takip sözü verme.
10. Test edilen adayın SHA'sı ile teslim edilen PR başını eşleştir; squash sonrası main commit'inin farklı olacağını bil. Birleşim, yayın ve canlı doğrulama ayrı sonuçlardır.

## Kullanıcıya sonuç

En fazla birkaç satır: yapılan iş; PR/main durumu; gerçekten çalıştırılan doğrulama; varsa tek somut engel ve sonraki adım. Kanıtı bağlantıyla ver. Yalnız dosya hazırladıysan 'hazırlandı', main'e girdiyse 'main'de', doğru canlı sürümü gördüysen 'yayında doğrulandı' de.

Kalıcı durum kaydı ve teslimat ölçütleri: [docs/calisma-standardi.md](docs/calisma-standardi.md).
