# Adresler — nerede ne var

Karışıklık bitsin diye tek kart. Başka adres yok.

---

## Kod nerede

**`main` dalı — tek gerçek.** Başka dalda duran iş "yapılmış" sayılmaz.

GitHub: `github.com/xpodiumyours/vixrex`

---

## Canlıya nasıl çıkar

1. İş bir dalda biter
2. PR açılır → CI kontrolleri geçer
3. `main`'e squash ile birleşir
4. **Vercel kendiliğinden production'a kurar** — elle bir şey yapılmaz

`main` korumalı: doğrudan push kapalı, düz geçmiş zorunlu.

---

## Canlıda test

**Uygulama** — karşılama, kurulum sohbeti, Vitrinim paneli
```
https://vixrex-app.vercel.app
```

**Vitrin** — müşterinin gördüğü sayfa
```
https://vixrex-public.vercel.app/v/<vitrin-adi>
```

Bu ikisi yeter. Vercel'de yalnız **iki proje** var: `vixrex-app` ve
`vixrex-public`. (Panelde "vixrex-uygulaması" görünüyorsa Chrome sayfayı
Türkçeye çeviriyordur — ayrı proje değil.)

### Test ederken

Flutter web servis çalışanı kaydediyor; sekmeyi kapatmak eski kopyayı
temizlemiyor. **Yeni bir sürümü denerken gizli sekme kullan.**

---

## Kullanılmayan adresler

- `vixrex.com` — alan adı **bağlı değil**, açılmıyor. Paylaş kutusunda
  bu adres gösteriliyor; düzeltilecek (tur bulgusu).
- `localhost:3000` / `localhost:5000` — yerel sunucular. Canlı testte
  kullanma, eski yapılandırmayla çalışıp yanıltır.
- `...-git-<dal>-...vercel.app` — dal önizlemeleri. Dal main'e indiyse
  bunlara bakma.

---

## E2E otomasyonu nerede koşar

**Yerelde, yerel Supabase ile** (`127.0.0.1:54321`). Buluta asla
bağlanmaz — testler veri yaratıp siliyor.

```
cd public_web
npm run e2e
```

Ayrıntı: `docs/e2e-otomasyon-plani.md`

---

## Özet

| Ne | Nerede |
|---|---|
| Kod | `main` dalı |
| Canlıya çıkış | PR → main → otomatik |
| Uygulama testi | `vixrex-app.vercel.app` |
| Vitrin testi | `vixrex-public.vercel.app/v/<slug>` |
| E2E otomasyonu | yerel, `npm run e2e` |
