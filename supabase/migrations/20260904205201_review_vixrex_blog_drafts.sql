-- Katman 2.5.5 — Mevcut iki merkezi taslağın doğruluk/provenance güncellemesi
-- Yalnız draft satırlar değişir; bu migration hiçbir yazıyı yayınlamaz.

update public.vixrex_blog_articles
set
  summary = 'Kuaför ve berber salonları için tek bir işletme sayfasında hangi bilgilerin bulunmasının müşterinin işini kolaylaştırdığını adım adım anlatıyoruz.',
  content = $vixrex_blog$Bir kuaför salonunun internetteki sayfasının temel görevi, müşterinin karar vermeden önce ihtiyaç duyduğu bilgileri tek yerde ve kolay okunur biçimde göstermektir.

Sayfanızda hangi bilgiler bulunmalı?

İşletme adı ve sunduğunuz hizmetler. Müşteri sayfayı açtığında doğru işletmede olduğunu hemen anlayabilmeli. Örneğin saç kesimi, boya, bakım veya gelin saçı gibi temel hizmetleri açık adlarla listeleyin.

Adres ve konum. Müşterinin işletmeye nasıl ulaşacağını anlaması için açık adresi ve mümkünse harita bağlantısını gösterin.

Telefon veya WhatsApp bağlantısı. İletişim bilgisini yalnız düz metin olarak bırakmak yerine telefonda kolayca kullanılabilen bir bağlantı olarak sunmak müşterinin işini kolaylaştırır.

Çalışma saatleri. Güncel çalışma saatlerini ve kapalı olduğunuz günleri açıkça belirtin.

Hizmet ve fiyat bilgileri. Sabit fiyatınız varsa yazabilirsiniz. Fiyat işlem türüne göre değişiyorsa başlangıç fiyatı, fiyat aralığı veya net fiyat için iletişim gerektiğini açıkça belirtmek daha doğru olur.

Fotoğraflar. İşletmeyi, ortamı veya çalışmalarınızı gerçekten temsil eden güncel ve net görseller kullanın. Google da işletme profillerinde fotoğraf ve videoların müşterilere sunulan hizmetleri göstermeye yardımcı olabileceğini belirtiyor.

Instagram hesabı tek başına yeterli mi?

Sosyal medya müşterinin sizi keşfetmesine yardımcı olabilir. Ancak adres, çalışma saati, hizmetler ve iletişim gibi temel bilgiler zaman içinde gönderilerin arasında dağılabilir. Ayrı bir işletme sayfası bu bilgileri tek ve paylaşılabilir bir bağlantıda toplar.

Alan adı şart mı?

Başlangıç için zorunlu değildir. Önce işletme bilgilerinizin bulunduğu erişilebilir bir sayfanızın olması daha temel bir ihtiyaçtır. Daha sonra kendi alan adınızı kullanmak isteyebilirsiniz.

Vixrex'te ne yapabilirsiniz?

Vixrex vitrininizde işletme adınızı, iletişim ve konum bilgilerinizi, çalışma saatlerinizi, hizmetlerinizi ve görsellerinizi tek bir sayfada düzenleyebilirsiniz. Sayfanızı yayınlamadan önce bilgilerin doğru ve güncel olduğunu kontrol edin.

Arama motorlarında görünürlük garanti değildir. Google, SEO çalışmalarının arama motorlarının içeriği taramasını, dizine eklemesini ve anlamasını kolaylaştırabileceğini; ancak belirli bir sayfanın dizine girmesini veya belirli bir sırada görünmesini garanti etmediğini açıkça belirtir.$vixrex_blog$,
  source_urls = array[
    'https://support.google.com/business/answer/7091?hl=tr',
    'https://developers.google.com/search/docs/fundamentals/seo-starter-guide?hl=tr'
  ]::text[]
where slug = 'kuafor-icin-internet-sitesi'
  and status = 'draft';

update public.vixrex_blog_articles
set
  summary = 'İşletmenizin Google Arama ve Haritalar’daki yerel görünürlüğü için İşletme Profili doğrulaması, doğru bilgiler ve web sayfası tarafında uygulanabilecek temel adımları anlatıyoruz.',
  content = $vixrex_blog$“İşletmem Google’da neden görünmüyor?” sorusunun tek bir cevabı yoktur. Google’ın yerel sonuçları işletmenin bilgilerine, aramaya ve kullanıcının konumuna göre değişebilir. Yine de işletme sahibinin doğrudan kontrol edebildiği bazı temel adımlar vardır.

1. Google İşletme Profilinizi ekleyin veya sahiplenin

İşletmeniz için bir Google İşletme Profili oluşturabilir veya mevcut profili sahiplenebilirsiniz. Profil doğrulaması, Google’a işletmeyi temsil etme yetkiniz olduğunu bildirir.

Doğrulama yöntemi her işletmede aynı değildir. Kullanabileceğiniz yöntemleri Google otomatik belirler. İşletmenize göre telefon veya SMS, e-posta, video kaydı, canlı video ya da posta ile doğrulama seçeneklerinden biri veya birkaçı sunulabilir. Posta kartı tüm işletmeler için zorunlu veya kullanılabilir tek yöntem değildir.

2. İşletme bilgilerinizi eksiksiz ve güncel tutun

Google, eksiksiz ve doğru bilgilere sahip işletmelerin yerel sonuçlarda görünme olasılığının daha yüksek olduğunu belirtiyor. İşletmenize uygunsa açık adres, çalışma saatleri, işletme kategorisi ve diğer temel bilgileri doğru girin.

Kategori seçerken işletmenizi gerçekte en iyi tanımlayan kategoriyi kullanın. Ayrıca fotoğraf ve videolar işletmenizin sunduklarını müşterilere göstermeye yardımcı olabilir.

3. Kendi işletme sayfanızda anlaşılır bilgiler yayınlayın

Web sayfanızda işletme adınızı, sunduğunuz hizmetleri, konum ve iletişim bilgilerinizi kullanıcıların kolay anlayacağı biçimde gösterin. Sayfa başlığı ve içerik gerçekten sunduğunuz hizmeti açıklamalıdır.

Google’ın SEO rehberine göre SEO’nun amacı arama motorlarının içeriğinizi anlamasını ve kullanıcıların sitenizi bulmasını kolaylaştırmaktır. Ancak bir sitenin Google dizinine alınacağı veya belirli bir sıraya çıkacağı garanti edilmez.

4. Yerel sıralamanın nasıl belirlendiğini bilin

Google, yerel sonuçların ağırlıklı olarak üç ana faktöre dayandığını açıklıyor: alaka düzeyi, mesafe ve belirginlik/popülerlik.

Alaka düzeyi, işletme profilinizin yapılan aramayla ne kadar iyi eşleştiğidir. Eksiksiz işletme bilgileri Google’ın işletmenizi daha iyi anlamasına yardımcı olabilir.

Mesafe, işletmenin arama yapan kişiye veya aramada belirtilen konuma uzaklığıyla ilgilidir.

Belirginlik ise işletmenin ne kadar bilindiğiyle ilgilidir. Google; web üzerindeki bağlantılar, işletme hakkındaki bilgiler ve yorumlar gibi sinyalleri bu kapsamda değerlendirebilir.

Ne kadar sürede görünürüm?

Bunun için güvenilir bir “bir hafta” veya “bir ay” garantisi yoktur. Google, yapılan değişikliklerin etkisinin bazı durumlarda saatler içinde, bazı durumlarda ise aylar içinde görülebileceğini; ayrıca belirli bir sayfanın dizine alınmasının garanti edilmediğini belirtir.

Bu nedenle sabit bir süre vaat etmek yerine İşletme Profilinizin doğrulanmış ve güncel olduğundan, web sayfanızın erişilebilir olduğundan ve bilgilerinizin kullanıcıya açık biçimde sunulduğundan emin olun.$vixrex_blog$,
  source_urls = array[
    'https://support.google.com/business/answer/7107242?hl=tr',
    'https://support.google.com/business/answer/7091?hl=tr',
    'https://developers.google.com/search/docs/fundamentals/seo-starter-guide?hl=tr'
  ]::text[]
where slug = 'isletmemi-googleda-nasil-gosteririm'
  and status = 'draft';