# Ajan Başlangıç Haritası

> Bu belge plan değil, günlük değil. Tek işi: "hangi bilgiye nereden bakılır" sorusunu
> tek yerde cevaplamak ve ezbere konuşmayı ölçülebilir bir yasak yapmak. Kural kitabı
> [AGENTS.md](../AGENTS.md)'de; bu belge **harita**dır.
>
> Son doğrulama: 2026-11-03 · Ana dal: `ef6a803` · Canlı: `ef6a803` (canlı = ana dal)

## 0. Oturum açılışı — 4 adım

1. **Defterler (varsa).** `C:\Projects\vixrex\CALISMA-DEFTERI.md` ve `C:\Projects\Casper\DEFTER.md`.
   Bu iki yol yalnız sahibin bilgisayarında vardır, depoda değildir. Yoksa arama yapma;
   "defter yok" de ve devam et. İkinci defter açma.
2. **Kapıyı koş.** `pwsh -NoProfile -File tool/ajan-baslangic.ps1`.
   Çıktısı olmadan "durum şu", "düzeldi", "çalışıyor", "canlıda" denmez.

   | Çıkış kodu | Anlamı | Ajan ne yapar |
   |---|---|---|
   | 0 | Ölçüm tam; canlı = ana dal | Normal çalışır |
   | 1 | Ölçüm kısmi (canlı veya PR okunamadı) | "ölçülmedi" yazar, iddia kurmaz |
   | 2 | Ana dal okunamadı | Durur, sebebi yazar; tahmin yürütmez |
   | 3 | Canlı ana daldan ayrı | "canlı geride" yazar; "canlıda" demez |
   | 4 | Sistem parçası eksik (bu belge/AGENTS/README bağı kopuk) | Kurcalamaz, bildirir |
   | 5 | Yalnız `-Kod` ile: harita yok/bayat | Kod değiştirmez; önce `graphify update .` |

   `pwsh` yoksa (başka ortam): aşağıdaki tablodaki üç komutu elle koş, sonucu yine yaz.
   Kapı yok diye ölçümsüz konuşulmaz. `gh` de yoksa iki ölçüm curl ile alınır:
   `curl -s https://api.github.com/repos/xpodiumyours/vixrex/commits/main` (ana dal `sha`)
   ve `curl -s https://vixrex-public.vercel.app/deploy-info.json` (canlı `commit`).
3. **Haritayı oku.** Bu belge.
4. **Sonra cevap ver.** Başka ajanın raporu kanıt değildir.

Kapı ölçüm kaydı: `.olcum/ajan/acilis.log` — bu makinede tutulur, depoya girmez.

## 1. Gerçek nerede — tek tablo

| Soru | Kaynak | Tek komut / yol | Kanıtlar | Kanıtlamaz |
|---|---|---|---|---|
| Ana dal hangi commit? | GitHub API | `gh api repos/xpodiumyours/vixrex/commits/main --jq .sha` | uzaktaki ana dalı | yerel kopyayı |
| Canlı hangi commit? | `deploy-info.json` (Vercel `vixrex-public`) | `curl -s https://vixrex-public.vercel.app/deploy-info.json` | gerçekten yayındaki sürümü | ana dalı (yayın geride olabilir) |
| Yayın kaydı (yedek) | GitHub deployment | `gh api "repos/xpodiumyours/vixrex/deployments?environment=Production%20%E2%80%93%20vixrex-public"` | en son üretim yayınının commit'i ve durumu | derlemenin başarısını tek başına (status'a bak) |
| Açık PR | GitHub | `gh pr list --state open --limit 200` | açık ve taslak işleri | işin canlıda olduğunu |
| Yerel kopya | git (yerel) | `git log --oneline -1` · `git status` | yalnız bu makineyi | uzaktaki gerçeği; yerel ref bayat olabilir |
| Veritabanı satırı | Supabase (proje `chfulefxczbgurtgavtp`) | Supabase MCP (okuma) veya SQL editör çıktısı | gerçek satırı | kodu |
| OpenRouter preset içeriği | OpenRouter paneli | panel + `OPENROUTER_API_KEY` (yeri §2) | yayındaki preset metnini | kodun hangi preseti seçtiğini tek başına |
| Görsel hakkı / ürün kartı | kod + DB | `public_web/src/lib/fatura*` · `usage_status` | kuralın kodda ne yaptığını | canlı davranışı (ekran/DB ölçümü ayrı) |
| Kod ilişkisi / etki | Graphify (yerel CLI ya da MCP) | `graphify affected "X"` · `graphify query "..."` · MCP: `graphify_impact` | kod bağımlılıklarını | canlıyı, DB'yi, preset içeriğini |

Not: her satır tek başına yeterli değildir. "Canlıda" cümlesi için canlı satırı,
"düzeldi" cümlesi için test çıktısı şarttır. Yerel `git` ref'i kanıt sayılmaz.

## 2. Anahtarlar nerede yaşar (değer asla yazılmaz)

| Anahtar türü | Yeri | Not |
|---|---|---|
| OpenRouter, Supabase, Instagram, Turnstile, reCAPTCHA, OneSignal | `public_web/.env.local` | depo dışı; değer sohbete yapıştırılmaz |
| Canlı ortam | Vercel `vixrex-public` ortam değişkenleri | panelden yönetilir; depoya girmez |
| Flutter panel | `dart_defines.local.json` | depo dışı; örneği `dart_defines.example.json` |
| CLI oturumları | `gh` (xpodiumyours), `vercel` (xpodiumyours) | kuruluysa hazır; yoksa ajan "yok" der |
| Veritabanı okuma | Supabase MCP (`chfulefxczbgurtgavtp`) | DSH'de DB bağlantısı/yazma yok (`DATABASE_URL` boş) |

Kural: ajan **anahtar istemez**. Anahtar yoksa "yok" der, okuma/ölçümle devam eder;
canlıya/veritabanına yazmaz. Depo herkese açıktır; hiçbir anahtar veya kişisel not
commit edilmez.

## 2.5 Platform bağlantıları — canlı kanıt (2026-11-03)

Kapı her açılışta bunları **salt okunur** ölçer; değer uydurulmaz.

| Platform | Kanıt komutu | Bugünkü ölçüm | Yazma sınırı |
|---|---|---|---|
| GitHub | `gh auth status` | BAĞLI (xpodiumyours) | okuma serbest; push/merge onayla |
| Vercel | `vercel whoami` + MCP ucu | BAĞLI (CLI: xpodiumyours) · MCP YETKİSİZ (OAuth) | deploy/rollback onayla |
| Supabase | REST okuma + MCP ucu | BAĞLI (REST 200) · MCP YETKİSİZ (OAuth) | migration/veri yazma onayla |
| OpenRouter | `GET /api/v1/models` + preset ucu | BAĞLI (modeller 200) · preset YETKİSİZ (401) | preset düzenleme onayla |
| Graphify | yerel `graphify` + MCP ucu | YEREL HAZIR (12.072 düğüm) · bulut MCP: hesap çakışması nedeniyle bekliyor | harita okuma serbest; `remember`/`set_workspace` onayla |

MCP uçları `https://api.graphify.com/mcp`, `https://mcp.vercel.com`,
`https://mcp.supabase.com/mcp?project_ref=chfulefxczbgurtgavtp` ve `.mcp.json`'da tanımlıdır.
OAuth oturumu bir kez açılır: Claude Code `/mcp` → Authenticate; Codex
`codex mcp login graphify`; Cursor MCP ayarları. Oturum yokken durum **YETKİSİZ** yazılır,
tahmin yürütülmez. Anahtar/adres istenmez; harita ve bağlantılar buradadır.

Graphify oturumu 2026-11-03'te tarayıcıda onaylandı; kayıt `~/.mcp-auth` altında.
`mcp-remote` köprüsü bu oturumu paylaşır (`.mcp.json` / `.cursor/mcp.json`). Bulut tarafında
depo yetkisi **hesap çakışması** yüzünden bekliyor: GitHub uygulaması başka bir Graphify
hesabına bağlı, giriş yapılan hesap o grubun üyesi görünmüyor. Resmî çözüm: Graphify
panosunda **Repositories → Claim** veya çakışma ekranındaki **destek ekibi** bağlantısıyla
hesap birleştirme. Bu, ajanları **durdurmaz**: kod haritası yerel `graphify` ile çalışır.

## 3. Hangi belge tarihsel — hangisi güncel (2026-11-03)

| Belge | Sınıf | Not |
|---|---|---|
| [AGENTS.md](../AGENTS.md) | kural (tek adres) | çalışma tarzı; harita değil |
| [README.md](../README.md) | tanıtım | depo mimarisi; durum kaynağı değil |
| `docs/ANA-DENETIM-KAYDI.md` | yerel kayıt | bu makinede var, depoda **değil**; yoksa yok say |
| `docs/FATURADAN-VITRINE-MASTER-PLAN.md` | **tarihsel** | 30 Eylül planı; güncel iş listesi değil |
| `docs/FATURA-URUN-KARTI-PLAN.md` | plan | 7 Ekim; havuz kararı birkaç satırını geçersiz kılar |
| `docs/URUN-EKLE-FATURA-DURUM.md` | tarihsel ölçüm | havuz satırları geçersiz |
| `docs/PRESET-TEMIZLIK-PLANI.md` | plan | uygulanmış |
| `docs/vixrex_faturadan_vitrin_HEDEF-ve-tasarim-plani.md` | tarihsel/çelişkili | kaldırılan kataloğa atıf yapar (kural 20) |
| `docs/vitrin-gorunum-referans.md` | aktüel referans | — |
| `docs/vitrin-kart-standardi.md` | aktüel standart | — |
| `docs/esnaf-yolculugu-kurumsal-kalite-tespit.md` | aktüel ölçüm | T1–T4, K1–K6, F1 |
| `docs/IZIN-MIMARISI.md` | aktüel taslak | beş katman |

Kural: tarihsel belge okunabilir; **güncel iş listesi yerine geçmez**. Bir belge kendini
"tarihsel" ilan etmiyorsa ve bu tabloda yoksa, önce bu tabloya eklenir.

## 4. Ezbere konuşma yasağı — ölçülebilir tanım

| Cümle | Kanıt şartı |
|---|---|
| "Sistem şöyle / durum şu" | kapı çıktısı (ana dal + canlı + PR) |
| "Düzeldi / çalışıyor" | test çıktısı + ekran/ölçüm (dosya:satır) |
| "Canlıda" | `deploy-info.json` commit'i = ana dal |
| "Başka yeri kırmadım" | etkilenen dosya listesi (Graphify veya `grep` + dosya:satır) |

Kanıt yoksa cümle kurulmaz; yerine **"ölçülmedi"** yazılır. "Bilmiyorum" demek serbesttir,
uydurmak yasaktır. Başka ajanın raporu kanıt değildir.

## 5. Değişiklikten önce (cerrahi sıra)

[AGENTS.md](../AGENTS.md) kural 4 aynen geçerlidir: önce tespit, onay, yalnız onaylanan
satırlar, yayılma alanı, kapılar, görsel kanıt, dal/canlı ayrımı ve geri alma.

Bu belgeden gelen ek:
- Etki listesi: Graphify bağlıysa `graphify_impact`; değilse `grep` + `dosya:satır`.
  Liste yoksa "başka yeri kırmadım" denmez.
- Görünen değişiklikte öncesi/sonrası ekran; gösteremiyorsan "gösteremedim" de.

## 6. Graphify — iki yol: yerel harita ve hosted MCP

**Yerel (her ajan, komutla):**
- Kurulum: `uv tool install graphifyy` → `graphify` komutu.
- Harita: `graphify extract . --code-only` → `graphify-out/graph.json` (makineye özel,
  depoya girmez; `.gitignore`'da).
- Sorgu: `graphify query "<soru>" --budget 1200` · `graphify affected "Sembol"` ·
  `graphify path "A" "B"` · `graphify explain "Sembol"`. Her sonuç dosya:satır verir.
- Tazeleme: kod değişince `graphify update .` (LLM gerekmez). Harita son kod
  commit'inden eskiyse kapı "YEREL BAYAT" yazar ve `-Kod` ile kod değişikliğini engeller.

**Hosted MCP (bulut haritası):**
- Adres `https://api.graphify.com/mcp`; OAuth ile bir kez oturum açılır (API anahtarı yok).
- İlk çağrı `list_repositories`, sonra `graph_stats` ile indeks commit'i ve yaşı alınır;
  indeks commit'i çalışılan commit değilse "harita güncel değil" denir.
- Değişiklik öncesi `graphify_impact`, `impact_and_risk`, `graphify_tests_for`.
- Sınır: hosted harita varsayılan dalın son indeksidir; PR dalı ve canlı davranış
  grafikten kanıtlanmaz.

**İkisi de yoksa:** dosyayı oku, `grep` + dosya:satır kullan ve "harita yok" de; iş durmaz,
ölçümsüz cümle kurulmaz.

## 7. Bu belgeyi kim günceller

Bir ajan bu belgedeki bir satırı değiştirdiğinde üstteki **"Son doğrulama"** tarihini ve
ölçtüğü ana dal/canlı değerini günceller. 30 günden eski tarih "bayat" sayılır; kapı belge
yaşını yazar. Bayat belgeyle durum cümlesi kurulmaz.
