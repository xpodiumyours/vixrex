-- ============================================================================
-- VixRex tohum verisi — supabase db reset sonunda calistirilir.
--
-- Yasal belgeler (gizlilik, kullanim sartlari, acik riza, veri silme).
-- Bunlar olmadan HICBIR vitrin yayinlanamaz: stores tetikleyicisi
-- PUBLICATION_CONSENT_REQUIRED firlatir.
--
-- NEDEN MIGRATION DEGIL DE BURADA
-- Belge metinlerinin icinde noktali virgul ve ters boluk var; hem Supabase
-- migration okuyucusu hem psql cumleyi orada boluyor ve sozdizimi hatasi
-- veriyor. Bu dosya pg_dump'in urettigi COPY bicimini kullanir — metin
-- kacislari dogru yapilmis hâlde.
-- ============================================================================

--
-- PostgreSQL database dump
--


-- Dumped from database version 17.6
-- Dumped by pg_dump version 17.10

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Data for Name: legal_documents; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.legal_documents (id, document_type, version, title, subtitle, sections, content_hash, is_active, effective_at, created_at) FROM stdin;
ce2742fb-c893-4e79-892d-432b3cd4ebc3	dataDeletion	data-deletion-2026-07-05	Hesap ve Veri Silme	Hesap, vitrin ve mağaza verilerinin silinmesi.	[{"body": "Hesap veya vitrin verilerinizin silinmesi için privacy@vixrex.app adresine talep gönderebilirsiniz.", "title": "Silme Talebi"}, {"body": "Yayınlama rızasını geri çektiğinizde vitrin yayından kaldırılır. Verilerin tamamen silinmesi için ayrıca veri silme talebi oluşturabilirsiniz.", "title": "Rızayı Geri Çekme"}]		t	2026-07-05 21:14:31.364122+00	2026-07-05 21:14:31.364122+00
99410de9-6a88-4d73-aa65-7ddc84ae69d7	privacy	privacy-2026-07-05	Gizlilik ve KVKK Politikası	Kişisel verilerin işlenmesine ilişkin aydınlatma metni.	[{"body": "Vixrex kapsamında kişisel verileriniz Xpodiumyours tarafından veri sorumlusu sıfatıyla işlenir.", "title": "Veri Sorumlusu"}, {"body": "Vitrin adı, açıklama, kategori, adres, il/ilçe, konum, iletişim bilgileri, sosyal bağlantılar, logo, galeri, ürün, hizmet, çalışma saatleri, hesap ve teknik kayıtlar işlenebilir.", "title": "İşlenen Veriler"}, {"body": "Gizlilik, KVKK ve veri silme talepleri için privacy@vixrex.app adresine ulaşabilirsiniz.", "title": "İletişim"}]		t	2026-07-05 21:14:31.364122+00	2026-07-05 21:14:31.364122+00
49fa6d9a-eb45-4bb1-a2cb-f6947e9523fe	terms	terms-2026-07-05	Kullanım Şartları	Vixrex platform kullanım kuralları.	[{"body": "Vixrex, kullanıcıların kendi işletme, ürün, hizmet, iletişim ve görsel içeriklerini dijital vitrin olarak yayınlayabildiği bir platformdur.", "title": "Platform Niteliği"}, {"body": "Vitrininize eklediğiniz işletme bilgileri, fiyatlar, ürün açıklamaları, bağlantılar ve görsellerden siz sorumlusunuz.", "title": "Kullanıcı Sorumluluğu"}, {"body": "Şartlar, içerik şikayeti veya hesap talepleri için privacy@vixrex.app adresine ulaşabilirsiniz.", "title": "İletişim"}]		t	2026-07-05 21:14:31.364122+00	2026-07-05 21:14:31.364122+00
cdf91ecb-1e8c-46e9-9c9c-9d315ad1bbf1	consent	consent-2026-07-05	Açık Rıza Beyanı	Vitrin bilgilerinin kamuya açık yayınlanmasına ilişkin beyan.	[{"body": "Vitrin oluştururken paylaştığım işletme bilgilerimin Vixrex üzerindeki dijital vitrinimde müşterilere açık şekilde yayınlanmasına açık rıza veriyorum.", "title": "Yayınlama Açık Rızası"}, {"body": "Bu rızayı vermediğimde yerel taslağımı düzenleyebileceğimi ancak herkese açık vitrin yayınlayamayacağımı; verdiğim rızayı daha sonra geri çekerek vitrini yayından kaldırabileceğimi biliyorum.", "title": "Tercih ve Geri Çekme"}]		t	2026-07-05 21:14:31.364122+00	2026-07-05 21:14:31.364122+00
\.


--
-- PostgreSQL database dump complete
--


