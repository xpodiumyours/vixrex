# İş Kaydı — Gelişim zincirinin yürürlüğe alınması (kontak + 4 fren)

Tarih: 17.09.2026 · Karar: proje sahibi, "4 eksiği sırayla kur"

## 1. İş — tek cümle

> Bir geliştirme istendiğinde zincir **kendiliğinden** başlar; kart yoksa,
> onay yoksa veya sinir dışına çıkılıyorsa **makine durdurur**.

## 2. Nereden başlıyoruz

**Başlangıç halkası:** Kural (zincirin 1. halkası). Çünkü kural yazılıydı ama
**hiçbir mekanizmaya bağlı değildi**; her ajan kendi yorumunu uyguladı.

**Ölçülen gerekçe:**
- `.specify/memory/constitution.md` var, planlama adımında okunuyor → ama
  **zorlamıyor** (kanca/CI yok).
- `.specify/workflows/overlays/speckit/vixrex-zincir.yml` **kayıtlı ve etkin**
  (araç doğruladı: `vixrex-zincir priority=10 enabled`), 10 adımlı akış + 4 onay
  durağı → ama **hiç çalıştırılmıyor** (duraklar canlı terminalde düğme ister).
- Mevcut 5 kanca **bağlı ve çalışıyor** ama sır/jeton/kod temizliği için;
  zincir/yüzey/test doğruluğu için **hiçbir fren yoktu**.
- Yerel ana dal origin/main'in **7 kayıt gerisinde** (bayat taban tuzağı).

## 3. Ne yapıldı

| # | Parça | Dosya | Ne yapar |
|---|---|---|---|
| 1 | **Kontak** | `.claude/skills/vixrex-is/SKILL.md` | İstek geldiğinde zinciri başlatır: **0. hedef tablosu** (bugün / eksik / olması gereken) → zincir ölçümü → iş kaydı → sınır dosyası → onay durağı |
| 2 | **Fren 1** | `.claude/hooks/is-siniri.sh` | Kart yoksa, onay yoksa veya dosya onaylı listede değilse Edit/Write **durur** |
| 3 | **Fren 2** | `.claude/hooks/yalan-test.sh` | Kaynak kodu okuyup metin arayan test yazımını **durdurur** (anayasa IV) |
| 4 | **Fren 3** | `.claude/hooks/dal-tabani.sh` | Yerel ana dal `origin/main` gerisindeyken dal açmayı **durdurur** (AGENTS.md 8) |
| 5 | **Fren 4** | `.claude/hooks/bitti-kapisi.sh` | Kayıt öncesi "Durum" (dalda/ana dalda/yayında/canlıda) işaretlenmemişse **durdurur** (anayasa IV) |
| 6 | Bağlama | `.claude/settings.json` | 4 fren `PreToolUse` olayına bağlandı |
| 7 | Hedef adımı | `.specify/templates/overrides/giris-kapisi-karti.md` | Kartın **0. bölümü**: "bugün canlıda / eksik / olması gereken" tablosu zorunlu |

## 4. Test kanıtı (10 senaryo, temiz projede koşuldu)

Kart yok → durdu · sınır dışı dosya → durdu · onay yok → durdu · kart + listede
dosya → izin · kaynakta kelime arayan test → durdu · bayat tabandan dal → durdu
(7 kayıt geride) · aktif iş yokken kayıt → izin · "Durum" işaretsizken kayıt →
durdu · "Durum" işaretli → izin · kural/şablon alanına yazım → izin.

## 5. Neye dokunulmadı

Ürün kodu · canlı · veritabanı · Flutter paneli · ana dal · GitHub.

## 6. Sınır bilgisi (dürüst not)

- Frenler **yalnız Claude ajanı** için bağlıdır (`.claude/settings.json`).
  Codex, Cursor, Kilo gibi diğer ajanlar bu kancaları okumaz → onlar için
  aynı kural CI tarafında kurulmalıdır (henüz kurulmadı).
- Kancalar `node` gerektirir. WSL bash'te node yok; Git Bash'te var
  (`/c/Program Files/nodejs/node`). Kanca node bulamazsa **durmaz, uyarır ve
  iş ilerlemez** (anayasa VII).

## 7. Onay

Onay: ☑ verildi · 17.09.2026 ("4 eksiği sırayla kur" kararı)

## 8. Durum

- ☑ **Dalda duruyor** — `docs/gelisim-zinciri-kurali`
- ☐ Ana dala indi
- ☐ Yayına dağıtıldı
- ☐ Canlıda gözle doğrulandı

## 9. Yarım kalan

1. **Ortak dala alma** (sıradaki adım): ana dala indirme + GitHub'a gönderme.
   Uyarı: ana dala gönderim **canlı yayını yeniden kurar** (Vercel tetiklenir).
2. **Üretim kontrol listesi**: hata izleme, geri alma provası, destek yolu.
3. Diğer ajanlar için CI tarafında aynı frenler.
4. Ana dalın 7 kayıt geride olması: `git fetch origin && git merge --ff-only`.
