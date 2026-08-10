---
name: obsidian-vault
description: VixRex'in insan tarafından okunacak proje belgelerinde arama yapar, kalıcı not oluşturur ve benzersiz wikilinklerle notları bağlar. Aktif görev planı için GitHub Issue kullanılır; Obsidian karar ve rota görünümüdür.
---

# VixRex belge kasası (Obsidian)

## Kasa nerede

`C:\Projects\vixrex` — kasa projenin kendisidir, ayrı bir klasör değildir.

Kod ve ham ajan çalışma klasörleri Obsidian ayarlarında gizlidir
(`.obsidian/app.json` içindeki `userIgnoreFilters`). Kasada insanın okuyacağı
kalıcı kaynaklar görünür:

```text
VIXREX_RULES.md                    değişmez ürün ve güvenlik kuralları
AGENTS.md                          tek ajan başlangıcı
docs/Ajan Calisma Akislari.md      insan için skill rota tablosu
docs/agents/repository-guide.md    teknik depo haritası
README.md
docs/                              şema, kalıcı karar, araştırma ve arşiv
```

Başlangıç sayfası: `docs/Vixrex Baslangic.md` — insan görünümündeki her ana kaynak oradan bağlanır.

## Kurallar

- **Yeni kalıcı notlar `docs/` içine yazılır.** Kök dizin kalabalıklaşmaz.
- Aktif görev kapsamı, planı ve ilerlemesi GitHub Issue’da tutulur. Obsidian’a ikinci bir görev planı kopyalanmaz.
- Yeni ana not eklendiğinde `docs/Vixrex Baslangic.md` içine benzersiz bir `[[bağlantı]]` eklenir.
- Dosya adlarında Türkçe karakter kullanma (`Vixrex Baslangic.md` olur, `Vixrex Başlangıç.md` olmaz).
- Bağlantı biçimi uzantısız wikilink’tir: `[[VIXREX_RULES]]`. Aynı ada sahip iki görünür not oluşturma.
- Geçmiş planlar `docs/arsiv/` altında içerik ve tarih belirten benzersiz adla saklanır.

## Yapılmayacaklar

- `VIXREX_RULES.md`, `AGENTS.md` ve GitHub issue kapsamı bu skill üzerinden serbestçe değiştirilmez; kendi yetki sözleşmeleri geçerlidir.
- Kod dosyalarına not olarak dokunulmaz.
- `.obsidian/` kişisel görünüm ayarları normal not işi sırasında düzenlenmez. Proje çapında kasa yönlendirmesi açıkça istenmişse değişiklik kanıtla yapılır.
- Kök `implementation_plan.md` veya aktif `docs/prompt*.md` oluşturulmaz.

## Sık işlemler

Dosya adına göre arama:

```bash
rg --files docs -g "*.md" | rg -i "anahtar"
```

İçeriğe göre arama:

```bash
rg -l "anahtar" docs -g "*.md"
```

Bir nota kimlerin bağlandığını bulma:

```bash
rg -l "\[\[Not Adi\]\]" -g "*.md"
```

Başlangıç bağlantıları ve ajan sistemi için proje doktoru:

```bash
python .github/scripts/verify_agent_system.py
```
