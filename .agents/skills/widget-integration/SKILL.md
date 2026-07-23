---
description: Widget bağlama. Yeni yazmadan önce grep. Plan kabuğunu düzenle/bağla (Complete).
argument-hint: bind/widget task
---

# Widget Entegrasyon

> Fast-path ise atla. Yeni widget yazmadan önce bu skill'i oku.

---

## Zorunlu 5 (inline yasak)

| İhtiyaç | Kullan |
|---|---|
| Loading | `LoadingIndicator` |
| Error | `ErrorState` |
| Skeleton | `SkeletonLoader` / `SkeletonGroup` |
| Tooltip | `TooltipWrapper` |
| Skip link | `SkipLink` |

---

## Akış

1. `rg` / grep — benzer widget var mı?
2. Varsa **import et / düzenle / bağla**, yeniden yazma
3. Yoksa yaz **ve aynı task'ta parent'a bağla** (import + kullanım)
4. Mini DoD: `rg ClassName lib/screens lib/widgets` + boş callback yok + etiket=içerik

**Yasak:** Bu task'ta yazıp bağlanmadan Complete demek. Plan checkbox yalnızca Complete DoD sonrası.

**Ayırım (kritik):**
| Durum | Ne yap |
|---|---|
| Bu task'ta yeni widget, parent yok | Aynı task'ta **bağla** |
| Kullanılmayan / kırık bağ | **Düzenle + bağla** veya dokunma (kurtarma: çekirdek önce) |
| Plansız / yanlışlıkla çift dosya | Kullanıcı onayıyla karar |

İş: **düzenle → bağla**. Yeniden sıfırdan yazma yok. Sahte bağlama (SnackBar/yanlış sayfa) yok.
Kaynak: `KURTARMA_OPERASYONU.md` — mega-plan checkbox avı yok.

---

## Plan kabukları (düzenle / Complete bağla)

Planda var; henüz ekranda Complete değil → mevcut dosyayı kullan.

| Kabuk | Dosya | İş |
|---|---|---|
| ExportImport | `content_area/export_import.dart` | **Complete** ürün yönetimi (CSV/Excel pano; PDF yok) |
| SavedViews | `content_area/saved_views.dart` | **Complete** ürün yönetimi (oturum içi) |
| ColumnVisibility | `content_area/column_visibility.dart` | **Complete** ürün listesi |
| MobileDrawer | `dashboard/mobile_drawer.dart` | **Complete** HomeShell mobil drawer |
| VirtualScrollView | `table/virtual_scroll_view.dart` | **Complete** liste ≥20 |
| CardList / CardDragTarget | `card/` | **Complete** list + sürükle sırala |
| Carousel | `common/carousel.dart` | **Complete** ürün detay |
| SplitView | `common/split_view.dart` | Numarasız — ertele |
| QuickActions | `dashboard/quick_actions.dart` | Dashboard `QuickActionCard` kullanılıyor; gerekirse birleştir |

**Kural:** Kabuk bul → **düzenle + bağla (Complete)** veya ertele (`[ ]` + not).

---

## Örnek (kısa)

```dart
// KÖTÜ
Center(child: CircularProgressIndicator())

// İYİ
LoadingIndicator(size: LoadingSize.large, message: 'Yükleniyor...')
```

---

*Bind/widget task'ta kullan. Katalog ezberleme — grep.*
