# VixRex plan öncesi kanıt sözleşmesi

Bu sözleşme, ajanın planı PR anlatısı, donmuş not veya yüzeysel bir tarama üzerine
kurmasını önleyen tek başlangıç fotoğrafını tanımlar.

## Kaynakların rolleri

- Kullanıcı talebi ve GitHub Issue: hedef, kapsam, karar ve ilerleme kaynağıdır.
- Aynı HEAD üzerindeki Git durumu, gerçek diff ve çalışan komut artefaktı: mevcut
  durum kanıtıdır.
- PR gövdesi, commit mesajı ve genel doküman: iddia veya indekstir; tek başına
  “çalışıyor” kanıtı değildir.

Çelişkide öncelik şöyledir:

```text
runtime artefaktı
  > repo ve gerçek diff
  > executable config / migration / test / kaynak kod
  > Issue hedefi
  > genel doküman
  > PR/commit anlatısı
```

## Tek komut

Değişiklik işinde Issue okunduktan sonra, plan ve kod değişikliğinden önce:

```powershell
python .github/scripts/vixrex_evidence.py --issue <numara> --base origin/main
```

Dış interface yalnız `--issue` ve `--base` seçenekleridir. Komut başka repo veya
çıktı dizinine yazma seçeneği sunmaz.

## Çıktı

Her koşu çakışmayan bir dizine atomik olarak iki dosya yayımlar:

```text
.vixrex-dev/<worktree-id>/<run-id>/evidence.json
.vixrex-dev/<worktree-id>/<run-id>/summary.md
```

`.vixrex-dev/` Git tarafından yok sayılır. JSON asıl makine kaydıdır;
`summary.md` yalnız onun insan görünümüdür.

Snapshot şunları aynı kayıtta tutar:

- repo, worktree ve linked Git dizini;
- branch, pinlenmiş HEAD/base/merge-base SHA;
- committed, staged, unstaged ve untracked dosyalar;
- Issue URL/state/update zamanı, gövde hash'i, etiketler ve yorum hash'leri;
- yalnız exact HEAD OID ile eşleşen PR metadata'sı ve GitHub'ın bildirdiği tam
  değişen dosya listesi;
- bulgular, report-only sonucu ve deterministik snapshot hash'i.

Ham Issue/PR gövdeleri ve secret değerleri artefakta yazılmaz. Git komutları
optional lock kapalı çalışır. Staged, unstaged ve untracked içerik değerleri
saklanmadan hashlenir; Issue ve exact-HEAD PR içeriği kapanışta yeniden okunur.
Snapshot sırasında HEAD, dosya listesi, dosya içeriği, Issue veya PR değişirse
artefakt yayımlanmaz.

`snapshot_sha256`, üretim zamanı ve `integrity` alanının kendisi dışındaki bütün
kararlı manifest alanlarını kapsar. Böylece worktree, kaynak hiyerarşisi veya
sonuç değiştirilip eski hash geçerli bırakılamaz.

## Sonuçların anlamı

- `verified`: doğrudan gözlem var ve kontrol edilen koşulla uyumlu.
- `contradicted`: daha güçlü repo kanıtı anlatıyla açıkça çelişiyor.
- `unverified`: iddiayı doğrulayacak HEAD-bağlı artefakt yok; doğru veya yanlış
  ilan edilmez.

Bu T0 sürümü test veya canlı-smoke komutu çalıştırmaz. “Çalışıyor”, “CI yeşil”,
“smoke başarılı”, “tests passed” ve eşdeğer test/canlı doğrulama cümleleri iddia
olarak sınıflandırılır. PR gövdesinde doğru HEAD
SHA ve bir `evidence.json` yolu yazması yalnız anlatı metadata'sıdır; dosyanın
varlığı, bütünlüğü ve ilgili çalıştırma kaydı doğrulanmadığı için test/canlı
iddiası yine `unverified` kalır. Çalıştırma kanıtı sonraki yerel runtime/E2E
katmanında ayrı bir sözleşmeyle bağlanacaktır.

İlk sürüm `report-only` çalışır. Bu nedenle advisory bulgu process exit kodunu
bozmaz; fakat JSON içindeki `would_exit` gelecekte enforce edilse oluşacak sonucu
korur. Çelişkili rapor `[OK]` yazmaz.

`dirty_worktree`, tek başına hata değildir; snapshot'ın hangi yerel değişiklikler
üzerinde alındığını görünür kılan doğrulanmış bilgidir.

## Ne zaman yeniden çalıştırılır

- HEAD, staged/unstaged/untracked durum veya bağlı Issue değiştiğinde;
- planın kapsamı değiştiğinde;
- PR kanıtı hazırlanırken.

Komut yapısal olarak çalışamazsa ajan “kanıt alınamadı” der; PR/doküman metninden
mevcut durum sonucu uydurmaz. Bu sürüm Issue, PR, kod, canlı sistem veya dış veri
üzerinde yazma yapmaz.
