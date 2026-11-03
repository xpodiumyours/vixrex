# CLAUDE.md — yönlendirme

Bu dosya kural içermez. VixRex'te çalışma kuralları [AGENTS.md](AGENTS.md) dosyasındadır;
burada yalnız açılış yolu yazılır.

Her oturumun başında:

1. `pwsh -NoProfile -File tool/ajan-baslangic.ps1` — açılış kapısı (çıkış kodu 0-4).
2. `docs/AJAN-BASLANGIC.md` — hangi bilgi hangi platformdan okunur.

Kapı çıktısı olmadan "durum şu", "düzeldi", "canlıda" denmez. Anahtar, platform, defter
yolu veya dosya adı sorulmaz; haritaya bakılır, ölçülemiyorsa "ölçemedim" denir.

Graphify ve platform kanıtı: kod değişikliğinden önce `graphify affected "Sembol"` ile
etkiyi çıkar; harita bayatsa `graphify update .`. Bağlantı durumu (BAĞLI / YETKİSİZ /
ERİŞİLEMEDİ) yalnız kapı raporundaki ölçümle yazılır. Erişim salt okunurdur; yazma,
deploy, migration ve preset düzenleme açık onay ister.
