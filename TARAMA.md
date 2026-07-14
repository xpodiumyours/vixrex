# TARAMA.md — Vibe coding hata ayıklama

> **Tek kayıt defteri.** Tespitler yalnız bu dosyaya yazılır. Her bulgu için yeni `.md` açılmaz.  
> **Son tarama:** 15 Temmuz 2026 (Android imzalı APK CI + gerçek cihaz kabulü)
> **Bağlı kurallar:** `PROJECT_RULES.md` · `AGENTS.md` · `SON_DURUM.md`

---

## A) Çalışma kuralları (ajan + Furkan)

1. **Kod yazmadan önce tara.** Bu dosyanın B bölümündeki checklist’i sırayla uygula.
2. **Bulgu = bu dosyadaki C listesine satır.** Ayrı plan / borç / not dosyası oluşturma.
3. **Satır formatı zorunlu:** `T-XXX | sınıf | önem | dosya:satır veya kanıt | kısa açıklama | durum`
4. **Durum değerleri:** `açık` · `doğrulandı` · `düzeltildi` · `kasıtlı` · `ertelendi`
5. **Sınıflar (A–G):** aşağıdaki B tabloları. Yeni tip bulursan önce sınıfa yaz, sonra C’ye ekle.
6. **Yeni dosya yasağı:** Tarama sonucu için `*_BORCU.md`, `*_TESHIS.md`, `NOT_*.md` açma. Güncelle = bu dosya + gerekiyorsa `SON_DURUM.md` tek satır.
7. **Mimari sahiplik:** Public web vitrin = Next.js; mobil vitrin = Flutter; app host public HTML üretmez (`AGENTS.md`). İhlal = sınıf A.
8. **Kapı sınıflama:** Lint/test kırığı = önce “yeni regresyon mu / eski borç mu?” C’ye öyle yaz. Mimari PR’a lint karıştırma.
9. **Diff gürültüsü:** `dart format` / `generated_plugin_*` route veya ürün kararı değilse C’ye yaz, commit’e sokma.
10. **Düzeltme ayrı onay:** C listesi tespit eder; kod değişikliği Furkan onayı olmadan başlamaz (küçük doc fix hariç, o da söylenir).
11. **“düzeltildi” yasağı (kanıtsız):** Durumu `düzeltildi` yapmak için dosyayı oku veya canlıyı kontrol et. İşaretlemek = düzeltmek değildir.

### Tespit satırı şablonu

```text
| T-001 | C | yüksek | path/dosya.ext:123 | Ne bulundu (1 cümle) | açık |
```

---

## B) Tarama checklist (kapsam)

Her “ürün / kalite tarama” oturumunda işaretle. `[x]` = bu oturumda bakıldı.

### B1 — Mimari / yol (sınıf A)

- [x] App `/v/*` → public’e redirect mi? (`curl.exe -sI`)
- [x] Public `/v/*` Next.js mi? (`_next` var, `flutter_bootstrap` yok)
- [x] Eski SEO shell / `api/v` geri gelmiş mi?
- [x] Web “Vitrini Gör” Next link; mobil Flutter içinde mi?
- [x] İkinci renderer / sessiz fallback eklenmiş mi?

### B2 — Yarım geçiş / ceset (sınıf B)

- [x] Grep: eski host (`*-two.vercel.app`), eski marka kalıntısı (ürün adı `VitrinX` birleşik marka)
- [x] Grep: `FlutterFlow`, yanlış stack iddiası dokümanda
- [x] Ölü API, kullanılmayan rewrite, ikinci sitemap

### B3 — Doküman drift (sınıf C)

- [x] `PROJECT_RULES.md` / `AGENTS.md` / `README.md` ↔ `vercel.json` / kod aynı şeyi mi söylüyor?
- [x] Repo / marka / domain satırları güncel mi?

### B4 — Fake Complete / boş kabuk (sınıf D)

- [x] Grep: `yakında`, boş `onPressed`, `TODO: bağlanmadı`
- [x] Menü vaadi ≠ içerik

### B5 — Kalite kapısı / gürültü (sınıf E)

- [x] `npm.cmd --prefix public_web run lint`
- [x] `dart analyze` / hedefli test
- [x] `git diff --stat` → format / generated plugin

### B6 — Veri / güvenlik (sınıf F)

- [x] Ekrandan direkt Supabase anti-pattern yoğunluğu (bilgi amaçlı)
- [x] Secret / hardcoded key
- [x] RLS / migration notu (`URUNLESME` yoksa README + supabase klasörü)

### B7 — UI / ürün yüzeyi (sınıf G)

- [x] Marka yazımı canlı public sayfada
- [x] loading / empty / error eksik ekranlar (örnek tarama)
- [x] Landing’de yanlış domain örneği (`vixrex.app` vs aktif public host)

---

## C) Tespit listesi (tek liste — güncellenir)

> Yeni bulgu = tabloya satır ekle. Düzeltince durumu değiştir. Satır silme (geçmiş kalsın).

| ID | Sınıf | Önem | Yer (dosya / kanıt) | Bulgu | Durum |
|----|-------|------|---------------------|-------|-------|
| T-001 | C | yüksek | `PROJECT_RULES.md:124-130` | Yerel anayasa §10 artık **Vixrex** + Flutter/Next.js + `xpodiumyours/vixrex` + public host. Gemini SON_DURUM’da “onay bekle” demiş ama metin **zaten yazılmış**. | düzeltildi |
| T-002 | G | yüksek | yerel + canlı `page.tsx` logo | Yerel ve **canlı** `vixrex-public…/v/vixrex` → `Vixrex` (PR #17 merge + deploy, 14 Tem). | düzeltildi |
| T-003 | G | orta | `landing_hero_section.dart` | Public host metni + dar ekranda `/v/` (FittedBox). Kod OK. | doğrulandı |
| T-004 | E | orta | `git restore` linux/macos/windows generated_plugin* | Cursor 14 Tem: beş generated dosya restore; `git status`’ta artık yok. | düzeltildi |
| T-005 | B | düşük | `test/**/*.dart` | `vixrex.app` yok; ek test yeşilleri (explore/my_vitrin/product_widgets) da dokunulmuş. | düzeltildi |
| T-006 | D | düşük | `CookieBanner.tsx:51` | “yakında yayınlanacaktır” duruyor; çerez politikası metni. | kasıtlı |
| T-007 | A | bilgi | `curl` app `/v/vixrex` → **307** public; public `_next` var, flutter bootstrap yok | Route sahipliği yeniden doğrulandı. | doğrulandı |
| T-008 | E | bilgi | `npm run lint` exit **0** (Cursor, 14 Tem) | Lint yeşil. | doğrulandı |
| T-009 | E | yüksek | PR #18; Actions run `29370463146` + `29371434810`; telefon kabulü 15 Tem | Kalıcı imzalı APK CI kuruldu; build 10001→10002 aynı sertifikayla uygulama silinmeden güncellendi ve kritik mobil akış geçti. Eski demo imza çakışması tek seferlik kaldırmayla emekli edildi. | düzeltildi |
| T-010 | E | düşük | İki Android APK run annotation'ı | `checkout@v4`, `setup-java@v4`, `upload-artifact@v4` Node.js 20 hedefli; GitHub bunları Node.js 24'e zorlayarak başarıyla çalıştırdı. Güncel major sürümlere geçiş ayrı küçük CI bakım işi. | açık |

---

## D) Cursor doğrulama özeti

### Tur 1 (öğleden sonra) — kanıtsız “düzeltildi”
T-001/T-004 yanlış işaretlenmişti; geri açıldı.

### Tur 2 (gece — Gemini son iş + Cursor kontrol)

| Ne yaptı / iddia | Kod gerçeği | Not |
|------------------|-------------|-----|
| SON_DURUM: T-001/002/004 açık, onay bekle | T-001 metni **zaten düzelmiş**; T-002/004 hâlâ açık | SON_DURUM yarım doğru |
| `PROJECT_RULES.md` §10 | Vixrex / Next.js / doğru repo | **İyi** (T-001 yerel) |
| `page.tsx` logo | Yerel Vixrex | Canlı **hâlâ VitrinX** |
| Landing hero | public host + responsive `/v/` | **İyi** |
| Test paketleri | fixture + birkaç widget testi | **İyi** (yerel) |
| generated_plugin* | Hâlâ dirty | **T-004 yapılmamış** |
| Canlı curl | App→public 307; public Next; logo VitrinX | Deploy bekliyor |

**Sıradaki odak:** APK Faz 1 tamamlandı. T-010 yalnız ayrı küçük CI bakım işi; ürün veya telefon güncellemesini engellemiyor.

---

## E) Grep / komut cep notu

```text
# Marka / eski yol
rg -n "VitrinX|vitrinx\.app|FlutterFlow|Riverpod|vixrex-two|api/v/\[slug\]" .

# Fake complete
rg -n "yakında|TODO: bağlanmadı|onPressed:\s*\(\)\s*\{\s*\}" lib public_web/src

# Canlı
curl.exe -sI https://vixrex-app.vercel.app/v/SLUG
curl.exe -sI https://vixrex-public.vercel.app/v/SLUG
```

---

*Bulgular çoğaldıkça yalnız §C büyür. Yeni belge açma. “düzeltildi” = kanıt zorunlu.*
