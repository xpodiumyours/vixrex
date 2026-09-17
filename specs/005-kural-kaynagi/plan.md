# Plan

## Ölçüm

Resmî doküman "Claude Code reads CLAUDE.md, not AGENTS.md" diyor ve çözüm
olarak CLAUDE.md içine `@AGENTS.md` içeri alma satırını gösteriyor. Depoda bu
satır yoktu; AGENTS.md yalnız yanlış bir notta geçiyordu.

## Çözüm

CLAUDE.md dosyasında üç değişiklik:

1. En başa `@AGENTS.md` satırı ve bu dosyanın yalnız Claude'a özel ekleri
   tuttuğunu, ortak süreci daraltamayacağını söyleyen kısa bölüm.
2. Onay maddesi yeniden yazıldı: onay Keşif kaydında alınır, sonrasında teknik
   ayrıntı tekrar sorulmaz, ürün sonucu doğuran karar ayrıca sorulur. Eski
   hâlin neden değiştiği ve korumanın gevşemediği yazıldı.
3. AGENTS.md'nin kaldırıldığını söyleyen not düzeltildi.

## Geri alma

Tek commit; geri alınması tek commit'in geri alınmasıdır, ürün davranışını
etkilemez.
