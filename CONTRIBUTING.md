# Katkıda Bulunma

VixRex, tek geliştirici (repo sahibi) ve ona yardım eden yapay zekâ
ajanları (Claude, ChatGPT, Codex vb.) tarafından geliştirilen kapalı
kaynaklı bir projedir. Dışarıdan katkı süreci (fork/PR akışı) açık
değildir.

## Bu depoda çalışırken

Bu depodaki çalışma kuralları, kalite kapıları ve komutlar için tek
kaynak `CLAUDE.md` dosyasıdır — hem insan hem de yapay zekâ ajanları için
geçerlidir. Bir değişiklik yapmadan önce onu okuyun.

Kısa özet:

- Değişiklikler ayrı bir dalda yapılır, doğrudan `main`'e commit
  edilmez.
- PR açmadan önce ilgili kalite kapılarını (`dart format`/`dart
  analyze`/`flutter test`, `npm run lint`/`typecheck`/`test`/`build`)
  yerelde çalıştırın.
- CI'daki gerçek kapılar `.github/workflows/ci.yml` içindedir.

## Güvenlik açığı bildirimi

`SECURITY.md` dosyasına bakın.
