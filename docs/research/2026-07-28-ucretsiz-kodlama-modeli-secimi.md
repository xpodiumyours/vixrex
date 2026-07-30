# Vixrex güvenlik planı için ücretsiz model seçimi

**Tarih:** 28 Temmuz 2026  
**Kapsam:** OpenCode ekranında görünen ücretsiz modeller arasından, `VIXREX_B2B_GUVENLIK_UYGULAMA_PLANI.md` görevlerini yürütmeye en uygun modelin seçilmesi.

## Kısa karar

### Ana tercih: Nemotron 3 Ultra Free

Planlama, geniş depo inceleme, kurallara bağlı kalma ve ikinci göz kod incelemesi için ekrandaki en mantıklı ücretsiz seçenek **Nemotron 3 Ultra Free**.

Gerekçeler:

- NVIDIA modeli karmaşık ajan görevleri, uzun bağlam ve büyük kod tabanları için konumlandırıyor.
- Resmî model kartında 1 milyon token bağlam desteği bulunuyor.
- NVIDIA'nın kendi teknik raporunda güçlü talimat takibi ve karşılaştırılan açık modeller arasında belirgin biçimde daha yüksek “desteksiz cevap üretmeme” sonucu bildiriliyor.
- Bu özellikler, Vixrex'in güvenlik planında ham kod üretme hızından daha önemli olan kapsam takibi ve kanıta bağlı kalma ihtiyacına daha uygundur.

### İkinci tercih: DeepSeek V4 Flash Free

Tek, küçük ve dosya sınırı belirlenmiş kod görevlerinde **DeepSeek V4 Flash Free** yedek tercih olabilir.

Gerekçeler:

- Resmî model kartı 1 milyon token bağlam, kodlama ve ajan görevlerinde güçlü performans bildiriyor.
- NVIDIA'nın yayımladığı karşılaştırmada bazı yazılım mühendisliği ve ajan ortalamalarında Nemotron'dan biraz daha yüksek sonuçlar gösteriyor.
- Buna karşılık aynı karşılaştırmada desteksiz cevap üretmeme sonucu Nemotron'dan belirgin biçimde düşük. Bu nedenle Vixrex planının yöneticisi veya tek denetçisi yapılmamalı.

## Diğer seçenekler

- **MiMo V2.5 Free:** 1 milyon bağlam ve ajan yetenekleri var. Ancak Xiaomi'nin özellikle karmaşık kod/ajan işleri için öne çıkardığı sürüm `V2.5-Pro`; ekrandaki ücretsiz model standart `V2.5`. İlk tercih yapılmadı.
- **North Mini Code Free:** Kod ve terminal görevleri için özel eğitilmiş, fakat 256 bin bağlamlı ve 3 milyar aktif parametreli daha küçük model. Küçük cerrahi işler için uygun olabilir; tüm Vixrex planını yönetmemeli.
- **Big Pickle:** OpenCode bunu “stealth model” olarak tanımlıyor; gerçek model kimliği açıklanmıyor. Güvenlik planında kullanılmamalı.
- **Laguna S 2.1 Free ve Ling-3.0-flash Free:** OpenCode ücretsiz erişimi doğruluyor, fakat bu araştırmada güçlü ve ayrıntılı birinci taraf kodlama/ajan kanıtı bulunamadı.
- **MiniMax M3 ve GLM 5.2:** Ekranda NVIDIA sağlayıcısı altında görünseler de OpenCode Zen resmî fiyat tablosunda ücretsiz değiller. “Tamamen ücretsiz” seçim listesine alınmadılar.

## Kritik gizlilik sonucu

OpenCode'un resmî Zen belgesine göre ücretsiz modeller sınırlı süreli deneme/geri bildirim dönemindedir ve bu modellerde gönderilen veriler model geliştirme amacıyla kullanılabilir. Nemotron ücretsiz NVIDIA endpoint'i ayrıca açıkça “trial use only” der ve kişisel veya gizli veri gönderilmemesini ister.

Bu nedenle:

- API anahtarı, parola, token ve gerçek müşteri verisi hiçbir ücretsiz modele gönderilmez.
- Production `.env` dosyaları, Supabase parolası ve PayTR secret'ları model bağlamına alınmaz.
- Depo özel/gizli kabul ediliyorsa bu ücretsiz modeller üretim kodunu topluca okumak için güvenli sayılmaz.
- Ücretsiz model commit, push, merge, deploy veya production veritabanı yetkisi alamaz.
- Model yalnız küçük görev sözleşmesi, izinli dosyalar ve kullanıcı onay kapıları içinde çalışır.

## Önerilen kullanım

1. **Nemotron 3 Ultra Free:** planı ve ilgili 1–3 dosyayı incele, riskleri ve diff'i kontrol et.
2. **DeepSeek V4 Flash Free:** yalnız onaylanmış küçük kod görevini uygula.
3. Sonuçlar korunan CI testleri ve kullanıcı onayı olmadan ana dala alınmaz.

## Resmî kaynaklar

- OpenCode Zen model, fiyat ve gizlilik bilgileri: <https://opencode.ai/docs/zen>
- NVIDIA Nemotron 3 Ultra tanıtımı: <https://research.nvidia.com/labs/nemotron/Nemotron-3-Ultra/>
- NVIDIA Nemotron 3 Ultra model kartı: <https://build.nvidia.com/nvidia/nemotron-3-ultra-550b-a55b/modelcard>
- NVIDIA Nemotron 3 Ultra teknik raporu: <https://research.nvidia.com/labs/nemotron/files/NVIDIA-Nemotron-3-Ultra-Technical-Report.pdf>
- DeepSeek V4 Flash resmî model kartı: <https://huggingface.co/deepseek-ai/DeepSeek-V4-Flash>
- Xiaomi MiMo V2.5 resmî belge ve duyurusu: <https://mimo.mi.com/docs/en-US/news/latest/v2.5-open-sourced>
- North Mini Code resmî model kartı: <https://huggingface.co/RedHatAI/North-Mini-Code-1.0>
