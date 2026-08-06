---
name: obsidian-vault
description: VixRex proje belgelerinde arama yapar, not oluşturur ve notları birbirine bağlar. Kullanıcı bir kararı, planı, kuralı bulmak veya yeni bir not eklemek istediğinde kullanılır.
---

# VixRex belge kasası (Obsidian)

## Kasa nerede

`C:\Projects\vixrex` — kasa projenin kendisidir, ayrı bir klasör değildir.

Kod klasörleri Obsidian ayarlarında gizlidir (`.obsidian/app.json` içindeki
`userIgnoreFilters`). Kasada yalnız okunacak belgeler görünür:

```
VIXREX_RULES.md          değişmez kurallar
implementation_plan.md   13 fazlık plan
AGENTS.md                ajan kuralları
CLAUDE.md                teknik özet
README.md
docs/                    şema, kontrol listeleri, araştırma, raporlar
```

Başlangıç sayfası: `docs/Vixrex Baslangic.md` — her şey oradan bağlanır.

## Kurallar

- **Yeni notlar `docs/` içine yazılır.** Kök dizin kalabalıklaşmasın.
- Yeni not eklendiğinde `docs/Vixrex Baslangic.md` içine bir `[[bağlantı]]`
  eklenir. Bağlanmayan not kaybolur.
- Dosya adlarında **Türkçe karakter kullanma**
  (`Vixrex Baslangic.md` olur, `Vixrex Başlangıç.md` olmaz). Bazı araçlar
  Windows'ta bozuk okuyor.
- Bağlantı biçimi `[[wikilink]]`, uzantısız ve yolsuz: `[[VIXREX_RULES]]`.

## Yapılmayacaklar

- `VIXREX_RULES.md` ve `implementation_plan.md` bu skill üzerinden
  **serbestçe düzenlenmez.** Onlar karar belgeleridir; değişikliği
  kullanıcı onaylar.
- Kod dosyalarına not olarak dokunulmaz.
- `.obsidian/` klasörü elle düzenlenmez; Obsidian kendi yönetir.

## Sık işlemler

Dosya adına göre arama:
```bash
find /c/Projects/vixrex/docs -name "*.md" | grep -i "anahtar"
```

İçeriğe göre arama (Grep aracı tercih edilir):
```bash
grep -rl "anahtar" /c/Projects/vixrex/docs --include="*.md"
```

Bir nota kimlerin bağlandığını bulma:
```bash
grep -rl "\[\[Not Adi\]\]" /c/Projects/vixrex --include="*.md"
```

Başlangıç sayfasındaki bağlantıların hepsi çalışıyor mu:
```bash
grep -oE "\[\[[^]]+\]\]" "/c/Projects/vixrex/docs/Vixrex Baslangic.md" |
  tr -d '[]' | while read n; do
    find /c/Projects/vixrex -name "$n.md" -not -path "*/node_modules/*" |
      grep -q . && echo "OK    $n" || echo "KIRIK $n"
  done
```
