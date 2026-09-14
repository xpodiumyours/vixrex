# Kök dizin rehberi

Bu depoda aynı anda birden fazla ajan çalışıyor. Bu belge, bir ajanın
"Vixrex şu an nasıl çalışıyor" sorusunu **hangi dosyalara bakarak**
cevaplayacağını söyler. Amaç, üretilmiş çıktıları ve eski anlık
görüntüleri kaynak sanmayı önlemek.

## Güncel gerçeği bu sırayla öğren

1. Açık ürün dalı (o an üzerinde çalışılan dal) — kodun son hâli
2. `supabase/migrations/` — veritabanının gerçek hâli
3. Canlı Supabase projesi — uygulanmış olan

Bu sıranın dışındaki hiçbir dosya "gerçek" değildir.

## Gerçek kaynak klasörler

| Klasör | Ne |
| --- | --- |
| `lib/` | Flutter uygulaması (Vixrex Asistan, APK) |
| `public_web/` | Next.js sitesi — vitrinler, landing, blog |
| `shared/` | Flutter ve Next.js'in ortak ürün şeması |
| `supabase/migrations/` | Veritabanının tek gerçek kaynağı |
| `test/`, `integration_test/` | Flutter testleri |
| `web/` | Flutter'ın web platform klasörü — `public_web/` ile ilgisi yok |
| `android/`, `ios/`, `windows/`, `linux/`, `macos/` | Flutter platform klasörleri |

## Kaynak olmayan, kanıt diye kullanılmayacak dosyalar

| Öğe | Ne | Neden kaynak değil |
| --- | --- | --- |
| `supabase_schema.sql` | Veritabanının eski anlık görüntüsü | Elle üretilir, kendiliğinden tazelenmez. Gerçek kaynak `supabase/migrations/`. Yalnız iki test ona bakar. |
| `build/`, `release_apk/` | Derleme çıktıları | Kaynaktan üretilir, eski olabilir |
| `*.log`, `build_output.txt`, `resp.txt` | Eski çalışma kayıtları | Kaynak değil |
| `test-sonuc/`, `public_web/test-sonuc/`, `public_web/design-qa/` | Test ekran görüntüleri | Üretilmiş çıktı |
| `board.json` | Yerel görev tahtası | Kod değil |
| `.scratch/`, `scratch/` | Geçici çalışma notları | Kod değil |
| `node_modules/`, `.dart_tool/`, `.pytest_cache/`, `.vercel/` | Bağımlılık ve önbellek | Üretilmiş |

## Depo kopyaları — arama yaparken dikkat

`.codex-worktrees/` ve `.claude/worktrees/` altında **deponun tam
kopyaları** durur. Her biri eski bir dala bağlıdır. Kök dizinde arama
yapan bir ajan aynı dosyayı defalarca bulur ve hangisinin güncel
olduğunu ayırt edemez.

Kural: kök dizinde arama yaparken bu iki klasörü **dışarıda bırak**.

Bunlar normal klasör değil, kayıtlı git worktree'leridir. Klasörü
silmek git kaydını bozar. Doğru komut:

```
git worktree list
git worktree remove <yol>
git worktree prune
```

Kaldırmadan önce o dalın main'e inip inmediğini ve içinde
kaydedilmemiş değişiklik olup olmadığını ölç.

## Yerel ortam dosyaları

`dart_defines.local.json`, `run_local.ps1`, `.claude/settings.local.json`
ve `*.yedek-*` dosyaları yalnız bu makinede vardır. Yereldeki davranışın
canlıdan farklı olmasının sebebi bunlar olabilir; ürün kodu değildirler.
