-- VixRex Yasal Belgeler (Aktif Versiyon)
-- Tarih: 2026-07-07
-- Durum: Şirket bilgileri eklenecek

-- ============================================
-- 1. GİZLİLİK VE KVKK POLİTİKASI
-- ============================================

INSERT INTO public.legal_documents (
  document_type, version, title, subtitle, sections, is_active, effective_at
)
VALUES
(
  'privacy',
  'privacy-2026-07-07-v1',
  'Gizlilik ve KVKK Politikası',
  'Kişisel verilerin işlenmesine ilişkin aydınlatma metni.',
  '[
    {
      "title": "Veri Sorumlusu",
      "body": "VixRex kapsamında kişisel verileriniz [ŞİRKET ÜNVANI] tarafından veri sorumlusu sıfatıyla işlenir. Adres: [ADRES]. E-posta: [E-POSTA]."
    },
    {
      "title": "İşlenen Veriler",
      "body": "Vitrin adı, açıklama, kategori, adres, il/ilçe, konum, iletişim bilgileri (telefon, WhatsApp), sosyal bağlantılar, logo, galeri görselleri, ürün ve hizmet bilgileri, çalışma saatleri, hesap bilgileri (e-posta, şifre hash), teknik kayıtlar (IP, cihaz bilgisi, oturum geçmişi) işlenebilir."
    },
    {
      "title": "İşleme Amaçları",
      "body": "Kişisel verileriniz şu amaçlarla işlenir: (1) Vitrin oluşturma ve yönetme hizmetinin sunulması, (2) Müşterilerinizin sizi bulmasını sağlamak, (3) Randevu yönetimi, (4) Platform güvenliğinin sağlanması, (5) Yasal yükümlülüklerin yerine getirilmesi."
    },
    {
      "title": "Hukuki Sebep",
      "body": "Veri işlemenin hukuki sebepleri: (1) Sözleşmenin ifası (KVKK m.5/2-c), (2) Açık rıza (KVKK m.5/1), (3) Meşru menfaat (KVKK m.5/2-f) - platform güvenliği için."
    },
    {
      "title": "Veri Saklama Süresi",
      "body": "Hesabınız aktif olduğu sürece verileriniz saklanır. Hesap silindiğinde tüm veriler 30 gün içinde kalıcı olarak silinir. Zorunlu yasal saklama süreleri hariç."
    },
    {
      "title": "Üçüncü Taraf Aktarımı",
      "body": "Verileriniz şu üçüncü taraflarla paylaşılabilir: (1) Supabase - veritabanı ve barındırma hizmeti, (2) Vercel - web barındırma hizmeti, (3) Google - harita ve konum hizmetleri. Üçüncü taraflar yalnızca hizmetin sunulması amacıyla veri işler."
    },
    {
      "title": "Instagram Entegrasyonu",
      "body": "Instagram hesabınızı bağlamanız halinde, yalnızca açıkça izin verdiğiniz veriler Meta/Instagram APIleri üzerinden işlenir. Bu kapsamda kullanıcı adınız, hesap türünüz, izin kapsamları, medya içerikleriniz işlenebilir. Token bilgileriniz sunucu tarafında şifreli saklanır. Bağlantıyı kestiğinizde token bilgileriniz silinir."
    },
    {
      "title": "Çerezler",
      "body": "Platformumuz temel oturum çerezleri kullanır. Üçüncü taraf çerez veya izleme teknolojisi kullanılmaz. Oturum çerezleri yalnızca giriş işlemleriniz için gereklidir."
    },
    {
      "title": "Haklarınız (KVKK m.11)",
      "body": "KVKK kapsamında şu haklara sahipsiniz: (1) Kişisel verilerinizin işlenip işlenmediğini öğrenme, (2) İşlenen verileriniz hakkında bilgi talep etme, (3) İşlenme amacını ve amacına uygun kullanılıp kullanılmadığını öğrenme, (4) Yurt içinde veya yurt dışında aktarıldığı üçüncü kişileri bilme, (5) Eksik veya yanlış işlenmiş verilerin düzeltilmesini isteme, (6) Verilerinizin silinmesini veya yok edilmesini isteme, (7) Aktarıldığı üçüncü kişilere bildirilmesini isteme, (8) Otomatik sistemlerle analiz edilmesine itiraz etme, (9) Zarara uğramanız halinde tazminat talep etme."
    },
    {
      "title": "Talepleriniz İçin",
      "body": "KVKK kapsamındaki taleplerinizi [E-POSTA] adresine gönderebilirsiniz. Talebiniz 30 gün içinde yanıtlanır. Kimlik doğrulaması yapılabilir."
    },
    {
      "title": "Değişiklikler",
      "body": "Bu politika güncellendiğinde platform üzerinden bildirilir. Güncel politika her zaman erişilebilir olacaktır."
    }
  ]'::jsonb,
  true,
  NOW()
)
ON CONFLICT (document_type, version) DO NOTHING;

-- ============================================
-- 2. KULLANIM ŞARTLARI
-- ============================================

INSERT INTO public.legal_documents (
  document_type, version, title, subtitle, sections, is_active, effective_at
)
VALUES
(
  'terms',
  'terms-2026-07-07-v1',
  'Kullanım Şartları',
  'VixRex platform kullanım kuralları ve koşulları.',
  '[
    {
      "title": "Platform Niteliği",
      "body": "VixRex, küçük işletmelerin ürünlerini, hizmetlerini ve iletişim bilgilerini dijital vitrin olarak yayınlayabildiği bir platformdur. Platform yalnızca vitrin oluşturma ve yönetme hizmeti sunar; satış, ödeme veya kargo işlemi yapmaz."
    },
    {
      "title": "Hesap Oluşturma",
      "body": "Platformu kullanmak için geçerli bir e-posta adresi ile hesap oluşturmanız gerekir. Hesap güvenliği sizin sorumluluğunuzdadır. Hesabınızın yetkisiz kullanımını fark ettiğinizde hemen bize bildirmelisiniz."
    },
    {
      "title": "Kullanıcı Yükümlülükleri",
      "body": "Kullanıcı olarak şu yükümlülükleri kabul edersiniz: (1) Doğru ve güncel bilgi sağlamak, (2) Hukuka uygun içerik paylaşmak, (3) Başkalarının haklarını ihlal etmemek, (4) Platformu kötüye kullanmamak, (5) Diğer kullanıcılara saygılı olmak."
    },
    {
      "title": "İçerik Sorumluluğu",
      "body": "Paylaştığınız tüm içeriklerden (ürün, hizmet, fiyat, görsel, açıklama) siz sorumlusunuz. Hukuka aykırı, yanıltıcı veya yanıltıcı içerik paylaşmak yasaktır. VixRex, uygunsuz içerikleri kaldırma hakkını saklı tutar."
    },
    {
      "title": "Fikri Mülkiyet",
      "body": "VixRex logosu, tasarımı ve yazılımı [ŞİRKET ÜNVANI]'na aittir. Kullanıcılar, kendi içeriklerinin fikri mülkiyet haklarını korur. VixRex, kullanıcı içeriklerini yalnızca platform hizmetini sunmak amacıyla kullanır."
    },
    {
      "title": "Sorumluluk Sınırı",
      "body": "VixRex: (1) Kullanıcı içeriklerinin doğruluğundan sorumlu değildir, (2) Üçüncü taraf hizmetlerinden kaynaklanan arızalardan sorumlu değildir, (3) Kullanıcılar arasındaki anlaşmazlıklara karışmaz, (4) Dolaylı veya sonuç zararlarından sorumlu değildir."
    },
    {
      "title": "Hesap Askıya Alma ve Sonlandırma",
      "body": "VixRex, kuralları ihlal eden hesapları askıya alma veya sonlandırma hakkını saklı tutar. Kullanıcı kendi hesabını istediği zaman silebilir. Hesap silindiğinde tüm veriler kalıcı olarak silinir."
    },
    {
      "title": "Değişiklikler",
      "body": "Bu şartlar güncellendiğinde kullanıcılar bilgilendirilir. Güncel şartları kabul etmeyen kullanıcılar hesaplarını silebilir."
    },
    {
      "title": "Uyuşmazlıklar",
      "body": "Bu şartlardan doğan uyuşmazlıklarda İstanbul mahkemeleri ve icra daireleri yetkilidir."
    }
  ]'::jsonb,
  true,
  NOW()
)
ON CONFLICT (document_type, version) DO NOTHING;

-- ============================================
-- 3. AÇIK RIZA BEYANI
-- ============================================

INSERT INTO public.legal_documents (
  document_type, version, title, subtitle, sections, is_active, effective_at
)
VALUES
(
  'consent',
  'consent-2026-07-07-v1',
  'Açık Rıza Beyanı',
  'Vitrin bilgilerinin kamuya açık yayınlanmasına ilişkin rıza.',
  '[
    {
      "title": "Yayınlama Açık Rızası",
      "body": "Vitrin oluştururken paylaştığım mağaza adı, açıklama, kategori, adres, konum, iletişim bilgileri, sosyal bağlantılar, logo, galeri, ürün, hizmet ve çalışma saatlerinin VixRex üzerindeki dijital vitrinimde kamuya açık şekilde yayınlanmasına açık rıza veriyorum."
    },
    {
      "title": "Verilerin Görünürlüğü",
      "body": "Yayınlanan vitrin bilgileri herkese açıktır ve Keşfet bölümünde, QR kod ile veya doğrudan link ile görüntülenebilir. Bu bilgiler arama motorları tarafından indekslenebilir."
    },
    {
      "title": "Geri Çekme Hakkı",
      "body": "Bu rızamı her zaman geri çekebilirim. Rıza geri çekildiğinde vitrinim yayından kaldırılır ancak verilerim hesabım silinene kadar saklanır."
    },
    {
      "title": "Rıza Olmadan Kullanım",
      "body": "Bu rızayı vermediğimde yerel taslağımı düzenleyebileceğimi ancak herkese açık vitrin yayınlayamayacağımı biliyorum."
    }
  ]'::jsonb,
  true,
  NOW()
)
ON CONFLICT (document_type, version) DO NOTHING;

-- ============================================
-- 4. HESAP VE VERİ SİLME
-- ============================================

INSERT INTO public.legal_documents (
  document_type, version, title, subtitle, sections, is_active, effective_at
)
VALUES
(
  'dataDeletion',
  'data-deletion-2026-07-07-v1',
  'Hesap ve Veri Silme',
  'Hesap, vitrin ve kişisel verilerin silinmesine ilişkin bilgilendirme.',
  '[
    {
      "title": "Hesap Silme",
      "body": "Hesabınızı uygulama içinden silebilirsiniz. Hesap silindiğinde tüm verileriniz (vitrin, ürün, galeri, randevu geçmişi) 30 gün içinde kalıcı olarak silinir."
    },
    {
      "title": "Veri Silme Talebi",
      "body": "Hesap silme dışında ek veri silme talebiniz varsa [E-POSTA] adresine yazabilirsiniz. Talebiniz 30 gün içinde değerlendirilir."
    },
    {
      "title": "Silinmeyen Veriler",
      "body": "Yasal yükümlülükler kapsamında bazı veriler belirli sürelerle saklanabilir (fatura, muhasebe kayıtları). Bu veriler yalnızca yasal zorunluluk kapsamında saklanır."
    },
    {
      "title": "Silme Sonrası",
      "body": "Veriler silindikten sonra geri yükleme mümkün değildir. Public vitrin linkiniz artık çalışmayacaktır."
    }
  ]'::jsonb,
  true,
  NOW()
)
ON CONFLICT (document_type, version) DO NOTHING;
