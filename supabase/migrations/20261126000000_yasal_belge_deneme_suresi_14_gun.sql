-- ============================================================================
-- Yasal belge metinleri — misafir (hesaba bağlanmamış) kiralık vitrin
-- otomatik silinme süresi tek tutarlı ifadeye getirildi (2026-11-26)
-- ============================================================================
-- Gerçek davranış (supabase/migrations/20260817010000_premium_deneme_suresi.sql):
--   cleanup_expired_trial_clones — "Bu vitrini kirala" denemesi, hiç premium
--   almamışsa ve yayınlanmamışsa 14 gününden eskiyse silinir (30 saat → 14 gün).
--
-- Aktif legal_documents satırlarında (privacy / terms / consent) "30 saat"
-- ifadesi hâlâ bulunuyordu; yasal metin ile gerçek temizlik eşiği çelişiyordu.
-- Bu migration, içerikteki "30 saat" ifadelerini "14 gün" ile günceller ve
-- yeni versiyonları aktif yapar. (Uygulanmış migration'lar ASLA değiştirilmez —
-- VIXREX_RULES §9; dolayısıyla mevcut aktif satırlar pasife çekilir, yeni
-- sürümler is_active=true ile eklenir. trg_set_legal_document_hash
-- ACTIVE_LEGAL_DOCUMENT_ISMUTABLE kuralı aktif satırların içerik değiştirilmesini
-- engeller — yeni sürüm INSERT'i bu yüzden güvenli ve hash tetikleyicisi yeniden
-- hesaplar.)
--

update public.legal_documents set is_active = false where is_active = true;

-- ─────────────────────────────────────────────────────────────────────
-- 1) AYDINLATMA METNİ (KVKK m.10) — yeni sürüm
-- ─────────────────────────────────────────────────────────────────────
insert into public.legal_documents
  (document_type, version, title, subtitle, sections, content_hash, is_active, effective_at)
values (
  'privacy',
  'privacy-2026-11-26',
  'Kişisel Verilerin Korunması ve İşlenmesi Aydınlatma Metni',
  '6698 sayılı Kişisel Verilerin Korunması Kanunu kapsamında hazırlanmıştır.',
  '[
    {
      "title": "Veri Sorumlusu",
      "body": "Kişisel verileriniz, veri sorumlusu sıfatıyla Aksakal Ticaret (Furkan Aksakal) tarafından işlenmektedir. Adres: Esenevler Mah. Lokman Hekim Cad. No:18 İç Kapı No:10 Ümraniye/İstanbul. Vergi Dairesi: Ümraniye, Vergi No: 0340472476. E-posta: destek@vixrex.com. Telefon: 0542 180 25 73."
    },
    {
      "title": "İşlenen Kişisel Veriler",
      "body": "Kimlik ve iletişim verileri (ad, e-posta, telefon), işletme verileri (vitrin adı, açıklama, kategori, adres, il/ilçe, konum, çalışma saatleri, ürün ve hizmet bilgileri, görseller, sosyal medya bağlantıları), işlem güvenliği verileri (IP adresi, oturum kayıtları, çerez kayıtları, tarayıcı bilgisi) ve varsa ödeme işlemine ilişkin sipariş kayıtları işlenmektedir. Kart bilgileri tarafımızca saklanmaz; ödeme kuruluşu üzerinden işlenir."
    },
    {
      "title": "İşleme Amaçları",
      "body": "Üyelik oluşturma ve hesap yönetimi, dijital vitrinin oluşturulması ve yayınlanması, hizmetin sunulması ve iyileştirilmesi, talep ve şikayetlerin karşılanması, hizmet güvenliğinin sağlanması ve kötüye kullanımın önlenmesi, yasal yükümlülüklerin yerine getirilmesi, varsa ücretlendirme ve faturalandırma süreçlerinin yürütülmesi amaçlarıyla işlenir."
    },
    {
      "title": "Hukuki Sebep",
      "body": "Kişisel verileriniz KVKK m.5 uyarınca; sözleşmenin kurulması veya ifasıyla doğrudan doğruya ilgili olması (m.5/2-c), veri sorumlusunun hukuki yükümlülüğünü yerine getirmesi (m.5/2-ç), ilgili kişinin kendisi tarafından alenileştirilmiş olması (m.5/2-d) ve veri sorumlusunun meşru menfaati (m.5/2-f) hukuki sebeplerine dayanılarak işlenir. Bu sebeplere dayanmayan işlemeler açık rızanıza tabidir."
    },
    {
      "title": "Toplama Yöntemi",
      "body": "Veriler; web sitesi ve mobil uygulama üzerinden doğrudan sizin tarafınızdan girilen bilgiler, Vixrex Asistan ile yürütülen kurulum akışı, çerezler ve benzeri teknolojiler ile otomatik veya kısmen otomatik yollarla toplanır."
    },
    {
      "title": "Yurt Dışına Aktarım",
      "body": "Hizmetin sunulabilmesi için veriler, sunucu ve altyapı hizmeti alınan yurt dışında yerleşik hizmet sağlayıcıların (veritabanı ve barındırma altyapısı) sistemlerinde işlenmekte ve saklanmaktadır. Bu aktarım KVKK m.9 kapsamında, hizmetin ifası için zorunlu olduğu ölçüde ve açık rızanız alınarak gerçekleştirilir. Vitrininiz yayınlandığında, vitrinde yer verdiğiniz bilgiler internet üzerinden herkese açık hale gelir."
    },
    {
      "title": "Saklama Süreleri",
      "body": "Hesap ve vitrin verileri, üyeliğiniz devam ettiği sürece saklanır. Hesabınızı sildiğinizde hesap, vitrin, ürün, blog ve randevu kayıtlarınız sistemden silinir. Kiralanan deneme vitrinleri, hesaba bağlanmamışsa 14 gün sonra otomatik olarak silinir. İşlem güvenliği ve oturum kayıtları en fazla 12 ay saklanır. Faturalandırma ve muhasebe kayıtları, vergi mevzuatı gereği 5 yıl; ticari defter ve belgeler Türk Ticaret Kanunu uyarınca 10 yıl saklanır. Yasal saklama süresi dolan veriler periyodik imha ile silinir."
    },
    {
      "title": "Haklarınız",
      "body": "KVKK m.11 uyarınca; kişisel verinizin işlenip işlenmediğini öğrenme, işlenmişse buna ilişkin bilgi talep etme, işlenme amacını ve amaca uygun kullanılıp kullanılmadığını öğrenme, yurt içinde veya yurt dışında aktarıldığı üçüncü kişileri bilme, eksik veya yanlış işlenmişse düzeltilmesini isteme, silinmesini veya yok edilmesini isteme, düzeltme/silme işlemlerinin aktarıldığı üçüncü kişilere bildirilmesini isteme, münhasıran otomatik sistemlerle analiz edilmesi suretiyle aleyhinize bir sonuç doğmasına itiraz etme ve kanuna aykırı işleme sebebinden zarara uğramanız hâlinde zararın giderilmesini talep etme haklarına sahipsiniz."
    },
    {
      "title": "Başvuru",
      "body": "Haklarınıza ilişkin taleplerinizi destek@vixrex.com adresine iletebilirsiniz. Başvurular en geç 30 gün içinde sonuçlandırılır. Talebiniz reddedilirse veya yanıt verilmezse Kişisel Verileri Koruma Kurulu''na şikayette bulunma hakkınız saklıdır."
    }
  ]'::jsonb,
  encode(sha256('privacy-2026-11-26'::bytea), 'hex'),
  true,
  now()
);

-- ─────────────────────────────────────────────────────────────────────
-- 2) KULLANIM ŞARTLARI — işletme korumaları burada
-- ─────────────────────────────────────────────────────────────────────
insert into public.legal_documents
  (document_type, version, title, subtitle, sections, content_hash, is_active, effective_at)
values (
  'terms',
  'terms-2026-11-26',
  'Kullanım Şartları',
  'Vixrex platformunu kullanarak bu şartları kabul etmiş olursunuz.',
  '[
    {
      "title": "Taraflar ve Hizmet",
      "body": "Vixrex, Esenevler Mah. Lokman Hekim Cad. No:18 İç Kapı No:10 Ümraniye/İstanbul adresinde faaliyet gösteren Aksakal Ticaret (Furkan Aksakal, Ümraniye Vergi Dairesi, Vergi No: 0340472476) tarafından işletilen; kullanıcıların kendi işletme, ürün, hizmet ve iletişim bilgilerini dijital vitrin olarak yayınlayabildiği bir yazılım hizmetidir. Vixrex bir pazaryeri değildir; satış, tahsilat, kargo ve iade süreçlerine taraf olmaz. Müşteriyle kurulan her ticari ilişki işletme sahibi ile müşteri arasındadır."
    },
    {
      "title": "Hesap ve Kullanım",
      "body": "Hesap açan kullanıcı, verdiği bilgilerin doğru ve güncel olduğunu kabul eder. Hesap güvenliğinden ve hesabı üzerinden yapılan işlemlerden kullanıcı sorumludur. Bir hesap ile bir vitrin açılabilir."
    },
    {
      "title": "İçerik Sorumluluğu",
      "body": "Vitrin eklenen işletme bilgileri, fiyatlar, ürün ve hizmet açıklamaları, görseller, bağlantılar ve tüm içerikten yalnızca kullanıcı sorumludur. Kullanıcı, yüklediği içerik üzerinde gerekli haklara sahip olduğunu; içeriğin üçüncü kişilerin fikri mülkiyet, kişilik veya ticari haklarını ihlal etmediğini beyan eder. Yanıltıcı fiyat, taklit ürün, yasa dışı mal ve hizmet tanıtımı yasaktır. Vixrex içeriği önceden denetlemekle yükümlü değildir; ihlal bildirimi üzerine içeriği kaldırma hakkını saklı tutar."
    },
    {
      "title": "Ücretlendirme ve Fiyat Değişikliği",
      "body": "Hizmetin ücretli paketleri, yayımlanan güncel fiyat listesi üzerinden sunulur. Vixrex, hizmet bedellerinde değişiklik yapma hakkını saklı tutar. Fiyat değişiklikleri, yürürlüğe girmeden en az 30 gün önce kullanıcıya e-posta veya uygulama içi bildirim ile duyurulur. Bildirimi takiben abonelik dönemini sürdüren kullanıcı yeni fiyatı kabul etmiş sayılır. Yeni fiyatı kabul etmeyen kullanıcı, bildirim tarihinden itibaren ücretsiz ve cezai şart ödemeksizin aboneliğini feshedebilir. Devam eden ödenmiş dönem için fiyat değişikliği uygulanmaz."
    },
    {
      "title": "Abonelik Süresi ve Fesih",
      "body": "Abonelikler belirsiz sürelidir. Kullanıcı, aboneliğini herhangi bir gerekçe göstermeden, cezai şart ödemeksizin dilediği zaman feshedebilir; fesih, içinde bulunulan ödenmiş dönemin sonunda yürürlüğe girer ve o döneme ait ücret iade edilmez. Ücretsiz deneme vitrinleri, hesaba bağlanmamışsa 14 gün sonra otomatik silinir."
    },
    {
      "title": "Hizmetin Askıya Alınması ve Sona Erdirilmesi",
      "body": "Vixrex; bu şartların ihlali, yasa dışı veya yanıltıcı içerik, ödeme yükümlülüğünün yerine getirilmemesi, sistemin güvenliğini tehdit eden kullanım veya üçüncü kişilerin haklarını ihlal eden davranış hâllerinde hesabı askıya alma veya sona erdirme hakkına sahiptir. Ağır ihlal ve hukuka aykırılık hâlleri dışında, askıya alma öncesinde kullanıcıya durumu düzeltmesi için makul süre tanınır."
    },
    {
      "title": "Hizmet Sürekliliği ve Değişiklikler",
      "body": "Vixrex, hizmetin kesintisiz ve hatasız sunulacağını taahhüt etmez. Bakım, güncelleme, altyapı sağlayıcı kaynaklı arıza veya mücbir sebep hâllerinde geçici kesintiler yaşanabilir. Vixrex, hizmetin kapsamında ve özelliklerinde değişiklik yapma hakkını saklı tutar; kullanıcı aleyhine esaslı değişiklikler önceden duyurulur."
    },
    {
      "title": "Sorumluluğun Sınırı",
      "body": "Vixrex, kullanıcının vitrininde yer verdiği bilgilerden, müşterileriyle kurduğu ticari ilişkiden, üçüncü kişilerin eylemlerinden ve dolaylı zararlardan (kâr kaybı, iş kaybı, veri kaybı, itibar zararı) sorumlu değildir. Vixrex''in her hâlükârda sorumluluğu, zararın doğduğu tarihten önceki son 12 ayda kullanıcının ödediği toplam hizmet bedeliyle sınırlıdır. Bu sınırlama, kanunen sınırlandırılamayan sorumluluk hâlleri bakımından uygulanmaz."
    },
    {
      "title": "Fikri Mülkiyet",
      "body": "Vixrex adı, markası, arayüzü, yazılımı ve tasarımı üzerindeki haklar Aksakal Ticaret''e aittir. Kullanıcı, hizmeti kullanma hakkı dışında herhangi bir hak elde etmez. Kullanıcının yüklediği içerikler kendisine aittir; kullanıcı, hizmetin sunulabilmesi için bu içeriklerin barındırılması ve görüntülenmesi amacıyla Vixrex''e sınırlı ve ücretsiz kullanım izni verir."
    },
    {
      "title": "Şartlardaki Değişiklikler",
      "body": "Bu şartlar güncellenebilir. Esaslı değişiklikler yürürlüğe girmeden önce kullanıcıya bildirilir. Bildirimden sonra hizmeti kullanmaya devam eden kullanıcı, güncellenmiş şartları kabul etmiş sayılır."
    },
    {
      "title": "Uyuşmazlık ve Uygulanacak Hukuk",
      "body": "Bu şartlara Türkiye Cumhuriyeti hukuku uygulanır. Uyuşmazlıklarda İstanbul Anadolu Mahkemeleri ve İcra Daireleri yetkilidir. Tüketici sıfatını haiz kullanıcılar bakımından, ilgili parasal sınırlar dâhilinde Tüketici Hakem Heyetleri ve tüketicinin yerleşim yerindeki tüketici mahkemeleri yetkilidir."
    },
    {
      "title": "İletişim",
      "body": "Şartlar, içerik şikayeti, fesih ve hesap talepleri için destek@vixrex.com adresine veya 0542 180 25 73 numarasına ulaşabilirsiniz."
    }
  ]'::jsonb,
  encode(sha256('terms-2026-11-26'::bytea), 'hex'),
  true,
  now()
);

-- ─────────────────────────────────────────────────────────────────────
-- 3) AÇIK RIZA — aydınlatma metninden AYRI belge (KVKK Kurulu 2026-347)
-- ─────────────────────────────────────────────────────────────────────
insert into public.legal_documents
  (document_type, version, title, subtitle, sections, content_hash, is_active, effective_at)
values (
  'consent',
  'consent-2026-11-26',
  'Açık Rıza Metni',
  'Aydınlatma metnini okuduktan sonra onayınıza sunulur.',
  '[
    {
      "title": "Yurt Dışına Aktarım Rızası",
      "body": "Aydınlatma metnini okudum. Vitrinimin yayınlanabilmesi ve hizmetin sunulabilmesi amacıyla kişisel verilerimin ve işletme bilgilerimin, sunucu ve barındırma hizmeti alınan yurt dışında yerleşik hizmet sağlayıcıların sistemlerinde işlenmesine ve saklanmasına açık rıza veriyorum."
    },
    {
      "title": "Yayınlama Rızası",
      "body": "Vitrinimde yer verdiğim işletme adı, adres, iletişim bilgileri, görseller, ürün ve hizmet bilgilerinin internet üzerinden herkese açık şekilde yayınlanmasına, arama motorlarınca dizinlenmesine ve Keşfet sayfasında listelenmesine açık rıza veriyorum. Bu rızayı dilediğim zaman geri çekebileceğimi, geri çekmem hâlinde vitrinimin yayından kaldırılacağını biliyorum."
    }
  ]'::jsonb,
  encode(sha256('consent-2026-11-26'::bytea), 'hex'),
  true,
  now()
);
