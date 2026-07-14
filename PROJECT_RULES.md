# VIXREX — PROJE ANAYASASI

> Bu dosyayı her yeni AI konuşmasının (Claude, Cursor, ChatGPT, Gemini fark etmez) EN BAŞINA yapıştır.
> Ajan bu kuralları okumadan hiçbir kod yazmaz, hiçbir dosyaya dokunmaz.

---

## 0. BEN KİMİM (AJAN BUNU BİLMELİ)

- Kodlama bilmiyorum, İngilizce bilmiyorum, teknik terim bilmiyorum.
- Detaylı prompt yazamam. "Şunu ekle" dersem, eksik ne varsa SEN sor, ben detaylandırmayı bilmiyorum diye susmayacaksın.
- Her cevabı Türkçe ver. Teknik terimi parantez içinde İngilizcesiyle yaz.
- Uzun, tekrarlı, teorik cevap istemiyorum. Kısa, net, aksiyon odaklı konuş.

---

## 1. DOKUNULMAZ ALANLAR (BUNLARI ASLA BOZMA)

- Canlı önizleme (live preview)
- Yerel kayıt (local save)
- Tema sistemi (dark/light switcher)
- Mobil tab yapısı (Düzenle / Canlı Önizleme / Yayınla)
- Masaüstü iki sütun düzeni (sol editör / sağ telefon önizleme)
- Sticky butonlar

Bunlardan biri bir görev sırasında bozulma riski taşıyorsa, KODU YAZMADAN ÖNCE bana söyle.

---

## 2. YASAK: SESSİZCE ÖLÜ KOD / BAĞLANMAMIŞ WIDGET BIRAKMAK

- Bir widget'ı ekrana koyuyorsan, `onPressed`, `onChanged`, `onTap` gibi callback'ler BOŞ (`() {}`) OLAMAZ.
- Boş bırakman gerekiyorsa: kod içine `// TODO: bağlanmadı` yaz VE cevabının sonunda "şunu bağlamadım çünkü X" diye açıkça söyle.
- Bir dosya/fonksiyon/widget artık hiçbir yerden çağrılmıyorsa (dead code), sildiğini veya sildiğini önerdiğini belirt. Sessizce "tamamlandı" deme.
- Bir görevi "tamamlandı" olarak işaretlemeden önce gerçekten uçtan uca çalıştığını doğrula. Varsayımla "tamam" deme.

---

## 3. ÇALIŞMA DÜZENİ (İŞ AKIŞI)

1. **Küçük görev → test → commit.** Büyük refactor YOK. Bir seferde bir şey.
2. Her değişiklikten sonra:
   - `flutter analyze` çalıştır
   - Değişen dosyaları listele
   - Ne test edilmesi gerektiğini bana söyle (ben nasıl test edeceğimi bilmiyorum, adım adım söyle)
3. Bir görev bittiğinde bana şunu rapor et:
   - Ne değişti (1-2 cümle, teknik jargon minimum)
   - Ne test etmemi istiyorsun
   - Hangi dokunulmaz alana (madde 1) yakın çalıştın, riski var mı

---

## 4. GÜVENLİK

- API key, Supabase key, hiçbir gizli bilgi asla kod içine veya GitHub'a yazılmaz.
- Her şey `--dart-define` ile verilir.

---

## 5. API MALİYET KONTROLÜ (SINIR ŞART)

Herhangi bir yeni API (OCR, Claude Vision, ödeme, vb.) entegre edilecekse, kod yazılmadan ÖNCE şunlar konuşulur ve kurulur:

- İlgili platformda (Anthropic Console, Google Cloud, vb.) **aylık sert harcama limiti** kurulmadan hiçbir API canlıya (production) alınmaz.
- Mümkünse limit dolunca API'yi OTOMATİK DURDURAN bir ayar seçilir, sadece uyarı veren değil.
- Kod tarafında rate limit (dakikada/kullanıcı başına istek sınırı) eklenir — sonsuz döngü/tekrarlayan istek riskine karşı.
- Yeni özellik önce sahte/mock veriyle test edilir, gerçek API sadece son onay aşamasında çağrılır.
- Limit ve rate limit kurulumu benimle (Furkan) birlikte, adım adım yapılır — ajan tek başına "kurdum" deyip geçemez, ekran görüntüsüyle doğrularım.

---

## 6. EKRAN GÖRÜNTÜSÜ ATTIĞIMDA

Ben "şurası bozuk", "bunu böyle istemiyorum" derim ama neyin teknik olarak yanlış olduğunu tarif edemem. Ekran görüntüsü + kısa cümle geldiğinde:

1. Önce görüntüde NE gördüğünü kendi cümlenle özetle (hangi ekran, hangi widget'lar, ne durumda).
2. Benim yazdığım kısa cümleyi bu görüntüyle eşleştir. Eşleşmiyorsa veya birden fazla anlama geliyorsa, tahmin etme — bana 2-3 seçenek sun:
   - "Bunu mu demek istedin: A) ... B) ... C) ..."
3. Netleşince, hangi dosya/widget'ın etkilendiğini söyle, sonra kodu yaz.
4. Değişiklik bittiğinde bana yeni bir ekran görüntüsü isteyeceğini söyle — "önce/sonra" karşılaştırması yap, ben görsel olarak onaylayayım. Kod satırı okuyup onay veremem, göz ile kontrol ederim.

Asla "anladım" deyip görüntüyü görmeden veya doğrulamadan direkt kod yazma.

---

## 7. OTURUM DEVİR TESLİM (SON_DURUM.md)

Her görev bitiminde `SON_DURUM.md` dosyasını GÜNCELLE — yeni satır EKLEME, dosyanın TAMAMINI SİL ve yeniden yaz. Bu bir günlük/defter değil, TEK BİR anlık fotoğraf. Eski kayıt kalmaz, sadece "şu an" kalır.

İçeriği sabit format, max 6 satır:
```
TARİH: ...
BUGÜN YAPILAN: ...
YARIM KALAN: ...
SIRADAKİ ADIM: ...
DOKUNULAN DOSYALAR: ...
DİKKAT: (varsa risk/uyarı, yoksa "yok")
```

Yeni bir AI/oturum başladığında, PROJECT_RULES.md ile birlikte bu dosyayı da oku — geçmiş oturumları değil, sadece bu son fotoğrafı dikkate al.

---

## 8. BİTTİ SAYILIR MI (DEFINITION OF DONE)

Bir görevi "tamamlandı" demeden önce ajan şu 3 soruyu KENDİNE sorup cevaplamalı, cevapları bana göstermeli:

1. Widget/buton gerçekten ekrana bağlı mı, yoksa görünüp çalışmıyor mu?
2. Bu özelliği tetikleyen (onPressed/onChanged/onTap) gerçekten bir işlev çalıştırıyor mu, yoksa boş mu?
3. Furkan bunu nasıl test edecek — adım adım söylendi mi (ben teknik değilim, "test et" demek yetmez)?

Üçüne de "evet" diyemiyorsa, görev "tamamlandı" değil "kısmi" olarak raporlanır.

---

## 9. NE ZAMAN BENİ UYARACAKSIN

- Prompt'um belirsizse: varsayımını söyle, devam et, ama varsaydığını açıkça yaz.
- Fikrim teknik olarak zayıfsa veya gereksizse: yumuşatmadan söyle, nedenini açıkla.
- Bir çözüm "hızlı ama kırılgan" ile "yavaş ama sağlam" arasında seçimse: ikisini de söyle, hangisini önerdiğini belirt.

---

## 10. PROJE BAĞLAMI (KISA ÖZET)

Vixrex: Türkiye'deki küçük işletmeler için dijital vitrin platformu.
- Stack: Flutter (App) + Next.js (Public Web) + Clean Architecture + Supabase + GitHub
- Repo: `xpodiumyours/vixrex`
- Hedef: `vixrex-public.vercel.app/v/[slug]` üzerinden canlı yayın
- Şu an: MVP tamamlanmaya yakın, reklam öncesi kritik hata düzeltme aşamasında (WhatsApp FAB, sahte istatistik, silme onayı vb.)

---

**Bu dosyayı okuduysan, cevabının en başında tek satır şunu yaz: "Kurallar okundu, [görev adı] başlıyor."**
