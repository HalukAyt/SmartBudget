# SmartBudget AI — Design System

## 1. Amaç

Bu doküman SmartBudget AI mobil uygulamasının görsel tasarım ve kullanıcı deneyimi kurallarını tanımlar.

Flutter uygulaması geliştirilirken bu dosya UI tarafındaki ana tasarım referansıdır.

Özellik ve backend davranışları açısından ana doğruluk kaynakları:

- `PROJECT.md`
- `docs/ANALIZ.md`
- `docs/TEKNIK_MIMARI_TASLAK.md`

dosyalarıdır.

Stitch tarafından oluşturulan tasarımlar yalnızca görsel ve UX referansı olarak kullanılmalıdır.

Stitch tasarımlarında backend'de bulunmayan bir özellik varsa Flutter uygulamasına taşınmamalıdır.

---

# 2. Tasarım Prensipleri

SmartBudget AI bir kişisel finans ve bütçe takip uygulamasıdır.

Tasarım şu özellikleri taşımalıdır:

- sade
- modern
- güven veren
- mobil kullanım odaklı
- finansal bilgileri hızlı okunabilir
- gereksiz dekorasyondan uzak
- genç kullanıcıya hitap eden
- kurumsal banka paneli gibi görünmeyen
- kripto veya trading uygulaması gibi görünmeyen

AI özellikleri uygulamada yardımcı rolündedir.

AI tasarımın ana odağı haline getirilmemelidir.

Öncelik sırası:

1. Finansal bilgilerin anlaşılabilirliği
2. Kullanım kolaylığı
3. Güven hissi
4. Görsel tutarlılık
5. Mobil kullanım
6. AI destekli yardımcı özellikler

---

# 3. Genel Görsel Stil

Uygulama açık tema üzerine kurulmalıdır.

Temel yaklaşım:

- açık gri/beyaz arka plan
- lacivert ana marka rengi
- beyaz yüzey/kartlar
- sade gölgeler
- yuvarlatılmış kartlar
- net tipografi
- kontrollü durum renkleri

Aşırı:

- gradient
- glassmorphism
- neon renkler
- ağır gölgeler
- aşırı animasyon
- dekoratif finans illüstrasyonları

kullanılmamalıdır.

---

# 4. Renk Sistemi

Aşağıdaki renkler Flutter theme için temel alınmalıdır.

## Primary

Ana marka rengi:

`#000666`

Kullanım alanları:

- ana buton
- aktif bottom navigation
- önemli başlık vurguları
- seçili filtreler
- link/aksiyon alanları

## Primary Dark

`#00034A`

Kullanım:

- pressed state
- koyu vurgu alanları
- gerektiğinde güçlü kontrast

## Primary Light

`#E8E9F5`

Kullanım:

- seçili chip arka planı
- hafif vurgu yüzeyleri
- primary renge bağlı soft state

---

## Background

`#F7F8FC`

Ana Scaffold arka planı.

---

## Surface

`#FFFFFF`

Kartlar, input alanları ve ön plan yüzeyleri.

---

## Text Primary

`#171A2B`

Ana metinler ve finansal rakamlar.

---

## Text Secondary

`#6B7280`

Açıklamalar, subtitle ve ikincil bilgiler.

---

## Text Muted

`#9CA3AF`

Placeholder, yardımcı metin ve düşük öncelikli içerikler.

---

## Border / Divider

`#E5E7EB`

Input border, divider ve kart ayrımları.

---

# 5. Durum Renkleri

## Success / Normal

`#16A34A`

Kullanım:

- gelir
- olumlu finansal durum
- normal bütçe durumu
- başarılı işlem

---

## Success Background

`#DCFCE7`

---

## Warning

`#F59E0B`

Kullanım:

- bütçe kullanımı `%80–99.99`
- dikkat gerektiren durum

UI metni Türkçe olarak:

`Kritik`

veya

`Limite Yakın`

kullanılabilir.

Backend değeri `Warning` olarak kalır.

---

## Warning Background

`#FEF3C7`

---

## Error / Exceeded

`#DC2626`

Kullanım:

- bütçe limiti aşımı
- validation error
- API hata durumu
- destructive işlem

---

## Error Background

`#FEE2E2`

---

# 6. Tipografi

Tercih edilen font:

`Inter`

Flutter tarafında font paketi veya asset kullanılması zorunlu değildir.

Inter kolay biçimde kullanılamıyorsa sistemin sade sans-serif fontu kullanılabilir.

## Display Financial

Büyük finansal değerler.

Örnek:

`₺24.850`

Önerilen:

- Size: 28–32
- Weight: 700
- Color: Text Primary

---

## Page Title

Örnek:

`Ana Sayfa`

- Size: 24
- Weight: 700

---

## Section Title

Örnek:

`Kategori Harcamaları`

- Size: 18
- Weight: 600

---

## Card Title

- Size: 16
- Weight: 600

---

## Body

- Size: 14–16
- Weight: 400

---

## Caption

- Size: 12
- Weight: 400
- Color: Text Secondary

---

## Button

- Size: 15–16
- Weight: 600

---

# 7. Spacing Sistemi

Temel spacing scale:

- `4`
- `8`
- `12`
- `16`
- `20`
- `24`
- `32`

Ana ekran yatay padding:

`16px`

Büyük section araları:

`24px`

Kart iç padding:

`16px`

Yakın ilişkili elemanlar:

`8px`

Form alanları arası:

`16px`

---

# 8. Border Radius

## Kart

`16px`

## Input

`12px`

## Primary Button

`12px`

## Chip / Badge

`20px` veya tamamen rounded

## Bottom Sheet

Üst köşeler:

`24px`

---

# 9. Shadow

Gölgeler çok hafif kullanılmalıdır.

Kartları ayırmak için öncelikle:

- surface rengi
- border
- spacing

kullanılmalıdır.

Ağır drop shadow kullanma.

---

# 10. Button Sistemi

## PrimaryButton

Ana aksiyonlar için.

Örnek:

- Giriş Yap
- Hesap Oluştur
- Gideri Kaydet
- Geliri Kaydet
- Bütçeyi Kaydet
- Faturayı Kaydet

Özellikler:

- full width kullanılabilir
- height yaklaşık 50–52
- primary background
- beyaz text
- radius 12
- loading state
- disabled state

---

## SecondaryButton

İkincil işlemler.

Örneğin:

- Başka Kategori Seç
- İptal

Primary butondan görsel olarak daha düşük öncelikte olmalıdır.

---

## Destructive Button

Silme ve çıkış gibi işlemlerde kullanılabilir.

Kırmızı renk yalnızca gerektiğinde kullanılmalıdır.

---

# 11. Input Sistemi

Tüm form alanları aynı tasarım dilini kullanmalıdır.

Input özellikleri:

- label
- hint
- border
- focus state
- error text
- disabled/read-only state

Input yüksekliği mobil kullanıma uygun olmalıdır.

## AmountInput

Tutar girişinde:

- numeric keyboard
- ₺ bağlamı
- büyük ve kolay okunabilir input

kullanılabilir.

---

# 12. Kart Yapısı

Temel finansal bilgiler kartlarla sunulabilir.

Kartlarda:

- radius 16
- Surface background
- 16px padding
- mümkün olduğunca sade border
- net bilgi hiyerarşisi

kullanılmalıdır.

---

# 13. Ana Tekrar Kullanılabilir Widgetlar

Flutter tarafında aşağıdaki ortak bileşenler oluşturulabilir:

- `PrimaryButton`
- `SecondaryButton`
- `AppTextField`
- `AmountInput`
- `SummaryCard`
- `TransactionListItem`
- `BudgetProgressCard`
- `BillCard`
- `AiInsightCard`
- `EmptyState`
- `ErrorState`
- `LoadingView`
- `AppBottomNavigation`

Gereksiz büyük bir component framework oluşturulmamalıdır.

---

# 14. Bottom Navigation

Authenticated uygulamanın ana navigation yapısı beş sekmeden oluşmalıdır.

Sıra:

1. Ana Sayfa
2. İşlemler
3. Bütçeler
4. Faturalar
5. Profil

Tutarlı tek icon ailesi kullanılmalıdır.

Aktif sekme:

- primary renk

Pasif sekme:

- Text Secondary

kullanmalıdır.

---

# 15. Dashboard

Dashboard uygulamanın ana ekranıdır.

Genel sıralama:

1. Üst başlık
2. Ay / yıl
3. Finansal özet
4. Kategori harcamaları
5. Bütçe durumu
6. Son 6 ay trendi
7. AI aylık analiz

Dashboard kalabalık görünmemelidir.

---

## Dashboard Header

Kullanıcı adına bağımlı içerik kullanılmamalıdır.

Örneğin:

`Merhaba`

veya:

`Finansal durumun`

kullanılabilir.

Backend'de isim alanı bulunmadığı için:

`Merhaba, Ahmet`

gibi hardcoded veya isim tabanlı UI yapılmamalıdır.

---

# 16. Finansal Summary

Ana kart içinde:

- Toplam Gelir
- Toplam Gider
- Bakiye

gösterilir.

Bakiye görsel olarak en önemli değer olabilir.

Gelir:

Success rengiyle vurgulanabilir.

Gider:

Text Primary veya gerektiğinde kontrollü error tonu.

Finansal rakamların tamamı backend'den gelmelidir.

Fake production değerleri hardcode edilmemelidir.

---

# 17. Category Expenses

Kategori harcamaları:

- kategori adı
- tutar
- toplam içindeki yüzde

ile gösterilebilir.

Progress bar veya sade grafik kullanılabilir.

Backend whitelist kategori isimleri birebir korunmalıdır:

- Market
- Ulaşım
- Fatura
- Eğlence
- Sağlık
- Eğitim
- Kira
- Diğer

UI tarafında:

`Market & Gıda`

gibi farklı kategori isimleri üretilmemelidir.

---

# 18. Budget UI

Bütçe kartı:

- kategori
- Limit
- Harcanan
- UsagePercent
- progress
- status

göstermelidir.

Backend statüleri:

- Normal
- Warning
- Exceeded

UI Türkçe karşılıkları:

- Normal
- Kritik / Limite Yakın
- Limit Aşıldı

olabilir.

## Renkler

Normal:

Success

Warning:

Warning / Amber

Exceeded:

Error

UsagePercent `%100` üzerinde olabilir.

Progress bar görsel olarak maksimum genişliğe ulaşabilir ancak text gerçek değeri göstermelidir.

Örneğin:

`%135`

değeri `%100` olarak değiştirilmemelidir.

---

# 19. Yeni Bütçe

Alanlar:

- Kategori
- Bütçe Limiti
- Ay
- Yıl

Kategori seçenekleri yalnızca backend'deki 8 kategori olmalıdır.

Bütçe için AI önerisi bulunmamaktadır.

---

# 20. Bütçe Güncelleme

Yalnızca:

`Bütçe Limiti`

editable olmalıdır.

Şunlar read-only:

- Kategori
- Ay
- Yıl

---

# 21. İşlemler

İşlemler ekranında:

- Tümü
- Giderler
- Gelirler

filtreleri bulunabilir.

Transaction satırında:

- ikon
- açıklama
- kategori gerekliyse kategori adı
- tarih
- tutar

gösterilebilir.

Gelir ve gider görsel olarak kolay ayırt edilmelidir.

---

# 22. Gider Ekle

Alanlar:

- Tutar
- Açıklama
- Tarih
- Kategori

AI kategorileme yardımcı özelliktir.

Akış:

1. Kullanıcı açıklama girer.
2. `AI ile Kategori Öner` butonuna basar.
3. Backend AI endpointi öneri üretir.
4. UI öneriyi gösterir.
5. Kullanıcı öneriyi kabul eder veya başka kategori seçer.
6. Kullanıcı Gideri Kaydet butonuna basar.

AI otomatik Expense oluşturmamalıdır.

---

## AI Category Suggestion Card

Örneğin:

`AI Önerisi`

`Market`

Confidence varsa küçük ikincil bilgi şeklinde gösterilebilir.

Butonlar:

- `Öneriyi Kullan`
- `Başka Kategori Seç`

AI'ın karar verdiği izlenimi yaratılmamalıdır.

Son karar kullanıcıdadır.

---

## AI Categorization Failure

AI başarısızsa:

`AI şu anda kategori öneremedi. Kategoriyi manuel olarak seçebilirsin.`

gibi sade mesaj göster.

Temel Expense akışı devam etmelidir.

---

# 23. Gelir Ekle

Alanlar:

- Tutar
- Açıklama (opsiyonel)
- Tarih

Buton:

`Geliri Kaydet`

Gelir için kategori veya AI özelliği eklenmemelidir.

---

# 24. Faturalar

Bill türleri yalnızca:

- Elektrik
- Su
- Doğalgaz

olmalıdır.

Filtreler:

- Tümü
- Elektrik
- Su
- Doğalgaz

kullanılabilir.

Şunlar bulunmamalıdır:

- İnternet
- Diğer
- Ödenmiş
- Bekleyen

Backend'de bu özellikler bulunmamaktadır.

---

# 25. Bill Card

Fatura kartı:

- fatura türü
- tutar
- tüketim varsa tüketim
- birim
- fatura tarihi

gösterebilir.

ConsumptionValue null ise:

- `0`

göstermek yerine tüketim alanı gizlenebilir veya:

`Tüketim bilgisi yok`

kullanılabilir.

---

# 26. Fatura Ekle

Alanlar:

- Fatura Türü
- Tutar
- Tüketim Miktarı (opsiyonel)
- Fatura Tarihi

Birim otomatik belirlenmelidir.

Elektrik:

`kWh`

Su:

`m³`

Doğalgaz:

`m³`

Kullanıcı birim yazmamalıdır.

Fatura için AI tahmini bulunmamaktadır.

---

# 27. Fatura Trendleri

Son 6 aylık veri gösterilir.

Tür filtresi:

- Elektrik
- Su
- Doğalgaz

Grafikler:

- Aylık toplam fatura tutarı
- Aylık tüketim

Tutar ve tüketimin farklı birimleri olduğu unutulmamalıdır.

Aynı grafik ekseninde anlamsız şekilde birleştirilmemelidir.

## Kesinlikle Gösterilmemesi Gerekenler

- AI gelecek fatura tahmini
- Tahmini gelecek fatura
- AI öngörüsü
- İnternet faturası

Backend bunları desteklememektedir.

---

# 28. AI Aylık Analiz

AI aylık analiz Dashboard tarafından hesaplanan finansal verileri yorumlar.

AI kartı diğer kartlardan hafifçe ayrışabilir ancak uygulamanın ana odağı olmamalıdır.

Örnek başlık:

`AI Aylık Analiz`

AI metni backend endpointinden gelir.

UI yeni analiz metni üretmemelidir.

---

## AI Analysis Detay

Gösterilebilir:

- ilgili ay/yıl
- AI analiz metni

Alt açıklama:

`Bu yorum mevcut finansal verilerine göre oluşturulmuştur.`

AI'ın yatırım tavsiyesi verdiğini düşündüren CTA kullanılmamalıdır.

Şunlar bulunmamalıdır:

- yatırım yap
- bütçeni otomatik güncelle
- şunu satın al
- gelecek yıl tahmini
- geçen yıla göre kıyaslama

Backend yalnızca sağlanan aylık finansal verileri yorumlar.

---

# 29. Profil

MVP profil ekranı bilinçli olarak minimal tutulmalıdır.

Gösterilecek:

- Email
- Çıkış Yap

Gösterilmeyecek:

- isim
- soyisim
- profil fotoğrafı upload
- Premium
- Pro Üye
- üyelik
- bildirim ayarları
- uygulama dili
- hesap ayarları
- yardım/destek backend özelliği
- şifre değiştirme

Backend bu özellikleri MVP kapsamında desteklememektedir.

---

# 30. Empty State

Liste boş olduğunda kullanıcı boş beyaz ekran görmemelidir.

Örnek:

`Henüz gider kaydın bulunmuyor.`

Altında uygun aksiyon:

`Gider Ekle`

kullanılabilir.

---

# 31. Dashboard Empty State

Finansal veri yoksa:

`Bu ay için henüz finansal kayıt bulunmuyor.`

gibi sade mesaj kullanılabilir.

Fake finansal değer gösterilmemelidir.

---

# 32. Loading State

Loading durumları tutarlı olmalıdır.

Kullanılabilir:

- CircularProgressIndicator
- skeleton benzeri sade loading

Ancak farklı ekranlarda farklı loading tasarımları üretme.

---

# 33. Error State

Teknik backend hata detayları kullanıcıya gösterilmemelidir.

Gösterilmemesi gerekenler:

- exception class
- stack trace
- PostgreSQL hata kodu
- raw JSON
- OpenAI provider response
- HTTP HTML response

Örnek kullanıcı mesajı:

`Bir sorun oluştu. Lütfen tekrar deneyin.`

---

# 34. Network Error

Örnek:

`İnternet bağlantısı kurulamadı. Bağlantını kontrol edip tekrar deneyebilirsin.`

Retry aksiyonu olabilir.

---

# 35. Session Expired

401 durumunda:

`Oturumunuz sona erdi. Lütfen tekrar giriş yapın.`

gösterilir.

Ardından Login ekranına yönlendirilir.

---

# 36. Destructive Actions

Silme işleminde confirmation kullanılmalıdır.

Örneğin:

`Bu gider kaydını silmek istediğinizden emin misiniz?`

Butonlar:

- İptal
- Sil

---

# 37. Login

Alanlar:

- E-posta
- Şifre

Aksiyon:

`Giriş Yap`

Alt link:

`Hesabın yok mu? Kayıt Ol`

Google ve Apple authentication kullanılmamalıdır.

---

# 38. Register

Alanlar:

- E-posta
- Şifre
- Şifre Tekrar

Şifre helper:

`En az 8 karakter`

Buton:

`Hesap Oluştur`

Alt link:

`Zaten hesabın var mı? Giriş Yap`

Google/Apple login bulunmamalıdır.

---

# 39. Form UX

Formlarda:

- kullanıcı yazarken validation aşırı agresif olmamalı
- submit sonrası açık hata gösterilmeli
- loading sırasında button tekrar basılamamalı
- numeric alanlarda numeric keyboard kullanılmalı
- tarih alanlarında native date picker kullanılmalı

---

# 40. Finansal Değer Formatı

Mobil arayüzde Türkçe para gösterimi tercih edilmelidir.

Örnek:

`₺1.250,50`

veya ürün genelinde seçilen tutarlı başka bir Türkçe format.

Uygulama içinde farklı para formatları karıştırılmamalıdır.

Backend decimal değerleri UI gösterimi için formatlanabilir.

Ancak finansal hesap Flutter tarafından yeniden yapılmamalıdır.

---

# 41. Tarih Formatı

UI:

`16 Ağustos 2026`

veya kısa listelerde:

`16 Ağu 2026`

formatını kullanabilir.

API ile iletişimde backend sözleşmesindeki date formatı korunmalıdır.

---

# 42. Icon Sistemi

Tek bir icon ailesi kullanılmalıdır.

Flutter built-in Material Icons yeterliyse tercih edilebilir.

Kategori iconları sade olmalıdır.

Aşırı dekoratif ikonlardan kaçınılmalıdır.

---

# 43. Responsive Mobil Tasarım

Ana hedef mobil cihazlardır.

Tasarımlar:

- küçük telefonlarda taşmamalı
- text overflow kontrol edilmeli
- uzun email adresleri düzgün gösterilmeli
- kartlar sabit pixel genişliğine bağımlı olmamalı
- SafeArea kullanılmalı

Tablet özel UI MVP için zorunlu değildir.

---

# 44. Erişilebilirlik

- Button touch target yeterli olmalı.
- Sadece renkle bilgi aktarılmamalı.
- Warning / Exceeded durumunda metin etiketi de kullanılmalı.
- Metin ve arka plan kontrastı yeterli olmalı.
- Input label'ları açık olmalı.

---

# 45. Stitch Kullanım Kuralı

Stitch çıktıları UI referansıdır.

Flutter implementasyonu sırasında:

- spacing
- kart stili
- renk yaklaşımı
- görsel hiyerarşi
- ekran yerleşimi

Stitch'ten alınabilir.

Ancak Stitch'te görülen her özellik uygulanmamalıdır.

Backend'de olmayan Stitch özellikleri kesinlikle eklenmemelidir.

Bilinen örnekler:

- AI gelecek fatura tahmini
- Pro Üye
- hesap ayarları
- Google/Apple login
- ödeme durumu
- Internet bill
- Budget AI önerisi

uygulanmayacaktır.

---

# 46. AI Görsel Kimliği

AI özelliği için küçük sparkle/stars ikonu veya hafif primary accent kullanılabilir.

Ancak AI kartlarında:

- neon gradient
- büyük robot illüstrasyonları
- uygulamanın geri kalanından tamamen farklı tasarım

kullanılmamalıdır.

AI uygulamayı destekleyen bir yardımcıdır.

---

# 47. Flutter Uygulama Kuralı

UI kodunda renk, spacing ve typography mümkün olduğunca merkezi theme/design token yapısından kullanılmalıdır.

Screen dosyalarında tekrar tekrar:

- hex renkler
- farklı radius
- farklı font size

hardcode edilmemelidir.

Design system mümkün olduğunca:

`AppTheme`

ve ortak widgetlar üzerinden uygulanmalıdır.

---

# 48. Nihai Tasarım Kararı

SmartBudget AI mobil uygulaması şu hissi vermelidir:

> Kullanıcının günlük gelir, gider, bütçe ve faturalarını kolayca takip ettiği; finansal durumunu sade grafiklerle gördüğü ve gerektiğinde AI'dan sınırlı, güvenli yardımcı yorum aldığı modern bir kişisel finans uygulaması.

UI'ın amacı kullanıcıya finansal karar vermek değil, mevcut finansal durumunu anlaşılır biçimde göstermektir.