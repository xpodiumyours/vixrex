# Privacy Mapping & Data Usage

This document outlines how user data is collected, stored, processed, and deleted under the Meta/Instagram integration on VitrinX.

## Data Processing Details

| Requested Permission | Data Fetched | Storage Location | Usage Purpose |
| :--- | :--- | :--- | :--- |
| `instagram_graph_user_profile` | Instagram User ID, Username, Account Type. | Supabase Database (`public.store_instagram_connections`) | To link the store with the Instagram account and display status. |
| `instagram_graph_user_media` | Media IDs, media URLs, captions, permalinks. | Temporarily fetched. Saved to `public.stores.products` and files saved to Supabase Storage (`shelf-images`) only when imported. | To display media to the user and allow them to convert posts into store products. |

---

## Data Deletion & Privacy Policy

- **Encryption:** Instagram access tokens are encrypted at rest using HMAC-SHA256 (`crypto`) before storage in the database.
- **Privacy Policy:** Read our complete policy at [https://vitrinx.app/privacy-policy](https://vitrinx.app/privacy-policy).
- **Data Deletion:** Users can delete their data via:
  1. The **Disconnect Connection (Mod B)** option in settings.
  2. The official **Meta Data Deletion Request Callback** (fully supported).
