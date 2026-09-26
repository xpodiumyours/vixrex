# Vixrex Haritası - Supabase

> Kaynak: `supabase/migration` dosyaları — 25 Eylül 2026, commit `08f03553`. Üst not: [[Vixrex Haritası]].
> **Uyarı:** bunlar migration dosyalarından çıkarıldı; canlı veritabanında hangi migration'ın uygulandığı ayrıca doğrulanmadı.

## Ölçümler

| Ne | Sayı |
| --- | --- |
| Migration | 127 |
| Tablo | 26 |
| RPC | 43 |
| Edge Function | 3 |

## 26 tablo

`stores`, `products`, `profiles`, `appointments`, `booking_settings`, `booking_blocks`, `appointment_reschedule_requests`, `product_categories`, `product_database`, `store_articles`, `article_reports`, `store_instagram_connections` / `store_instagram_imports` / `store_instagram_tokens`, `store_category_image_usage`, `category_image_templates`, `vitrin_views`, `xml_feeds`, `legal_documents`, `legal_acceptance_events`, `feature_flags`, `platform_settings`, `admins`, `audit_logs`, `assistant_rate_limits`, `ocr_feedback_dataset`.

## 43 RPC — en önemlileri (kodda çağrılan hâlleriyle)

- **Taslak yaşam döngüsü**: `get_or_create_working_draft` → `update_working_draft_field` / `apply_working_draft_command` → `publish_working_draft`; ayrıca `discard_…`, `restore_…`, `refresh_…`
- **Vitrin sahipliği**: `bootstrap_owner_state`, `get_owner_workspace_bootstrap`, `claim_store_for_user`, `accept_store_legal_consent`
- **Asistan**: `ensure_assistant_conversation`, `append_assistant_message`, `get/set_assistant_pending_slot`, `consume_assistant_request`
- **Randevu**: `create_appointment_request`, `respond_to_appointment`, `get_public_booking_slots`, `request_appointment_reschedule`, `cancel_appointment_by_token`
- **Kiralık vitrin**: `rent_demo_canonical`, `start_demo_trial`
- **Premium**: `record_premium_payment`, `get_store_premium_status`
- **Ölçüm**: `record_vitrin_view`, `record_vitrin_engagement`

## 3 Edge Function

| Fonksiyon | Ne yapar |
| --- | --- |
| `send-booking-push` | OneSignal ile randevu bildirimi |
| `verify-business-ownership` | İşyeri sahiplik doğrulama |
| `vixrex-assistant-nlu` | Asistan NLU (Flutter ve web'den çağrılır) |

## Realtime kanalları

`vitrin_<slug>` (stores satırı) ve `draft:<slug>` (taslak alan güncellemeleri) — bkz. [[Vixrex Haritası - Akışlar]].

---

İlgili notlar: [[Vixrex Haritası]], [[Vixrex Haritası - Flutter]], [[Vixrex Haritası - Next.js]]
