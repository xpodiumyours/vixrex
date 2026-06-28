# Data Deletion Callback Specification

VitrinX complies with Meta's Data Deletion Policy. We provide a secure, real-time data deletion callback endpoint that completely cleans up user data.

---

## 1. Endpoint Configuration

- **Data Deletion Callback URL:** `https://vitrinx.app/api/meta/data-deletion`
- **Method:** `POST`
- **Content-Type:** `application/x-www-form-urlencoded` or `application/json`
- **Payload:** Contains `signed_request` which is decoded and verified using the `INSTAGRAM_CLIENT_SECRET`.

---

## 2. Execution Flow (Strict Mode B)

Upon receiving a valid signature and Meta User ID from the callback:

1. **Token Deletion:** All access tokens corresponding to the user connection are deleted from the database.
2. **Product Deletion:** Any product with `source === "instagram"` or matching import slugs is removed from the store's product list.
3. **Image Cleanup:** All downloaded media files saved under the store's storage path `/{storeSlug}/instagram/` in the Supabase Storage bucket are deleted.
4. **Log & Nonce Clearing:** Connection records are updated to `disconnected` and state nonces are cleared.
5. **Cache Invalidation:** Next.js cache is immediately revalidated using tags `store-{slug}`, `products-{slug}`, and `sitemap`.
6. **Logging Request:** A request log is saved to `meta_data_deletion_requests` with a unique `confirmation_code`.
7. **Status Page:** The API returns a JSON response containing the status tracking URL:
   `https://vitrinx.app/data-deletion/status/{confirmation_code}`
