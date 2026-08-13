# 0002 — Vixrex Asistan: iskelet vitrini rehberli tamamlama

## Durum

Kabul edildi (2026-08-12).

## Bağlam

Yeni kullanıcı, Flutter onboarding'de yalnız 4 alanı cevaplayıp (işletme
adı, kategori, WhatsApp, konum) + yasal onayla vitrini yayınlıyor —
"iskelet" bir vitrin. Sonra Next.js sahiplik paneline (`/v/:slug`)
yönlendiriliyor; orada "Vixrex Asistan" sohbeti var.

Sorun: Keşfet'teki örnek vitrinler (TeknoFix vb.) çok daha dolu/kaliteli.
İskeletle karşılaşan kullanıcının oraya ulaşması için bugün elinde:
- Sohbet açılışında **tek seferlik** bir "doluluk %X" mesajı ve tek bir
  "sonraki eksik alan" cümlesi (`vitrinReadiness.ts` → `assistantHandoff.ts`).
- Alan doldurulduktan sonra **devam eden bir yönlendirme yok** — kullanıcı
  kendi başına hangi alanı dolduracağını bulmak zorunda.
- `sablonlar/hedef-vitrin.html` içinde, üretim koduna hiç bağlı olmayan bir
  **JS prototip** var: sohbet çekmecesi, adım adım soru, hazır resim/paket
  seçme düğmeleri — ama gerçek AI çağırmıyor, tamamen senaryolu/JS state
  machine. Bu prototip "hedef deneyimin" ne olduğunu gösteriyor.

ADR 0001 (`0001-vixrex-core-omurga-ve-uzman-beyinler.md`), Flutter'ın
`VixRexGuidanceService`'i (fazlı rehberlik motoru) ile Next.js'in
`vitrinReadiness.ts`'ini (doluluk raporu) BİLİNÇLİ olarak birleştirmedi,
"bunu birine bağlamak ayrı bir tasarım kararı gerektirir" dedi. Bu ADR o
kararı — sadece Next.js tarafı için — veriyor.

## Karar

1. **Motor senaryolu/kurallara dayalı kalır, gerçek AI çağrılmaz.**
   Prototipteki mekanizma zaten böyle (canned mesaj + düğme), gerçek AI
   değil. Next.js tarafında bugün hiç LLM entegrasyonu yok (Flutter'ın
   NLU'su da `assistantEnabled = false` ile kapalı). Maliyet, gecikme ve
   tutarsız-cevap riski olmadan, mevcut `vitrinFieldSchema.ts` +
   `vitrinReadiness.ts` üzerine inşa edilir.
2. **Düzenlenebilir alanlar her zaman görünür şekilde işaretli/tıklanabilir
   kalır** — bugünkü gibi yalnız bir alan seçildikten sonra değil, vitrin
   ilk açıldığı andan itibaren (`data-vixrex-editable` işaretli her öğe
   üstünde sürekli hafif bir vurgu/ışıma).
3. **Gezinme melez:** Asistan bir sıra ÖNERİR (temel → kalite alanları,
   `vitrinReadiness.ts`'teki `eksikler` sırasıyla) ama kullanıcı istediği
   an vitrinde başka bir alana tıklayıp oraya atlayabilir — sıra bir kilit
   değil.
4. **"İsteğe bağlı" alan sessizce arka planda kalmaz — hepsi 44 alan
   yönlendirmeye dahildir, kullanıcı bilerek atlar.** İlk tasarımda
   yalnız 4 temel + 7 kalite alan (11) hedeflenmiş, 33 `istege-bagli` alan
   hedefe dahil edilmemişti — bu YANLIŞ bulundu ve değiştirildi (2026-08-13,
   kullanıcı kararı). Gerekçe: "vitrin" (minimal) ile "web sitesi" (tam
   dolu) arasındaki farkı sistem sessizce belirlememeli, kullanıcı açıkça
   karar vermeli. Rehberli sıra bu yüzden **temel → kalite → isteğe bağlı**
   sırasıyla tüm 44 alanı gezer; her isteğe bağlı alanda kullanıcı
   "boş geç" diyebilir (blok, alanı `sonrakiAdim`'e işaretlemez, sırada
   ilerler) — atlamak sessiz varsayım değil, görünür bir eylem olur.
   "Doluluk %" göstergesi de buna göre güncellenir: bugünkü hesap yalnız
   11/11 üstünden gidiyor (`vitrinReadiness.ts:79-80`), artık 44 alan
   üstünden (dolu + bilerek-atlanmış = "işlem görmüş" sayılır, hiç
   sorulmamış olanlardan ayrı) gösterilmesi gerekir — bu ayrım Faz 1
   tasarımında netleştirilecek.
5. **Prototipteki interaktif bileşenler (resim seçici, hazır paket, bölüm
   aç/kapa, renk paleti) ilk fazda YOK** — önce düz metin adım-adım akış +
   kalıcı vurgulama kurulur, interaktif seçiciler sonraki fazlara bırakılır
   (küçük, tek başına gönderilebilir PR'lar — bkz. controller parçalama
   faz disiplini, `docs/agents/store-editor-controller-parcalama.md`).

## Sonuçlar

- `sablonlar/hedef-vitrin.html`'in JS motoru referans/ilham olarak
  kullanılır, koddan kopyalanmaz (VIXREX_RULES zaten bu dosya için "görünüş
  alınır, içerik alınmaz" diyor — burada "davranış deseni alınır, JS'i
  aynen taşınmaz" olarak genişletiliyor).
- Bu iş de fazlara bölünecek; her fazın kesin kapsamı o faza gelindiğinde,
  o anki koda bakılarak ayrıca planlanır (bkz. Kademeli planlama).
