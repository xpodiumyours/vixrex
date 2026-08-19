# 0003 — Vault/bağlam kuralı: kod kazanır, not güncellenir

## Durum

Kabul edildi (2026-08-15).

## Bağlam

Kullanıcı (Casper), bu repoyu zaten kendi Obsidian kurulumuyla (`.obsidian/`
repo kökünde) geziyor. Uzun bir ajan oturumu raydan çıktığında ya da yeni
bir model/oturum işe başladığında, 100+ mesajlık geçmişi yeniden anlatmak
yerine birkaç temel notu okutup doğrudan işe başlatmak istedi.

Aynı oturumda somut bir örnek zaten bulunmuştu: `AGENTS.md`, "kalıcı ürün
ve mimari kararlar" için `CONTEXT.md` dosyasına işaret ediyordu ama o dosya
hiç yoktu — yani rehber, olmayan bir dosyaya güveniyordu. Bu, "not"un koddan
(veya bu durumda repo'nun gerçek dosya yapısından) sessizce sapabileceğinin
kanıtıydı.

## Karar

**Kod/runtime = mevcut teknik gerçek. `CONTEXT.md` + `docs/adr/` = onaylanmış
hedefler ve kararlar (Vault).**

Çelişki çıkarsa **kod kazanır** — Vault güncellenir, kod Vault'a
uydurulmaz. Gerekçe: kod her zaman çalışan/doğrulanabilir gerçek; bir not
eskiyip unutulsa bile kimse fark etmeyebilir (`CONTEXT.md` örneğinde
olduğu gibi — dosya yoktu, kimse fark etmedi).

Pratik uygulama:
1. Bir ajan `CONTEXT.md`/ADR'de bir iddia okur, kodda doğrulayamazsa —
   önce kodu doğru kabul eder, notu düzeltir. Tersini yapmaz.
2. Ürün hedefi/mimari karar değişikliğinde önce ADR/`CONTEXT.md`
   güncellenir (kod değişikliğiyle aynı PR'da veya hemen ardından) —
   ama "not güncellemesi kod değişikliğini bekletmez", tersi de olmaz.
3. `CONTEXT.md`'nin "Şu anki teknik/ürün durumu" bölümü en hızlı eskiyen
   kısım olarak işaretlenir — okuyan taraf orayı özellikle şüpheyle
   okumalı, kodla çapraz kontrol etmeli.

## Kapsam dışı

- Bu kural VIXREX_RULES.md'nin kanıt seviyesi / doğrulama disiplinini
  DEĞİŞTİRMEZ, onu tamamlar — "canlıda doğrulanmadı" gibi ifadeler hâlâ
  geçerli, Vault bunun yerine geçmez.
- Kullanıcının kişisel Obsidian vault'u (`C:\Users\Casper\Obsidian Vault\`)
  bu kararın kapsamı dışında — bu yalnız VixRex reposundaki (proje-özel,
  git-takipli) notlar için geçerli.
