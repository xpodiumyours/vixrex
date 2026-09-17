# Plan

## Bugünkü sorun

Gelişim zinciri Claude klasörüne ve Claude araç kancalarına bağlanmıştı.
Bu nedenle diğer üreticiler aynı zorunluluğa girmiyor, yazılı kurallar ortak
olsa bile merkezi teslimat bunu kanıtlamıyordu.

## Çözüm

1. Ortak kuralları AGENTS.md ve DEVELOPMENT.md altında toplamak.
2. Spec Kit iş akışını araç seçimi serbest olacak şekilde düzenlemek.
3. Her değişiklikte tek specs iş kaydı zorunlu tutmak.
4. Bu kaydı GitHub üzerinde merkezi olarak doğrulamak.
5. Teslimat sistemini bu doğrulamaya bağlamak.
6. Otomatik canlı yayını kapalı tutmak.

## Güvenlik ve geri alma

Canlı veri, veritabanı ve uygulama kodu değişmez. Son commit geri alınırsa
gelişim sistemi bütünüyle eski hâline döner. Yayın ayrıca başlatılmadığı için
canlı ürün etkilenmez.

## Doğrulama

Eksik kayıt örneği kırmızı, tam kayıt örneği yeşil çalıştırılacak. Son commit
ana çalışmanın tek yeni kaydı olarak kalacak.
