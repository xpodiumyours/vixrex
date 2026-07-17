TARİH: 17 Temmuz 2026
BUGÜN YAPILAN: P0 canlı + Flutter Keşfet/publish güvenli select; P1 canlı uygulandı (`p1_security_hardening`: storage listing kapat, shelf delete `objects.name`, store_articles sahiplik RLS, duplicate stores SELECT düştü, inert grants revoke, search_path sabit).
YARIM KALAN: Flutter+SQL repo commit/push (Vercel Keşfet için şart); iki hesaplı canlı kabul; HaveIBeenPwned (Auth dashboard manuel); `send-booking-push` deploy + OneSignal secrets.
SIRADAKİ ADIM: Commit/push onayı → Keşfet smoke → A/B hesap kabulü.
DOKUNULAN DOSYALAR: store_safe_select.dart, explore/auth/autofill/publish + repos, error mapper, 20260717_* migrations (auth gap, lock shelf, gate template, p1), testler.
DİKKAT: Maskot widget/asset’ler commit dışı bırakılmalı. Global blog moderasyon (`fetchPendingReviewArticles`) artık owner-only UPDATE ile kırılır — ayrı admin yolu yoksa kullanma.
