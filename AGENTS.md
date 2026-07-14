# Vixrex Project Rules

Bu dosya, prompt ne kadar kısa veya belirsiz olursa olsun bu repoda çalışan bütün
kod ajanları için bağlayıcıdır. Kullanıcının doğru teknik terimleri bilmesini
bekleme; mevcut mimariyi incelemek ve çelişki üretmemek ajanın sorumluluğudur.

## 0. Zorunlu okuma ve kural hiyerarşisi

Her AI ajanı herhangi bir dosyaya dokunmadan önce sırasıyla şunları tamamen okur:

1. [`PROJECT_RULES.md`](PROJECT_RULES.md) — kullanıcı anayasası, çalışma biçimi ve
   dokunulmaz alanlar için en üst kuraldır.
2. Varsa `SON_DURUM.md` — yalnız güncel oturum devridir.
3. Bu `AGENTS.md` — güncel teknik mimari ve repo sözleşmesidir.
4. İlgili alt dizindeki `AGENTS.md` ve görevle eşleşen `.agents/skills/*/SKILL.md`
   dosyaları — yalnız ek kural koyabilir, üst kuralları gevşetemez.

`PROJECT_RULES.md`, Furkan'ın açık onayı olmadan silinemez, yeniden adlandırılamaz,
kısaltılamaz veya etkisizleştirilemez. Kullanıcı anayasası ile güncel teknik bilgi
arasında çelişki görülürse ajan sessizce seçim yapmaz; değişiklikten önce Furkan'a
çelişkiyi açıkça bildirir ve yön ister.

## 1. Değişmez mimari sahiplik

Aşağıdaki sahiplik tablosu bağlayıcı mimari karardır.

| Yüzey | Tek sahibi | Kural |
|---|---|---|
| Mobil işletme uygulaması | Flutter | Public vitrin uygulama içinde `PublicVitrinScreen` ile açılır. |
| Web editör ve yönetim | Flutter | App host public müşteri HTML'i render etmez. |
| Web müşteri vitrini | Next.js `public_web` | `/v/:slug` ve alt rotaların tek web renderer'ıdır. |
| SEO, canonical, sitemap, robots | Next.js `public_web` | İkinci bir SEO shell veya API fallback oluşturulmaz. |

Aktif geçici originler:

- App: `https://vixrex-app.vercel.app`
- Public: `https://vixrex-public.vercel.app`

## 2. Paralel yol oluşturma yasağı

- Aynı kullanıcı akışı için ikinci renderer, router, API shell, rewrite veya
  sessiz fallback ekleme.
- Yeni uygulama bir eski yolun yerini alıyorsa, aynı task içinde eski yolu ve
  ölü referansları kaldır. Geçiş tamamlanmadan task'ı tamamlandı sayma.
- Web ve native davranışını açık platform koşuluyla ayır; mobil kullanıcıyı
  public web'e gönderme.
- Geçici deploy/domain hatasını yeni kalıcı kod yoluyla yamama. Önce mevcut
  host, route ve environment sahipliğini doğrula.
- Aktif ürün adı `Vixrex`tir. Arşiv/deneme kaynaklarını açık kullanıcı talebi
  olmadan yeniden adlandırma veya üretim akışına bağlama.

## 3. Zorunlu çalışma sırası

1. Önce `rg` ile mevcut ekran, route, service, fallback ve domain kullanımını ara.
2. Değişiklikten önce tek sahibin kim olduğunu yazılı mimariyle karşılaştır.
3. En küçük çözümü uygula; kapsam dışı UI veya özellik çalışması ekleme.
4. Değişen davranış için otomatik sözleşme testi ekle veya mevcut testi güncelle.
5. Eski yolun gerçekten kaldırıldığını repo taramasıyla doğrula.
6. Yerel test/build, ardından gerekiyorsa preview ve canlı kabul testi çalıştır.
7. Kanıt tamamlanmadan plan kutusunu `[x]` yapma ve “tamamlandı” deme.

## 4. Public vitrin değişiklik kapısı

Public vitrin, route, domain, Vercel veya navigasyon değişikliğinde en az şunlar
geçmelidir:

```powershell
flutter test test\architecture_routing_contract_test.dart test\public_site_config_test.dart
dart analyze
npm.cmd --prefix public_web run build
```

Ayrıca şu davranışlar doğrulanır:

- App host `/v/*`, `/sitemap.xml` ve `/robots.txt` isteklerini public hosta
  redirect eder; app host bunları rewrite/render etmez.
- Alt route ve query string korunur.
- Public `/v/:slug` Next.js HTML üretir ve Flutter bootstrap içermez.
- Native vitrin akışı Flutter içinde kalır.

Mevcut lint veya test borcu yeni hata eklemek için gerekçe değildir. Kapsam dışı
önceden var olan hata açıkça raporlanır; gizlenmez ve yanlışlıkla “geçti” denmez.

## 5. Plan sapması kontrolü

Her değişiklikten önce ve sonra sor:

1. Tek sahipliği güçlendiriyor mu?
2. Yeni bir paralel yol veya fallback yaratıyor mu?
3. Mobil kullanıcıyı uygulama dışına çıkarıyor mu?
4. Değiştirilen eski yol aynı task içinde emekli edildi mi?
5. Kod, test, README ve mimari belge aynı davranışı anlatıyor mu?

2 veya 3 için cevap “evet”, 4 veya 5 için cevap “hayır” ise değişikliği durdur;
mimari karar netleşmeden uygulama yapma.

## 6. Alt dizin kuralları

Bir alt dizinde başka `AGENTS.md` varsa bu kök kurallara ek olarak uygulanır.
Özellikle `public_web/AGENTS.md`, Next.js sürümüne ait yerel dokümantasyonu
okumayı zorunlu kılar.
