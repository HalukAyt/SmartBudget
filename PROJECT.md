# SmartBudget AI

## 1. Proje Özeti

SmartBudget AI, kullanıcıların gelir, gider, bütçe ve faturalarını takip edebildiği; yapay zekâ ile harcamaları otomatik kategorize eden ve aylık harcama verilerini anlaşılır şekilde yorumlayan mobil bir bütçe takip uygulamasıdır.

Proje, yalnızca çalışan bir mobil uygulama geliştirmeyi değil; yapay zekânın geliştirme sürecinde kontrollü, izlenebilir ve denetlenebilir şekilde kullanılmasını da amaçlar.

Proje görev dokümanındaki **Aile Bütçesi ve Fatura Takibi** projesi temel alınmıştır. İstenen temel özellikler gelir-gider takibi, kategori bazlı bütçe limiti ve uyarılar, fatura/tüketim trendleri ve AI destekli harcama analizidir.

---

## 2. Projenin Amacı

Kullanıcının:

* Gelirlerini kaydedebilmesi
* Giderlerini kaydedebilmesi
* Giderlerini kategori bazında takip edebilmesi
* Kategori bazlı aylık bütçe limiti belirleyebilmesi
* Bütçe limitine yaklaştığında uyarı alabilmesi
* Bütçe limitini geçtiğinde uyarı alabilmesi
* Elektrik, su ve doğalgaz faturalarını kaydedebilmesi
* Aylık harcama ve tüketim trendlerini grafiklerle görebilmesi
* Yapay zekâ ile gider kategorisini otomatik belirleyebilmesi
* Yapay zekâ ile aylık harcamalarını yorumlayabilmesi

amaçlanmaktadır.

---

# 3. MVP Kapsamı

İlk sürümde aşağıdaki özellikler geliştirilecektir:

1. Kullanıcı kayıt olma
2. Kullanıcı giriş yapma
3. JWT tabanlı authentication
4. Gelir ekleme
5. Gelir listeleme
6. Gelir silme
7. Gider ekleme
8. Gider listeleme
9. Gider silme
10. Harcama kategorileri
11. AI destekli gider kategorileme
12. Manuel kategori seçimi
13. Aylık kategori bütçesi oluşturma
14. Bütçe kullanım yüzdesi hesaplama
15. Bütçe limiti uyarıları
16. Elektrik faturası kaydı
17. Su faturası kaydı
18. Doğalgaz faturası kaydı
19. Aylık fatura / tüketim trendleri
20. Dashboard ekranı
21. AI destekli aylık harcama analizi
22. Temel hata yönetimi
23. Temel güvenlik kontrolleri
24. Test senaryoları

---

# 4. Opsiyonel Özellikler

MVP tamamlandıktan sonra zaman kalırsa aşağıdaki özellikler eklenebilir:

* Fatura fotoğrafı yükleme
* Fotoğraftan fatura tutarı okuma
* Fotoğraftan fatura tarihi okuma
* OCR / Vision model entegrasyonu
* Bildirim sistemi
* PDF veya CSV dışa aktarma

Fatura fotoğrafından tutar ve tarih okunması proje dokümanında zor mod olarak belirtilmiştir.

---

# 5. Kapsam Dışı

İlk sürümde aşağıdaki özellikler bulunmayacaktır:

* Gerçek banka entegrasyonu
* Open Banking entegrasyonu
* Gerçek kredi kartı işlemleri
* Para transferi
* Banka hesabından otomatik işlem çekme
* Muhasebe sistemi entegrasyonu
* ERP entegrasyonu
* Yatırım işlemleri
* Finansal yatırım danışmanlığı

---

# 6. Teknoloji Yığını

## Mobile

* Flutter
* Dart

## Backend

* ASP.NET Core Web API
* C#
* Entity Framework Core
* JWT Authentication

## Database

* PostgreSQL

## AI

* LLM API
* AI entegrasyonu backend üzerinden gerçekleştirilecektir.
* AI API anahtarı mobil uygulamaya gönderilmeyecektir.

---

# 7. Genel Mimari

```text
Flutter Mobile App
        |
        | HTTP / HTTPS
        v
ASP.NET Core Web API
        |
        +----------------------+
        |                      |
        v                      v
   PostgreSQL              AI Service
                               |
                               v
                            LLM API
```

Backend temel olarak:

```text
Controller
    |
    v
Service
    |
    +-----------> AI Service
    |
    v
Entity Framework Core
    |
    v
PostgreSQL
```

şeklinde çalışacaktır.

---

# 8. Mimari Kurallar

Proje geliştirilirken aşağıdaki kurallara uyulmalıdır:

1. Controller içerisinde business logic yazılmamalıdır.
2. Business logic Service katmanında tutulmalıdır.
3. Entity nesneleri doğrudan client'a açılmamalıdır.
4. Request ve response işlemlerinde DTO kullanılmalıdır.
5. Veritabanı işlemleri Entity Framework Core üzerinden gerçekleştirilmelidir.
6. Kullanıcı yalnızca kendi verilerine erişebilmelidir.
7. `UserId` request body'sinden güvenilir kabul edilmemelidir.
8. Kullanıcı kimliği JWT içerisindeki authenticated user bilgisinden alınmalıdır.
9. Password düz metin olarak saklanmamalıdır.
10. Password hashing kullanılmalıdır.
11. API key ve secret değerleri source code içerisinde tutulmamalıdır.
12. Hassas bilgiler loglanmamalıdır.
13. AI çıktısına doğrudan güvenilmemelidir.
14. AI response doğrulanmadan veritabanına kaydedilmemelidir.
15. AI servisinin çalışmaması uygulamanın temel özelliklerini durdurmamalıdır.
16. AI kategorileme başarısız olursa kullanıcı manuel kategori seçebilmelidir.
17. Finansal hesaplamalar AI tarafından yapılmamalıdır.
18. Toplam, yüzde, fark ve trend hesaplamaları backend tarafından yapılmalıdır.
19. AI yalnızca backend tarafından hesaplanan verileri yorumlamak için kullanılmalıdır.
20. Yeni özellik eklenirken mevcut çalışan özellikler gereksiz şekilde değiştirilmemelidir.

---

# 9. Temel Veri Modeli

## User

```text
Id
Email
PasswordHash
CreatedAt
```

---

## Category

```text
Id
Name
```

Temel kategoriler:

* Market
* Ulaşım
* Fatura
* Eğlence
* Sağlık
* Eğitim
* Kira
* Diğer

---

## Expense

```text
Id
UserId
Amount
Description
CategoryId
Date
CreatedAt
IsAiCategorized
```

---

## Income

```text
Id
UserId
Amount
Description
Date
CreatedAt
```

---

## Budget

```text
Id
UserId
CategoryId
LimitAmount
Month
Year
CreatedAt
```

---

## Bill

```text
Id
UserId
BillType
Amount
ConsumptionValue
BillingDate
CreatedAt
```

---

# 10. Temel API Taslağı

## Authentication

```text
POST /api/auth/register
POST /api/auth/login
```

## Expenses

```text
GET    /api/expenses
GET    /api/expenses/{id}
POST   /api/expenses
DELETE /api/expenses/{id}
```

## Income

```text
GET    /api/incomes
POST   /api/incomes
DELETE /api/incomes/{id}
```

## Categories

```text
GET /api/categories
```

## Budgets

```text
GET    /api/budgets
POST   /api/budgets
PUT    /api/budgets/{id}
DELETE /api/budgets/{id}
```

## Bills

```text
GET    /api/bills
POST   /api/bills
DELETE /api/bills/{id}
```

## Dashboard

```text
GET /api/dashboard/monthly
```

## AI

```text
POST /api/ai/categorize-expense
POST /api/ai/monthly-summary
```

Endpoint isimleri geliştirme sırasında değiştirilebilir. Yapılan değişiklikler teknik dokümana yansıtılmalıdır.

---

# 11. AI Özelliği — Harcama Kategorileme

Kullanıcı örneğin:

```text
Migros alışverişi 850 TL
```

şeklinde bir gider oluşturduğunda AI harcamayı kategorize edebilir.

Örnek response:

```json
{
  "category": "Market",
  "confidence": 0.96
}
```

AI yalnızca şu kategorilerden birini seçebilir:

```text
Market
Ulaşım
Fatura
Eğlence
Sağlık
Eğitim
Kira
Diğer
```

## Kurallar

* AI yeni kategori oluşturamaz.
* Response mümkünse JSON formatında alınmalıdır.
* Category whitelist ile kontrol edilmelidir.
* Confidence değeri doğrulanmalıdır.
* Geçersiz kategori kabul edilmemelidir.
* AI timeout durumunda kullanıcı manuel kategori seçebilmelidir.
* AI servisinin hata vermesi Expense oluşturma özelliğini tamamen engellememelidir.

---

# 12. AI Özelliği — Aylık Harcama Analizi

Aylık finansal hesaplamalar AI tarafından yapılmayacaktır.

Backend öncelikle:

* Toplam aylık gelir
* Toplam aylık gider
* Kategori bazlı gider
* Bütçe kullanım oranı
* Geçen aya göre değişim
* En fazla harcama yapılan kategori
* En fazla artış gösteren kategori

gibi verileri hesaplayacaktır.

Örnek:

```json
{
  "totalIncome": 50000,
  "totalExpense": 32750,
  "categories": [
    {
      "name": "Market",
      "amount": 9200,
      "budget": 10000,
      "usagePercent": 92
    },
    {
      "name": "Eğlence",
      "amount": 4800,
      "budget": 3000,
      "usagePercent": 160
    }
  ]
}
```

AI bu veriyi kullanıcıya anlaşılır şekilde yorumlayacaktır.

Örneğin:

```text
Bu ay eğlence harcamalarınız belirlediğiniz bütçeyi aşmıştır.
Market bütçenizin ise %92'sini kullandınız.
```

AI:

* Rakamları değiştirmemeli
* Olmayan veri hakkında tahmin yapmamalı
* Finansal yatırım tavsiyesi vermemeli

---

# 13. AI Güvenlik ve Doğrulama Kuralları

AI response her zaman güvenilmeyen veri olarak kabul edilmelidir.

Her AI response için:

1. Response parse edilmelidir.
2. Beklenen format kontrol edilmelidir.
3. Enum / whitelist alanları doğrulanmalıdır.
4. Null ve boş değerler kontrol edilmelidir.
5. Gerekli sınırlar kontrol edilmelidir.
6. Geçersiz response reddedilmelidir.
7. Fallback davranışı uygulanmalıdır.
8. Gereksiz kişisel bilgiler AI'a gönderilmemelidir.

AI API key:

* Flutter uygulamasına yazılmamalıdır.
* Git repository'ye commit edilmemelidir.
* Backend configuration / environment variable üzerinden alınmalıdır.

---

# 14. Hata Yönetimi

Aşağıdaki hata senaryoları dikkate alınmalıdır.

## AI Timeout

```text
AI kategorileme servisine ulaşılamadı.
Kullanıcı kategoriyi manuel seçebilir.
```

## Invalid AI JSON

AI response reddedilir ve manuel kategori seçimi sunulur.

## Geçersiz AI Kategorisi

Örneğin:

```json
{
  "category": "Coffee"
}
```

`Coffee` izin verilen kategoriler arasında olmadığı için kabul edilmez.

## Authentication Error

```text
401 Unauthorized
```

## Başka Kullanıcının Verisine Erişim

Kullanıcı başka bir kullanıcının Expense, Income, Budget veya Bill kaydına erişememelidir.

## Validation Error

Örneğin:

```text
Amount = -500
```

isteği kabul edilmemelidir.

---

# 15. Business Rules

## Expense

* `Amount > 0` olmak zorundadır.
* Description boş olamaz.
* Category geçerli olmalıdır.
* Kullanıcı yalnızca kendi Expense kayıtlarına erişebilmelidir.

## Income

* `Amount > 0` olmak zorundadır.
* Kullanıcı yalnızca kendi gelir kayıtlarına erişebilmelidir.

## Budget

* `LimitAmount > 0` olmak zorundadır.
* Aynı kullanıcı, kategori, ay ve yıl için birden fazla aktif bütçe oluşturulmamalıdır.

## Budget Alert

```text
>= %80  → Warning
>= %100 → Exceeded
```

## Bill

* Amount negatif olamaz.
* BillType tanımlı değerlerden biri olmalıdır.
* Kullanıcı yalnızca kendi faturalarına erişebilmelidir.

---

# 16. Güvenlik Kuralları

* JWT Authentication kullanılmalıdır.
* Protected endpointlerde authorization uygulanmalıdır.
* Kullanıcı kaynaklarında ownership kontrolü yapılmalıdır.
* Password hash kullanılmalıdır.
* Secret değerler source code içerisinde saklanmamalıdır.
* Hassas bilgiler loglanmamalıdır.
* AI promptlarına gereksiz kişisel veri gönderilmemelidir.
* Production ortamında kullanıcıya stack trace gösterilmemelidir.
* AI çıktısı doğrulanmadan kullanılmamalıdır.
* Kullanıcı girdileri backend tarafından validate edilmelidir.

---

# 17. Test Stratejisi

En az aşağıdaki durumlar test edilmelidir.

## Authentication

* Başarılı register
* Duplicate email
* Başarılı login
* Yanlış password
* Token olmadan protected endpoint çağrısı

## Expense

* Başarılı gider ekleme
* Negatif gider
* 0 TL gider
* Boş description
* Geçersiz category
* Başka kullanıcının giderine erişim

## Budget

* Başarılı bütçe oluşturma
* Duplicate aylık bütçe
* %80 kullanım uyarısı
* %100 bütçe aşımı

## AI

* Doğru JSON response
* AI timeout
* Invalid JSON
* Geçersiz category
* Boş response

## Bill

* Başarılı fatura oluşturma
* Negatif tutar
* Geçersiz fatura tipi

AI tarafından üretilen test senaryoları insan tarafından ayrıca kontrol edilmelidir.

---

# 18. Flutter Uygulamasında Planlanan Ekranlar

Minimum ekranlar:

```text
Splash
Login
Register
Dashboard
Expenses
Add Expense
Income
Add Income
Budgets
Bills
AI Analysis
```

Flutter uygulaması API ile REST üzerinden iletişim kuracaktır.

Mobil tarafta:

* Loading state
* Error state
* Empty state
* Token yönetimi
* API hata mesajları

dikkate alınmalıdır.

---

# 19. AI ile Çalışma Kuralları

Bu proje geliştirilirken AI:

* Analiz taslağı oluşturabilir
* Mimari öneri sunabilir
* Kod taslağı oluşturabilir
* Refactoring önerebilir
* Test senaryosu üretebilir
* Dokümantasyon taslağı oluşturabilir

Ancak AI çıktısı doğrudan kabul edilmeyecektir.

Her önemli AI çıktısında geliştirici:

1. Çıktıyı inceler.
2. PROJECT.md kurallarına uygunluğunu kontrol eder.
3. Güvenlik açısından değerlendirir.
4. Gereksinimlerle karşılaştırır.
5. Gerekirse düzeltir.
6. Önemli AI kullanımlarını prompt dosyasında saklar.
7. Kritik insan müdahalelerini AI çalışma günlüğüne kaydeder.

Proje görev dokümanında kullanılan prompt/context dosyalarının ve AI ile insan arasındaki karar farklarının görünür olması istenmektedir.

---

# 20. Codex / AI İçin Çalışma Talimatları

Her geliştirme görevinde:

1. Önce `PROJECT.md` dosyasını oku.
2. İlgili analiz ve teknik dokümanları oku.
3. Mevcut repository yapısını incele.
4. Mevcut kodu anlamadan yeni mimari oluşturma.
5. Gereksiz dependency ekleme.
6. Gereksiz dosya oluşturma.
7. Küçük ve kontrollü değişiklikler yap.
8. Mevcut endpointleri sebepsiz değiştirme.
9. Validation kontrollerini atlama.
10. Authorization kontrollerini atlama.
11. AI entegrasyonlarında fallback davranışı oluştur.
12. Secret değerleri hard-code etme.
13. Yapılan değişiklikleri görev sonunda özetle.
14. Test edilmesi gereken noktaları belirt.
15. Belirsiz gereksinimleri kendi başına kesinleştirme.

---

# 21. Definition of Done

Bir özellik tamamlanmış sayılabilmesi için:

* Çalışıyor olmalıdır.
* Backend validation bulunmalıdır.
* Gerekliyse authorization uygulanmalıdır.
* Kullanıcı yalnızca kendi verisine erişebilmelidir.
* Hata senaryosu ele alınmış olmalıdır.
* Flutter tarafında loading/error state bulunmalıdır.
* Test edilebilir olmalıdır.
* İlgili teknik doküman güncellenmelidir.
* Önemli AI promptu kayıt altına alınmalıdır.
* AI'ın kritik hatası veya insan müdahalesi varsa AI çalışma günlüğüne eklenmelidir.

---

# 22. Proje Teslim Dosyaları

Repository içerisinde hedeflenen doküman yapısı:

```text
SmartBudgetAI/
│
├── PROJECT.md
├── README.md
│
├── prompts/
│   ├── 00_project_md_olusturma.txt
│   ├── 01_analiz_ilk_taslak.txt
│   ├── 02_analiz_revizyon.txt
│   └── ...
│
├── docs/
│   ├── ANALIZ.md
│   ├── TEKNIK_DOKUMAN.md
│   ├── KULLANIM_KILAVUZU.md
│   ├── AI_CALISMA_GUNLUGU.md
│   └── TEST_SENARYOLARI.md
│
├── backend/
│
└── mobile/
```

Analiz, teknik doküman ve kullanım kılavuzu proje için zorunlu teslimler arasındadır.

---

# 23. Demo İçin Minimum Akış

5 dakikalık demo içerisinde:

1. Kullanıcı giriş yapar.
2. Dashboard gösterilir.
3. Yeni gider eklenir.
4. AI gider kategorisini önerir.
5. Bütçe ekranı gösterilir.
6. Bütçe uyarısı gösterilir.
7. Grafikler gösterilir.
8. AI aylık harcama analizi gösterilir.
9. En az bir hata senaryosu gösterilir.

Önerilen hata senaryosu:

```text
AI servisi cevap vermiyor.
        ↓
Uygulama çökmüyor.
        ↓
Kullanıcı kategoriyi manuel seçiyor.
```

Proje görevinde 5 dakikalık canlı demo içerisinde mutlu senaryo ve en az bir hata senaryosu gösterilmesi istenmektedir.

---

# 24. Temel İlke

**AI, uygulamanın karar vericisi değildir.**

AI yardımcı bir sistemdir.

Finansal hesaplamalar, validation, authentication, authorization, güvenlik kontrolleri ve nihai teknik kararlar uygulama kodu ve geliştiricinin kontrolünde olmalıdır.
