-- Butik kategorisinin "El Yapımı Çanta" sablon gorseli, taninmis bir markanin
-- logolu urununu gosteriyordu. Bu sablondan acilan HER yeni vitrin o fotografi
-- devraliyordu -> marka riski.
--
-- Gorsel 2026-09-16'da depodan indirilip goz ile dogrulandi. Yerine logosuz
-- sade kahverengi deri canta fotografi konuldu (o da goz ile dogrulandi).
--
-- ACIK KALAN: eski dosya category-templates/butik/product-3-d25af6.jpg depoda
-- duruyor ama artik hicbir kayit onu gostermiyor; depodan silinmesi ayri is.
-- Ayrica bu satir 20260825000000'in "gorselleri kendi depomuzda tut" kuralindan
-- sapiyor. Dogru cozum yeni dosyayi depoya yukleyip image_url'i oraya cevirmek;
-- bu service_role anahtari gerektiriyor ve makinedeki anahtar gecersiz.

update public.category_image_templates
set image_url  = 'https://images.unsplash.com/photo-1691480150204-66dd1eb77391?w=600&q=80',
    source_url = 'https://images.unsplash.com/photo-1691480150204-66dd1eb77391?w=600&q=80',
    updated_at = now()
where category_key = 'butik'
  and image_type   = 'product'
  and source_url like '%1548036328%';
