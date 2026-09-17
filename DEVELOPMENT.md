# Vixrex Gelişim Sistemi

Bu sistem bir ajana veya araca özel değildir. Vixrex'te çalışan herkes aynı
Anayasa'yı, aynı kayıt biçimini ve aynı GitHub kapısını kullanır.

Kaynak: GitHub Spec Kit. Resmî çekirdek yol Specify → Plan → Tasks →
Implement → Converge'dir. Clarify, Checklist ve Analyze resmî belgede her işte
zorunlu değildir; gerektiğinde açılan kalite kapılarıdır. Vixrex bu çekirdeğin
başına kendi **Keşif** halkasını ekler.

Temel kural: **iş zincire uymaz, zincir işe uyar.** Bir düğmenin hizası için
veritabanı kapısı açılmaz; asistanın davranışı değişiyorsa veri, güvenlik ve
görsel kanıt kendiliğinden devreye girer.

## Bir özellik istediğinde ne oluyor

Sen doğal Türkçeyle söylüyorsun. Örnek: "Vixrex Asistan daha akıllı olsun ama
çalışan sistemi bozmayalım."

1. **Ajan bugünkü hâli araştırır.** Hangi dosyalar, hangi akış, hangi testler.
   Sana "hangi dosyayı değiştirelim" diye sorulmaz.
2. **Keşif kaydı yazılır** (`kesif.md`): bugün ne var, gelişim nereden başlar,
   nerede biter, ne ve nasıl gözükecek, esnafa/Vixrex'e/tüketiciye ne katar,
   **ne korunacak**, neye dokunulmayacak, karar gerekiyorsa tek soru.
3. **Sen onaylarsın.** Onaydan önce ürün kodu değişmez.
4. Çekirdek yol yürür: Specify → Plan → Tasks → Implement → Converge.
5. **Risk kadar kapı açılır.** Ekran değiştiyse görsel kanıt, veritabanı
   değiştiyse canlı doğrulama, yetki değiştiyse güvenlik denemesi.
6. PR ile teslim edilir; ana dala alınması canlı yayın değildir.

## İş türleri

### Yeni özellik veya davranış değişikliği

Zorunlu sıra: Anayasa → Keşif → Specify → Plan → Tasks → Implement → Converge
→ Review / PR.

Kayıtlar: `kesif.md`, `spec.md`, `plan.md`, `tasks.md`, `zincir.md`.

### Hata düzeltmesi

Hatayı yeniden gör → gerçek sebebi bul → en küçük doğru düzeltmeyi uygula →
asıl hatayı tekrar dene → incelemeye gönder.

Kayıtlar: `root-cause.md`, `tasks.md`, `zincir.md`. Düzeltme yeni kullanıcı
sonucu, veri yapısı, güvenlik kuralı, ekran akışı veya yayın davranışı
doğuruyorsa tam zincire geçirilir.

### Bakım

Bağımlılık sürümü ve üretilen dosyalar (`package.json`, kilit dosyaları,
`*.g.dart`) tek başına değişiyorsa iş kaydı gerekmez; kapı kendiliğinden geçer.

### Yeni fikir veya araştırma

Önce mevcut ürün ve kanıtlar araştırılır. Sonuç "yapalım", "yapmayalım" veya
"karar için şu bilgi eksik" olarak kaydedilir. Karar verilmeden ürün kodu,
veritabanı veya yayın ayarı değiştirilmez. Araştırma kayıtları `specs/<iş>/`
altında kalır; ürün kodu değişmediği için kapı karışmaz.

## Gerektiğinde açılan kalite kapıları

Kapılar `zincir.md` içinde `KAPILAR:` satırında adlarıyla açılır ve her açılan
kapının kanıtı yazılır. Açılmayan kapı çalıştırılmaz.

- `veri` — veritabanı değişti; göç canlıda uygulandı ve doğrulandı.
- `görsel` — ekran değişti; gerçek tarayıcıda görüldü, adresi yazıldı.
- `güvenlik` — yetki veya erişim değişti; herkes, misafir ve giriş yapmış
  kullanıcı ile denendi.
- `eşitlik` — hem Flutter hem Next.js etkilendi; ikisi aynı sonucu veriyor.
- `clarify`, `checklist`, `analyze` — belirsizlik veya çelişki riski varsa
  Spec Kit'in kendi kapıları açılır ve çıktısı iş klasörüne yazılır.

`supabase/migrations/` altında bir değişiklik varsa `veri` kapısı zorunludur;
kapı bunu kendisi ölçer.

## Ortak GitHub kapısı

`zincir.md` ilk bölümünde tam olarak bir iş türü bulunur: `İŞ TÜRÜ: özellik`,
`İŞ TÜRÜ: değişiklik` veya `İŞ TÜRÜ: hata`.

Kapının aradığı tam yazımlar:

1. **Aşama satırları** — özellik ve değişiklik için `- [x] Anayasa`,
   `- [x] Keşif`, `- [x] Specify`, `- [x] Plan`, `- [x] Tasks`,
   `- [x] Implement`, `- [x] Converge`, `- [x] Review / PR`; hata için
   `- [x] Anayasa`, `- [x] Hata tekrarlandı`, `- [x] Sebep bulundu`,
   `- [x] Implement`, `- [x] Converge`, `- [x] Review / PR`.
2. **Kapanış satırları** — `zincir.md` içinde `KAPILAR:`, `YAKINSAMA: tamam`,
   `İNCELEME: hazır`; açılan her kapı için `KANIT <ad>: <kanıt>`.
3. **Gerçek yollar** — `kesif.md` (en az iki satır) ve `root-cause.md` (en az
   bir satır) içindeki `ÖLÇÜLDÜ:` yolları depoda gerçekten bulunmalıdır.
4. **Kayıtta geçmeyen değişiklik yok** — değişen her ürün dosyası iş
   kayıtlarında en az bir kez geçmelidir.

Kapı belgelerin varlığını ve bu işaretleri ölçer; işin doğruluğunu ölçmez.
Doğruluğun kanıtı açılan kapılardadır: gerçek kullanıcı yolu, gerçek tarayıcı,
yazılı adres.

## Yayın ayrı bir karardır

Ana dala alma canlı yayın değildir. Git kaynaklı otomatik yayın kapalı tutulur.
Canlı yayın ancak kontroller yeşil, önizleme gerçek kullanıcı yolunda
doğrulanmış, geri alma yolu hazır ve Furkan açıkça yayın kararı vermişse
ayrıca başlatılır.
