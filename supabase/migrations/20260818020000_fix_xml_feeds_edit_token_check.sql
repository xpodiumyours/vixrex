-- V-05 (attack-vectors.md, 2026-08-18): "xml_feeds" politikası edit_token'ın
-- VARLIĞINI kontrol ediyordu, DEĞERİNİ değil.
--
-- BULGU: "owner_xml_feeds" politikası ... OR s.edit_token IS NOT NULL
-- şeklindeydi. `edit_token` kolonunun varsayılanı boş metin ''
-- (bkz. temel şema :2062 — DEFAULT ''::text NOT NULL) ve boş metin de
-- NOT NULL sayılır. Yani bu kontrol pratikte HER store için doğru
-- çıkıyordu — giriş yapmış herhangi bir kullanıcı, sahibi olmadığı
-- HERHANGİ bir store'un xml_feeds kayıtlarını okuyabilir/yazabilirdi.
--
-- Token'ın DEĞERİNİ karşılaştırmak çıplak bir RLS politikasında mümkün
-- değil (istemciden gelen p_edit_token parametresine RLS'in erişimi yok).
-- Bu yüzden token bu şemada her yerde SECURITY DEFINER RPC fonksiyonları
-- üzerinden doğrulanıyor (bkz. public._check_store_authorization,
-- batch_create_products vb.) — çıplak tablo politikası değil.
--
-- Bugün hiçbir uygulama kodu (public_web/src, lib/) xml_feeds'i doğrudan
-- okumuyor/yazmıyor (grep: 0 eşleşme) — tablo şu an kullanılmıyor (latent).
-- İleride edit_token'lı (anonim) erişim gerekirse, aynı desenle
-- (_check_store_authorization çağıran bir RPC) eklenmeli; çıplak tablo
-- politikasına tekrar "IS NOT NULL" gibi bir kısayol konmamalı.
--
-- ÇÖZÜM: politika yalnız gerçek sahipliğe (auth.uid() = stores.user_id)
-- bağlanır.

DROP POLICY IF EXISTS "owner_xml_feeds" ON "public"."xml_feeds";

CREATE POLICY "owner_xml_feeds" ON "public"."xml_feeds"
  TO "authenticated"
  USING (EXISTS (
    SELECT 1 FROM "public"."stores" "s"
    WHERE "s"."id" = "xml_feeds"."store_id" AND "s"."user_id" = "auth"."uid"()
  ))
  WITH CHECK (EXISTS (
    SELECT 1 FROM "public"."stores" "s"
    WHERE "s"."id" = "xml_feeds"."store_id" AND "s"."user_id" = "auth"."uid"()
  ));

REVOKE ALL ON TABLE "public"."xml_feeds" FROM "anon";
