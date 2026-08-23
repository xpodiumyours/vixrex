# Vixrex Security Analysis: Attack Vectors & Vulnerability Register

**Last Updated:** 2026-08-24
**Method:** 6 parallel sub-agents, 6 categories. Code-only evidence. Total: **~65 findings**

---

## 📊 SUMMARY

| Status | Count | % |
|--------|-------|---|
| ✅ FIXED (proven in code) | 23 | 35% |
| 🔴 OPEN — CRITICAL/HIGH | 2 | 3% |
| 🟡 OPEN — MEDIUM | 15 | 23% |
| 🟢 OPEN — LOW | 12 | 18% |
| 🟡 TEST REQUIRED | 4 | 6% |
| ⚪ Dormant/Passive | 3 | 5% |
| **TOTAL** | **~65** | **100%** |

---

## ✅ FIXED (23 vectors — proven in code)

| # | Finding | Risk | Fix Evidence |
|---|---------|------|--------------|
| V-01 | admins INSERT privilege escalation | 🔴 CRITICAL | `20260818000000` — DROP POLICY "Allow insert admins", REVOKE ALL anon/authenticated |
| V-02 | Vitrin page JSON-LD XSS | 🟠 HIGH | `jsonLd.ts:safeJsonLdHtml()` — `<` → `\u003c` escape; `page.tsx:651` uses it |
| V-03 | Product page JSON-LD XSS | 🟠 HIGH | `urun/[productSlug]/page.tsx:282,286` — `safeJsonLdHtml()` |
| V-04 | marketplace_link javascript: URI | 🟠 HIGH | `20260818040000` — `_sanitize_marketplace_links()` scheme allowlist |
| V-05 | xml_feeds edit_token ownership check | 🟠 HIGH | `20260818020000` — `s.user_id = auth.uid()` |
| V-06 | category_image_templates public write | 🟠 HIGH | `20260818010000` — admin check added |
| V-07 | OWNER_SESSION_SECRET static value | 🟠 HIGH | `ownerSession.ts` — KNOWN_WEAK_SECRETS + fail-closed + 32-char minimum |
| V-08 | Reschedule capacity race condition | 🟠 HIGH | `20260818070000` — `pg_try_advisory_xact_lock` + capacity loop |
| V-09 | Store PII anon read (user_id) | 🟡 MEDIUM | `20260818050000` — REVOKE SELECT("user_id") anon/authenticated |
| V-12 | reCAPTCHA not verified server-side | 🟡 MEDIUM | `auth_screen.dart:58,147` — `RecaptchaService.verifyOnBackend()` called |
| V-13 | reCAPTCHA threshold 0.3 | 🟡 MEDIUM | `recaptchaServer.ts:21` — DEFAULT_MIN_SCORE = 0.5 |
| V-14 | Password reset dead end | 🟡 MEDIUM | `sifre-sifirla/page.tsx` — PASSWORD_RECOVERY + updateUser({password}) |
| V-16 | RATE_LIMIT_SECRET undefined → raw IP | 🟡 MEDIUM | `rentDemoSecurity.ts:53` — production throws (fail-closed) |
| V-21 | Booking flow reCAPTCHA server missing | 🟡 MEDIUM | `BookingWizardClient.tsx` — executeRecaptcha("booking_create") + RPC |
| V-25 | attack-vectors.md real secrets | 🟠 HIGH | All values `[REDACTED]` |
| V-26 | google-services.json in git | 🟡 MEDIUM | `git ls-files` → empty, untracked |
| V-28 | shelf-images public bucket anon upload | 🟡 MEDIUM | `20260818060000` — scoped regex pattern |
| V-34 | CORS * wildcard (send-booking-push) | 🟢 LOW | `send-booking-push:13` → ALLOWED_ORIGIN = 'https://vixrex-public.vercel.app' |
| V-43 | Storage definitions only in archive | 🟡 MEDIUM | `20260818060000` added to migration chain |
| V-52 | Feature flags anon access | 🟡 MEDIUM | `20260819020000` — anon policy removed |
| V-53 | Booking settings anon access | 🟢 LOW | `20260819020000` — anon policy removed |
| V-57 | Rent-demo service role bypass | 🔴 CRITICAL | `20260824000000` — `getSupabaseAdmin()` kaldırıldı; normal client + iki RPC (start_demo_trial → create_owner_session) |
| V-58 | Article content XSS | 🟠 HIGH | `sanitize.ts` — sanitize-html allowlist; `formatContent()` calls sanitizeHtml() |

> **Note:** V-17 and V-18 (JSON-LD in articles list/detail) marked MEDIUM in register but `safeJsonLdHtml()` is used — effectively FIXED; attack-vectors.md still shows CONFIRMED.

---

## 🔴 OPEN / UNVERIFIED (36 vectors — still in code)

### CRITICAL (0)

*Yok — tüm kritik açıklar kapatıldı.*

### HIGH (2)

| # | Finding | Evidence |
|---|---------|----------|
| V-56 | Category images API missing p_edit_token | `category-images/route.ts:63-90` — `apply_category_template` RPC called without `p_edit_token` |
| V-51 | Owner sessions store ownership gap | `link_store_to_user` function lacks store ownership check |

### MEDIUM (15)

| # | Finding | Evidence |
|---|---------|----------|
| V-10 | Storage slug-prefix anon upload | `migrations_arsiv/20260717000009` — scoped regex but unregistered slugs open |
| V-11 | JWT + edit_token plaintext storage | `lib/main.dart:83-86` — flutter_secure_storage not used; web uses localStorage |
| V-15 | edit_token perpetual bearer | `00000000000000_temel_sema_bulut_20260805.sql:2062` — text DEFAULT '', no TTL |
| V-17 | Articles list JSON-LD injection | `yazilar/page.tsx:109-110` — safeJsonLdHtml ✅ but store.name still risky |
| V-18 | Article detail JSON-LD injection | `yazilar/[articleSlug]/page.tsx:183-188` — safeJsonLdHtml ✅ but article.title risky |
| V-19 | Reschedule working hours/lunch/block check missing | `request_appointment_reschedule` — only capacity loop |
| V-22 | Edge fn raw exception to client | `send-booking-push/index.ts:91-93` — FIXED ✅ (generic error message) |
| V-23 | OneSignal raw response to client | `send-booking-push/index.ts:80-87` — FIXED ✅ (generic error message) |
| V-27 | OAuth client_secret plaintext | `.gitignore:60` protected but `git add -f` risk |
| V-41 | .env.local real values (3 copies) | `.env.local`, `.env.local.yerel-yedek`, `.env.local.bulut-yedek` — gitignored |
| V-42 | .env.vercel-tesis VERCEL_OIDC_TOKEN | Expired but on disk |
| V-48 | Google Cloud Console OAuth config | reCAPTCHA client ID unverified |
| V-49 | url_launcher javascript: URI | `pubspec.yaml:35` — Flutter web executes javascript: |
| V-50 | SharedPreferences/localStorage | `lib/main.dart:83-86` — Supabase writes to localStorage |
| V-60 | Error disclosure owner-upload | `owner-upload/route.ts:205` — err.message to client |

### LOW (12)

| # | Finding | Evidence |
|---|---------|----------|
| V-29 | Daily 5 appointment limit race | count(*) before advisory lock |
| V-30 | Client price/duration no validation | `p_appointment_time > now()` check missing |
| V-31 | Tracking link PII | Phone unmasked |
| V-32 | send-booking-push storeSlug no ownership | Any storeSlug sendable |
| V-33 | assistant-nlu auth missing (dormant) | assistantEnabled = false |
| V-35 | Open redirect protocol-relative | safeReturnTo — //evil.com passes |
| V-36 | category-images raw Supabase errors | error.message to client |
| V-37 | revalidate/report-abuse err.message | Error messages still to client |
| V-38 | Instagram API error reflection | Raw errors to client |
| V-39 | ocode in URL query | Visible but HMAC-signed |
| V-40 | paytr/create-link userIp from header | x-forwarded-for — Vercel platform spoofs |
| V-44 | recaptcha_v3 unused package | `pubspec.yaml` defined, 0 usage in lib/ |
| V-45 | Supabase demo service_role key | Demo key, won't work in real project |

---

## 🟡 TEST REQUIRED (4 vectors)

| # | Finding | Risk |
|---|---------|------|
| V-20 | PayTR callback TOCTOU | FOR UPDATE missing — test needed |
| V-32 | send-booking-push storeSlug ownership | Code evidence exists but manual test needed |
| V-35 | Open redirect protocol-relative | //evil.com bypass — test needed |
| V-40 | paytr/create-link userIp from header | Vercel platform spoofs — test needed |

---

## ⚪ DORMANT / PASSIVE (3 vectors)

| # | Finding | Status |
|---|---------|--------|
| V-24 | assistant-nlu rate-limit bypass (clientId) | assistantEnabled = false — dormant |
| V-33 | vixrex-assistant-nlu auth missing | Dormant — flag off |
| V-45 | Supabase demo service_role key | Demo key, non-functional in production |

---

## 🎯 PRIORITY ACTIONS (Ordered)

1. **HIGH** — V-56: category images API — add `p_edit_token` validation to RPC call
2. **HIGH** — V-51: owner sessions — add store possession check to `link_store_to_user`
3. **MEDIUM** — V-54: article reports IDOR — add CHECK constraint
4. **MEDIUM** — V-55: store working drafts — review security definer RPC
5. **MEDIUM** — V-59: CORS * wildcard — API Gateway review
6. **MEDIUM** — V-60: error disclosure owner-upload — filter err.message
7. **LOW** — V-20: PayTR callback — add `SELECT ... FOR UPDATE` + `WHERE status='pending'`
8. **LOW** — V-29: daily appointment race — move count(*) inside lock
9. **LOW** — V-30: client price/duration validation — add server checks
10. **LOW** — V-31: tracking link PII — mask phone
11. **LOW** — V-35: open redirect — fix safeReturnTo protocol-relative
12. **LOW** — V-36/37/38: error disclosure — generic messages
13. **LOW** — V-39: ocode in URL — consider header/body
14. **LOW** — V-40: userIp header — verify Vercel behavior
15. **LOW** — V-44: remove unused recaptcha_v3 package
16. **LOW** — V-45: remove demo service_role key from .env files

---

## 📝 NOTES

- **V-17, V-18**: Marked MEDIUM/CONFIRMED in register but `safeJsonLdHtml()` is used in code — effectively mitigated.
- **V-22, V-23**: Marked MEDIUM/CONFIRMED but fixed with generic error messages (verified in code).
- **V-43**: Marked TEST NEEDED/MEDIUM but `20260818060000` added to migration chain — FIXED.
- **V-34, V-59**: CORS * wildcard — V-34 shows FIXED (send-booking-push), V-59 notes elevated severity for API Gateway review.
- **V-57**: **FIXED (2026-08-24)** — `20260824000000` migration + API route rewrite; service role bypass eliminated via Option A (Least Privilege).

---

*Register compiled from 6 parallel sub-agent scans (18 Aug 2026). All findings code-evidenced; TEST REQUIRED items need manual/tool verification.*