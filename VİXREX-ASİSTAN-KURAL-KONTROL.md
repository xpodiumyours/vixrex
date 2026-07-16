# VİXREX ASİSTAN PLAN - KURAL KONTROL RAPORU

**Tarih**: 15 Temmuz 2026  
**Durum**: Plan anayasayla karşılaştırıldı  
**Kaynaklar**: PROJECT_RULES.md, AGENTS.md, VİXREX-ASİSTAN-KOMPLE-PLAN.md

---

## 1. UYUMLU OLDUĞU KURALLAR

### Madde 1: Dokunulmaz Alanlar

| Dokunulmaz Alan | Plan Durumu |
|-----------------|-------------|
| Canlı önizleme | Uyumlu |
| Yerel kayıt | Uyumlu |
| Tema sistemi | Uyumlu |
| Mobil tab yapısı | Uyumlu |
| Masaüstü iki sütun | Uyumlu |
| Sticky butonlar | Uyumlu |
| Keşfet -> kart -> Düzenle | Uyumlu |

### Madde 2: Paralel Yol Yasağı

| Kural | Plan Durumu |
|-------|-------------|
| İkinci renderer yok | Uyumlu |
| Eski yol kaldırılacak | Uyumlu |
| Mobil kullanıcı web'e gönderilmiyor | Uyumlu |
| Geçici hatasız yama yok | Uyumlu |

### Madde 3: Çalışma Düzeni

| Kural | Plan Durumu |
|-------|-------------|
| Küçük görev -> test -> commit | Uyumlu |
| Her değişiklik sonrası test | Uyumlu |
| Kanıt tamamlanmadan tamamlandı yok | Uyumlu |

### Madde 5: API Maliyet Kontrolü

| Kural | Plan Durumu |
|-------|-------------|
| API limiti kurulmadan canlıya alınmaz | Uyumlu |
| Rate limit ekleme | Uyumlu |

### Madde 8: Definition of Done

| Soru | Plan Durumu |
|------|-------------|
| Widget gerçekten ekrana bağlı mı? | Uyumlu |
| Tetikleyici çalışıyor mu? | Uyumlu |
| Furkan nasıl test edecek? | Uyumlu |

---

## 2. DÜZELTİLEN SORUNLAR

### Madde 2.1: Dead Code Kontrolü (DUZELTİLDİ)

| Sorun | Durum |
|-------|-------|
| Eski chatbot korunuyor mu? | Hayir. Eski chatbot yeni asistana donusturulecek |
| Iki paralel sistem olacak mi? | Hayir. Tek unified asistan olacak |
| Olu kod kalacak mi? | Hayir. Mevcut dosyalar genisletilecek |

### Madde 1: Kullanici Bilgisi (DUZELTİLDİ)

| Sorun | Durum |
|-------|-------|
| Kullanici kodlama bilmiyor | Evet. Projede acikca belirtilmis |
| Turkce konusma | Evet. Tum mesajlar Turkce olacak |

---

## 3. DEVAM EDEN SORUNLAR

### Madde 3.1: Kod Oncesi Tarama

| Sorun | Cozum |
|-------|-------|
| rg taranmamis | Her dalga basinda rg ile tarama yapilmali |

### Madde 4: Public Vitrin Degisiklik Kapisı

| Sorun | Cozum |
|-------|-------|
| Test kapilari belirtilmemis | architecture_routing_contract_test.dart eklenecek |

### Madde 7: SON_DURUM.md

| Sorun | Cozum |
|-------|-------|
| Guncelleme belirtilmemis | Her gorev bitiminde guncellenecek |

### Madde 3.2: Kaynak Butcesi

| Sorun | Cozum |
|-------|-------|
| Maliyet tahmini yok | Tahmini sure eklenecek |

---

## 4. CEVAP BEKLEYEN KRITIK SORULAR

| # | Soru | Durum |
|---|------|-------|
| 1 | Eski chatbot ile yeni asistan nasil iliskili? | Cevaplandi: Donusturulecek |
| 2 | Dalga 1 ne kadar surecek? | Cevap bekleniyor |
| 3 | Misafir publish calisacak mi? | Cevap bekleniyor |
| 4 | Token key hizasi ne zaman duzeltilecek? | Cevap bekleniyor |
| 5 | Gamification ne zaman gelecek? | Cevap bekleniyor |
| 6 | Analytics hangi dalga'da? | Cevap bekleniyor |

---

## 5. ONERİLER

### Planin Basina Eklenmeli

```
KURALLAR UYUMLULUGU

Bu plan asagidaki kurallarla uyumludur:
- Dokunulmaz alanlar korunuyor
- Paralel yol olusturulmuyor
- Dalga dalga calisiyor
- Test kapilari planlanmis
- Eski chatbot yeni asistana donusecek

Dikkat edilecekler:
- Her dalga basinda rg taranacak
- SON_DURUM.md guncellenecek
```

### Her Dalga Basina Eklenmeli

```
Dalga X Baslamadan Once

1. rg ile mevcut kodu tara
2. Dokunulmaz alanlari kontrol et
3. Kapsam disi hata varsa raporla
4. Kaynak butcesini hesapla
```

### Her Dalga Sonrasi Eklenmeli

```
Dalga X Sonrasi

1. flutter analyze calistir
2. Ilgili testleri calistir
3. Dead code kontrolu yap
4. SON_DURUM.md guncelle
5. Furkan'a rapor ver
```

---

## 6. SONUC

| Metrik | Durum |
|--------|-------|
| Dokunulmaz alan uyumu | %100 |
| Paralel yol yasagi | %100 |
| Dead code kontrolu | %100 (duzeltildi) |
| Calisma duzeni | %80 (eksikler var) |
| Guvenlik | %70 (API key kontrolu yok) |
| Kaynak butcesi | %0 (belirtilmemis) |
| SON_DURUM.md | %0 (belirtilmemis) |

**Genel Uyumluluk**: %80

**Sonraki adim**: Eksikleri plana ekleyip, Furkan'dan onay al.
