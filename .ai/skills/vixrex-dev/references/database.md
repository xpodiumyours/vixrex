# VixRex Veritabanı Kuralları

## Ana Tablolar

### stores (İşletmeler)
- `id` UUID — Primary key
- `slug` TEXT UNIQUE — URL dostu isim (ör: "casper-giyim")
- `name` TEXT — İşletme adı
- `products` JSONB — Ürün listesi (array of objects)
- `gallery_items` JSONB — Galeri görselleri
- `product_categories` JSONB — Kategori listesi
- `offerings` JSONB — Hizmet listesi (max 6)
- `is_published` BOOLEAN — Yayında mı?
- `is_store` BOOLEAN — Mağaza mı?
- `user_id` UUID — auth.users'a referans

### vitrin_views (Ziyaretçi Takibi)
- `store_slug` TEXT — Hangi işletmenin vitrini
- `viewer_ip` TEXT — Ziyaretçi IP
- `user_agent` TEXT — Tarayıcı bilgisi
- `created_at` TIMESTAMPTZ

### bookings (Randevular)
- İşletme ve müşteri arasındaki randevu kayıtları

## JSONB Yapıları

### products (Örnek)
```json
[
  {
    "id": "uuid",
    "name": "Ürün Adı",
    "description": "Açıklama",
    "price": 100,
    "imageUrl": "https://...",
    "categoryId": "kategori-id"
  }
]
```

### gallery_items (Örnek)
```json
[
  {
    "imageUrl": "https://...",
    "title": "Başlık",
    "description": "Açıklama"
  }
]
```

## Kurallar

1. **DROP TABLE yapma** — Tabloları silme
2. **ALTER TABLE dikkatli** — Sadece ADD COLUMN, asla DROP/RENAME
3. **CREATE IF NOT EXISTS** — Yeni tablo eklerken
4. **RLS aktif** — Her tablo için Row Level Security
5. **Migrationları kaydet** — supabase_schema.sql'e ekle

## Örnek Migration

```sql
-- Yeni alan eklerken
ALTER TABLE public.stores
ADD COLUMN IF NOT EXISTS new_field TEXT;

-- Yeni tablo eklerken
CREATE TABLE IF NOT EXISTS public.new_table (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id UUID REFERENCES public.stores(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- İndeks eklerken
CREATE INDEX IF NOT EXISTS idx_new_table_store_id
ON public.new_table(store_id);
```
