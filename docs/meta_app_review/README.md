# Meta App Review Package

This directory contains the documentation and guidelines required for the Meta App Review process for **VitrinX**.

## Contents

1. **[Reviewer Instructions](file:///c:/Projects/vitrinx/docs/meta_app_review/reviewer_instructions.md)**
   Step-by-step walkthrough for the Meta App Reviewer to test the integration.
2. **[Test Account Details](file:///c:/Projects/vitrinx/docs/meta_app_review/test_account.md)**
   Credentials and instructions for using the App Review test accounts.
3. **[Screencast Checklist](file:///c:/Projects/vitrinx/docs/meta_app_review/screencast_checklist.md)**
   Checklist and guidelines for recording the mandatory App Review demo video.
4. **[Privacy Mapping & Data Usage](file:///c:/Projects/vitrinx/docs/meta_app_review/privacy_mapping.md)**
   Description of requested permissions, data fetched, usage, and retention policies.
5. **[Data Deletion Callback Specification](file:///c:/Projects/vitrinx/docs/meta_app_review/data_deletion_callback.md)**
   Technical explanation and flow of the Meta/Instagram data deletion request callback.

---

## Requested Permissions

Our application requests the following Meta/Instagram Graph API permissions:
- `instagram_graph_user_profile`: To retrieve the user's Instagram username and profile type to display active connection status.
- `instagram_graph_user_media`: To list the user's media (images/videos/captions) so they can select and import them as products on their VitrinX store.
