# send-booking-push

Randevu olaylarında OneSignal push gönderir.

## Secrets (Supabase Dashboard → Edge Functions)

```
ONESIGNAL_APP_ID=
ONESIGNAL_REST_API_KEY=
```

## Deploy

```bash
supabase functions deploy send-booking-push
```

## Body

```json
{
  "externalUserId": "<auth.uid>",
  "title": "...",
  "body": "...",
  "storeSlug": "...",
  "type": "booking"
}
```

`externalUserId` çağıran kullanıcının `auth.uid` değeri ile aynı olmalıdır.
