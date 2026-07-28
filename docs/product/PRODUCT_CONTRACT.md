# Vixrex — Ürün Sözleşmesi (Product Contract)

**Tarih:** 28 Temmuz 2026  
**Durum:** Taslak — kullanıcı kararları bekliyor  

---

## 1. Ürün Tanımı

Vixrex, küçük ve orta ölçekli işletmelerin hazır fakat kişiselleştirilebilir web sitelerini inceleyip kiralayabildiği veya satın alabildiği; ödeme sonrasında kendilerine atanan vitrini yönetip yayınlayabildiği B2B web sitesi ve dijital vitrin platformudur.

## 2. İki Yüzey

| Yüzey | Teknoloji | Kullanıcı |
|-------|-----------|-----------|
| İşletme paneli | Flutter (web + mobil) | Vitrin sahibi, admin |
| Public vitrin | Next.js (vixrex-public) | Ziyaretçi, potansiyel müşteri |

## 3. Roller

| Rol | Yetki |
|-----|-------|
| Ziyaretçi | Public vitrinleri görür, kirala/satın al başlatabilir |
| Kullanıcı (vitrin sahibi) | Kendi vitrinini düzenler, yayınlar |
| Admin | Tüm vitrinleri, kullanıcıları, siparişleri ve ödemeleri yönetir |

## 4. Bekleyen Ürün Kararları

Aşağıdaki kararlar kullanıcı tarafından onaylanmayı beklemektedir:

### 4.1 Kiralama Modeli
- [ ] Kiralama aylık mı, yıllık mı, ikisi de mi?
- [ ] Kira bedeline domain/hosting dahil mi?
- [ ] Kişiselleştirme müşteri tarafından mı yapılacak, Vixrex hizmeti de olacak mı?

### 4.2 Satış Modeli
- [ ] Satın alma sürekli kullanım hakkı mı, tek seferlik kurulum mu?
- [ ] Güncelleme ve destek satışa dahil mi?

### 4.3 Fiyatlandırma
- [ ] KDV dahil mi hariç mi gösterilecek?
- [ ] Kurulum/kişiselleştirme bedeli ayrı mı?

### 4.4 İptal ve İade
- [ ] Cayma süresi ne kadar?
- [ ] Kısmi iade mümkün mü?

## 5. Kapsam Dışı (İlk Sürümde)

- Ayrı bir üçüncü frontend uygulaması
- Flutter içinde Next.js public vitrinlerin kopyası
- Kapsamlı kurumsal CRM
- Pazaryeri tipi çok satıcılı ödeme dağıtımı
- Gelişmiş kampanya motoru
- Farklı ödeme sağlayıcılarının aynı anda kurulması
- AI tabanlı yeni içerik üretim sistemi

## 6. Korunan Davranışlar (Test Edilebilir)

| # | Davranış |
|---|----------|
| 1 | Kapak seçilince editör önizlemesinde hemen görünür |
| 2 | Kapak seçmek otomatik publish oluşturmaz |
| 3 | Taslak kaydedildiğinde kapak yeniden açılan editörde korunur |
| 4 | Açık "Yayınla" eylemi public vitrini bir kez günceller |
| 5 | Editörü yalnızca açmak Supabase yazması veya publish oluşturmaz |
| 6 | GPS başlatmak manuel adresi temizlemez |
| 7 | İzin reddi, servis kapalı veya hata manuel adresi değiştirmez |
| 8 | Başarılı kesin sonuç açık ve tutarlı biçimde gösterilir |
