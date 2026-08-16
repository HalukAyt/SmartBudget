# SmartBudget AI — Teknik Mimari Taslağı

> **Doküman durumu:** İlk AI mimari taslağıdır; insan incelemesi ve onayı gerektirir.  
> **Revizyon durumu:** İnsan incelemesi sonrası güncellenen ikinci AI mimari sürümüdür.  
> **Ana kaynaklar:** `PROJECT.md` ve `docs/ANALIZ.md`  
> **Kapsam:** Kod, migration veya dependency oluşturmadan MVP için backend, mobil, veri tabanı ve AI yapısını netleştirir.

## 1. Genel Sistem Mimarisi

SmartBudget AI, tek bir Flutter mobil istemcisi, tek bir ASP.NET Core Web API uygulaması, PostgreSQL veri tabanı ve backend üzerinden erişilen bir LLM API'den oluşan istemci-sunucu mimarisi kullanacaktır. Microservice mimarisi kullanılmayacaktır.

```text
Flutter Mobile App
  ├─ Ekranlar ve kullanıcı etkileşimi
  ├─ Form doğrulamasının kullanıcı deneyimi tarafı
  ├─ Token/session yönetimi
  └─ REST API istemcisi
             │
             │ HTTPS + JSON + JWT Bearer
             ▼
ASP.NET Core Web API (tek uygulama)
  ├─ Controllers: HTTP sözleşmesi ve durum kodları
  ├─ Services: iş kuralları, sahiplik, hesaplamalar ve akış yönetimi
  ├─ AI Service: LLM çağrısı, yanıt doğrulama ve fallback sonucu
  └─ Entity Framework Core / DbContext
             │                         │
             │                         └── HTTPS ──► LLM API
             ▼
        PostgreSQL
```

Temel sorumluluk dağılımı:

- Flutter, veriyi kullanıcıdan alır ve API sonucunu loading/error/empty/success durumlarıyla gösterir. Finansal hesapların doğruluk kaynağı değildir.
- Controller, request DTO'yu kabul eder, authenticated kullanıcı kimliğini JWT claim'inden alır, servisi çağırır ve HTTP cevabı üretir. İş kuralı içermez.
- Service, doğrulama sonrası iş kurallarını, kullanıcı veri sahipliğini, finansal hesapları ve işlem akışını yürütür.
- Entity Framework Core, service katmanının PostgreSQL'e erişim aracıdır.
- AI Service, harici LLM API ile yalnızca backend tarafında konuşur. AI yanıtı güvenilmeyen girdi gibi doğrulanır.
- PostgreSQL, kullanıcılar ile onların gelir, gider, bütçe ve fatura kayıtlarının kalıcı veri kaynağıdır.

MVP için ayrı application/domain/infrastructure projeleri, event bus, CQRS, mediator veya generic repository gibi ek yapılar zorunlu değildir. Tek backend projesi içinde açık klasör ve sorumluluk ayrımı yeterlidir.

## 2. Flutter Mobil Uygulama Klasör Yapısı

Önerilen yapı feature-first ve sınırlı ortak altyapı yaklaşımıdır:

```text
mobile/
└─ lib/
   ├─ main.dart
   ├─ app/
   │  ├─ app.dart
   │  └─ routes.dart
   ├─ core/
   │  ├─ config/
   │  ├─ network/
   │  ├─ auth/
   │  ├─ errors/
   │  └─ utils/
   ├─ shared/
   │  └─ widgets/
   └─ features/
      ├─ auth/
      │  ├─ models/
      │  ├─ data/
      │  └─ presentation/
      ├─ dashboard/
      │  ├─ models/
      │  ├─ data/
      │  └─ presentation/
      ├─ expenses/
      │  ├─ models/
      │  ├─ data/
      │  └─ presentation/
      ├─ incomes/
      │  ├─ models/
      │  ├─ data/
      │  └─ presentation/
      ├─ budgets/
      │  ├─ models/
      │  ├─ data/
      │  └─ presentation/
      ├─ bills/
      │  ├─ models/
      │  ├─ data/
      │  └─ presentation/
      └─ ai_analysis/
         ├─ models/
         ├─ data/
         └─ presentation/
```

Klasör sorumlulukları:

- `app/`: uygulamanın başlangıç yapısı ve ekran yönlendirmesi.
- `core/network/`: HTTP istemcisi, base URL, JSON iletişimi, ortak header'lar ve API hata eşleme davranışı.
- `core/auth/`: JWT'nin `flutter_secure_storage` ile güvenli saklanması, uygulama oturumu boyunca yönetimi ve authenticated isteklerde Bearer header eklenmesi.
- `core/errors/`: API hata modelinin mobil durumlara çevrilmesi.
- `core/utils/`: yalnızca gerçekten ortak ve küçük yardımcılar; iş kuralları buraya taşınmaz.
- `shared/widgets/`: birden fazla feature tarafından kullanılan loading, error ve empty state bileşenleri gibi ortak görseller.
- `features/*/models`: backend response/request DTO'larının mobil karşılıkları; veri tabanı entity'leri değildir.
- `features/*/data`: ilgili feature'ın API çağrılarını yapan sınıflar.
- `features/*/presentation`: ekranlar, form durumları ve kullanıcı etkileşimleri.

Login, Register, Dashboard, Expenses, Add Expense, Income, Add Income, Budgets, Bills ve AI Analysis MVP akışındaki temel ekranlardır. Splash ekranı akışta bulunabilir ancak zorunlu fonksiyonel gereksinim veya ayrı feature değildir.

Mobil tarafta gelir, gider, bütçe veya trend toplamları yeniden hesaplanarak doğruluk kaynağı oluşturulmamalıdır. Backend'in sunduğu hesaplanmış değerler gösterilmelidir.

## 3. ASP.NET Core Backend Klasör Yapısı

MVP için tek Web API projesi ve aşağıdaki yalın yapı önerilir:

```text
backend/
└─ SmartBudget.Api/
   ├─ Controllers/
   ├─ Services/
   │  └─ AI/
   ├─ Data/
   │  ├─ AppDbContext
   │  └─ Configurations/
   ├─ Entities/
   ├─ DTOs/
   │  ├─ Auth/
   │  ├─ Expenses/
   │  ├─ Incomes/
   │  ├─ Categories/
   │  ├─ Budgets/
   │  ├─ Bills/
   │  ├─ Dashboard/
   │  └─ AI/
   ├─ Enums/
   ├─ Authentication/
   ├─ Middleware/
   ├─ Common/
   ├─ Program.cs
   └─ configuration files
```

- `Controllers/`: endpoint tanımları, authorization niteliği, request kabulü ve response üretimi.
- `Services/`: iş kuralları, sahiplik filtreleri, doğrulama koordinasyonu ve finansal hesaplar.
- `Services/AI/`: LLM istemcisiyle iletişim, prompt girdisinin hazırlanması ve AI response doğrulaması.
- `Data/`: `AppDbContext` ve Entity Framework Core entity konfigürasyonları.
- `Entities/`: veri tabanı modelleri; client'a doğrudan döndürülmez.
- `DTOs/`: API request/response sözleşmeleri.
- `Enums/`: sabit kategori yaklaşımıyla uyumlu enum/sabit değerler ve fatura türleri. Kategorilerin veri tabanındaki `Category` kayıtlarıyla nasıl eşleneceği uygulama başlamadan doğrulanmalıdır.
- `Authentication/`: parola hash/doğrulama, JWT üretimi ve authenticated kullanıcı claim'ine erişimle ilgili sınırlı yardımcılar.
- `Middleware/`: beklenmeyen hataları tek biçimde API cevabına dönüştüren merkezi hata yakalama.
- `Common/`: yalnızca ortak response veya küçük sabitler; genel amaçlı soyutlama deposuna dönüştürülmez.

## 4. Entity Listesi

Entity'ler `PROJECT.md` temel veri modeline dayanır.

### User

| Alan | Amaç / kural |
|---|---|
| Id | `Guid` tipinde kullanıcının birincil anahtarı |
| Email | Giriş ve kayıt kimliği; benzersiz olmalı |
| PasswordHash | Hash'lenmiş parola; düz parola tutulmaz |
| CreatedAt | UTC tutulan kaydın oluşturulma zamanı |

Parola entity alanı değildir. Kayıt sırasında en az 8 karakter kontrol edilir, ardından yalnızca hash saklanır.

### Category

| Alan | Amaç / kural |
|---|---|
| Id | `Guid` tipinde kategorinin birincil anahtarı |
| Name | Market, Ulaşım, Fatura, Eğlence, Sağlık, Eğitim, Kira veya Diğer |

AI yeni `Category` kaydı oluşturamaz.

Sabit kategoriler database seed ile oluşturulur: Market, Ulaşım, Fatura, Eğlence, Sağlık, Eğitim, Kira ve Diğer.

### Expense

| Alan | Amaç / kural |
|---|---|
| Id | `Guid` tipinde giderin birincil anahtarı |
| UserId | `Guid` tipinde kaydın sahibi |
| Amount | Sıfırdan büyük, PostgreSQL `numeric(18,2)` gider tutarı |
| Description | Boş olamayan gider açıklaması |
| CategoryId | `Guid` tipinde geçerli kategori ilişkisi |
| Date | Tarih-only mantığıyla ele alınan gider tarihi |
| CreatedAt | UTC tutulan kaydın oluşturulma zamanı |
| IsAiCategorized | Kaydedilen kategorinin AI kategorileme akışından gelip gelmediği |
| BillId | Nullable `Guid`; bu gider bir Bill'den otomatik oluşturulduysa ilgili Bill'in kimliği (bkz. Bölüm 5.1 Bill → Expense Senkronizasyonu). Manuel oluşturulan giderlerde `null`dur. |

### Income

| Alan | Amaç / kural |
|---|---|
| Id | `Guid` tipinde gelirin birincil anahtarı |
| UserId | `Guid` tipinde kaydın sahibi |
| Amount | Sıfırdan büyük, PostgreSQL `numeric(18,2)` gelir tutarı |
| Description | Opsiyonel gelir açıklaması |
| Date | Tarih-only mantığıyla ele alınan gelir tarihi |
| CreatedAt | UTC tutulan kaydın oluşturulma zamanı |

### Budget

| Alan | Amaç / kural |
|---|---|
| Id | `Guid` tipinde bütçenin birincil anahtarı |
| UserId | `Guid` tipinde kaydın sahibi |
| CategoryId | `Guid` tipinde bütçenin ait olduğu kategori |
| LimitAmount | Sıfırdan büyük, PostgreSQL `numeric(18,2)` aylık limit |
| Month | Bütçe ayı |
| Year | Bütçe yılı |
| CreatedAt | UTC tutulan kaydın oluşturulma zamanı |

Aynı `UserId + CategoryId + Month + Year` birleşimi için birden fazla aktif bütçe oluşmamalıdır.

### Bill

| Alan | Amaç / kural |
|---|---|
| Id | `Guid` tipinde faturanın birincil anahtarı |
| UserId | `Guid` tipinde kaydın sahibi |
| BillType | Electricity, Water veya NaturalGas |
| Amount | Sıfırdan büyük, PostgreSQL `numeric(18,2)` fatura tutarı |
| ConsumptionValue | Opsiyonel; verilirse sıfırdan büyük tüketim değeri |
| BillingDate | Tarih-only mantığıyla ele alınan fatura tarihi |
| CreatedAt | UTC tutulan kaydın oluşturulma zamanı |

`ConsumptionValue` verilirse gösterim ve trend anlamı `BillType` üzerinden belirlenir:

- Electricity → kWh
- Water → m³
- NaturalGas → m³

Ölçü birimini kullanıcıdan serbest metin olarak almak veya ayrı bir kalıcı alan eklemek MVP için gerekli değildir; birim fatura türünden türetilebilir.

### RecurringFinancialRule

| Alan | Amaç / kural |
|---|---|
| Id | `Guid` tipinde kuralın birincil anahtarı |
| UserId | `Guid` tipinde kuralın sahibi |
| RecordType | Income, Expense veya Bill |
| Amount | Nullable; Income/Expense ve sabit tutarlı Bill için dolu, tutarı bilinmeyen Bill kuralı için `null` |
| StartDate | Tekrar gününün belirlendiği başlangıç tarihi (`StartDate.Day` her ayın tekrar günüdür) |
| Frequency | MVP'de yalnızca Monthly |
| DurationMonths / EndDate | Opsiyonel; kuralın kaç ay veya hangi tarihe kadar geçerli olduğu |
| IsActive | `false` ise kural otomatik/manuel gerçekleştirme akışına dahil edilmez |
| CategoryId, Description, ConsumptionValue vb. | RecordType'a göre gerçek kayıt oluştururken kullanılan şablon alanları |

`RecurringFinancialRule`, gerçekleşmiş (actual) bir finansal kayıt değil, yalnızca bir **plan/şablondur**. Dashboard ve Budget hesaplarına doğrudan dahil edilmez.

### RecurringOccurrence

| Alan | Amaç / kural |
|---|---|
| Id | `Guid` tipinde occurrence'ın birincil anahtarı |
| RecurringRuleId | İlgili `RecurringFinancialRule` |
| Year, Month | Hangi takvim ayı için gerçekleştirme izlendiği |
| CreatedRecordId | Nullable `Guid`; bu ay için oluşturulan gerçek Income/Expense/Bill kaydının kimliği (bkz. Bölüm 5.1) |

`(RecurringRuleId, Year, Month)` üzerinde **unique** kısıt vardır; bu, aynı kural için aynı ayda ikinci bir gerçek kaydın oluşmasını (arka plan servisi birden fazla kez çalışsa veya eşzamanlı çalışsa bile) veri tabanı seviyesinde engeller.

## 5. Entity İlişkileri

```text
User 1 ─── N Expense N ─── 1 Category
User 1 ─── N Income
User 1 ─── N Budget  N ─── 1 Category
User 1 ─── N Bill  1 ─── 0..1 Expense   (Bill.Id == Expense.BillId)
User 1 ─── N RecurringFinancialRule 1 ─── N RecurringOccurrence
```

- Bir kullanıcının birden fazla gideri, geliri, bütçesi, faturası ve recurring kuralı olabilir.
- Her gider tam bir kategoriye bağlıdır.
- Her bütçe tam bir kategoriye bağlıdır.
- Bir kategori birçok gider ve bütçe tarafından kullanılabilir.
- Her Bill, en fazla bir otomatik oluşturulmuş Expense'e sahip olabilir (`Expense.BillId`); bu ilişki `Expense` üzerinde nullable bir foreign key'dir, ayrı bir join tablosu değildir.
- Her `RecurringFinancialRule`, sıfır veya daha fazla `RecurringOccurrence` kaydına sahip olabilir; her occurrence tam bir kurala ve tek bir (Year, Month) çiftine bağlıdır.
- `Expense`, `Income`, `Budget`, `Bill` ve `RecurringFinancialRule` kayıtlarının her biri tam bir kullanıcıya ait olmalıdır.
- Kullanıcıya bağlı kayıtlar üzerinde veri tabanı ilişki bütünlüğü kurulmalıdır. Silme davranışının fiziksel silme/cascade ayrıntısı insan incelemesinde kararlaştırılmalıdır; kaynaklarda kullanıcı hesabı silme özelliği bulunmadığından bu taslak hesap silme akışı eklemez.

Önerilen veri bütünlüğü kontrolleri:

- `User.Email` için benzersizlik,
- `Budget(UserId, CategoryId, Month, Year)` için benzersizlik,
- `RecurringOccurrence(RecurringRuleId, Year, Month)` için benzersizlik,
- Entity primary key ve ilgili foreign key alanlarında `Guid`,
- `Expense.Amount`, `Income.Amount`, `Budget.LimitAmount` ve `Bill.Amount` için PostgreSQL `numeric(18,2)`,
- Zorunlu foreign key alanlarında null olmama,
- `ConsumptionValue` alanında null kabulü; değer varsa sıfırdan büyük olma kontrolü,
- Sabit kategori kayıtlarının database seed ile oluşturulması.

### 5.1 Bill → Expense Senkronizasyonu

Dashboard'ın tek gider gerçekliği kaynağı `Expense` tablosudur; `DashboardService` içine ayrı bir "Expenses + Bills" toplama mantığı **eklenmemiştir**. Bunun yerine, bir Bill oluşturulduğunda (manuel `POST /api/bills` ile veya recurring otomatik gerçekleşme ile) aynı işlem içinde `Category = Fatura` olan bağlı bir Expense de otomatik olarak oluşturulur; `Expense.BillId` bu Bill'e işaret eder.

```text
Bill oluşturma isteği (manuel veya recurring realize)
        │
        ▼
BillService.CreateAsync (tek mantıksal işlem)
   ├─ Bill kaydı oluşturulur
   └─ bağlı Expense kaydı oluşturulur (BillId = Bill.Id, Category = Fatura)
        │
        ▼
DashboardService yalnızca Expense'i toplar → double counting oluşmaz
```

Bill silindiğinde bağlı Expense da silinir. `BillId != null` olan bir Expense, İşlemler ekranından bağımsız olarak silinemez (409/conflict); bu tutarsız bir durumun (Bill kalırken bağlı giderin silinmesi) oluşmasını engeller. Bill trend endpoint'i (`GET /api/bills/trends`) Bill tablosunu kullanmaya devam eder; bu, Dashboard'ın Expense tabanlı finansal hesabından bağımsızdır.

### 5.2 Recurring Mimarisi: Plan → Occurrence → Actual Kayıt

```text
RecurringFinancialRule (plan/şablon — Dashboard'a dahil değil)
    │
    │  due kontrolü: bugün StartDate.Day mi? bu ay occurrence var mı?
    ▼
RecurringOccurrence (Rule + Year + Month üzerinde unique — realize edilip edilmediğini izler)
    │
    │  "reserve → create → finalize": önce CreatedRecordId=null ile occurrence
    │  rezerve edilir (unique constraint race-condition koruması), ardından
    │  gerçek kayıt IncomeService/ExpenseService/BillService üzerinden
    │  oluşturulur, son olarak CreatedRecordId geri yazılır.
    ▼
actual Income / Expense / Bill (+ linked Expense) kaydı
    │
    ▼
Dashboard / Budget yalnızca buradan (actual kayıtlardan) hesap yapar
```

`RecurringOccurrence.CreatedRecordId`, `RecordType`'a göre `Income.Id`, `Expense.Id` veya `Bill.Id`'den birine işaret eden **polimorfik (soft) bir referanstır**: veri tabanı seviyesinde tek bir foreign key olarak tanımlanmamıştır, çünkü üç farklı tabloya işaret edebilir. Bütünlüğü veri tabanı foreign key'i değil, uygulama mantığı (`RecurringRuleService`) sağlar. Bu tasarım tercih edilmiştir çünkü MVP kapsamında üç ayrı polimorfik ilişki tablosu veya generic bir "financial record" temel sınıfı/tablosu oluşturmak, mevcut Income/Expense/Bill modelini bozacak gereksiz bir refactor olurdu.

**Tutarı bilinmeyen (Amount=null) Bill kuralları için**: otomatik gerçekleştirme akışı hiçbir `RecurringOccurrence`/Bill/Expense kaydı **oluşturmaz**; kural o ay için "due" (gerçekleştirilmesi bekleniyor) durumda kalır. Kullanıcı gerçek tutarı `Faturayı Gir` akışıyla girdiğinde, mevcut manuel realize endpoint'i (`RecurringRuleService.RealizeAsync`) çalışır ve normal Bill → Expense senkronizasyonu aynen uygulanır.

**Double counting neden oluşmaz:** Dashboard ve Budget, hesaplarını yalnızca `Income`, `Expense` ve (Expense üzerinden) `Bill` tablolarından yapar; `RecurringFinancialRule` veya `RecurringOccurrence` tablolarını hiç sorgulamaz. Bir kural gerçekleştiğinde ortaya çıkan tek somut etki, normal akışta zaten var olan bir Income/Expense/Bill(+Expense) kaydıdır — bu nedenle recurring bir kaydın hem "plan" hem "actual" olarak iki kez sayılması mümkün değildir. `RecurringOccurrence`'ın `(RecurringRuleId, Year, Month)` benzersizliği ise aynı ay için iki gerçek kaydın (örn. arka plan servisinin iki kez çalışması durumunda) oluşmasını ayrıca engeller.

### 5.3 Hosted Service: Otomatik Gerçekleştirme Zamanlayıcısı

`RecurringRuleRealizationHostedService` (bir `BackgroundService`), yalnızca bir **zamanlama sarmalayıcısıdır**; iş mantığının hiçbiri bu sınıfta yaşamaz — tüm due-kontrolü, kategori/tutar kuralları, duplicate koruması ve Income/Expense/Bill oluşturma mantığı `RecurringRuleService` içindedir.

```text
ExecuteAsync
   ├─ (1) başlangıçta bir kez RunOnceAsync() çağrılır
   │      → startup catch-up: backend gece kapalıyken kaçırılan
   │        güncel günün due kaydı hemen tamamlanır
   │
   └─ (2) döngü:
         a. RecurringScheduleHelper.GetDelayUntilNextIstanbulMidnight(now) hesaplanır
         b. o süre kadar beklenir (Task.Delay + TimeProvider + CancellationToken)
         c. RunOnceAsync() tekrar çağrılır
         d. (a)'ya dön — gecikme HER seferinde yeniden hesaplanır,
            sabit bir TimeSpan.FromDays(1) kullanılmaz
```

`RunOnceAsync`, scoped `RecurringRuleService.RunAutomaticRealizationAsync`'i çağırır ve gelen istisnayı yakalayıp loglar; tek bir başarısız çalıştırma (veya bir kuralın hata vermesi) servisin tamamen durmasına ya da bir sonraki gece yarısının zamanlanmamasına yol açmaz.

Bu servis, üçüncü parti bir scheduler (Hangfire, Quartz vb.) veya harici bir cron/queue altyapısı **kullanmaz**; tek instance'lı MVP process'i için yeterli, sade bir `BackgroundService` döngüsüdür ve yalnızca backend process çalışırken işler.

### 5.4 Yardımcı Sınıfların Rolleri

- **`RecurrenceDateHelper.GetOccurrenceDate(startDate, year, month)`**: `RecurringRuleService` tarafından kullanılan, saf ve deterministik bir tarih hesaplama fonksiyonudur. `startDate.Day` ilgili (year, month) ayında yoksa (örn. 29/30/31), o ayın gerçek son gününü döndürür. Zamanlama veya scheduling ile ilgisi yoktur; yalnızca "bu ay için tekrar günü hangi takvim günüdür" sorusuna cevap verir.
- **`RecurringScheduleHelper.GetNextIstanbulMidnightUtc` / `GetDelayUntilNextIstanbulMidnight`**: `RecurringRuleRealizationHostedService` tarafından kullanılan, saf ve `TimeProvider`-girdili Europe/Istanbul gece yarısı zamanlama matematiğidir (`TimeZoneInfo.ConvertTime`/`GetUtcOffset` ile). Hangi kuralın due olduğuna dair hiçbir iş kararı vermez; yalnızca "bir sonraki Istanbul gece yarısına kadar ne kadar beklenmeli" sorusuna cevap verir.

Bu ayrım, iki farklı sorumluluğun (hangi gün due mu / ne zaman bir sonraki kontrol yapılmalı) birbirinden bağımsız olarak, saat beklemeden, sahte/fixed zamanla test edilebilmesini sağlar.

## 6. DTO Yapısı

Entity'ler doğrudan Flutter'a açılmayacaktır. Request ve response DTO'ları kullanım senaryosuna göre küçük tutulacaktır. Request DTO'larında `UserId` bulunmamalıdır.

### Authentication DTO'ları

- `RegisterRequest`: Email, Password
- `LoginRequest`: Email, Password
- `AuthResponse`: JWT token ve istemcinin oturum için ihtiyaç duyduğu sınırlı kullanıcı bilgisi

### Expense DTO'ları

- `CreateExpenseRequest`: Amount, Description, CategoryId, Date, kategorinin AI akışından seçildiğini belirlemek için gereken kontrollü bilgi
- `ExpenseResponse`: Id, Amount, Description, Category, Date, CreatedAt, IsAiCategorized
- `ExpenseListItemResponse`: liste için gereken gider alanları

`CreateExpenseRequest` içindeki kategori mutlaka backend'de doğrulanmalıdır. İstemcinin AI sonucu gönderiyor olması kategori whitelist/sahiplik doğrulamasını ortadan kaldırmaz.

### Income DTO'ları

- `CreateIncomeRequest`: Amount, nullable Description, Date
- `IncomeResponse`: Id, Amount, nullable Description, Date, CreatedAt

### Category DTO'ları

- `CategoryResponse`: Id, Name

### Budget DTO'ları

- `CreateBudgetRequest`: CategoryId, LimitAmount, Month, Year
- `UpdateBudgetRequest`: yalnızca LimitAmount içerir; CategoryId, Month, Year ve `UserId` içermez
- `BudgetResponse`: Id, Category, LimitAmount, Month, Year, spent amount, usage percent ve alert status

Harcama toplamı, kullanım yüzdesi ve uyarı durumu request ile alınmaz; backend tarafından hesaplanır.

### Bill DTO'ları

- `CreateBillRequest`: BillType, Amount, nullable ConsumptionValue, BillingDate; ConsumptionValue verilirse sıfırdan büyük olmalıdır
- `BillResponse`: Id, BillType, Amount, nullable ConsumptionValue, BillType'tan türetilen ConsumptionUnit, BillingDate, CreatedAt
- Trend cevabı: ay, fatura türü, toplam tutar ve yalnızca mevcutsa tüketim değeri/birimi

### Dashboard DTO'ları

- `MonthlyDashboardResponse`: TotalIncome, TotalExpense, kategori bazlı giderler, bütçe limit/kullanım bilgileri, geçen aya göre değişim, en yüksek harcama kategorisi ve en fazla artış gösteren kategori
- Son 6 ay trend serileri: dönem etiketi ve backend tarafından hesaplanmış tutar/tüketim değerleri

### AI DTO'ları

- `CategorizeExpenseRequest`: gider kategorilemesi için gerekli minimum açıklama/veri; `UserId` içermez
- `CategorizeExpenseResponse`: geçerli kategori önerisi, doğrulanmışsa confidence bilgisi ve manuel fallback gerekip gerekmediğini mobil istemcinin anlayacağı kontrollü sonuç
- LLM'in ham kategorileme response modeli: yalnızca backend içinde parse/doğrulama amacıyla kullanılır, doğrudan client'a veya veri tabanına aktarılmaz
- `MonthlySummaryResponse`: backend hesaplarının değiştirilmemiş bağlamına dayalı AI yorumu veya kontrollü unavailable/error durumu

Confidence doğrulanır ancak zorunlu kabul eşiği yoktur. Geçerli JSON ve whitelist içindeki kategori kabul edilir; confidence'ın eksik/geçersiz olması tek başına kategori ret sebebi değildir.

### Recurring DTO'ları

- `CreateRecurringRuleRequest`: RecordType, Amount (Bill için opsiyonel), StartDate, DurationMonths/EndDate, RecordType'a göre kategori/tüketim gibi ek alanlar; `UserId` içermez
- `UpdateRecurringRuleRequest`: kuralın güncellenebilir alanları
- `RealizeRecurringRuleRequest`: manuel/fallback realize akışı için (özellikle tutarı bilinmeyen Bill'de) girilen gerçek Amount ve opsiyonel ConsumptionValue
- `RecurringRuleResponse`: kural bilgileri ve UI'nin ihtiyaç duyduğu minimum backend-hesaplı sunum alanları — `IsRealizedForCurrentMonth`, `NextDueDate`
- `RecurringRealizeResponse`: realize işlemi sonucunda oluşturulan gerçek kaydın özeti

Bu alanlar Flutter'da yeniden hesaplanmaz; backend tarafından üretilir ve olduğu gibi gösterilir.

## 7. Controller Listesi ve API Endpoint Dokümantasyonu

Controller'lar ince tutulmalı; doğrulama ve iş kararlarını service katmanına devretmelidir. Aşağıdaki liste `backend/SmartBudget.Api/Controllers/*.cs` dosyalarından doğrudan çıkarılmış ve koddaki `[Authorize]`/route attribute'larıyla karşılaştırılarak doğrulanmıştır (16.08.2026, final audit). Listelenmeyen hiçbir endpoint yoktur.

### AuthController (`api/auth`, controller `[Authorize]` içermez)

| METHOD | PATH | AMAÇ | AUTH |
|---|---|---|---|
| POST | `/api/auth/register` | Yeni kullanıcı kaydı oluşturur | Anonim |
| POST | `/api/auth/login` | Kullanıcıyı doğrular ve JWT access token döner | Anonim |

### CategoriesController (`api/categories`, `[Authorize]`)

| METHOD | PATH | AMAÇ | AUTH |
|---|---|---|---|
| GET | `/api/categories` | Sabit (seed) kategori listesini döner | JWT gerekli |

### ExpensesController (`api/expenses`, `[Authorize]`)

| METHOD | PATH | AMAÇ | AUTH |
|---|---|---|---|
| GET | `/api/expenses` | Authenticated kullanıcının gider listesini döner | JWT gerekli |
| GET | `/api/expenses/{id}` | Tek bir gider kaydının detayını döner (sahiplik doğrulanır, aksi halde 404) | JWT gerekli |
| POST | `/api/expenses` | Yeni gider kaydı oluşturur | JWT gerekli |
| DELETE | `/api/expenses/{id}` | Gider kaydını siler (Bill-linked ise `BillService` üzerinden reddedilir) | JWT gerekli |

### IncomesController (`api/incomes`, `[Authorize]`)

| METHOD | PATH | AMAÇ | AUTH |
|---|---|---|---|
| GET | `/api/incomes` | Authenticated kullanıcının gelir listesini döner | JWT gerekli |
| POST | `/api/incomes` | Yeni gelir kaydı oluşturur | JWT gerekli |
| DELETE | `/api/incomes/{id}` | Gelir kaydını siler | JWT gerekli |

### BudgetsController (`api/budgets`, `[Authorize]`)

| METHOD | PATH | AMAÇ | AUTH |
|---|---|---|---|
| GET | `/api/budgets` | Authenticated kullanıcının bütçelerini (SpentAmount/UsagePercent/AlertStatus dahil) döner | JWT gerekli |
| POST | `/api/budgets` | Yeni aylık kategori bütçesi oluşturur (tekillik kontrolüyle) | JWT gerekli |
| PUT | `/api/budgets/{id}` | Mevcut bütçenin yalnızca `LimitAmount` alanını günceller | JWT gerekli |
| DELETE | `/api/budgets/{id}` | Bütçeyi siler | JWT gerekli |

### BillsController (`api/bills`, `[Authorize]`)

| METHOD | PATH | AMAÇ | AUTH |
|---|---|---|---|
| GET | `/api/bills` | Authenticated kullanıcının fatura listesini döner | JWT gerekli |
| GET | `/api/bills/trends` | Son 6 aylık fatura tutar/tüketim trendini döner | JWT gerekli |
| POST | `/api/bills` | Yeni fatura oluşturur ve aynı işlemde bağlı bir Expense üretir (Bill → Expense sync) | JWT gerekli |
| DELETE | `/api/bills/{id}` | Faturayı ve bağlı Expense'ini siler | JWT gerekli |

### DashboardController (`api/dashboard`, `[Authorize]`)

| METHOD | PATH | AMAÇ | AUTH |
|---|---|---|---|
| GET | `/api/dashboard/monthly` | Belirtilen (veya varsayılan güncel) ay için hesaplanmış aylık özet, kategori/bütçe dağılımı ve son 6 ay trendini döner (`year`/`month` opsiyonel query parametreleri) | JWT gerekli |

### AiController (`api/ai`, `[Authorize]`)

| METHOD | PATH | AMAÇ | AUTH |
|---|---|---|---|
| POST | `/api/ai/categorize-expense` | Gider açıklamasından AI destekli kategori önerisi üretir | JWT gerekli |
| POST | `/api/ai/monthly-summary` | Backend'in hesapladığı aylık verileri AI ile kullanıcı dostu Türkçe metne yorumlar | JWT gerekli |

### RecurringRulesController (`api/recurring-rules`, `[Authorize]`)

| METHOD | PATH | AMAÇ | AUTH |
|---|---|---|---|
| GET | `/api/recurring-rules` | Authenticated kullanıcının tüm recurring kurallarını (durum/NextDueDate dahil) döner | JWT gerekli |
| GET | `/api/recurring-rules/due` | Yalnızca şu an due (gerçekleştirilmeyi bekleyen) kuralları döner | JWT gerekli |
| POST | `/api/recurring-rules` | Yeni recurring kural (Income/Expense/Bill) oluşturur | JWT gerekli |
| PUT | `/api/recurring-rules/{id}` | Mevcut recurring kuralı günceller | JWT gerekli |
| DELETE | `/api/recurring-rules/{id}` | Recurring kuralı siler | JWT gerekli |
| POST | `/api/recurring-rules/{id}/realize` | Kuralı ilgili ay için manuel gerçekleştirir; normal Income/Expense akışında zorunlu değildir, admin/fallback ve tutarı bilinmeyen Bill'in "Faturayı Gir" akışı için kullanılır | JWT gerekli |

Endpoint adları `PROJECT.md` uyarısı gereği geliştirme öncesi sözleşme incelemesinde değişebilirdi; yukarıdaki liste artık taslak değil, mevcut kod tabanının final halidir. Hiçbir endpoint body/query içinden `UserId` kabul etmez; kimlik her istekte JWT claim'inden okunur.

## 8. Service Listesi

| Service | Sorumluluk |
|---|---|
| AuthService | Kayıt, benzersiz e-posta kontrolü, minimum 8 karakter parola kuralı, hash/doğrulama ve JWT üretimi |
| ExpenseService | Gider iş kuralları, kategori doğrulaması, kullanıcı filtreli liste/detay/ekleme/silme |
| IncomeService | Gelir tutarı doğrulaması ve kullanıcı filtreli ekleme/listeleme/silme |
| CategoryService | İzinli kategorileri sunma ve kategori geçerliliğini kontrol etme |
| BudgetService | Aylık kategori bütçesi, tekillik kontrolü, gider toplamı, kullanım yüzdesi ve Warning/Exceeded durumu |
| BillService | Fatura kuralları, opsiyonel tüketim, türden birim türetme, kullanıcı filtreli kayıt/liste/silme, Bill oluşturulurken bağlı Expense'in atomic olarak oluşturulması/silinmesi ve son 6 ay trend verisi |
| DashboardService | Europe/Istanbul ay sınırlarıyla gelir/gider/bütçe/trend hesaplarını birleştirip dashboard DTO'su üretme; yalnızca actual Income/Expense/Bill kayıtlarını okur, RecurringFinancialRule/RecurringOccurrence'a dokunmaz |
| AiCategorizationService | LLM kategorileme çağrısı, JSON parse, whitelist ve confidence doğrulaması, fallback sonucu |
| AiMonthlyAnalysisService | DashboardService tarafından hesaplanan veriyi LLM'e iletme, güvenli aylık yorum sonucu üretme ve AI çıktısındaki teknik alan adı/JSON/`null` sızıntısını doğrulayıp gerekirse fallback'e düşme |
| RecurringRuleService | Recurring kural CRUD'u, due-kontrolü (StartDate.Day + Europe/Istanbul), `RecurrenceDateHelper` ile 29/30/31 hesabı, "reserve → create → finalize" realize akışı, Income/Expense/sabit Bill için otomatik gerçekleştirme (`RunAutomaticRealizationAsync`), tutarı bilinmeyen Bill için due bırakma, `Rule+Year+Month` duplicate koruması |

JWT claim'inden kullanıcı kimliğini okumak için ortak, küçük bir authenticated-user accessor kullanılabilir. Bu yardımcı yalnızca claim okuma/parse etme sorumluluğu taşır; authorization veya kaynak sahipliği iş kuralları service sorgularında kalır.

## 9. Repository / Entity Framework Core Kullanımı

MVP'de service sınıflarının `AppDbContext` üzerinden Entity Framework Core'u doğrudan kullanması önerilir. EF Core zaten sorgu ve değişiklik izleme davranışını sağladığı için generic repository ve ayrı Unit of Work katmanı eklenmeyecektir.

Temel yaklaşım:

1. Service, authenticated `userId` ile başlayan filtreli sorguyu oluşturur.
2. Gerekli ilişkiler ve hesap alanları veri tabanından DTO/projection olarak alınır.
3. Yazma işleminde iş kuralları service tarafından kontrol edilir.
4. Entity ekleme/güncelleme/silme yapılır ve tek işlem için `SaveChanges` çağrılır.
5. Entity client'a döndürülmez; response DTO oluşturulur.

Önemli sorgu kuralları:

- Kullanıcıya ait tablolarda sorgu başlangıcı `UserId == authenticatedUserId` filtresini içermelidir.
- `GET/DELETE/PUT {id}` işlemlerinde önce hem `Id` hem `UserId` ile kayıt aranmalıdır.
- Dashboard, bütçe ve trend sorguları kullanıcı ve Europe/Istanbul dönem sınırlarıyla filtrelenmelidir.
- Salt okunur liste/rapor sorgularında gereksiz change tracking kullanılmamalıdır.
- Hesaplamalar mümkün olduğunca veri tabanı sorgusu içinde toplulaştırılmalı; tüm kayıtların mobil istemciye çekilip orada hesaplanmasından kaçınılmalıdır.
- Bütçe tekilliği yalnızca uygulama kontrolüne bırakılmamalı, veri tabanı benzersizlik kuralıyla da korunmalıdır.

Özel repository ancak EF sorgularının ciddi biçimde tekrarlandığı somut bir ihtiyaç görülürse değerlendirilmelidir; ilk taslak için önerilmez.

## 10. Authentication ve JWT Akışı

### Kayıt

1. Flutter e-posta ve parolayı `AuthController`a gönderir.
2. `AuthService`, e-posta ve minimum 8 karakter parola kuralını doğrular.
3. E-posta benzersizliği kontrol edilir.
4. Parola güvenli biçimde hash'lenir; yalnızca `PasswordHash` saklanır.
5. Başarılı sonuç uygun auth response ile Flutter'a döner. Kayıt sonrası token verilip verilmeyeceği kaynaklarda kesin değildir ve insan incelemesinde netleştirilmelidir.

### Giriş

1. Flutter e-posta ve parolayı gönderir.
2. `AuthService` kullanıcıyı bulur ve hash üzerinden parolayı doğrular.
3. Başarılıysa backend, kullanıcı `Guid` değerini standart JWT subject/user id claim'inde taşıyan ve 60 dakika geçerli imzalı access token üretir.
4. Flutter access token'ı `flutter_secure_storage` ile güvenli biçimde saklar.
5. Korunan isteklerde `Authorization: Bearer <token>` header'ı gönderilir.
6. ASP.NET Core JWT Authentication token imzası ve geçerliliğini doğrular.
7. Controller veya ortak accessor authenticated kullanıcının standart user id claim'ini (`sub`/ASP.NET Core'da eşlenen `NameIdentifier`) okuyup `Guid` olarak doğrulayarak service metoduna iletir.

MVP'de refresh token bulunmaz. Access token süresi dolduğunda kullanıcı yeniden giriş yapar. Sosyal giriş veya parola kurtarma da kaynaklarda bulunmadığından eklenmez.

JWT issuer/audience değerleri uygulamadan önce kesinleştirilmelidir. İmzalama secret'ı kaynak kodda tutulmamalıdır.

### Flutter auth/token yönetimi

1. Başarılı login response'undaki access token `flutter_secure_storage` içine yazılır.
2. Uygulama oturumu başlatılırken token güvenli saklama alanından okunur.
3. Korunan API isteklerinde token Bearer header'a eklenir.
4. Token hiçbir loga, hata mesajına veya genel amaçlı düz metin saklama alanına yazılmaz.
5. Token 60 dakika sonunda geçersizdir; MVP'de refresh denenmez.
6. Süresi dolmuş/geçersiz token nedeniyle `401` alındığında güvenli saklamadaki token temizlenir ve kullanıcı login akışına yönlendirilir.
7. Kullanıcı çıkış yaptığında token `flutter_secure_storage` içinden silinir.

## 11. Kullanıcı Veri Sahipliği / Authorization Yaklaşımı

Kimlik doğrulama kullanıcının kim olduğunu, veri sahipliği kontrolü ise hangi kaynağa erişebileceğini belirler. İkisi ayrı kontrollerdir.

Zorunlu akış:

1. Korunan controller endpoint'i geçerli JWT ister.
2. `UserId`, request body veya query'den değil standart JWT user id claim'inden okunur ve `Guid` olarak doğrulanır.
3. Service metodu `authenticatedUserId` alır.
4. Gelir, gider, bütçe veya fatura sorgusu hem kaynak `Id`'si hem `UserId` ile filtrelenir.
5. Başka kullanıcıya ait kayıt bulunmuş olsa bile içerik döndürülmez, işlem yapılmaz ve veri sızıntısını azaltmak için `404 Not Found` yaklaşımı uygulanır.

Örnek sahiplik ilkesi:

```text
Yanlış: Kaydı yalnızca Id ile bul → daha sonra UserId kontrol et
Doğru:  Kaydı Id + authenticated UserId ile sorgula
```

Oluşturma sırasında entity'nin `UserId` değeri backend tarafından authenticated claim'den atanır. İstemci `UserId` gönderirse güvenilir kabul edilmez; tercih edilen DTO tasarımında alan hiç bulunmaz.

Liste, detay, silme, bütçe güncelleme, dashboard hesapları ve AI aylık analiz girdisi aynı sahiplik kuralına tabidir. Böylece başka kullanıcının verisinin hem API cevabına hem de LLM promptuna karışması önlenir.

## 12. AI Servisinin Mimarideki Konumu

AI entegrasyonu backend içindeki service katmanında yer alır:

```text
AiController
   └─ AiCategorizationService / AiMonthlyAnalysisService
         ├─ girdi minimizasyonu
         ├─ LLM API çağrısı
         ├─ response parse ve doğrulama
         └─ kontrollü başarı/fallback sonucu
```

- Flutter LLM API'ye doğrudan bağlanmaz.
- AI API key yalnızca backend configuration/environment üzerinden okunur.
- AI service, Entity Framework Core'un veya finansal iş kurallarının yerine geçmez.
- AI için gönderilecek veri yalnızca ilgili işlevin ihtiyaç duyduğu minimum veri olmalıdır.
- Ham AI response güvenilir değildir; doğrudan entity veya client response olarak kullanılmaz.
- AI servis kesintisi temel CRUD, bütçe, dashboard ve trend işlevlerini durdurmaz.

LLM sağlayıcısına özel istemci, genel uygulama servislerinden ayrılmalıdır; ancak MVP'de birden fazla sağlayıcıyı destekleyen gereksiz provider/plugin katmanı kurulmayacaktır.

## 13. AI Gider Kategorileme Akışı

```text
Kullanıcı gider açıklamasını girer
        │
        ▼
Flutter kategorileme isteğini backend'e yollar
        │
        ▼
Backend girdiyi doğrular ve minimum veriyi AI Service'e verir
        │
        ▼
LLM API JSON yanıt üretir
        │
        ▼
Backend JSON parse + category whitelist + confidence doğrulaması yapar
        │
        ├─ Geçerli JSON + whitelist kategori → öneriyi döndür
        │                                      (confidence eşiği yok)
        │
        └─ Geçersiz JSON/kategori/timeout → manuel kategori fallback'i
```

Ayrıntılı kurallar:

1. Flutter gider açıklamasını gönderir; `UserId` göndermez.
2. Backend boş açıklamayı AI'a göndermeden reddeder.
3. LLM'den yapılandırılmış JSON yanıt istenir.
4. Ham yanıt JSON olarak parse edilir.
5. `category`, Market/Ulaşım/Fatura/Eğlence/Sağlık/Eğitim/Kira/Diğer whitelist'iyle doğrulanır.
6. Confidence varsa veri tipi ve sınırı doğrulanır; zorunlu kabul eşiği uygulanmaz.
7. Geçerli JSON ve whitelist kategori varsa kategori önerisi kabul edilir. Geçersiz confidence tek başına kategoriyi reddettirmez.
8. AI yeni kategori oluşturamaz.
9. Flutter geçerli AI kategorisini yalnızca öneri olarak gösterir; otomatik veya zorunlu seçim yapmaz. Kullanıcı öneriyi açıkça kabul edebilir ya da manuel olarak başka bir whitelist kategorisi seçebilir.
10. Gider oluşturulurken backend seçilen kategoriyi tekrar doğrular ve `UserId`yi JWT'den atar.

AI response'un gelmesi tek başına gider kaydı oluşturmaz. Böylece geç gelen AI cevabının veya tekrarlanan isteğin çift kayıt üretmesi önlenir; kalıcı kayıt ayrı gider oluşturma işlemiyle yapılır.

## 14. AI Aylık Analiz Akışı

```text
Authenticated UserId + raporlama ayı
        │
        ▼
DashboardService / backend hesapları
  ├─ toplam gelir
  ├─ toplam gider
  ├─ kategori bazlı gider
  ├─ bütçe kullanım yüzdesi
  ├─ geçen aya göre değişim
  ├─ en yüksek harcama kategorisi
  └─ en fazla artış gösteren kategori
        │
        ▼
Minimum, hesaplanmış veri AI Service'e verilir
        │
        ▼
AI yalnızca anlaşılır metin yorumu üretir
        │
        ▼
Backend yanıtı kontrol eder ve Flutter'a döner
```

- Dönem sınırları Europe/Istanbul zaman dilimine göre backend tarafından belirlenir.
- Tüm sorgular authenticated kullanıcı verisiyle filtrelenir.
- Toplam, fark, yüzde ve trend AI'a hesaplatılmaz.
- LLM'e mümkün olduğunca ham işlem açıklamaları veya gereksiz kişisel veri yerine hesaplanmış özet gönderilir.
- AI rakamları değiştiremez, olmayan veriyi tahmin edemez ve yatırım tavsiyesi veremez.
- AI yorumu kalıcı finansal kaydın doğruluk kaynağı değildir.

## 15. AI Hata ve Fallback Akışı

### Kategorileme fallback'i

| Hata | Backend davranışı | Flutter davranışı |
|---|---|---|
| Timeout / bağlantı hatası | Kontrollü kategorileme başarısız sonucu üretir | Hata mesajı ve manuel kategori seçimi gösterir |
| Boş response | Yanıtı reddeder | Manuel kategori seçimini korur |
| Geçersiz JSON | Yanıtı reddeder | Manuel kategori seçimini korur |
| Whitelist dışı kategori | Kategoriyi reddeder; yeni kategori oluşturmaz | Manuel kategori seçimini korur |
| Eksik/geçersiz confidence, fakat geçerli JSON ve whitelist kategori | Confidence'ı geçersiz işaretler; kategoriyi yalnızca bu nedenle reddetmez | Geçerli kategoriyi otomatik seçmeden öneri olarak gösterir; kullanıcı kabul eder veya değiştirir |

### Aylık analiz fallback'i

1. DashboardService hesapları AI çağrısından önce üretir.
2. AI timeout, servis hatası, boş veya kabul edilemez yanıt verirse AI yorumu unavailable olarak ele alınır.
3. Flutter, AI yorumunun üretilemediğini anlaşılır biçimde gösterir.
4. Hesaplanmış dashboard verileri ve grafikler kullanılabilir kalır.

AI hataları expense, income, budget, bill veya dashboard temel işlevlerini genel servis hatasına dönüştürmemelidir.

## 16. Dashboard Veri Akışı

```text
Flutter Dashboard
      │ GET /api/dashboard/monthly + Bearer token
      ▼
DashboardController
      │ authenticated UserId
      ▼
DashboardService
      ├─ Europe/Istanbul raporlama dönemini belirler
      ├─ Income toplamını hesaplar
      ├─ Expense toplamını ve kategori dağılımını hesaplar
      ├─ Budget kullanımını hesaplar
      ├─ önceki ay karşılaştırmasını hesaplar
      └─ son 6 ay trend serilerini hesaplar
      │
      ▼
MonthlyDashboardResponse
      │
      ▼
Flutter: loading / error / empty / success görünümü
```

Dashboard controller hesap yapmaz. Flutter da backend toplamlarını yeniden üretmez. İlgili ayda veri yoksa backend sıfır/boş veri durumunu tutarlı DTO ile bildirir; Flutter yanıltıcı grafik yerine empty state gösterir.

Önceki ay verisi yoksa veya önceki ay tutarı sıfırsa, değişim hesabı sıfıra bölme ya da yanıltıcı yüzde üretmeden kontrollü biçimde temsil edilmelidir. Kesin response gösterimi insan incelemesinde belirlenmelidir.

## 17. Budget Hesaplama Akışı

1. Kullanıcı kategori, ay, yıl ve `LimitAmount > 0` değerini gönderir.
2. Controller authenticated `UserId`yi claim'den alır.
3. BudgetService kategori geçerliliğini doğrular.
4. Aynı `UserId + CategoryId + Month + Year` için bütçe olup olmadığını kontrol eder.
5. Yeni bütçe kaydedilir veya sahipliği doğrulanmış mevcut bütçede yalnızca `LimitAmount` güncellenir. `CategoryId`, `Month` ve `Year` update işleminde değiştirilemez.
6. İstenen dönem için aynı kullanıcı ve kategorideki giderlerin toplamı backend'de hesaplanır.
7. Kullanım yüzdesi backend'de `spent / limit` yaklaşımıyla hesaplanır; Flutter veya AI hesap yapmaz.
8. Kullanım oranı:
   - %80'den azsa normal,
   - %80 veya üzeri ve %100'den azsa `Warning`,
   - %100 veya üzeriyse `Exceeded`
   olarak döndürülür.
9. Oran %100'ü aşarsa gerçek oran korunur; yapay biçimde %100'e sabitlenmez.

Dönem giderleri Europe/Istanbul ay sınırlarına göre seçilmelidir. Bütçe yoksa kullanım/uyarı varmış gibi üretilmemelidir.

## 18. Bill / Tüketim Trendi Akışı

### Fatura kaydı

1. Flutter BillType, `Amount > 0`, opsiyonel `ConsumptionValue` ve BillingDate gönderir.
2. Backend BillType'ın Electricity, Water veya NaturalGas olduğunu doğrular.
3. `ConsumptionValue` yoksa geçerli fatura kaydedilebilir; değer verilmişse sıfırdan büyük olması doğrulanır.
4. Geçerli `ConsumptionValue` varsa birim BillType'tan türetilir: Electricity için kWh; Water ve NaturalGas için m³.
5. `UserId` JWT claim'inden atanır ve fatura kaydedilir.

### Son 6 ay trendi

1. Backend Europe/Istanbul zaman dilimine göre mevcut ay dahil varsayılan son 6 aylık sınırı belirler.
2. Faturalar authenticated kullanıcı, tarih ve gerekirse fatura türüyle filtrelenir.
3. Her ay için fatura tutarı backend'de gruplanır/toplanır.
4. `ConsumptionValue` bulunan kayıtlardan tüketim serisi üretilir; null değerler tüketim varmış gibi sıfır kayıt şeklinde yorumlanmamalıdır.
5. Farklı birimli tüketimler tek seri içinde toplanmaz; Electricity kWh, Water m³ ve NaturalGas m³ tür bazlı anlamını korur.
6. Hesaplanmış seri DTO olarak Flutter'a döner ve grafiklerde gösterilir.

Fatura trendi `BillsController` altında `GET /api/bills/trends` endpoint'iyle sunulur. Endpoint varsayılan olarak Europe/Istanbul dönem hesabına göre son 6 ayı döndürür ve yalnızca authenticated kullanıcının verisini içerir.

## 19. Backend ile Flutter Arasındaki API İletişimi

- İletişim HTTP/HTTPS üzerinde REST ve JSON ile yapılır; production kullanımı HTTPS gerektirir.
- Korunan endpointlerde JWT Bearer token gönderilir.
- Request/response sözleşmeleri DTO'lardır; entity'ler API sözleşmesi değildir.
- `Date` ve `BillingDate` tarih-only olarak taşınır; `CreatedAt` UTC zaman damgasıdır. Aylık raporlama ve trend dönemleri backend'de Europe/Istanbul esas alınarak belirlenir.
- Flutter her istek için loading, success, validation error, unauthorized, not found ve beklenmeyen hata durumlarını ayırabilmelidir.
- `401` sonucu oturumun geçersiz olduğunu belirtir; `flutter_secure_storage` içindeki token temizlenip login yönlendirmesi tek bir ortak noktada ele alınmalıdır. Refresh token akışı çalıştırılmaz.
- Validation hataları alan bazlı gösterime uygun, tutarlı API hata yapısıyla dönmelidir.
- Liste boşluğu başarılı fakat boş sonuç olarak ele alınmalı; genel hata gibi gösterilmemelidir.
- Ağ veya AI gecikmesi, aynı giderin iki kez oluşturulmasına yol açmamalıdır. Kaydetme düğmesinin işlem sürerken tekrar tetiklenmesi mobil durum yönetimiyle engellenmelidir.

API'nin base URL, timeout ve ortam değerleri Flutter kaynak koduna dağılmamalı, ortak config altında tutulmalıdır. Token saklama için netleştirilen `flutter_secure_storage` dışında bu taslak yeni bir paket seçimi yapmaz.

## 20. Hata Yönetimi Yaklaşımı

### Backend

- Request model doğrulama hataları kontrollü `400` cevabına dönüştürülür.
- Sıfır/negatif finansal tutar ile verilmiş fakat sıfır/negatif `ConsumptionValue` kontrollü `400` doğrulama hatasıdır.
- Kimlik doğrulama eksik/geçersizse `401` kullanılır.
- Authenticated kullanıcının sahip olmadığı kayıt ile bulunmayan kayıt aynı biçimde `404 Not Found` olarak ele alınır; kaydın başka kullanıcıya ait olduğu açığa çıkarılmaz.
- Yinelenen e-posta veya aylık bütçe gibi çakışmalar için tutarlı conflict/validation politikası belirlenir.
- Beklenmeyen hatalar merkezi middleware tarafından yakalanır; production cevabında stack trace gösterilmez.
- Hata loglarında parola, JWT, API key, tam finansal içerik veya gereksiz kişisel veri bulunmaz.
- AI timeout ve format hataları genel uygulama çökmesine çevrilmez; ilgili AI servisi kontrollü fallback sonucu üretir.

ASP.NET Core'un standart hata cevabı yaklaşımı kullanılabilir; özel ve karmaşık exception hiyerarşisi MVP için gerekli değildir.

### Flutter

- Her feature loading, error, empty ve success durumlarını açık biçimde yönetir.
- Validation mesajları ilgili forma, authorization hatası oturum akışına, ağ hatası tekrar deneme/geri bildirim durumuna çevrilir.
- AI kategorileme hatasında manuel kategori seçimi görünür ve kullanılabilir kalır.
- Geçerli AI kategorisi otomatik uygulanmaz; öneri olarak gösterilir ve kullanıcı kabulü veya manuel değişikliği beklenir.
- AI aylık analiz hatasında dashboard verisi ve grafikler korunur.
- Kullanıcıya backend stack trace veya ham LLM response gösterilmez.

## 21. Güvenlik Açısından Mimaride Dikkat Edilmesi Gereken Noktalar

- Parola en az 8 karakter olmalı ve güçlü hash ile saklanmalıdır; düz parola hiçbir kalıcı alanda veya logda bulunmamalıdır.
- JWT imzalama secret'ı ve AI API key environment/configuration üzerinden backend'de tutulmalı, repository'ye veya Flutter uygulamasına eklenmemelidir.
- JWT access token 60 dakika geçerli olmalı, standart user id claim'i taşımalı ve Flutter'da `flutter_secure_storage` ile saklanmalıdır; MVP'de refresh token bulunmamalıdır.
- Tüm korunan endpointlerde authentication ve kaynak bazlı ownership filtresi uygulanmalıdır.
- Request body'deki `UserId` hiçbir zaman yetki kaynağı değildir; ideal olarak DTO'larda bulunmaz.
- IDOR riskine karşı `Id + authenticated UserId` sorgusu kullanılmalıdır.
- AI'a yalnızca gerekli minimum veri gönderilmeli; başka kullanıcı verisi veya gereksiz finansal açıklamalar prompta girmemelidir.
- Kullanıcı girdileri ve AI response'ları güvenilmeyen veri kabul edilmelidir.
- AI category değeri whitelist dışında kalırsa reddedilmelidir; AI yeni kategori üretemez.
- Geçerli JSON/whitelist kontrolü yapılmadan AI kategorisi kalıcı kayda dönüşmemelidir.
- Finansal sonuçlar AI'dan kabul edilmemeli; backend hesapları tek doğruluk kaynağı olmalıdır.
- HTTPS kullanılmalı ve token yalnızca authenticated istek header'ında taşınmalıdır.
- Production hata cevaplarında stack trace, secret veya altyapı ayrıntısı gösterilmemelidir.
- Loglar parola, token, API key ve hassas kullanıcı finansal verilerini içermemelidir.
- Veri tabanı sorguları her rapor ve AI analizi için kullanıcı bazında filtrelenmelidir.

## 22. Önerilen Geliştirme Sırası

Bu sıra bağımlılıkları azaltacak şekilde MVP'nin temel akışından AI özelliklerine ilerler:

1. **API sözleşmesi ve temel proje yapısı:** Entity/DTO adlarını, hata formatını, tarih sözleşmesini ve endpoint taslağını insan incelemesiyle kesinleştirme.
2. **Veri modeli ve DbContext:** `Guid` anahtarlı User, Category, Expense, Income, Budget ve Bill modelleri; `numeric(18,2)` finansal tutarlar; UTC `CreatedAt`; tarih-only `Date`/`BillingDate`; kategori seed'i ve ilişkileri hazırlama. Migration oluşturma bu taslağın değil sonraki geliştirme görevinin parçasıdır.
3. **Authentication:** Kayıt, minimum 8 karakter parola, parola hash, standart user id claim'i içeren 60 dakikalık access token ve JWT doğrulama; refresh token eklememe.
4. **Authorization temeli:** Authenticated UserId accessor ve tüm kullanıcı kaynakları için sahiplik sorgu desenini yerleştirme.
5. **Category ve Expense:** Database seed ile sabit kategori listesi, manuel kategoriyle gider ekleme/listeleme/detay/silme.
6. **Income:** Opsiyonel Description ile gelir ekleme/listeleme/silme.
7. **Budget:** Aylık bütçe CRUD, update sırasında yalnızca LimitAmount değişikliği, tekillik, kullanım yüzdesi ve %80/%100 durumları.
8. **Bill:** Fatura ekleme/listeleme/silme, `Amount > 0`, opsiyonel fakat verildiğinde sıfırdan büyük tüketim, türe göre birim ve BillsController altındaki trend endpoint'i.
9. **Dashboard ve rapor hesapları:** Europe/Istanbul aylık sınırları, aylık özet, önceki ay karşılaştırmaları ve son 6 ay trendleri.
10. **Flutter temel akışları:** `flutter_secure_storage` tabanlı auth/session, ortak API/hata yönetimi ve ilgili CRUD ekranlarının loading/error/empty durumları.
11. **AI gider kategorileme:** Backend LLM çağrısı, JSON/whitelist/confidence doğrulaması, kullanıcı onaylı öneri ve manuel fallback.
12. **AI aylık analiz:** Yalnızca backend hesaplarından yorum üretme ve AI unavailable fallback'i.
13. **Entegrasyon ve hata senaryoları:** Sahiplik, validation, eşik, tarih sınırı, null tüketim, AI timeout/geçersiz JSON ve çift kayıt risklerini uçtan uca doğrulama.
14. **Dokümantasyon ve insan kontrolü:** Teknik dokümanı güncelleme, önemli AI promptlarını ve kritik insan müdahalelerini ilgili kayıtlara işleme.

Her aşamada ilgili backend davranışı çalışmadan mobil tarafta varsayımsal finansal hesap veya geçici iş kuralı kalıcılaştırılmamalıdır.

## Mimari Kararlar

- Sistem microservice yerine tek ASP.NET Core Web API, tek PostgreSQL veri tabanı ve tek Flutter istemciden oluşacaktır.
- Controller'lar ince tutulacak; iş kuralları ve hesaplamalar service katmanında bulunacaktır.
- Service katmanı Entity Framework Core `DbContext`ini doğrudan kullanacak; MVP'de generic repository/Unit of Work eklenmeyecektir.
- Entity'ler client'a açılmayacak; request/response DTO'ları kullanılacaktır.
- Tüm entity primary key'leri `Guid` olacak; ilgili foreign key'ler aynı tipi kullanacaktır.
- Finansal tutarlar PostgreSQL'de `numeric(18,2)` tutulacaktır.
- `CreatedAt` UTC tutulacak; `Date` ve `BillingDate` tarih-only ele alınacaktır.
- Request DTO'larında `UserId` bulunmayacak; kimlik JWT standart user id claim'inden okunacaktır.
- Kullanıcıya bağlı her sorgu authenticated `UserId` ile filtrelenecektir.
- Başka kullanıcıya ait veya bulunmayan kaynaklar veri sızıntısını azaltmak için aynı `404 Not Found` yaklaşımıyla ele alınacaktır.
- Finansal toplam, yüzde, bütçe ve trend hesaplarının tek doğruluk kaynağı backend olacaktır.
- Europe/Istanbul aylık raporlama sınırlarında esas alınacak; trendler varsayılan olarak son 6 ayı kapsayacaktır.
- JWT access token süresi 60 dakika olacak; MVP'de refresh token bulunmayacaktır.
- Flutter access token'ı `flutter_secure_storage` ile güvenli saklayacaktır.
- Income Description nullable olacaktır.
- Sabit gider kategorileri database seed ile oluşturulacaktır.
- `ConsumptionValue` nullable olacak; değer verilirse sıfırdan büyük olacak ve birim Electricity için kWh, Water ve NaturalGas için m³ olarak BillType'tan türetilecektir.
- Bill trend endpoint'i `BillsController` altında yer alacaktır.
- Budget update yalnızca `LimitAmount` alanını değiştirecek; `CategoryId`, `Month` ve `Year` değiştirilemeyecektir.
- LLM yalnızca backend AI service üzerinden çağrılacak; API key backend configuration/environment içinde tutulacaktır.
- AI kategorilemede geçerli JSON ve category whitelist kabul koşuludur; confidence doğrulanacak fakat zorunlu eşik uygulanmayacaktır.
- AI kategori sonucu yalnızca öneri olarak gösterilecek; kullanıcı öneriyi kabul edebilecek veya manuel kategoriyle değiştirecektir.
- AI hataları manuel kategori seçimini ve AI'sız dashboard kullanımını engellemeyecektir.
- AI aylık analiz yalnızca backend tarafından önceden hesaplanan verileri yorumlayacaktır.
- Bill oluşturulduğunda aynı işlem içinde bağlı bir Expense (`Expense.BillId`) otomatik oluşturulacak; Dashboard ikinci bir "Expenses + Bills" toplama mantığı içermeyecektir.
- Recurring finansal kayıtlar `RecurringFinancialRule` (plan) + `RecurringOccurrence` (Rule+Year+Month unique, realize izleme) modeliyle temsil edilecek; `CreatedRecordId` veri tabanı foreign key'i olmayan, uygulama tarafından yönetilen polimorfik bir referans olacaktır.
- Income/Expense ve sabit tutarlı Bill recurring kuralları, StartDate.Day Europe/Istanbul takviminde geldiğinde backend tarafından otomatik gerçekleştirilecek; tutarı bilinmeyen Bill kuralları otomatik gerçekleştirilmeyecek, due kalacaktır.
- Otomatik gerçekleştirme, ana ASP.NET Core sürecinde çalışan sade bir `BackgroundService` (`RecurringRuleRealizationHostedService`) ile yapılacak; Hangfire/Quartz/üçüncü parti scheduler kullanılmayacaktır. Servis başlangıçta bir kez (catch-up) ve ardından her seferinde yeniden hesaplanan bir sonraki Europe/Istanbul gece yarısında çalışacak; sabit `TimeSpan.FromDays(1)` gibi bir polling aralığı kullanılmayacaktır.
- Zamanlama matematiği (`RecurringScheduleHelper`) ve tekrar günü hesabı (`RecurrenceDateHelper`), iş mantığından ayrı, saf ve `TimeProvider` ile test edilebilir yardımcı sınıflarda tutulacaktır.

## İnsan İncelemesinde Kontrol Edilmesi Gereken Noktalar

- `Guid` değerlerinin uygulama veya veri tabanı tarafında üretilmesi ve varsayılan üretim stratejisi.
- `ConsumptionValue` için PostgreSQL sayısal hassasiyeti; alanın opsiyonel ve verilirse sıfırdan büyük olması değişmemelidir.
- JWT issuer ve audience değerleri.
- Kayıt işleminden hemen sonra token dönülüp dönülmeyeceği.
- Parola dışındaki alan uzunluğu sınırları.
- Database seed ile oluşturulan görünen Türkçe kategori adlarıyla AI whitelist değerlerinin tek biçimli eşlenmesi.
- AI confidence değerinin geçersiz olduğunun API response'unda nasıl temsil edileceği; kategori kabulünü etkilememesi korunmalıdır.
- Dashboard ay seçimi ve son 6 aylık trend verisinin kesin endpoint/query sözleşmesi.
- Kullanıcı hesabı silme özelliği kapsamda olmadığı için ilişkilerde cascade davranışının geleceğe etkisi.
- AI aylık analiz response'unun metin doğrulama sınırları ve yatırım tavsiyesi/olmayan veri kontrolünün test yaklaşımı.
- API validation/conflict hata formatı ve mobilde alan bazlı gösterim sözleşmesi.

## Revizyon Özeti

- Entity anahtarları `Guid`, finansal tutarlar `numeric(18,2)`, `CreatedAt` UTC ve işlem/fatura tarihleri tarih-only olarak netleştirildi.
- JWT user id claim'i, 60 dakikalık access token, refresh token kapsam dışılığı ve `flutter_secure_storage` kullanımı belirlendi.
- Sahip olunmayan kaynaklar için `404`, opsiyonel Income Description ve database category seed kararları işlendi.
- AI kategori önerisinin kullanıcı onayına bağlı olması, Bill tüketim doğrulaması ve trend endpoint'inin BillsController altında bulunması netleştirildi.
- Budget update yalnızca `LimitAmount` ile sınırlandırıldı ve kesinleşen maddeler insan inceleme listesinden çıkarıldı.
- **16.08.2026 — Final dokümantasyon/audit revizyonu (`prompts/37_final_documentation_and_audit.txt`):** `Expense.BillId` ve Bill → Expense senkronizasyonu (Bölüm 5.1); `RecurringFinancialRule`/`RecurringOccurrence` entity'leri, recurring DTO'ları, `RecurringRulesController`/`RecurringRuleService` ve plan→occurrence→actual mimarisi (Bölüm 5.2); `RecurringRuleRealizationHostedService` zamanlayıcısı ve `RecurrenceDateHelper`/`RecurringScheduleHelper` yardımcı sınıflarının rolleri (Bölüm 5.3–5.4) mevcut gerçek implementasyona göre belgeye eklendi. Bu revizyon yalnızca dokümantasyon güncellemesidir; hiçbir kod/iş kuralı değiştirilmemiştir.
