# Barkod tekilliği — ölçüm ve index önerisi

Durum: **ölçüm yapılamadı, index eklenmedi.**
Bu çalışma ortamında `chfulefxczbgurtgavtp` (Vixrex Project) için yalnız `NEXT_PUBLIC_SUPABASE_ANON_KEY`
bulunuyor; `products` tablosunu okuyacak servis anahtarı yok. Çakışma sayısı ölçülmeden index
eklenmez (kural: ölçmeden değiştirme).

## 1) Önce çalıştırılacak okuma (çakışma ölçümü)

```sql
select store_id, barcode, count(*) as kart_sayisi,
       array_agg(id order by created_at) as kart_idleri
from public.products
where barcode is not null and btrim(barcode) <> ''
group by store_id, barcode
having count(*) > 1
order by kart_sayisi desc;
```

Beklenen yorum: satır dönerse önce hangi kartın kalacağına karar verilir, sonra index eklenir.
Satır dönmezse aşağıdaki index güvenli.

## 2) Index (yalnız ölçüm temizse uygulanır)

```sql
create unique index concurrently if not exists products_store_barkod_tekil
  on public.products (store_id, barcode)
  where barcode is not null and btrim(barcode) <> '';
```

`concurrently` nedeniyle migration içinde tek başına koşmalıdır (transaction bloğu içine alınmaz).
