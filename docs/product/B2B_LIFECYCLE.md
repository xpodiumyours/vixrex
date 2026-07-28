# Vixrex — B2B Yaşam Döngüsü (B2B Lifecycle)

**Tarih:** 28 Temmuz 2026  
**Durum:** Taslak — kullanıcı kararları bekliyor  

---

## 1. İlan Durumları

```
draft → available → reserved → rented/sold → assigned → archived
```

| Durum | Açıklama |
|-------|----------|
| `draft` | Admin tarafından hazırlanıyor, henüz yayında değil |
| `available` | Kiralık/satılık olarak public vitrinde listeleniyor |
| `reserved` | Bir müşteri ödeme başlattı, rezerve edildi |
| `rented` / `sold` | Ödeme onaylandı, sözleşme aktif |
| `assigned` | Vitrin müşteriye atandı, kişiselleştirme başlayabilir |
| `archived` | Süre doldu veya iptal edildi |

## 2. Sipariş Durumları

```
created → payment_pending → paid → failed/cancelled → refunded
```

| Durum | Açıklama |
|-------|----------|
| `created` | Sipariş oluşturuldu, ödeme bekleniyor |
| `payment_pending` | PayTR ödeme sayfası açıldı |
| `paid` | Ödeme doğrulandı (callback ile) |
| `failed` | Ödeme başarısız |
| `cancelled` | Kullanıcı iptal etti |
| `refunded` | İade yapıldı |

## 3. Uçtan Uca Akış

```
Ziyaretçi → ilanı görür → kirala/satın al tıklar
→ hesap açar/giriş yapar → sipariş oluşturulur
→ PayTR ödemesi → callback doğrulanır
→ sipariş = paid → atomik vitrin ataması
→ müşteri Flutter panelinde kişiselleştirir
→ açık "Yayınla" eylemi → public vitrin güncellenir
```

## 4. Bekleyen Kararlar

- [ ] Kiralama süresi: aylık / yıllık / ikisi de?
- [ ] Otomatik yenileme var mı?
- [ ] İptal bildirim süresi ne kadar?
- [ ] Ödeme sonrası vitrin hemen atanır mı, yoksa admin onayı gerekir mi?
