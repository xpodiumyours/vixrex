# Akışlar

## Değişiklik riskine göre rota

| Risk | Durum | Skill akışı | Çıkış |
|---|---|---|---|
| Hafif | Doküman | `vixrex-router` | Diff |
| Normal | Davranış | `tdd` → `code-review` | Kanıt |
| Zor bug | Belirsiz hata | `diagnosing-bugs` → `tdd` → `code-review` | Kanıt |
| Yüksek risk | Güvenlik | `tdd` → `code-review` | Tam kapı |

Çakışmada yüksek risk kazanır.
Aynı diff üzerinde aynı skill ikinci kez çalışmaz.
Bir oturum yalnız bir issue/PR üzerinde çalışır.

## Son
