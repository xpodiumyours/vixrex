# Katkıda Bulunma

VixRex, tek geliştirici (repo sahibi) ve ona yardım eden yapay zekâ
ajanları (Claude, ChatGPT, Codex vb.) tarafından geliştirilen kapalı
kaynaklı bir projedir. Dışarıdan katkı süreci (fork/PR akışı) açık
değildir.

## Bu depoda çalışırken

Bu depodaki çalışma kurallarının tek adresi `AGENTS.md` dosyasıdır — hem
insan hem de yapay zekâ ajanları için geçerlidir. Bir değişikliğe
başlamadan önce onu okuyun. Kuralları başka bir dosyada tekrarlamayın: iki
kopya zamanla ayrışır ve çelişki doğar.

Kısa özet:

- Çalışma kuralları ve işlem sırası: `AGENTS.md`.
- Değişiklikler ayrı bir dalda yapılır, doğrudan `main`'e commit
  edilmez; ana dala giriş PR iledir.
- Kalite kapıları yerelde koşulur; merge öncesi `bash tool/merge-hazir.sh`.
  Gerçek/kalan kapı listesi `.github/workflows/ci.yml` içindedir.

## Güvenlik açığı bildirimi

`SECURITY.md` dosyasına bakın.
