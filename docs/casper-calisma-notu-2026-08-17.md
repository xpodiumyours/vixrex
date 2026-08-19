# Casper ile çalışma notu (2026-08-17)

> Bu not **yalnız bana (yazılım ajanı)** — Casper'ı tanımak ve sohbetten
> kopmadan devam etmek için. Her oturumda önce buraya + CONTEXT.md'ye bak.
> Tarihli tutulur; değişen davranışlar görüldükçe güncellenir.

## Güncelleme kuralı (kullanıcı kararı, 2026-08-17)

**Her oturum sonunda** bu not güncellenir — ama dosya şişirilmez:

1. **Tespit et:** Bu oturumda ne değişti? (kararlar, durum, açık işler,
   öğrenilen dersler, bekleyenler)
2. **Yalnız değişen yerleri güncelle:** "Açık bekleyenler" bölümünü tazele,
   yeni ders varsa ekle, eski/yürürlükten kalkan satırları sil.
3. **Şişirme:** Günlük ayrıntı buraya YAZILMAZ — tarihsel akış CONTEXT.md
   ve `docs/arsiv/` içindir. Bu not kısa, öz ve yaşayan kalır.
4. Güncelleme "her oturum sonu" rutinidir; unutulursa bir sonraki oturum
   başında tamamlanır.

## Casper kim

- **VixRex'in %49 kar-zarar ortağı.** Ben (ajan) yazılımdan, güvenlikten
  ve gelişimden sorumluyum; **asıl gelişim ve yük benim omuzlarımda.**
  Kararlar onun onayına sunulur — "kararları benim onayıma sunarsın."
- **Teknik değil.** Kod/DB/jargon değil, iş ve ürün dili konuşur.
- **Vizyonu güçlü ve cesur:** tek başına devlere karşı çıkıyor, fikrine
  güveniyor, "değerli bir yoldayım" diyor. Bu coşku korunur; gerçekçi
  uyarılar nazikçe yapılır, asla küçümsenmez.

## İletişim stili (önemli — net kurallar)

- **Kısa, net, BASİT Türkçe.** Teknik terim varsa hemen sadeleştir.
- **Özet en sonda, basit dille** — "çok teknik konuşuyorsun, basit anlat"
  dedi; her işin sonunda sade bir özet ister.
- Uzun plan/çok seçenek kafasını karıştırır; **tek öneri + tek soru** ile
  ilerle, çoklu seçim gerekirse ask_user ile kolay tıklanır yap.
- **Git/merge kararları onun.** Onay almadan canlıya, main'e, remote'a
  dokunmam. PR'ları açabilirim, merge'i o onaylar (ya da açıkça yetki verir).
- Duygusal tarafı önemlidir: takdir, ilerleme hissi ve "yol değerli" mesajı
  ona enerji verir. Samimi ama abartısız ol.

## Öğrenilmiş dersler (2026-08-17)

- **"Sakinleş, yöntemlerini ve zihnini kontrol et" dediğinde ciddiye al.**
  Bir kez "API salt-okunur" diye yanlış sonuç çıkarıp onu gereksiz işe
  yönlendirmiştim (gerçek neden: istekte eksik User-Agent başlığı —
  Cloudflare engelliyordu). O haklı çıktı. **Sonuç çıkarmadan önce
  varsayımı kanıtla; yanıldıysam hızlıca kabul et ve düzelt.**
- "Testler yeşil ≠ kod doğru" — büyük pencereden, bağımsız gözle
  doğrulama ister (canlı DB'de saldırı simülasyonu gibi). Bunu yaptığımda
  gerçek bir güvenlik açığı yakaladım (premium süresi esnaf tarafından
  yazılabiliyordu) — onun ısrarı sayesinde.

## Disiplinler (onun için değişmez)

- **Güvenli geri dönüş her şeyin başında:** her adım geri alınabilir
  (git revert), yedek dal, CONTEXT.md'de güncel durum notu.
- **Önce migration'lar canlıya, sonra kod PR'ları** — tersi yarım sistem
  üretir (sessiz gelir sızıntısı / kırık ödeme).
- **PR'lar küçük, tek amaçlı, sırayla main'e.** Migration + test + kod bir
  arada. Biri bozulursa tek revert ile o parça geri alınır.
- **"MVP değil gerçek ürün"** — mevcut akışı ve güvenliği ön planda tut.
- **Sırlar mesajda yazılmaz** (DB şifresi, API anahtarları); env'e yazılır.
- Sözleşme testleri + kapsam nöbetçileri (verify_pr_scope, tıkla-düzenle
  nöbetçisi gibi) korunur, asla zayıflatılmaz.

## Ürün bağlamı (özet — detay vizyon belgesinde)

- Hedef: **4 ana iskelet + 19 katalog + 100 kiralanabilir vitrin** Keşfet
  ekranında hazır → uygulama güvenli kilitlenir → reklam → esnafa ulaşılır.
- Katmanlar: Kiralama (şimdi) → Al-Sat → Kurye/Teslimat → B2B. Hepsi
  vitrin tabanının üstüne biner. Detay:
  [[vizyon-katman-mimarisi-2026-08-17]]

## Nereden devam edilir (oturum başında)

1. `CONTEXT.md` — güncel teknik/ürün durumu + güvenli geri dönüş noktası
2. Bu not — Casper'ı tanıma
3. [[vizyon-katman-mimarisi-2026-08-17]] — yön
4. `gh pr list` — açık PR'lar (merge sırası onun onayıyla)
5. `gh issue list` — açık işler
6. PayTR numarası geldiyse: `docs/research/paytr-canli-kurulum.md` — adımlar hazır

## Açık bekleyenler (2026-08-17 sonu)

- PayTR panel numarası/anahtarları → Vercel env + callback + ilk ödeme teyidi
- Yeni APK dağıtıldı (vixrex-android-1.0.0-10017) — telefon testi devam
- Akış testi (kiralama → yayın kapısı → ödeme) sırada
- PR #216 (tıkla-düzenle) + #217 (vizyon) + #218 (bu not) merge onayı bekliyor
