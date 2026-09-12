# Yayın akışı (dal → main → push → yayın)

Sıra: dalda çalış → main'e al → push'la → Vercel yayına alır.
Main'e almak yayına almak değildir — site ancak push sonrası değişir.

## Bu iş ne yapıyor

<!-- 2-3 cümle: ne değişti, neden -->

## Kontrol listesi

- [ ] İş ayrı dalda yapıldı, main'e doğrudan commit yok
- [ ] Dal, güncel `main` üzerine alındı (merge/rebase)
- [ ] İlgili testler geçti (`flutter test` / `public_web` vitest)
- [ ] Push sonrası Vercel deploy'u izlendi
- [ ] Canlıda doğrulandı (ilgili sayfa açılıp bakıldı)
