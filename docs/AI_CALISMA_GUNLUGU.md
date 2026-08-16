# AI Çalışma Günlüğü

## AI-LOG-001 — PROJECT.md Oluşturulması

**Tarih:** 15.08.2026  
**Kullanılan AI:** ChatGPT  
**Kullanılan Prompt:** `prompts/00_project_md_olusturma.txt`

### Amaç
SmartBudget AI projesinin kapsamını, teknoloji seçimlerini, mimari kurallarını,
AI kullanım sınırlarını ve güvenlik kurallarını belirleyen ana context dosyasını oluşturmak.

### AI Ne Yaptı?
AI, proje görev dokümanındaki Aile Bütçesi ve Fatura Takibi projesini temel alarak
PROJECT.md için ilk taslağı oluşturdu.

### İnsan Tarafından Yapılan Kontrol
- Mobil teknoloji olarak Flutter + Dart kullanılmasına karar verildi.
- Backend teknolojileri ASP.NET Core Web API ve PostgreSQL olarak netleştirildi.
- AI'ın finansal hesaplamaları yapmaması gerektiği kontrol edildi.
- AI başarısız olduğunda manuel kategori seçimi fallback'i tanımlandı.
- Gerçek banka entegrasyonu kapsam dışı bırakıldı.
- Kullanıcıların yalnızca kendi verilerine erişebilmesi kuralı kontrol edildi.

### Sonuç
PROJECT.md proje boyunca geliştirici ve AI araçları için ana context dosyası olarak kabul edildi.




## AI-LOG-002 — ANALIZ.md Oluşturulması ve Revizyonu

**Tarih:** 15.08.2026  
**Kullanılan AI:** Codex  
**İlk Prompt:** `prompts/01_analiz_ilk_taslak.txt`  
**Revizyon Promptu:** `prompts/02_analiz_revizyon.txt`

### Amaç
SmartBudget AI için problem tanımı, kapsam, gereksinimler,
kullanıcı hikâyeleri ve kabul kriterlerini içeren analiz dokümanını oluşturmak.

### AI Ne Yaptı?
AI, PROJECT.md dosyasını okuyarak ANALIZ.md dosyasının ilk taslağını oluşturdu.

### İnsan İncelemesinde Tespit Edilen Noktalar
- Fatura tutarının 0 TL olabilmesi mantıksız bulundu ve `Amount > 0` olarak değiştirildi.
- Fatura tüketim değerinin zorunluluğu ve ölçü birimi belirsizdi.
- AI confidence değeri için kabul eşiği net değildi.
- Trend grafiklerinin kaç aylık veri göstereceği belli değildi.
- Tarih/zaman dilimi politikası tanımlanmamıştı.
- Minimum parola uzunluğu belirtilmemişti.
- Splash ekranı zorunlu MVP özelliği gibi görünüyordu.

### İnsan Tarafından Alınan Kararlar
- Fatura tutarı `Amount > 0` yapıldı.
- ConsumptionValue opsiyonel yapıldı.
- Elektrik için kWh, su ve doğalgaz için m³ kullanılması kararlaştırıldı.
- AI confidence için zorunlu eşik kullanılmamasına karar verildi.
- Trend grafikleri son 6 ay olarak belirlendi.
- Europe/Istanbul zaman dilimi kullanılmasına karar verildi.
- Minimum parola uzunluğu 8 karakter yapıldı.
- Splash ekranı zorunlu MVP gereksiniminden çıkarıldı.

### AI Revizyonu
Bu kararlar `02_analiz_revizyon.txt` promptuyla AI'a verilerek ANALIZ.md güncellendi.

### Sonuç
İnsan tarafından incelenmiş ve revize edilmiş ikinci ANALIZ.md sürümü oluşturuldu.




## AI-LOG-003 — Teknik Mimari Tasarımı ve Revizyonu

**Tarih:** 15.08.2026  
**Kullanılan AI:** Codex  
**İlk Prompt:** `prompts/03_mimari_tasarim.txt`  
**Revizyon Promptu:** `prompts/04_mimari_revizyon.txt`

### Amaç

SmartBudget AI projesinin kodlama başlamadan önce Flutter, ASP.NET Core,
PostgreSQL ve AI entegrasyonunu kapsayan teknik mimarisini belirlemek.

### AI Ne Yaptı?

AI, PROJECT.md ve ANALIZ.md dosyalarını okuyarak:

- genel sistem mimarisini,
- Flutter klasör yapısını,
- backend klasör yapısını,
- entity ve DTO yapılarını,
- controller ve service'leri,
- JWT authentication akışını,
- kullanıcı veri sahipliği yaklaşımını,
- AI kategorileme ve aylık analiz akışlarını,
- hata/fallback davranışlarını,
- önerilen geliştirme sırasını

içeren ilk teknik mimari taslağını oluşturdu.

### İnsan İncelemesinde Netleştirilen Noktalar

- Entity primary key tipi Guid olarak belirlendi.
- Finansal tutarlar PostgreSQL numeric(18,2) olarak belirlendi.
- CreatedAt UTC, işlem tarihleri tarih-only olarak belirlendi.
- JWT access token süresi 60 dakika olarak belirlendi.
- Refresh token MVP kapsamı dışında bırakıldı.
- Flutter token saklama için flutter_secure_storage seçildi.
- Başka kullanıcı kayıtlarına erişimde 404 yaklaşımı seçildi.
- Income Description opsiyonel yapıldı.
- Sabit kategorilerin database seed ile oluşturulmasına karar verildi.
- AI kategori sonucunun otomatik uygulanmaması, kullanıcıya öneri olarak gösterilmesi kararlaştırıldı.
- ConsumptionValue opsiyonel bırakıldı ancak verilirse sıfırdan büyük olması kararlaştırıldı.
- Bill trend endpoint'inin BillsController altında bulunmasına karar verildi.
- Budget update işleminde yalnızca LimitAmount değiştirilebileceği belirlendi.

### AI Revizyonu

Bu kararlar `04_mimari_revizyon.txt` promptuyla AI'a verilerek
TEKNIK_MIMARI_TASLAK.md dosyası güncellendi.

### Sonuç

İnsan tarafından incelenmiş ve revize edilmiş teknik mimari kabul edildi.
Kod geliştirme aşamasında bu mimari temel alınacaktır.




## AI-LOG-004 — Authentication ve JWT Geliştirmesi

**Tarih:** 16.08.2026  
**Kullanılan AI:** Codex  
**Kullanılan Prompt:** `prompts/06_authentication.txt`

### Amaç

SmartBudget AI backend'inde kullanıcı kayıt, giriş, parola güvenliği,
JWT authentication ve authenticated kullanıcı kimliği altyapısını oluşturmak.

### AI Ne Yaptı?

AI, PROJECT.md, ANALIZ.md ve TEKNIK_MIMARI_TASLAK.md dosyalarını okuyarak:

- Register ve Login DTO'larını,
- AuthService'i,
- AuthController'ı,
- password hashing altyapısını,
- JWT token üretimini,
- JWT authentication/authorization konfigürasyonunu,
- authenticated kullanıcı kimliğini claim'den okuyan CurrentUserAccessor yapısını,
- merkezi hata yönetimini,
- Swagger Bearer desteğini,
- authentication testlerini

oluşturdu.

### Uygulanan Güvenlik Kararları

- Parolalar düz metin olarak saklanmadı.
- ASP.NET Core `PasswordHasher<User>` kullanıldı.
- Minimum parola uzunluğu 8 karakter olarak uygulandı.
- E-posta normalize edilerek duplicate kullanıcı kontrolü yapıldı.
- Başarısız login durumunda e-posta veya parola bilgisinin hangisinin yanlış olduğu açıklanmadı.
- JWT access token süresi 60 dakika olarak uygulandı.
- Refresh token MVP kapsamına eklenmedi.
- JWT içerisinde kullanıcı kimliği `sub` ve `NameIdentifier` claim'leriyle taşındı.
- Token içerisinde parola, password hash veya finansal veri tutulmadı.
- JWT signing key kaynak koda yazılmadı; configuration/user-secrets üzerinden okunacak şekilde yapılandırıldı.
- Request body veya query içerisindeki `UserId` kullanılmadı.
- Authenticated kullanıcı kimliği JWT claim'inden Guid olarak okunacak şekilde CurrentUserAccessor oluşturuldu.

### Endpointler

- `POST /api/auth/register`
- `POST /api/auth/login`

### İnsan Tarafından Yapılan Kontrol

AI sonuç raporu incelendi.

Aşağıdaki noktaların proje kararlarıyla uyumlu olduğu doğrulandı:

- Register sonrasında otomatik JWT üretilmemesi,
- PasswordHasher kullanılması,
- JWT'nin 60 dakika geçerli olması,
- Refresh token eklenmemesi,
- Hassas verilerin token içine eklenmemesi,
- JWT secret'ın repository'ye yazılmaması,
- CurrentUserAccessor'ın yalnızca claim okuma sorumluluğu taşıması,
- Authentication dışındaki CRUD, Dashboard ve AI özelliklerine geçilmemesi.

Bu aşamada kritik bir hata tespit edilmediği için ek bir revizyon promptu oluşturulmadı.

### Test Sonucu

Authentication için oluşturulan testlerin tamamı başarılı oldu.

- Toplam test: 10
- Başarılı: 10
- Başarısız: 0

Build sonucu:

- 0 hata
- 0 uyarı

### İnsan Tarafından Sonraya Bırakılan Kontroller

- Production JWT issuer ve audience değerleri,
- Production signing key ve secret rotation yaklaşımı,
- Duplicate email için gerçek PostgreSQL concurrency/race testi,
- Endpoint seviyesinde HTTP integration testleri,
- Deployment ortamındaki secret configuration yaklaşımı.

### Sonuç

Authentication ve JWT altyapısı insan kontrolünden geçirilerek kabul edildi.

Bir sonraki geliştirme aşamasında authenticated kullanıcı sahipliği kuralları korunarak
Category ve Expense özelliklerine geçilecektir.




## AI-LOG-005 — Category ve Expense Geliştirmesi

**Tarih:** 16.08.2026  
**Kullanılan AI:** Codex  
**Kullanılan Prompt:** `prompts/07_category_expense.txt`

### Amaç

SmartBudget AI backend'inde sabit gider kategorilerinin listelenmesi ve
authenticated kullanıcıya ait gider kayıtlarının oluşturulması, listelenmesi,
detay görüntülenmesi ve silinmesi özelliklerini geliştirmek.

### AI Ne Yaptı?

AI, source-of-truth dokümanlarını ve mevcut Authentication altyapısını kullanarak:

- CategoriesController,
- ExpensesController,
- CategoryService,
- ExpenseService,
- Category ve Expense DTO'ları,
- ownership odaklı sorguları,
- kategori doğrulamasını,
- Expense hata davranışlarını,
- Category ve Expense testlerini

oluşturdu.

### Uygulanan İş ve Güvenlik Kuralları

- Request DTO'larına UserId eklenmedi.
- Authenticated UserId JWT claim'inden CurrentUserAccessor ile alındı.
- Kullanıcı yalnızca kendi Expense kayıtlarına erişebildi.
- Expense detail ve delete sorguları doğrudan Id + authenticated UserId ile filtrelendi.
- Başka kullanıcıya ait veya bulunmayan Expense için aynı 404 yaklaşımı kullanıldı.
- CategoryId her Expense create işleminde backend tarafından doğrulandı.
- Amount değerinin sıfırdan büyük olması zorunlu tutuldu.
- Description trim edilerek boş ve whitespace değerler reddedildi.
- Expense CreatedAt değeri UTC üretildi.
- Entity'ler doğrudan API response olarak dönülmedi.
- Category navigation entity yerine sınırlı CategoryResponse DTO kullanıldı.
- IsAiCategorized yalnızca veri alanı olarak saklandı; authorization veya kategori doğrulama kararlarında kullanılmadı.
- AI kategorileme bu aşamada geliştirilmedi.

### Endpointler

- `GET /api/categories`
- `GET /api/expenses`
- `GET /api/expenses/{id}`
- `POST /api/expenses`
- `DELETE /api/expenses/{id}`

### İnsan Tarafından Yapılan Kontrol

AI sonuç raporu incelendi.

Aşağıdaki noktaların proje kararlarıyla uyumlu olduğu doğrulandı:

- Category yazma endpointlerinin eklenmemesi,
- yalnızca seed edilmiş kategorilerin kullanılması,
- UserId'nin request'ten alınmaması,
- ownership kontrolünün Id + authenticated UserId sorgusuyla yapılması,
- başka kullanıcı kayıtlarında güvenli 404 davranışı,
- CategoryId'nin backend tarafından tekrar doğrulanması,
- Expense entity yerine DTO kullanılması,
- mevcut Authentication/JWT yapısının korunması,
- sonraki feature'lara geçilmemesi.

Bu aşamada kritik bir hata tespit edilmediği için ek revizyon promptu oluşturulmadı.

### Test Sonucu

Category ve Expense için 18 yeni test eklendi.

Toplam test sonucu:

- Toplam test: 28
- Başarılı: 28
- Başarısız: 0

Mevcut 10 Authentication/JWT testi de başarılı olmaya devam etti.

Build sonucu:

- 0 hata
- 0 uyarı

### İnsan Tarafından Sonraya Bırakılan Kontroller

- Gerçek PostgreSQL üzerinde uçtan uca endpoint testleri,
- Expense Description maksimum uzunluğu,
- numeric(18,2) üst sınırına yönelik API doğrulaması,
- gelecekteki Expense tarihine izin verilip verilmeyeceği,
- Flutter istemcisinin 400/401/404 hata sözleşmesiyle uyumu.

### Sonuç

Category ve Expense backend özellikleri insan kontrolünden geçirilerek kabul edildi.

Bir sonraki geliştirme aşamasında authenticated kullanıcı sahipliği kuralları korunarak
Income özelliğine geçilecektir.




## AI-LOG-006 — Income Geliştirmesi

**Tarih:** 16.08.2026  
**Kullanılan AI:** Codex  
**Kullanılan Prompt:** `prompts/08_income.txt`

### Amaç

SmartBudget AI backend'inde authenticated kullanıcıya ait gelir kayıtlarının
oluşturulması, listelenmesi ve silinmesi özelliklerini geliştirmek.

### AI Ne Yaptı?

AI, mevcut Authentication/JWT ve Category/Expense altyapısını koruyarak:

- Income DTO'larını,
- IncomeService'i,
- IncomesController'ı,
- Income ownership kurallarını,
- Description normalization davranışını,
- Income testlerini

oluşturdu.

### Uygulanan İş ve Güvenlik Kuralları

- Request DTO'sunda UserId bulunmadı.
- UserId mevcut CurrentUserAccessor ile JWT claim'inden alındı.
- Amount değerinin sıfırdan büyük olması zorunlu tutuldu.
- Description opsiyonel bırakıldı.
- Null Description kabul edildi.
- Boş veya yalnızca whitespace olan Description değerleri null olarak normalize edildi.
- Dolu Description değerleri trim edilerek saklandı.
- CreatedAt UTC olarak oluşturuldu.
- Income listesi yalnızca authenticated kullanıcının kayıtlarını döndürdü.
- Income silme sorgusu Id + authenticated UserId ile filtrelendi.
- Başka kullanıcıya ait veya bulunmayan kayıt için aynı güvenli 404 yaklaşımı kullanıldı.
- Entity doğrudan API response olarak kullanılmadı.
- Generic Repository, Unit of Work, CQRS veya MediatR eklenmedi.

### Endpointler

- `GET /api/incomes`
- `POST /api/incomes`
- `DELETE /api/incomes/{id}`

### İnsan Tarafından Yapılan Kontrol

AI sonuç raporu incelendi.

Aşağıdaki noktaların proje kararlarıyla uyumlu olduğu doğrulandı:

- UserId'nin request'ten alınmaması,
- mevcut CurrentUserAccessor yapısının kullanılması,
- Description alanının opsiyonel olması,
- ownership sorgularının authenticated UserId ile yapılması,
- başka kullanıcı kayıtlarında güvenli 404 davranışı,
- Income update/detail endpointlerinin eklenmemesi,
- sonraki Budget, Bill, Dashboard ve AI özelliklerine geçilmemesi.

Bu aşamada kritik bir hata tespit edilmediği için ek revizyon promptu oluşturulmadı.

### Test Sonucu

Income için 15 yeni test eklendi.

Toplam test sonucu:

- Toplam test: 43
- Başarılı: 43
- Başarısız: 0
- Atlanan: 0

Mevcut testler:

- Authentication/JWT: 10/10 başarılı
- Category/Expense: 18/18 başarılı
- Income: 15/15 başarılı

Build sonucu:

- 0 hata
- 0 uyarı

### İnsan Tarafından Sonraya Bırakılan Kontroller

- Gerçek PostgreSQL üzerinde endpoint integration testi,
- Income Description maksimum uzunluğu,
- ileri tarihli Income kayıtlarının kabul politikası,
- mobil istemcinin Problem Details hata sözleşmesiyle uyumu.

### Sonuç

Income backend özelliği insan kontrolünden geçirilerek kabul edildi.

Bir sonraki geliştirme aşamasında authenticated kullanıcı sahipliği korunarak
Budget özelliğine geçilecektir.




## AI-LOG-007 — Budget Geliştirmesi

**Tarih:** 16.08.2026  
**Kullanılan AI:** Codex  
**Kullanılan Prompt:** `prompts/09_budget.txt`

### Amaç

SmartBudget AI backend'inde kategori bazlı aylık bütçe oluşturma,
listeleme, güncelleme ve silme özellikleri ile bütçe kullanım hesaplarını geliştirmek.

### AI Ne Yaptı?

AI mevcut Authentication/JWT, Category, Expense ve Income yapılarını koruyarak:

- Budget DTO'larını,
- BudgetService'i,
- BudgetsController'ı,
- duplicate Budget kontrolünü,
- ownership sorgularını,
- SpentAmount ve UsagePercent hesaplarını,
- Budget AlertStatus kurallarını,
- Budget testlerini

oluşturdu.

### Uygulanan İş ve Güvenlik Kuralları

- Request DTO'larında UserId bulunmadı.
- Authenticated kullanıcı kimliği JWT üzerinden alındı.
- LimitAmount değerinin sıfırdan büyük olması zorunlu tutuldu.
- Month değeri 1–12 aralığında doğrulandı.
- CategoryId backend tarafından doğrulandı.
- Aynı UserId + CategoryId + Month + Year için ikinci Budget oluşturulması engellendi.
- Database unique constraint korunarak PostgreSQL unique ihlali kontrollü 409 Conflict davranışına çevrildi.
- Liste yalnızca authenticated kullanıcının Budget kayıtlarını döndürdü.
- Update ve delete sorguları Id + authenticated UserId ile yapıldı.
- Update işleminde yalnızca LimitAmount değiştirilebildi.
- CategoryId, Month ve Year update işleminde değiştirilemedi.
- Başka kullanıcıya ait veya bulunmayan Budget için aynı güvenli 404 yaklaşımı kullanıldı.
- Finansal hesaplamalar yalnızca backend tarafından yapıldı.

### Budget Hesaplama Kuralları

SpentAmount yalnızca:

- aynı authenticated kullanıcı,
- aynı kategori,
- aynı ay,
- aynı yıl

içindeki Expense kayıtlarından hesaplandı.

UsagePercent:

`SpentAmount / LimitAmount * 100`

formülüyle backend tarafından hesaplandı.

Kullanım yüzdesi %100'ü aşarsa gerçek oran korunmaktadır.

AlertStatus:

- %80 altı → Normal
- %80 veya üzeri, %100 altı → Warning
- %100 veya üzeri → Exceeded

Tam %80 Warning ve tam %100 Exceeded olarak uygulanmıştır.

### Endpointler

- `GET /api/budgets`
- `POST /api/budgets`
- `PUT /api/budgets/{id}`
- `DELETE /api/budgets/{id}`

### İnsan Tarafından Yapılan Kontrol

AI sonuç raporu incelendi.

Aşağıdaki noktaların proje kararlarıyla uyumlu olduğu doğrulandı:

- UserId'nin request'ten alınmaması,
- CategoryId'nin backend tarafından doğrulanması,
- duplicate Budget kontrolünün hem uygulama hem database seviyesinde korunması,
- ownership sorgularının Id + authenticated UserId ile yapılması,
- update işleminde yalnızca LimitAmount'ın değiştirilebilmesi,
- SpentAmount hesabına başka kullanıcı, kategori veya dönem giderlerinin karışmaması,
- %80 ve %100 eşiklerinin doğru uygulanması,
- kullanım yüzdesinin %100 ile sınırlandırılmaması,
- finansal hesapların Flutter veya AI tarafına taşınmaması.

### İnsan Tarafından Alınan Ek Karar

Source-of-truth dokümanlarında Budget Year için kesin bir aralık belirtilmemişti.

AI tarafından kullanılan 2000–2100 aralığı MVP için uygun bulunarak insan tarafından kabul edildi.

Bu nedenle ek revizyon promptu oluşturulmadı.

### Test Sonucu

Budget için 33 yeni test eklendi.

Toplam test sonucu:

- Toplam test: 76
- Başarılı: 76
- Başarısız: 0
- Atlanan: 0

Mevcut testler:

- Authentication: 10/10
- Category/Expense: 18/18
- Income: 15/15
- Budget: 33/33

Build sonucu:

- 0 hata
- 0 uyarı

### İnsan Tarafından Sonraya Bırakılan Kontroller

- Gerçek PostgreSQL üzerinde DateOnly Month/Year sorgularının doğrulanması,
- eşzamanlı duplicate Budget işleminde PostgreSQL 23505 → 409 davranışının entegrasyon testi,
- UsagePercent değerinin mobil arayüzde kaç ondalık basamakla gösterileceği.

### Sonuç

Budget backend özelliği insan kontrolünden geçirilerek kabul edildi.

Bir sonraki geliştirme aşamasında authenticated kullanıcı sahipliği korunarak
Bill ve tüketim trendi özelliğine geçilecektir.




## AI-LOG-008 — Bill ve Tüketim Trendi Geliştirmesi

**Tarih:** 16.08.2026  
**Kullanılan AI:** Codex  
**Kullanılan Prompt:** `prompts/10_bill.txt`

### Amaç

SmartBudget AI backend'inde elektrik, su ve doğalgaz faturalarının
oluşturulması, listelenmesi, silinmesi ve son 6 aylık fatura/tüketim
trendlerinin hesaplanması özelliklerini geliştirmek.

### AI Ne Yaptı?

AI mevcut Authentication/JWT, Category, Expense, Income ve Budget yapılarını koruyarak:

- Bill DTO'larını,
- BillService'i,
- BillsController'ı,
- BillType doğrulamasını,
- ConsumptionUnit türetme yaklaşımını,
- ownership sorgularını,
- son 6 aylık trend hesaplarını,
- null ConsumptionValue davranışını,
- Bill ve trend testlerini

oluşturdu.

### Uygulanan İş ve Güvenlik Kuralları

- Request DTO'sunda UserId bulunmadı.
- UserId mevcut CurrentUserAccessor ile JWT claim'inden alındı.
- BillType yalnızca Electricity, Water ve NaturalGas değerlerini kabul etti.
- Amount değerinin sıfırdan büyük olması zorunlu tutuldu.
- ConsumptionValue opsiyonel bırakıldı.
- ConsumptionValue verilmişse sıfırdan büyük olması zorunlu tutuldu.
- BillingDate tarih-only olarak kullanıldı.
- CreatedAt UTC oluşturuldu.
- Kullanıcı yalnızca kendi Bill kayıtlarını görebildi ve silebildi.
- Delete sorgusu Id + authenticated UserId ile yapıldı.
- Başka kullanıcıya ait veya bulunmayan Bill için aynı güvenli 404 yaklaşımı kullanıldı.
- Entity doğrudan API response olarak kullanılmadı.

### ConsumptionUnit Kararı

ConsumptionUnit veritabanında ayrı alan olarak tutulmadı.

BillType üzerinden türetildi:

- Electricity → kWh
- Water → m³
- NaturalGas → m³

### Trend Hesaplama Kuralları

Trend mevcut ay dahil son 6 ayı kapsayacak şekilde backend tarafından hesaplandı.

Europe/Istanbul zaman dilimi kullanıldı.

Her ay ve her BillType için ayrı trend noktası üretildi.

Bu nedenle varsayılan response:

6 ay × 3 BillType = 18 trend noktası

şeklinde deterministik tutuldu.

Her nokta:

- Year
- Month
- BillType
- TotalAmount
- TotalConsumption
- ConsumptionUnit

bilgilerini içerdi.

### Null ConsumptionValue Davranışı

ConsumptionValue null olan faturalar:

- TotalAmount hesabına dahil edildi.
- TotalConsumption hesabında sahte 0 tüketim olarak değerlendirilmedi.

Bir ay ve BillType için hiç tüketim değeri yoksa:

`TotalConsumption = null`

olarak tutuldu.

Farklı BillType tüketimleri birbirine karıştırılmadı.

### Endpointler

- `GET /api/bills`
- `GET /api/bills/trends`
- `POST /api/bills`
- `DELETE /api/bills/{id}`

### İnsan Tarafından Yapılan Kontrol

AI sonuç raporu incelendi.

Aşağıdaki noktaların proje kararlarıyla uyumlu olduğu doğrulandı:

- UserId'nin request'ten alınmaması,
- ownership sorgularının authenticated UserId ile yapılması,
- ConsumptionUnit'in database alanı yapılmaması,
- null ConsumptionValue değerlerinin sahte 0 tüketim olarak kullanılmaması,
- farklı BillType tüketimlerinin birbirine karıştırılmaması,
- son 6 aylık dönemin Europe/Istanbul üzerinden hesaplanması,
- finansal/trend hesaplarının Flutter veya AI tarafına taşınmaması,
- Bill update/detail endpointlerinin eklenmemesi.

### İnsan Tarafından Alınan Ek Karar

Trend endpointinin her ay ve üç BillType için ayrı nokta üretmesi sonucu
6 ay için toplam 18 noktalı response yapısı MVP açısından uygun bulundu.

Bu nedenle ek revizyon promptu oluşturulmadı.

### Test Sonucu

Bill ve trend özellikleri için 30 yeni test eklendi.

Toplam test sonucu:

- Toplam test: 106
- Başarılı: 106
- Başarısız: 0
- Atlanan: 0

Mevcut testler:

- Authentication: 10/10
- Category/Expense: 18/18
- Income: 15/15
- Budget: 33/33
- Bill/Trend: 30/30

Build sonucu:

- 0 hata
- 0 uyarı

### İnsan Tarafından Sonraya Bırakılan Kontroller

- Gerçek PostgreSQL üzerinde DateOnly Year/Month group-by sorgusunun doğrulanması,
- deployment ortamında Europe/Istanbul time-zone verisinin mevcut olması,
- ConsumptionValue için PostgreSQL numeric hassasiyetinin kesinleştirilmesi,
- Flutter tarafının BillType string enum sözleşmesiyle uyumu.

### Sonuç

Bill ve tüketim trendi backend özellikleri insan kontrolünden geçirilerek kabul edildi.

Bir sonraki geliştirme aşamasında Dashboard ve aylık finansal özet özelliğine geçilecektir.




## AI-LOG-009 — Dashboard ve Aylık Finansal Özet Geliştirmesi

**Tarih:** 16.08.2026  
**Kullanılan AI:** Codex  
**Kullanılan Prompt:** `prompts/11_dashboard.txt`

### Amaç

SmartBudget AI backend'inde kullanıcının seçilen aya ait finansal durumunu
tek bir endpoint üzerinden gösterecek Dashboard ve aylık finansal özet
özelliklerini geliştirmek.

### AI Ne Yaptı?

AI mevcut Authentication/JWT, Category, Expense, Income, Budget ve Bill yapılarını koruyarak:

- Dashboard DTO'larını,
- DashboardService'i,
- DashboardController'ı,
- aylık gelir/gider hesaplarını,
- bakiye hesabını,
- kategori bazlı harcama özetlerini,
- bütçe kullanım özetlerini,
- önceki ay karşılaştırmasını,
- en yüksek harcama kategorisini,
- en fazla artış gösteren kategoriyi,
- son 6 aylık finansal trendi,
- Dashboard testlerini

oluşturdu.

### Uygulanan Finansal Kurallar

Dashboard hesaplamalarının tamamı backend tarafından yapıldı.

- TotalIncome yalnızca authenticated kullanıcının seçilen ay gelirlerinden hesaplandı.
- TotalExpense yalnızca authenticated kullanıcının seçilen ay giderlerinden hesaplandı.
- Balance = TotalIncome - TotalExpense olarak hesaplandı.
- Negatif bakiye desteklendi.
- CategoryExpenses kategori bazında backend tarafından gruplandı.
- Kategori yüzdeleri backend tarafından hesaplandı.
- TotalExpense 0 olduğunda sıfıra bölme engellendi.
- Budget kullanım hesapları mevcut Budget kurallarıyla ortaklaştırıldı.

Budget eşikleri:

- %80 altı → Normal
- %80 veya üzeri ve %100 altı → Warning
- %100 veya üzeri → Exceeded

%100 üzerindeki gerçek kullanım oranı korunmaktadır.

### Önceki Ay Karşılaştırması

PreviousMonthExpenseChangePercent:

- Önceki ay gideri > 0 ise standart yüzde değişimi hesaplanır.
- Önceki ve mevcut ay gideri 0 ise sonuç 0 olur.
- Önceki ay gideri 0 ve mevcut ay gideri > 0 ise yanıltıcı/sonsuz yüzde üretilmez ve sonuç null olur.
- Ocak ayı için önceki yılın Aralık ayı doğru şekilde kullanılır.

### En Yüksek Harcama Kategorisi

Seçilen ayda en fazla harcama yapılan kategori backend tarafından belirlenir.

Veri yoksa sonuç null olur.

Eşitlik durumunda deterministik sıralama uygulanır.

### En Fazla Artış Gösteren Kategori

Kategori artışı:

`CurrentMonthAmount - PreviousMonthAmount`

formülüyle mutlak tutar üzerinden hesaplanır.

- Eksik ay değeri 0 kabul edilir.
- Yalnızca pozitif artışlar aday olur.
- Pozitif artış yoksa sonuç null olur.
- Başka kullanıcı verileri hesaba katılmaz.
- Eşitlik deterministik biçimde çözülür.

### Son 6 Aylık Trend

Seçilen rapor ayı dahil son 6 ay için:

- Year
- Month
- TotalIncome
- TotalExpense
- Balance

bilgileri oluşturulur.

- Tam 6 nokta döndürülür.
- Veri bulunmayan aylar 0 değerleriyle temsil edilir.
- Seri en eski aydan en yeni aya kronolojik sıralanır.
- Yıl geçişleri desteklenir.

Bill tüketim trendi Dashboard içine taşınmadı ve ayrı endpoint olarak korunmuştur.

### Endpoint

- `GET /api/dashboard/monthly`
- `GET /api/dashboard/monthly?year=2026&month=8`

Year ve Month birlikte verilmek zorundadır.

Parametre verilmezse Europe/Istanbul zaman dilimine göre mevcut ay kullanılır.

MVP için daha önce insan tarafından kabul edilen 2000–2100 yıl aralığı korunmuştur.

### Ownership ve Güvenlik

- Request üzerinden UserId alınmadı.
- Authenticated UserId mevcut JWT/CurrentUserAccessor yapısından alındı.
- Income, Expense, Budget ve trend sorgularının tamamı kullanıcı bazında filtrelendi.
- Başka kullanıcı verilerinin Dashboard sonuçlarına karışması engellendi.
- Dashboard hesabı Controller, Flutter veya AI tarafına taşınmadı.
- AI bu aşamada kullanılmadı.

### İnsan Tarafından Yapılan Kontrol

AI sonuç raporu incelendi.

Aşağıdaki noktaların proje kararlarıyla uyumlu olduğu doğrulandı:

- finansal hesapların backend'de yapılması,
- Europe/Istanbul varsayılan ay yaklaşımı,
- önceki ay gideri 0 olduğunda yanıltıcı yüzde üretilmemesi,
- yıl geçişlerinin desteklenmesi,
- HighestIncreaseCategory hesabının mutlak artış üzerinden yapılması,
- son 6 aylık trendin tam ve kronolojik olması,
- kullanıcı veri izolasyonunun tüm sorgularda korunması,
- AI veya Flutter tarafına finansal hesap taşınmaması.

Bu aşamada kritik hata tespit edilmediği için ek revizyon promptu oluşturulmadı.

### Test Sonucu

Dashboard için 30 yeni test eklendi.

Toplam test sonucu:

- Toplam test: 136
- Başarılı: 136
- Başarısız: 0
- Atlanan: 0

Mevcut testler:

- Authentication: 10/10
- Category/Expense: 18/18
- Income: 15/15
- Budget: 33/33
- Bill/Trend: 30/30
- Dashboard: 30/30

Build sonucu:

- 0 hata
- 0 uyarı

### İnsan Tarafından Sonraya Bırakılan Kontroller

- Gerçek PostgreSQL üzerinde DateOnly/group-by/aggregate entegrasyon testleri,
- yüzde değerlerinin mobil arayüzde gösterim hassasiyeti,
- Dashboard DTO alan adlarının Flutter sözleşmesiyle doğrulanması,
- production ortamında Europe/Istanbul time-zone desteği,
- veri büyüdüğünde composite index ihtiyacının performans ölçümü.

### Sonuç

Dashboard ve aylık finansal özet backend özelliği insan kontrolünden geçirilerek kabul edildi.

Bir sonraki geliştirme aşamasında AI destekli gider kategorileme özelliğine geçilecektir.




## AI-LOG-010 — AI Destekli Gider Kategorileme

**Tarih:** 16.08.2026  
**Kullanılan AI:** Codex  
**Kullanılan Prompt:** `prompts/12_ai_expense_categorization.txt`

### Amaç

SmartBudget AI backend'inde kullanıcının gider açıklamasından hareketle
tanımlı kategorilerden birini öneren kontrollü AI kategorileme özelliğini geliştirmek.

### AI Ne Yaptı?

AI mevcut backend mimarisini koruyarak:

- CategorizeExpenseRequest ve CategorizeExpenseResponse DTO'larını,
- AI configuration yapısını,
- OpenAI kategorileme client'ını,
- AiCategorizationService'i,
- AiController'ı,
- JSON response doğrulamasını,
- category whitelist kontrolünü,
- Category name → CategoryId eşlemesini,
- confidence doğrulamasını,
- timeout ve fallback davranışlarını,
- prompt injection kontrollerini,
- AI kategorileme testlerini

oluşturdu.

### AI Kullanım Sınırı

AI yalnızca gider kategorisi önerisi üretmektedir.

AI:

- Expense kaydı oluşturmaz,
- Category kaydı oluşturmaz,
- CategoryId üretmez,
- kullanıcı adına otomatik kategori seçmez,
- authorization kararı vermez,
- finansal hesaplama yapmaz.

AI kategorileme endpointi Expense oluşturma akışından ayrı tutulmuştur.

### İzinli Kategoriler

AI çıktısı yalnızca aşağıdaki whitelist üzerinden kabul edilmektedir:

- Market
- Ulaşım
- Fatura
- Eğlence
- Sağlık
- Eğitim
- Kira
- Diğer

Whitelist dışındaki sonuçlar reddedilerek manuel kategori fallback'i uygulanmaktadır.

### CategoryId Eşleme Yaklaşımı

AI yalnızca kategori adı üretmektedir.

CategoryId:

- AI tarafından üretilmez,
- AI response içinden alınmaz,
- doğrulanmış kategori adına karşılık gelen database seed kaydından backend tarafından bulunur.

Seed kategori bulunamazsa AI önerisi kabul edilmez.

### Confidence Davranışı

İnsan tarafından daha önce alınan karar korunmuştur:

Confidence için zorunlu kabul eşiği yoktur.

Geçerli JSON ve whitelist içerisinde geçerli kategori varsa kategori önerisi korunur.

Confidence:

- düşük,
- eksik,
- null,
- geçersiz tipte,
- 0–1 aralığı dışında

olursa geçersiz kabul edilerek null yapılabilir; ancak kategori yalnızca confidence nedeniyle reddedilmez.

### Fallback Davranışı

Aşağıdaki durumlarda kontrollü manuel seçim fallback'i uygulanmaktadır:

- AI timeout,
- bağlantı hatası,
- HTTP servis hatası,
- eksik configuration,
- boş response,
- geçersiz JSON,
- eksik category,
- whitelist dışı category,
- beklenmeyen provider veya deserialize hatası.

Fallback sonucu semantik olarak:

- Success = false
- Category = null
- CategoryId = null
- Confidence = null
- RequiresManualSelection = true

şeklindedir.

AI hatası temel Expense özelliğinin çalışmasını engellemez.

### Prompt Injection ve AI Güvenliği

AI çıktısı güvenilir kabul edilmemektedir.

Uygulanan kontroller:

- sistem talimatları kullanıcı açıklamasından ayrıldı,
- gider açıklaması güvenilmeyen kullanıcı verisi olarak işaretlendi,
- structured JSON schema kullanıldı,
- schema kategori enum'u ile sınırlandı,
- backend tarafında tekrar whitelist doğrulaması yapıldı,
- CategoryId database üzerinden türetildi.

Kullanıcı açıklamasındaki AI talimatlarının uygulama sistem kurallarını değiştirmesine izin verilmemektedir.

### Secret Yönetimi

OpenAI API key source code veya appsettings dosyasına yazılmadı.

Development ortamında user-secrets, production ortamında environment variable veya güvenli secret store kullanılacak şekilde yapılandırıldı.

### Endpoint

- `POST /api/ai/categorize-expense`

Endpoint authentication gerektirir.

Geçerli öneride kontrollü DTO,
AI servis hatasında ise manuel seçimi mümkün kılan kontrollü fallback DTO dönmektedir.

### İnsan Tarafından Yapılan Kontrol

AI sonuç raporu incelendi.

Aşağıdaki noktaların proje kararlarıyla uyumlu olduğu doğrulandı:

- AI endpointinin Expense kaydı oluşturmaması,
- AI'ın yeni kategori oluşturmaması,
- CategoryId'nin AI'dan alınmaması,
- whitelist kontrolünün backend'de yapılması,
- confidence threshold eklenmemesi,
- geçersiz confidence'ın geçerli kategoriyi tek başına reddettirmemesi,
- AI hatalarının manuel kategori akışını bozmaması,
- API key'in repository'ye yazılmaması,
- finansal hesaplamaların AI'a taşınmaması.

Bu aşamada kritik hata tespit edilmediği için ek revizyon promptu oluşturulmadı.

### Test Sonucu

AI kategorileme için 32 yeni test eklendi.

Toplam test sonucu:

- Toplam test: 168
- Başarılı: 168
- Başarısız: 0
- Atlanan: 0

Mevcut test gruplarının tamamı başarılı olmaya devam etti.

### İnsan Tarafından Sonraya Bırakılan Kontroller

- Gerçek OpenAI API key ile development smoke testi,
- kullanılan modelin proje hesabında erişilebilirliğinin doğrulanması,
- production timeout değerinin belirlenmesi,
- API kullanım maliyeti ve rate-limit yaklaşımı,
- Flutter'ın Success / RequiresManualSelection sözleşmesiyle uyumu,
- production telemetry/log sisteminin prompt veya raw AI response saklamadığının doğrulanması.

### Sonuç

AI destekli gider kategorileme özelliği insan kontrolünden geçirilerek kabul edildi.

Bir sonraki geliştirme aşamasında backend tarafından önceden hesaplanan aylık finansal
verileri yorumlayan AI aylık analiz özelliğine geçilecektir.




## AI-LOG-011 — AI Destekli Aylık Finansal Analiz ve İnsan Revizyonu

**Tarih:** 16.08.2026  
**Kullanılan AI:** Codex  
**İlk Prompt:** `prompts/13_ai_monthly_analysis.txt`  
**Revizyon Promptu:** `prompts/14_ai_monthly_analysis_revizyon.txt`

### Amaç

SmartBudget AI backend'inde DashboardService tarafından deterministik olarak
hesaplanmış aylık finansal verileri AI ile kısa ve kontrollü biçimde yorumlamak.

AI'ın finansal hesapların doğruluk kaynağı olmaması ve yalnızca backend tarafından
hesaplanan değerleri yorumlaması hedeflendi.

### İlk AI Uygulaması

AI:

- MonthlyAnalysis DTO'larını,
- aylık analiz client ve service yapısını,
- OpenAI Responses API entegrasyonunu,
- DashboardService entegrasyonunu,
- structured output doğrulamasını,
- empty-data fallback davranışını,
- yatırım tavsiyesi kontrollerini,
- aylık analiz testlerini

oluşturdu.

Finansal verilerin tek doğruluk kaynağı DashboardService olarak korundu.

AI'a ham transaction kayıtları yerine yalnızca hesaplanmış finansal özet gönderildi.

### Veri Minimizasyonu

AI'a gönderilen veriler:

- Year / Month
- TotalIncome
- TotalExpense
- Balance
- kategori bazlı hesaplanmış gider özetleri
- bütçe kullanım özetleri
- PreviousMonthExpenseChangePercent
- HighestSpendingCategory
- HighestIncreaseCategory

AI'a gönderilmeyen veriler:

- UserId
- Email
- JWT
- Password veya password hash
- Expense açıklamaları
- ham transaction kayıtları
- entity listeleri
- CategoryId veya finansal Guid değerleri

### Empty-Data Davranışı

Seçilen ayda:

- TotalIncome = 0
- TotalExpense = 0

ise AI çağrısı yapılmamaktadır.

Backend deterministik olarak:

`Bu ay için henüz yeterli finansal veri bulunmuyor.`

mesajını üretmektedir.

Bu davranış AI'ın boş finansal veriden yorum veya rakam uydurmasını engellemektedir.

### İnsan Tarafından Tespit Edilen Problem

İlk AI implementasyonunda Analysis metni şu kontrolle doğrulanıyordu:

`analysis.Any(char.IsDigit)`

Bu nedenle AI yorumunda herhangi bir 0–9 karakteri bulunması response'un tamamen
reddedilmesine neden oluyordu.

İnsan incelemesinde bu yaklaşımın fazla katı olduğu tespit edildi.

Backend zaten:

- toplam gelir,
- toplam gider,
- bakiye,
- kategori tutarları,
- bütçe kullanım oranları,
- önceki ay değişimi

gibi finansal değerleri güvenilir ve deterministik biçimde hesaplamaktadır.

Dolayısıyla AI'ın kendisine backend tarafından verilen bir değeri yorum metninde
kullanmasının tek başına güvenlik ihlali olmadığına karar verildi.

### İnsan Tarafından Verilen Revizyon

Bu sorun için:

`prompts/14_ai_monthly_analysis_revizyon.txt`

hazırlandı ve Codex'e verildi.

Amaç:

`AI hiçbir rakam yazamaz`

yaklaşımını:

`AI yalnızca backend tarafından sağlanan finansal değerleri kullanabilir`

yaklaşımına dönüştürmekti.

### Revizyon Sonrası Numeric Validation

Genel rakam yasağı kaldırıldı.

Bunun yerine Dashboard sonucundaki güvenilir finansal değerlerden kontrollü bir
`allowedNumbers` kümesi oluşturuldu.

Kümeye dahil edilen değerler:

- TotalIncome
- TotalExpense
- Balance
- kategori Amount değerleri
- kategori yüzdeleri
- Budget LimitAmount
- Budget SpentAmount
- Budget UsagePercent
- PreviousMonthExpenseChangePercent
- HighestSpendingCategory tutarı
- HighestIncreaseCategory IncreaseAmount

AI yorumundaki sayısal ifadeler normalize edilerek bu güvenilir değerlerle karşılaştırılmaktadır.

Örneğin aşağıdaki temel gösterimler desteklenmektedir:

- `1500.50`
- `1.500,50`
- `%80`

Backend özetinde bulunan bir değer AI yorumunda kullanılabilir.

Backend özetinde bulunmayan açıkça yeni bir sayı ise kontrollü fallback'e neden olur.

### Finansal Halüsinasyon Kontrolleri

Revizyon sonrası da aşağıdaki kurallar korunmuştur:

- AI yeni finansal değer üretmemelidir.
- AI yeniden finansal hesap yapmamalıdır.
- AI verilen rakamları değiştirmemelidir.
- DashboardService finansal hesapların tek doğruluk kaynağıdır.
- AI response Dashboard hesaplarının yerine kullanılmaz.
- AI response database'e yazılmaz.
- Structured JSON output doğrulaması devam etmektedir.
- Analysis maksimum 1200 karakter olabilir.

### Yatırım Tavsiyesi Sınırı

AI'ın:

- yatırım tavsiyesi,
- hisse önerisi,
- kripto önerisi,
- fon önerisi,
- satın alma yönlendirmesi,
- ödeme veya para transferi talimatı

vermesi yasaklanmıştır.

Mevcut backend kontrolleri revizyon sırasında korunmuştur.

### Database Değişmezliği

AI aylık analiz akışı:

- Expense oluşturmaz veya değiştirmez.
- Income oluşturmaz veya değiştirmez.
- Budget oluşturmaz veya değiştirmez.
- Bill oluşturmaz veya değiştirmez.
- SaveChanges çağrısı yapmaz.
- AI response'u kalıcı olarak saklamaz.

### İnsan Tarafından Yapılan Kontrol

Revizyon sonucu incelendi.

Aşağıdaki noktalar doğrulandı:

- blanket numeric ban kaldırıldı,
- backend tarafından verilen rakamların AI yorumunda kullanılabilmesi sağlandı,
- AI'ın yeni sayı üretmesine karşı doğrulama korundu,
- DashboardService değiştirilmedi,
- empty-data davranışı korunmaya devam etti,
- yatırım tavsiyesi kontrolleri korunmaya devam etti,
- veri minimizasyonu korunmaya devam etti,
- endpoint sözleşmesi değiştirilmedi,
- database write işlemi eklenmedi.

### Test Sonucu

Revizyon sonrası AI Monthly Analysis test sayısı:

- 31/31 başarılı

Toplam proje test sonucu:

- Toplam: 199
- Başarılı: 199
- Başarısız: 0
- Atlanan: 0

Diğer test grupları:

- Authentication: 10/10
- Category/Expense: 18/18
- Income: 15/15
- Budget: 33/33
- Bill/Trend: 30/30
- Dashboard: 30/30
- AI Categorization: 32/32
- AI Monthly Analysis: 31/31

Build sonucu:

- 0 hata
- 0 uyarı

### İnsan Tarafından Kabul Edilen Sınırlamalar

Numeric validation sade ve kontrollü tutuldu.

Bilinen sınırlamalar:

- `1.000` gibi tek ayraçlı ifadeler bağlama göre ondalık veya binlik olarak yorumlanabilir.
- Sayıların yazıyla ifade edilmesi doğal dil seviyesinde doğrulanmamaktadır.
- Decimal karşılaştırmaları birebir yapılmaktadır.
- AI tarafından yapılan yaklaşık yuvarlamalar otomatik kabul edilmemektedir.

Bu sınırlamalar MVP kapsamında kabul edilmiştir.

### Sonuç

AI aylık analiz özelliği ilk AI çıktısından sonra insan tarafından incelendi.

Aşırı katı numeric validation yaklaşımı insan tarafından tespit edilerek ayrı bir revizyon
promptuyla düzelttirildi.

Revizyon sonrası özellik proje mimarisi, güvenlik kuralları ve AI sınırlarıyla uyumlu bulunarak kabul edildi.




## AI-LOG-012 — Flutter Mobil Temel Kurulum

**Tarih:** 16.08.2026  
**Kullanılan AI:** Codex  
**Kullanılan Prompt:** `prompts/18_flutter_base_setup.txt`

### Amaç

SmartBudget AI mobil uygulamasının Flutter tabanlı temel yapısını oluşturmak.

Bu aşamada gerçek finansal özelliklerin tamamını geliştirmek yerine:

- authentication,
- API iletişimi,
- JWT secure storage,
- session yönetimi,
- theme/design system,
- navigation,
- temel ekran iskeletleri

hazırlanmıştır.

### AI Ne Yaptı?

AI:

- Flutter Android/iOS proje iskeletini,
- merkezi API configuration yapısını,
- ApiClient'i,
- SecureStorageService'i,
- AuthService'i,
- Login ve Register ekranlarını,
- authenticated MainShell yapısını,
- bottom navigation'ı,
- merkezi theme'i,
- reusable temel widget'ları,
- Dashboard / Transactions / Budgets / Bills placeholder ekranlarını,
- minimal Profile ekranını,
- Flutter testlerini

oluşturdu.

### Kullanılan Paketler

- `http 1.6.0`
- `flutter_secure_storage 10.3.1`
- `flutter_lints 6.0.0`

Gereksiz state-management, navigation, chart veya architecture framework paketleri eklenmedi.

### API Configuration

Backend base URL merkezi `ApiConfig` üzerinden yönetilmektedir.

Android emulator development varsayılanı:

`http://10.0.2.2:5259`

Farklı ortamlar için:

`--dart-define=API_BASE_URL=...`

yaklaşımı desteklenmiştir.

Production URL uydurulmamıştır.

### API Client

Merkezi ApiClient:

- GET
- POST
- PUT
- DELETE
- JSON encode/decode
- Bearer token
- timeout
- network error
- HTTP hata durumları

için ortak davranış sağlamaktadır.

Token, password, stack trace ve ham backend hata çıktıları loglanmamaktadır.

### JWT ve Secure Storage

JWT yalnızca `flutter_secure_storage` içerisinde tutulmaktadır.

Desteklenen işlemler:

- saveToken
- readToken
- deleteToken

Authenticated kullanıcının email bilgisi de profil gösterimi için saklanabilmektedir.

Password hiçbir local storage alanına yazılmamaktadır.

### Authentication Akışı

Login ekranı:

- email doğrulama,
- email trim,
- password kontrolü,
- loading,
- double-submit engeli,
- backend login çağrısı

davranışlarını içermektedir.

Başarılı login sonrasında JWT secure storage'a kaydedilip authenticated shell açılmaktadır.

Register ekranı:

- email validation,
- minimum 8 karakter password,
- password confirmation

kontrollerini içermektedir.

Password confirmation backend'e gönderilmemektedir.

Backend register işleminden sonra token döndürmediği için kullanıcı otomatik authenticated kabul edilmemekte ve Login ekranına yönlendirilmektedir.

### Startup ve Session Yönetimi

Uygulama başlangıcında secure storage içerisindeki JWT kontrol edilir.

- Token yok → Login
- Token var → Authenticated MainShell

Refresh token eklenmemiştir.

Token'ın gerçek geçerliliği backend'in 401 cevabıyla doğrulanmaktadır.

### Merkezi 401 Davranışı

Korunan endpointlerden 401 geldiğinde:

- JWT silinir,
- authenticated email temizlenir,
- auth state sıfırlanır,
- kullanıcı Login ekranına yönlendirilir.

Kullanıcıya teknik olmayan:

`Oturumunuz sona erdi. Lütfen tekrar giriş yapın.`

benzeri mesaj gösterilmektedir.

Login endpointindeki hatalı kullanıcı bilgisi kaynaklı 401 ile session-expired davranışı birbirinden ayrılmıştır.

### Design System

`docs/DESIGN.md` tasarım referansı kullanılmıştır.

Flutter theme içerisinde:

- `#000666` primary,
- açık background,
- white surface,
- success,
- warning,
- error,
- input,
- button,
- card,
- navigation,
- typography

kuralları merkezileştirilmiştir.

Stitch yalnızca görsel referans olarak kullanılmış; backend'de olmayan Stitch özellikleri mobil uygulamaya taşınmamıştır.

### Navigation

Authenticated uygulama beş ana sekmeden oluşmaktadır:

1. Ana Sayfa
2. İşlemler
3. Bütçeler
4. Faturalar
5. Profil

Üçüncü parti navigation framework kullanılmamıştır.

### Profil

MVP sınırlarına uygun olarak profil ekranında yalnızca:

- authenticated email,
- Çıkış Yap

bulunmaktadır.

İsim, premium/pro üyelik, hesap ayarları veya backend'de olmayan profil özellikleri eklenmemiştir.

### Güvenlik Kontrolleri

- JWT secure storage dışında tutulmamaktadır.
- Password saklanmamaktadır.
- OpenAI API key Flutter'a eklenmemiştir.
- Flutter doğrudan OpenAI'a bağlanmamaktadır.
- UserId ownership amacıyla client tarafından gönderilmemektedir.
- Token loglanmamaktadır.
- Logout sonrasında authenticated ekranlara geri dönüş engellenmektedir.

### İnsan Tarafından Yapılan Kontrol

AI sonuç raporu incelendi.

Aşağıdaki noktaların source-of-truth kararlarıyla uyumlu olduğu doğrulandı:

- Flutter + Dart kullanılması,
- authentication'ın backend JWT yapısıyla uyumlu olması,
- JWT'nin secure storage'da tutulması,
- Google/Apple login eklenmemesi,
- refresh token eklenmemesi,
- backend'de olmayan Stitch özelliklerinin uygulanmaması,
- profil ekranının MVP seviyesinde tutulması,
- OpenAI API anahtarının mobile taşınmaması,
- henüz gerçek finansal API entegrasyonlarının yapılmaması.

Bu aşamada kritik hata tespit edilmediği için revizyon promptu oluşturulmadı.

### Test ve Build Sonucu

Flutter testleri:

- Toplam: 12
- Başarılı: 12
- Başarısız: 0

`flutter analyze`:

- No issues found

Android debug APK:

- Başarılı üretildi.

### Bilerek Sonraya Bırakılanlar

Bu aşamada:

- Dashboard API entegrasyonu,
- Expense API entegrasyonu,
- Income API entegrasyonu,
- Budget API entegrasyonu,
- Bill API entegrasyonu,
- grafikler,
- AI gider kategorileme UI entegrasyonu,
- AI aylık analiz UI entegrasyonu

geliştirilmedi.

### İnsan Tarafından Sonraya Bırakılan Kontroller

- gerçek cihaz için local network API adresi,
- production HTTPS URL,
- iOS build/signing,
- nihai uygulama ikonları,
- Flutter SDK'nın kalıcı development ortamına taşınması.

### Sonuç

SmartBudget AI Flutter mobil uygulamasının temel mimarisi, authentication sistemi,
API iletişim altyapısı, güvenli token saklama yaklaşımı ve tasarım sistemi oluşturularak
insan kontrolünden geçirilmiş ve kabul edilmiştir.




## AI-LOG-013 — Flutter Dashboard Entegrasyonu

**Tarih:** 16.08.2026  
**Kullanılan AI:** Codex  
**Kullanılan Prompt:** `prompts/19_flutter_dashboard.txt`

### Amaç

SmartBudget AI Flutter uygulamasındaki Dashboard ekranını gerçek backend
Dashboard ve AI Monthly Summary endpointleriyle entegre etmek.

### AI Ne Yaptı?

AI:

- Dashboard mobil modellerini,
- DashboardService'i,
- ChangeNotifier tabanlı DashboardViewModel'i,
- gerçek Dashboard ekranını,
- finansal summary kartlarını,
- kategori harcama görünümlerini,
- bütçe kullanım kartlarını,
- önceki ay karşılaştırmasını,
- en yüksek harcama ve artış alanlarını,
- son 6 aylık trend görünümünü,
- AI aylık analiz kartını,
- Türkçe para/dönem formatlama yardımcılarını,
- Dashboard testlerini

oluşturdu.

### Backend Tek Doğruluk Kaynağı

Flutter tarafında:

- TotalIncome yeniden hesaplanmadı.
- TotalExpense yeniden hesaplanmadı.
- Balance yeniden hesaplanmadı.
- Budget SpentAmount yeniden hesaplanmadı.
- Budget UsagePercent yeniden hesaplanmadı.
- HighestIncreaseCategory yeniden hesaplanmadı.
- Son 6 aylık finansal değerler yeniden üretilmedi.

Tüm finansal değerler backend Dashboard endpointinden alınarak yalnızca gösterildi.

### Dashboard Endpointleri

Kullanılan endpointler:

- `GET /api/dashboard/monthly`
- `GET /api/dashboard/monthly?year=X&month=Y`

Varsayılan dönem için Flutter tarih hesabı yapmadı.

Europe/Istanbul varsayılan raporlama ayı backend tarafından belirlendi ve response'taki Year/Month UI'da kullanıldı.

### Dönem Seçimi

Kullanıcı farklı dönem seçtiğinde month/year query parametreleri backend'e gönderildi.

Ay için 1–12, yıl için MVP kapsamında 2000–2100 seçenekleri sunuldu.

Nihai validation kaynağı backend olarak bırakıldı.

### Finansal Özet

Dashboard'da backend'den alınan:

- Toplam Gelir
- Toplam Gider
- Bakiye

değerleri gösterilmektedir.

Türkçe para formatlama yalnızca presentation işlemi olarak Flutter'da uygulanmaktadır.

### Kategori Harcamaları

Backend tarafından döndürülen:

- CategoryName
- Amount
- PercentageOfTotalExpense

alanları kullanıldı.

Backend sıralaması korunarak Flutter tarafında yeniden finansal gruplama yapılmadı.

### Budget Kullanımları

Her Budget için backend'den gelen:

- LimitAmount
- SpentAmount
- UsagePercent
- AlertStatus

kullanıldı.

Durumlar UI'da:

- Normal
- Warning → Kritik / Limite Yakın
- Exceeded → Limit Aşıldı

şeklinde görselleştirildi.

UsagePercent %100 üzerinde olduğunda gerçek değer metinde korunmaktadır.

Örneğin `%135` backend tarafından geldiyse UI `%135` göstermektedir.

Yalnızca progress bar görsel genişliği maksimum seviyede sınırlandırılmaktadır.

### Önceki Ay Karşılaştırması

`PreviousMonthExpenseChangePercent` yeniden hesaplanmadı.

UI:

- null,
- sıfır,
- pozitif,
- negatif

durumlarını ayrı ve tarafsız Türkçe metinlerle göstermektedir.

### Kategori Insight Alanları

HighestSpendingCategory ve HighestIncreaseCategory doğrudan backend response'undan kullanılmaktadır.

Flutter tarafında kategori toplamı veya aylık fark hesabı yapılmamaktadır.

### Son 6 Aylık Trend

Backend'in döndürdüğü kronolojik 6 aylık seri kullanıldı.

Yeni chart paketi eklenmedi.

Trend verileri sade ve mobil uyumlu aylık satırlar halinde gösterilmektedir.

### AI Aylık Analiz

Kullanılan endpoint:

- `POST /api/ai/monthly-summary`

AI analizi Dashboard açıldığında otomatik çağrılmamaktadır.

Kullanıcı:

`AI Analizini Oluştur`

aksiyonuna bastığında backend endpointi çağrılır.

Bu karar gereksiz AI çağrısını ve API maliyetini azaltmak amacıyla uygulanmıştır.

Flutter doğrudan OpenAI API'ye bağlanmamaktadır.

### AI Durum Yönetimi

AI loading durumu Dashboard loading durumundan ayrılmıştır.

AI isteği sırasında yalnızca AI kartı loading durumuna geçmektedir.

Double-submit engellenmiştir.

AI başarısız olursa Dashboard finansal verileri görünmeye devam eder.

### Pull-to-Refresh

Dashboard refresh işlemi yalnızca finansal Dashboard verisini yeniden yüklemektedir.

Önceden oluşturulmuş AI analizi otomatik olarak tekrar çağrılmamaktadır.

### Güvenlik

- UserId requestlere eklenmedi.
- JWT merkezi ApiClient tarafından yönetilmeye devam etti.
- OpenAI API key mobile uygulamaya eklenmedi.
- Flutter doğrudan AI provider'a bağlanmadı.
- Merkezi 401/session-expired davranışı korundu.
- Teknik backend exceptionları kullanıcıya gösterilmedi.

### İnsan Tarafından Yapılan Kontrol

AI sonuç raporu incelendi.

Özellikle:

- finansal hesapların Flutter'a taşınmadığı,
- Dashboard'un backend tek doğruluk kaynağını kullandığı,
- %100 üzerindeki bütçe oranlarının değiştirilmediği,
- AI analizinin otomatik her refresh'te çağrılmadığı,
- AI hatasının Dashboard'u bozmadığı,
- UserId'nin client requestlerine eklenmediği

doğrulandı.

Kritik bir hata tespit edilmediği için revizyon promptu oluşturulmadı.

### Test ve Build Sonucu

Flutter test sonucu:

- Toplam: 33
- Başarılı: 33
- Başarısız: 0

Önceki 12 Flutter temel testi geçmeye devam etti.

`flutter analyze`:

- No issues found

Android debug APK:

- Başarıyla oluşturuldu.

### Format Notu

`dart format .` komutu generated `build/flutter_secure_storage/.transforms`
içerisindeki eski Windows yolu nedeniyle hata verdi.

Kaynak kod kapsamı:

`dart format lib test`

ile doğrulandı ve ilgili 37 dosyanın tamamı formatlı bulundu.

Bu durum uygulama kaynak kodunda bir format hatası olarak değerlendirilmedi.

### Sonuç

Flutter Dashboard gerçek backend ile entegre edildi.

Finansal hesapların doğruluk kaynağı backend olarak korunurken Flutter yalnızca
presentation ve kullanıcı etkileşimi sorumluluğunu üstlenmektedir.




## AI-LOG-014 — Flutter İşlemler, Expense/Income ve AI Kategori Entegrasyonu

**Tarih:** 16.08.2026  
**Kullanılan AI:** Codex  
**Kullanılan Prompt:** `prompts/20_flutter_transactions.txt`

### Amaç

SmartBudget AI Flutter uygulamasındaki İşlemler ekranını gerçek backend
Expense, Income, Category ve AI Expense Categorization endpointleriyle entegre etmek.

### AI Ne Yaptı?

AI:

- Category mobil model ve servisini,
- Expense mobil model ve servisini,
- Income mobil model ve servisini,
- AI kategori öneri servisini,
- Transactions ViewModel'ini,
- birleşik işlem listesini,
- gelir/gider filtrelerini,
- Gider Ekle ekranını,
- Gelir Ekle ekranını,
- kategori seçim akışını,
- AI kategori öneri kartını,
- Expense/Income silme akışlarını,
- transaction doğrulama ve formatlama yardımcılarını,
- ilgili Flutter testlerini

oluşturdu.

### Category Yaklaşımı

Kategoriler yalnızca backend:

`GET /api/categories`

endpointinden alınmaktadır.

Mobil uygulama yeni kategori üretmemektedir.

Backend kategori ID ve isimleri source of truth olarak kullanılmıştır.

### Expense Entegrasyonu

Kullanılan endpointler:

- `GET /api/expenses`
- `POST /api/expenses`
- `DELETE /api/expenses/{id}`

Create Expense request yalnızca:

- amount
- description
- categoryId
- date
- isAiCategorized

alanlarını içermektedir.

UserId request içine eklenmemektedir.

### Income Entegrasyonu

Kullanılan endpointler:

- `GET /api/incomes`
- `POST /api/incomes`
- `DELETE /api/incomes/{id}`

Income Description opsiyonel tutulmuştur.

Boş veya whitespace Description mobil request'te null olarak gönderilebilmektedir.

### Birleşik İşlem Listesi

Backend Expense ve Income kayıtlarını ayrı endpointlerden döndürmektedir.

Flutter bu iki listeyi yalnızca presentation amacıyla ortak işlem modeline dönüştürmektedir.

Sıralama:

- Date descending
- CreatedAt descending
- deterministik ID tie-breaker

yaklaşımıyla yapılmıştır.

Bu işlem sırasında:

- toplam gelir,
- toplam gider,
- bakiye

gibi finansal hesaplar yapılmamaktadır.

Finansal Dashboard hesaplarının doğruluk kaynağı backend olmaya devam etmektedir.

### Filtreler

İşlemler ekranında:

- Tümü
- Giderler
- Gelirler

filtreleri uygulanmıştır.

### Gider Ekleme

Gider formunda:

- Tutar
- Açıklama
- Tarih
- Kategori
- AI ile Kategori Öner

alan ve aksiyonları bulunmaktadır.

Kategori backend'den alınan CategoryId üzerinden gönderilmektedir.

### AI Kategori Önerisi

Kullanılan endpoint:

`POST /api/ai/categorize-expense`

Flutter doğrudan OpenAI API'ye bağlanmamaktadır.

AI çağrısı Expense create işleminden tamamen ayrı tutulmuştur.

AI yalnızca kategori önerisi üretmektedir.

### Kullanıcı Onayı

AI sonucu kategoriyi otomatik olarak seçmemektedir.

Kullanıcı:

- `Öneriyi Kullan`
- `Başka Kategori Seç`

aksiyonlarından birini seçmektedir.

AI önerisi ancak kullanıcı `Öneriyi Kullan` dediğinde seçili kategoriye uygulanmaktadır.

### IsAiCategorized Davranışı

Mobil state aşağıdaki kuralları uygulamaktadır:

- AI önerisi kabul edilip aynı kategoriyle kayıt oluşturulursa → `true`
- Manuel kategori seçilirse → `false`
- AI önerisi kabul edildikten sonra kullanıcı kategoriyi değiştirirse → `false`

Bu sayede backend'deki `IsAiCategorized` alanı kullanıcının gerçek son seçimini yansıtmaktadır.

### AI Failure Davranışı

AI başarısız olduğunda Expense formu kapanmamakta veya kullanılamaz hale gelmemektedir.

Kullanıcı manuel kategori seçerek gider kaydetmeye devam edebilmektedir.

AI hatası temel Expense akışını bozmamaktadır.

### Gelir Ekleme

Gelir formunda yalnızca:

- Tutar
- Açıklama (opsiyonel)
- Tarih

bulunmaktadır.

Gelir için kategori veya AI özelliği eklenmemiştir.

### Silme

Expense ve Income kayıtlarında silme öncesi confirmation dialog kullanılmaktadır.

Backend ownership doğrulaması mobil tarafa taşınmamıştır.

Flutter UserId göndermemektedir.

404 durumunda başka kullanıcı sahipliği gibi güvenlik detayları kullanıcıya açıklanmadan:

`Kayıt bulunamadı veya artık mevcut değil.`

benzeri kontrollü davranış uygulanmaktadır.

### Pull-to-Refresh

Refresh işlemi:

- Expense listesini
- Income listesini

yenilemektedir.

Kategori listesi gereksiz yere tekrar yüklenmemekte ve AI çağrısı yapılmamaktadır.

### Güvenlik

- UserId requestlere eklenmemektedir.
- JWT merkezi ApiClient üzerinden gönderilmektedir.
- OpenAI API key mobile uygulamada bulunmamaktadır.
- Flutter doğrudan AI provider'a bağlanmamaktadır.
- AI provider'ın raw cevabı kullanıcıya gösterilmemektedir.
- Ownership kontrolü backend'e bırakılmıştır.

### İnsan Tarafından Yapılan Kontrol

AI sonuç raporu incelendi.

Özellikle:

- AI önerisinin kullanıcı onayı olmadan kategoriyi seçmediği,
- IsAiCategorized değerinin son kullanıcı kararına göre doğru tutulduğu,
- AI hatasının Expense oluşturmayı engellemediği,
- Expense ve Income birleşiminin yalnızca presentation seviyesinde yapıldığı,
- finansal toplamların Flutter'da hesaplanmadığı,
- UserId'nin requestlere eklenmediği,
- OpenAI'ın mobile taşınmadığı

doğrulandı.

Kritik hata tespit edilmediği için revizyon promptu oluşturulmadı.

### Test ve Build Sonucu

Flutter test sonucu:

- Toplam: 65
- Başarılı: 65
- Başarısız: 0

Önceki Authentication ve Dashboard testleri başarılı olmaya devam etti.

`flutter analyze`:

- No issues found

Android debug APK:

- başarıyla oluşturuldu.

### Bilerek Sonraya Bırakılanlar

Bu aşamada:

- Budget Flutter CRUD entegrasyonu,
- Bill Flutter CRUD entegrasyonu,
- Bill trend entegrasyonu,
- Expense update/detail,
- Income update/detail,
- yeni kategori oluşturma

geliştirilmedi.

### Sonuç

Flutter İşlemler ekranı gerçek backend Expense, Income, Category ve AI kategorileme
özellikleriyle entegre edilerek insan kontrolünden geçirilmiş ve kabul edilmiştir.




## AI-LOG-015 — Flutter Budget Entegrasyonu

**Tarih:** 16.08.2026  
**Kullanılan AI:** Codex  
**Kullanılan Prompt:** `prompts/21_flutter_budget.txt`

### Amaç

SmartBudget AI Flutter uygulamasındaki Bütçeler ekranını gerçek backend Budget
endpointleriyle entegre etmek.

### AI Ne Yaptı?

AI:

- Budget mobil modellerini,
- BudgetService'i,
- BudgetsViewModel'i,
- Budget liste ekranını,
- Yeni Bütçe Ekle ekranını,
- Budget düzenleme ekranını,
- CategoryService yeniden kullanımını,
- duplicate conflict davranışını,
- delete confirmation akışını,
- Budget Flutter testlerini

oluşturdu.

### Budget Endpointleri

Kullanılan endpointler:

- `GET /api/budgets`
- `POST /api/budgets`
- `PUT /api/budgets/{id}`
- `DELETE /api/budgets/{id}`

Backend'de olmayan detail endpointi eklenmedi.

### Budget Create

Create request yalnızca:

- CategoryId
- LimitAmount
- Month
- Year

alanlarını içermektedir.

UserId request'e eklenmemektedir.

Kategori backend CategoryService üzerinden alınmaktadır.

### Duplicate Budget

Backend tarafından dönen 409 Conflict durumu mobilde raw database veya exception
detayı gösterilmeden:

`Bu kategori için seçilen dönemde zaten bir bütçe bulunuyor.`

mesajıyla ele alınmaktadır.

### Budget Listeleme

Backend tüm kullanıcı bütçelerini döndürmektedir.

Flutter yalnızca presentation amacıyla seçilen ay ve yıla göre filtreleme yapmaktadır.

Bu filtre sırasında finansal değerler yeniden hesaplanmamaktadır.

### Budget Finansal Değerleri

Flutter aşağıdaki değerleri backend response'undan doğrudan kullanmaktadır:

- LimitAmount
- SpentAmount
- UsagePercent
- AlertStatus

SpentAmount ve UsagePercent mobil tarafta tekrar hesaplanmamaktadır.

### AlertStatus

Backend string enum değerleri UI'a şu şekilde eşlenmektedir:

- Normal → Normal
- Warning → Limite Yakın
- Exceeded → Limit Aşıldı

Bilinmeyen değer geldiğinde uygulama çökmemekte ve kontrollü:

`Durum Bilinmiyor`

fallback'i kullanılmaktadır.

### %100 Üzeri UsagePercent

Backend tarafından `%135` gibi bir değer döndürüldüğünde gerçek değer metinde korunmaktadır.

Yalnızca progress göstergesinin fiziksel genişliği maksimum `1.0` seviyesinde sınırlandırılmaktadır.

Bu nedenle görsel progress ile finansal veri birbirinden ayrılmıştır.

### Budget Update

Budget update ekranında:

- Category read-only
- Month read-only
- Year read-only
- LimitAmount editable

olarak uygulanmıştır.

Update request yalnızca:

`limitAmount`

alanını göndermektedir.

CategoryId, Month, Year veya UserId update request'e eklenmemektedir.

### Budget Delete

Silme işleminden önce confirmation dialog kullanılmaktadır.

Backend ownership kontrolü mobil tarafa taşınmamıştır.

404 durumunda başka kullanıcı sahipliği gibi güvenlik detayları gösterilmemektedir.

### Pull-to-Refresh

Refresh işlemi yalnızca Budget listesini yenilemektedir.

Cache'lenmiş Category listesi gereksiz yere tekrar çağrılmamaktadır.

### Dashboard İlişkisi

Budget create/update/delete sonrasında Flutter tarafında global finansal state senkronizasyonu
veya yeniden finansal hesaplama yapılmamaktadır.

Dashboard kendi bağımsız backend refresh mekanizmasını korumaktadır.

### Güvenlik

- UserId Budget requestlerine eklenmemektedir.
- JWT merkezi ApiClient üzerinden gönderilmektedir.
- Ownership backend'e bırakılmıştır.
- CategoryId backend category listesinden seçilmektedir.
- Mobil tarafta hidden ownership kontrolü yapılmamaktadır.

### İnsan Tarafından Yapılan Kontrol

AI sonuç raporu incelendi.

Özellikle:

- update request'in yalnızca LimitAmount göndermesi,
- SpentAmount'ın Flutter'da hesaplanmaması,
- UsagePercent'in Flutter'da hesaplanmaması,
- AlertStatus'un Flutter'da üretilmemesi,
- %100 üzerindeki kullanım değerinin korunması,
- duplicate Budget 409 davranışının güvenli olması,
- UserId'nin requestlere eklenmemesi

doğrulandı.

Kritik hata tespit edilmediği için revizyon promptu oluşturulmadı.

### Test ve Build Sonucu

Flutter test sonucu:

- Toplam: 90
- Başarılı: 90
- Başarısız: 0

Önceki Authentication, Dashboard ve Transactions testleri geçmeye devam etti.

`flutter analyze`:

- No issues found

Android debug APK:

- başarıyla oluşturuldu.

### Bilerek Sonraya Bırakılanlar

Bu aşamada:

- Bill Flutter CRUD entegrasyonu,
- Bill tüketim trendleri,
- Budget AI özelliği,
- RemainingAmount,
- mobil finansal Budget hesapları,
- Budget detail endpointi,
- Category CRUD

geliştirilmedi.

### Sonuç

Flutter Budget ekranı gerçek backend Budget endpointleriyle entegre edilmiş,
backend finansal hesapları tek doğruluk kaynağı olarak korunmuş ve özellik insan
kontrolünden geçirilerek kabul edilmiştir.




## AI-LOG-016 — Flutter Bill ve Tüketim Trend Entegrasyonu

**Tarih:** 16.08.2026  
**Kullanılan AI:** Codex  
**Kullanılan Prompt:** `prompts/22_flutter_bills.txt`

### Amaç

SmartBudget AI Flutter uygulamasındaki Faturalar ekranını gerçek backend Bill
ve son 6 aylık tüketim trendi endpointleriyle entegre etmek.

### AI Ne Yaptı?

AI:

- Bill mobil modellerini,
- BillService'i,
- BillsViewModel'i,
- Faturalar liste ekranını,
- Fatura Ekle ekranını,
- BillType eşlemesini,
- Bill filtrelerini,
- Bill silme akışını,
- son 6 aylık trend görünümünü,
- liste ve trend için ayrı hata/loading durumlarını,
- ilgili Flutter testlerini

oluşturdu.

### BillType Yaklaşımı

Backend API değerleri:

- Electricity
- Water
- NaturalGas

Flutter UI'da:

- Elektrik
- Su
- Doğalgaz

olarak gösterilmektedir.

Internet veya Diğer gibi backend'de olmayan türler eklenmemiştir.

### Bill Endpointleri

Kullanılan endpointler:

- `GET /api/bills`
- `GET /api/bills/trends`
- `POST /api/bills`
- `DELETE /api/bills/{id}`

Backend'de olmayan update veya detail endpointleri oluşturulmamıştır.

### Bill Create

Create request yalnızca:

- billType
- amount
- consumptionValue
- billingDate

alanlarını içermektedir.

UserId, ConsumptionUnit, payment status veya AI prediction alanı request'e eklenmemektedir.

### ConsumptionValue

ConsumptionValue opsiyoneldir.

Null tüketim değeri UI'da `0` olarak gösterilmemektedir.

Bunun yerine:

`Tüketim bilgisi yok`

yaklaşımı kullanılmaktadır.

Bu sayede "tüketim ölçülmemiş" durumu ile "0 tüketim" durumu birbirine karıştırılmamaktadır.

### ConsumptionUnit

ConsumptionUnit kullanıcıdan alınmamaktadır.

Form tarafında seçilen BillType üzerinden yalnızca yardımcı UI metni gösterilmektedir.

Backend response'ta gelen ConsumptionUnit liste ve trend görünümünde kullanılmaktadır.

### Create Sonrası Yenileme

Yeni fatura oluşturulduktan sonra:

- Bill listesi
- Bill trend endpointi

yeniden çağrılmaktadır.

Flutter trend toplamlarını kendi başına yeniden hesaplamamaktadır.

### Bill Delete

Silme öncesinde confirmation dialog kullanılmaktadır.

Başarılı delete sonrasında:

- ilgili Bill listeden kaldırılır,
- trend backend'den yeniden yüklenir.

404 durumunda ownership detayı kullanıcıya açıklanmamaktadır.

### Trend Response

Backend trend modeli:

- Year
- Month
- BillType
- TotalAmount
- TotalConsumption
- ConsumptionUnit

alanlarıyla parse edilmektedir.

Backend'in:

6 ay × 3 BillType = 18 nokta

response yapısı desteklenmektedir.

### Trend Tür Seçimi

Kullanıcı trend görünümünde:

- Elektrik
- Su
- Doğalgaz

arasında seçim yapabilmektedir.

Flutter yalnızca seçilen BillType noktalarını presentation amacıyla filtrelemektedir.

Aylık TotalAmount veya TotalConsumption yeniden hesaplanmamaktadır.

### TotalAmount

TotalAmount backend tarafından hesaplanan değer olarak kullanılmaktadır.

Flutter yalnızca Türkçe para formatında göstermektedir.

### TotalConsumption

TotalConsumption backend değerinden doğrudan gösterilmektedir.

Tutar ve tüketim ayrı alanlarda sunulmaktadır.

Farklı ölçüler tek finansal grafik hesabında birleştirilmemektedir.

### Null TotalConsumption

Backend:

`TotalConsumption = null`

döndürdüğünde Flutter bunu `0` tüketim gibi göstermemektedir.

UI:

`Tüketim verisi yok`

şeklinde kontrollü semantik kullanmaktadır.

### Trend Error Isolation

Bill listesi ve trend hata durumları ayrılmıştır.

Trend endpointi başarısız olduğunda mevcut Bill listesi kullanılabilir durumda kalmaktadır.

Trend bölümünde ayrı hata mesajı ve yalnızca trendi tekrar çağıran retry aksiyonu bulunmaktadır.

### Pull-to-Refresh

Refresh işlemi:

- Bill listesini
- Bill trend endpointini

yenilemektedir.

Başka finansal veya AI endpointleri çağrılmamaktadır.

### AI Fatura Tahmini

İnsan kontrolünde özellikle doğrulandı:

Flutter uygulamasına:

- AI gelecek fatura tahmini,
- AI Öngörüsü,
- tahmini gelecek fatura tutarı

eklenmemiştir.

Stitch tasarımlarında daha önce görülen bu backend dışı özellik mobil implementasyona taşınmamıştır.

### Güvenlik

- UserId Bill requestlerine eklenmemektedir.
- JWT merkezi ApiClient tarafından gönderilmektedir.
- Ownership backend'e bırakılmıştır.
- OpenAI API key mobile uygulamada bulunmamaktadır.
- Payment status gibi backend'de olmayan alanlar request'e eklenmemektedir.
- Teknik backend exceptionları kullanıcıya gösterilmemektedir.

### İnsan Tarafından Yapılan Kontrol

AI sonuç raporu incelendi.

Özellikle:

- null ConsumptionValue değerinin 0 yapılmadığı,
- 18 noktalı trend response'un doğru parse edildiği,
- Flutter'ın TotalAmount hesaplamadığı,
- Flutter'ın TotalConsumption hesaplamadığı,
- create/delete sonrasında trendin backend'den yeniden çekildiği,
- AI gelecek fatura tahmininin eklenmediği,
- UserId'nin requestlerde bulunmadığı

doğrulandı.

Kritik hata tespit edilmediği için revizyon promptu oluşturulmadı.

### Test ve Build Sonucu

Flutter test sonucu:

- Toplam: 105
- Başarılı: 105
- Başarısız: 0

Önceki Authentication, Dashboard, Transactions ve Budget testleri geçmeye devam etti.

`flutter analyze`:

- No issues found

Android debug APK:

- başarıyla oluşturuldu.

### Bilerek Geliştirilmemiş Özellikler

Bu aşamada:

- Bill update
- Bill detail
- Internet BillType
- Diğer BillType
- payment status
- AI future bill prediction
- Flutter trend aggregation
- yeni backend endpointleri

geliştirilmedi.

### Sonuç

Flutter Bill ve son 6 aylık tüketim trendi özellikleri gerçek backend endpointleriyle
entegre edilmiş, backend hesapları tek doğruluk kaynağı olarak korunmuş ve özellik
insan kontrolünden geçirilerek kabul edilmiştir.




## AI-LOG-017 — Backend / Flutter Integration Smoke Test ve Decimal Culture Bug Fix

**Tarih:** 16.08.2026  
**Kullanılan AI:** Codex  
**Kullanılan Prompt:** `prompts/23_integration_smoke_test.txt`

### Amaç

SmartBudget AI MVP'nin mevcut:

- ASP.NET Core backend,
- PostgreSQL database,
- Flutter mobile,
- JWT authentication,
- finansal özellikler,
- AI endpointleri

arasındaki gerçek entegrasyonu development ortamında smoke test seviyesinde doğrulamak.

Bu aşamada yeni özellik geliştirilmemesi, yalnızca gerçek entegrasyon hatalarının bulunması
ve minimum değişiklikle düzeltilmesi hedeflendi.

### Test Ortamı

- Windows
- .NET 8
- Flutter 3.44
- PostgreSQL development database
- Europe/Istanbul raporlama yaklaşımı

Backend development adresi:

`http://localhost:5259`

Android emulator için Flutter varsayılan adresi:

`http://10.0.2.2:5259`

olarak doğrulandı.

### PostgreSQL ve Migration Kontrolü

Development PostgreSQL database bağlantısı başarılı oldu.

Aşağıdaki migration'ın uygulanmış olduğu doğrulandı:

`20260815204220_InitialCreate`

Sekiz seed kategori veritabanında bulundu:

- Market
- Ulaşım
- Fatura
- Eğlence
- Sağlık
- Eğitim
- Kira
- Diğer

Yeni migration oluşturulmadı.

### Authentication Smoke Test

Development amacıyla test kullanıcıları oluşturuldu.

Register:

- `201 Created`
- plaintext password database'e yazılmadı
- password hash saklandı
- CreatedAt UTC

Login:

- `200 OK`
- JWT üretildi
- token protected endpointlerde başarıyla kullanıldı

Token veya secret değerleri rapora yazılmadı.

### Income Smoke Test

Gerçek PostgreSQL üzerinde Income oluşturuldu ve listelendi.

Örnek doğrulanan değerler:

- Amount: `2500.25`
- Date: `2026-08-16`

UserId request'ten gönderilmedi.

### Expense Smoke Test

Gerçek PostgreSQL üzerinde Expense oluşturuldu.

Doğrulanan noktalar:

- Market kategorisi
- Amount `125.50`
- `IsAiCategorized = false`
- UserId request'te yok

### AI Expense Categorization

Gerçek OpenAI API key development ortamında yapılandırılmadığı için real-provider
smoke testi gerçekleştirilemedi.

Ancak backend fallback davranışı doğrulandı:

- Success = false
- RequiresManualSelection = true
- Expense oluşturulmadı
- Category tablosu değiştirilmedi

Bu durum uygulama hatası değil, test ortamı configuration eksikliği olarak değerlendirildi.

### Budget Smoke Test

Budget create başarılı oldu.

Backend tarafından hesaplanan değerler doğrulandı:

- LimitAmount: 2000
- SpentAmount: 125.50
- UsagePercent: 6.275
- AlertStatus: Normal

Aynı UserId + CategoryId + Month + Year kombinasyonunun ikinci kez oluşturulması:

`409 Conflict`

ile reddedildi.

Database/PostgreSQL internal hata detayı client'a sızmadı.

### Budget Update

Budget update başarılı oldu.

Request yalnızca `LimitAmount` içerdi.

Aşağıdaki alanlar değişmedi:

- Category
- Month
- Year

SpentAmount, UsagePercent ve AlertStatus backend tarafından tekrar üretildi.

### Bill Smoke Test

Electricity ve Water faturaları gerçek database üzerinde oluşturuldu.

Doğrulanan davranışlar:

- Electricity → kWh
- Water ConsumptionValue null kalabildi
- UserId request'e eklenmedi

### Bill Trend

`GET /api/bills/trends`

başarılı oldu.

Backend:

6 ay × 3 BillType = 18 nokta

döndürdü.

Electricity, Water ve NaturalGas ayrı tutuldu.

Null consumption değeri sahte `0` değerine dönüştürülmedi.

### Dashboard Smoke Test

Gerçek oluşturulan finansal kayıtlarla Dashboard endpointi test edildi.

Doğrulanan örnek:

- TotalIncome: 2500.25
- TotalExpense: 125.50
- Balance: 2374.75

Ayrıca:

- CategoryExpenses
- BudgetUsages
- HighestSpendingCategory
- HighestIncreaseCategory
- LastSixMonthsTrend

alanlarının tutarlı olduğu doğrulandı.

Finansal hesaplar Flutter'a taşınmadı.

### AI Monthly Summary

Gerçek OpenAI provider configuration bulunmadığı için gerçek model analizi test edilemedi.

Empty-data senaryosunda backend'in AI çağrısı yapmadan kontrollü deterministik response
üretebildiği doğrulandı.

### Security / Error Smoke Testleri

#### Unauthorized

Tokensız protected endpoint:

`401 Unauthorized`

döndürdü.

#### Validation

Aşağıdaki örnekler `400` ile reddedildi:

- Expense Amount = 0
- Income Amount < 0
- Bill ConsumptionValue = 0
- Budget Month = 13

#### Ownership / IDOR

İkinci development kullanıcısı ile başka kullanıcıya ait Expense silinmeye çalışıldı.

Beklenen güvenli davranış:

`404 Not Found`

elde edildi.

Başka kullanıcının finansal kayıtları listelerde görünmedi.

### İnsan/AI Kontrolünde Bulunan Gerçek Bug

Smoke test sırasında `tr-TR` culture altında gerçek bir validation problemi tespit edildi.

Decimal DTO alanlarında kullanılan bazı `Range` attribute sınırları:

`"0.01"`

değerini mevcut culture altında doğru parse edemiyordu.

Bunun sonucunda bazı geçerli/geçersiz decimal istekleri beklenen `400` yerine:

`500`

üretebiliyordu.

Bu problem önceki unit testlerde görülmemiş, gerçek integration smoke test sırasında ortaya çıkmıştır.

### Minimum Düzeltme

İlgili decimal Range attribute'larına:

`ParseLimitsInInvariantCulture = true`

özelliği eklendi.

Düzeltilen DTO'lar:

- CreateExpenseRequest
- CreateIncomeRequest
- CreateBudgetRequest
- UpdateBudgetRequest
- CreateBillRequest

Yeni feature veya mimari refactor yapılmadı.

### Regression Test

Yeni:

`DecimalRangeCultureTests`

test grubu eklendi.

Testler `tr-TR` culture altında:

- geçerli decimal değerlerin kabul edilmesini,
- sıfır/geçersiz değerlerin doğru validation davranışını

doğrulamaktadır.

### Flutter ↔ Backend Sözleşme Kontrolü

Aşağıdaki response/request modelleri casing, nullability ve enum açısından kontrol edildi:

- Login
- Dashboard
- Expense
- Income
- Budget
- Bill
- Bill Trend
- AI Categorization
- AI Monthly Analysis

DateOnly / BillingDate:

`yyyy-MM-dd`

formatında uyumlu bulundu.

Decimal JSON değerleri number olarak korunmaktadır.

Nullable:

- ConsumptionValue
- TotalConsumption

değerleri null semantiğini korumaktadır.

Türkçe para/tarih formatlama yalnızca Flutter presentation katmanında yapılmaktadır.

### Final Test Sonuçları

Backend:

- Build: 0 hata / 0 uyarı
- Test: 200/200 başarılı

Flutter:

- Test: 105/105 başarılı
- Analyze: No issues found
- Android debug APK: başarılı

### Smoke Test Sonucu

**PARTIAL PASS**

Temel:

- backend,
- PostgreSQL,
- authentication,
- ownership,
- Expense,
- Income,
- Budget,
- Bill,
- Bill trend,
- Dashboard,
- Flutter/backend DTO sözleşmeleri

gerçek development ortamında doğrulandı.

Eksik kalanlar:

- gerçek OpenAI provider smoke testi
- Android emulator / gerçek cihaz üzerinden interaktif UI testi

Bu eksikler application bug değil, test ortamı/configuration eksikliği nedeniyle beklemektedir.

### Sonuç

Smoke test sırasında daha önce unit testlerde ortaya çıkmayan gerçek bir culture-dependent
decimal validation problemi tespit edilmiş ve minimum değişiklikle düzeltilmiştir.

Düzeltme için regression test eklenmiş ve tüm backend/Flutter testleri yeniden başarıyla
çalıştırılmıştır.

Bu aşama AI tarafından üretilen kodun yalnızca unit testlerle kabul edilmediğini,
gerçek database ve API entegrasyonu üzerinden insan kontrollü biçimde doğrulandığını göstermektedir.



## AI-LOG-018 — Budget PostgreSQL EF Core Translation Hatası

**Tarih:** 16.08.2026  
**Kullanılan AI:** Codex  
**Kullanılan Prompt:** `prompts/24_budget_query_translation_fix.txt`

### Amaç / Problem

Manuel emulator testinde `GET /api/budgets` çağrısı gerçek PostgreSQL üzerinde şu hatayla çöktü:

`The LINQ expression ... OrderByDescending(... new BudgetValue(...).Year) could not be translated.`

Sebep: `BudgetService.GetAllAsync` sıralamayı, projection ile üretilmiş bir `BudgetValue`
nesnesinin alanları üzerinden yapıyordu; Npgsql/EF Core bu ifadeyi SQL'e çeviremiyordu.
Bu hata mevcut InMemory-provider unit testlerinde ortaya çıkmamıştı; yalnızca gerçek
PostgreSQL provider ile görünen bir integration bug'ıydı.

### AI Önerisi / Uygulaması

Codex, `OrderBy` zincirini projection'dan önce, doğrudan entity alanları üzerinde
(`budget.Year`, `budget.Month`, `budget.Category.Name`, `budget.Id`) SQL'e çevrilebilir
şekilde yeniden kurdu; `Select` projeksiyonu sıralamadan sonraya taşındı.

### İnsan İncelemesi / Kararı

İnsan, düzeltmenin `AsEnumerable`/client-side evaluation'a veya tüm tabloyu belleğe
çekmeye kaçmadığını, endpoint/DTO sözleşmesinin ve ownership davranışının değişmediğini
doğruladı. Bu bir provider-specific bug olduğu için regression testinin gerçek
PostgreSQL'e karşı da anlamlı olması istendi.

### Yapılan Revizyon

`BudgetService.cs` içindeki sıralama SQL-translatable hale getirildi; DTO/endpoint
sözleşmesi, `BudgetCalculations` mantığı ve ownership kuralları değiştirilmedi.

### Doğrulama / Test Sonucu

Kod incelemesinde (`backend/SmartBudget.Api/Services/BudgetService.cs:144-147`) düzeltmenin
hâlâ kod tabanında olduğu doğrulandı: sıralama `OrderByDescending(budget => budget.Year)` →
`ThenByDescending(budget => budget.Month)` → `ThenBy(budget => budget.Category.Name)` →
`ThenBy(budget => budget.Id)` şeklinde, projection'dan önce yapılmaktadır. Güncel toplam
backend test sonucu bu belgenin sonundaki "Final Test Audit" bölümünde ayrıca belirtilmiştir.

---

## AI-LOG-019 — Dashboard 6 Aylık Trend Empty-State

**Tarih:** 16.08.2026  
**Kullanılan AI:** Codex  
**Kullanılan Prompt:** `prompts/25_dashboard_empty_trend_state.txt`

### Amaç / Problem

Manuel Flutter testinde, kullanıcının hiç gerçek harcaması olmadığı durumda Dashboard'daki
son 6 aylık trend grafiği altı adet `0,00` satırı gösteriyordu; bu kullanıcı için anlamsız
ve kafa karıştırıcı bir görünümdü.

### AI Önerisi / Uygulaması

Codex, yalnızca Flutter presentation katmanında bir kontrol ekledi: `LastSixMonthsTrend`
içindeki tüm ayların değeri 0 ise trend satırları yerine "Son 6 ay için veri yok." benzeri
bir empty-state metni gösterildi; en az bir ayda gerçek harcama varsa mevcut trend görünümü
aynen korundu.

### İnsan İncelemesi / Kararı

İnsan, backend contract'ının, Dashboard endpoint'inin ve finansal hesaplamanın
değiştirilmediğini; kararın yalnızca UI/presentation seviyesinde alındığını doğruladı.

### Yapılan Revizyon

Dashboard trend widget'ına empty-state dalı eklendi; backend'e dokunulmadı.

### Doğrulama / Test Sonucu

Kod incelemesinde `mobile/lib/screens/dashboard/dashboard_widgets.dart` içinde
"Son 6 ay için veri yok." empty-state metninin hâlâ mevcut olduğu doğrulandı.

---

## AI-LOG-020 — Fatura Trend Empty-State

**Tarih:** 16.08.2026  
**Kullanılan AI:** Codex  
**Kullanılan Prompt:** `prompts/26_bill_trend_empty_state.txt`

### Amaç / Problem

Aynı empty-state problemi Faturalar ekranındaki 6 aylık tutar/tüketim trendinde de vardı:
seçili fatura türünde hiç gerçek veri yokken kart altı adet `₺0,00 / Tüketim verisi yok`
satırı gösteriyordu.

### AI Önerisi / Uygulaması

Codex, seçili `BillType` için 6 ayın tamamında `TotalAmount == 0` ve
`TotalConsumption == null` ise trend satırları yerine "Son 6 ay için fatura verisi yok."
mesajını gösterecek şekilde Flutter tarafında bir kontrol ekledi. Elektrik/Su/Doğalgaz
sekmeleri birbirinden bağımsız değerlendirildi.

### İnsan İncelemesi / Kararı

İnsan, `/api/bills/trends` sözleşmesinin ve backend tüketim/finansal hesaplamasının
değişmediğini, null değerlerin 0'a çevrilmediğini doğruladı.

### Yapılan Revizyon

Faturalar trend kartına empty-state dalı eklendi; backend'e dokunulmadı.

### Doğrulama / Test Sonucu

Kod incelemesinde `mobile/lib/screens/bills/bills_screen.dart` içinde
"Son 6 ay için fatura verisi yok." empty-state metninin hâlâ mevcut olduğu doğrulandı.

---

## AI-LOG-021 — Flutter Tutorial / Interaktif Walkthrough Geliştirmesi ve İnsan Revizyonu

**Tarih:** 16.08.2026  
**Kullanılan AI:** Codex  
**İlk Prompt:** `prompts/27_flutter_tutorial.txt`  
**Revizyon Promptu:** `prompts/28_flutter_interactive_tutorial_revision.txt`

### Amaç / Problem

İlk kullanım deneyiminde kullanıcının uygulamanın temel ekranlarını (Ana Sayfa, İşlemler,
Bütçeler, Faturalar, AI özellikleri) anlaması için bir onboarding/tutorial akışı eklemek.

### AI Önerisi / Uygulaması (İlk Prompt)

Codex, ilk aşamada ayrı sayfalardan oluşan klasik bir onboarding akışı kurdu: her adım
kendi başlık/metin içeriğine sahip bağımsız bir sayfaydı; kullanıcı yalnızca açıklama
metnini görüyor, anlatılan gerçek ekranı görmüyordu. Kullanıcı bazlı `tutorial_seen_v1_*`
anahtarıyla `flutter_secure_storage` üzerinde saklama ve sağ üstte `?` yardım butonuyla
manuel yeniden açma eklendi.

### İnsan Tarafından Tespit Edilen Problem

İnsan, ayrı onboarding sayfalarının öğretici değerinin düşük olduğunu belirledi:
örneğin "Gelir ve Giderlerinizi Ekleyin" adımında kullanıcı gerçek İşlemler ekranını
görmüyordu, yalnızca soyut bir açıklama metni okuyordu.

### İnsan Tarafından Verilen Revizyon

`prompts/28_flutter_interactive_tutorial_revision.txt` ile Codex'ten, tutorial'ı
uygulamanın gerçek ekranlarını arka planda gösteren interaktif bir walkthrough'a
dönüştürmesi istendi: her adımda gerçek `MainShell` sekmesi açık kalıyor, tutorial
açıklaması bunun üzerinde bir kart/overlay olarak gösteriliyor; "İleri" ilgili gerçek
sekmeye otomatik geçiyor. Tutorial sırasında hiçbir backend write veya AI çağrısı
yapılmaması şart koşuldu.

### Yapılan Revizyon

Ayrı onboarding sayfaları kaldırılıp gerçek `MainShell` üzerinde adım→sekme eşlemesiyle
çalışan bir walkthrough yapısına geçildi; `tutorial_seen_v1_*` saklama mekanizması ve `?`
yardım butonu korundu.

### Doğrulama / Test Sonucu

Kod incelemesinde `mobile/lib/screens/tutorial/tutorial_dialog.dart` ve
`mobile/lib/screens/main_shell.dart` içinde gerçek sekmeler üzerinde çalışan walkthrough
yapısının ve `mobile/lib/storage/secure_storage_service.dart` içinde kullanıcı bazlı
tutorial-seen saklamanın hâlâ mevcut olduğu doğrulandı.

---

## AI-LOG-022 — Coach-Mark Highlight Revizyonu

**Tarih:** 16.08.2026  
**Kullanılan AI:** Codex  
**Kullanılan Prompt:** `prompts/29_flutter_coachmark_highlight_revision.txt`

### Amaç / Problem

Manuel emulator testinde interaktif walkthrough'un UX'i yetersiz bulundu: tüm ekran
belirgin şekilde karartılıyor, tutorial kartı çok büyüktü ve ekranın büyük bölümünü
kaplıyordu, anlatılan gerçek UI öğesi (buton/alan) görsel olarak vurgulanmıyordu.

### AI Önerisi / Uygulaması

Codex, üçüncü parti coach-mark paketi eklemeden, hedef widget'lara `GlobalKey` verip
`RenderBox` üzerinden ekran konumunu okuyan ve `Overlay`/`Stack` içinde hedefin çevresine
ince bir border/highlight çizen sade bir çözüm kurdu. Tam ekran karartma kaldırıldı veya
minimuma indirildi; tutorial kartı yalnızca başlık, kısa metin, adım göstergesi ve
Geri/İleri kontrollerini içerecek şekilde küçültüldü.

### İnsan İncelemesi / Kararı

İnsan, hard-coded pixel koordinat kullanılmadığını, highlight'ın farklı ekran
boyutlarında `RenderBox` tabanlı responsive konumlandırmayla çalıştığını ve tutorial
sırasında highlighted butona basılarak yanlışlıkla gerçek bir finansal işlem
başlatılamadığını doğruladı.

### Yapılan Revizyon

Büyük full-screen modal, hedef UI öğesini vurgulayan kompakt bir coach-mark kartına
dönüştürüldü; her adım (Dashboard özet kartı, İşlem Ekle butonu, Yeni Bütçe Ekle butonu,
Fatura Ekle butonu, AI aylık analiz kartı) kendi gerçek hedefini highlight eder hale
getirildi.

### Doğrulama / Test Sonucu

Kod incelemesinde `mobile/lib/screens/tutorial/tutorial_dialog.dart` içinde `GlobalKey`
tabanlı hedef highlight mekanizmasının hâlâ mevcut olduğu doğrulandı.

---

## AI-LOG-023 — Tutorial Adım 3 AI Hedefi Düzeltmesi

**Tarih:** 16.08.2026  
**Kullanılan AI:** Codex  
**Kullanılan Prompt:** `prompts/30_tutorial_ai_step_target_fix.txt`

### Amaç / Problem

Manuel testte, walkthrough'un Adım 2'si ("Gelir ve Giderlerinizi Ekleyin") ve Adım 3'ü
("AI ile Kategori Önerisi") aynı gerçek UI öğesini — "İşlem Ekle" butonunu — highlight
ediyordu. Bu nedenle Adım 3, kullanıcıya AI kategori özelliğinin gerçekte nerede olduğunu
göstermiyor, Adım 2'nin tekrarı gibi görünüyordu.

### AI Önerisi / Uygulaması

Codex, Adım 3'e geçildiğinde gerçek gider ekleme formunun tutorial amacıyla (backend
write yapılmadan, AI endpoint çağrılmadan, otomatik değer doldurulmadan) açılmasını ve
formun içindeki gerçek AI kategori önerisi kontrolünün highlight edilmesini sağladı; Adım
3'ten Geri/İleri/Atla ile çıkışta bu tutorial-amaçlı form güvenli şekilde kapatıldı.

### İnsan İncelemesi / Kararı

İnsan, Adım 2 ve Adım 3'ün artık farklı hedefleri highlight ettiğini, tutorial dışı normal
gider ekleme formu davranışının bozulmadığını ve tutorial sırasında hiçbir Expense
kaydının veya AI çağrısının oluşmadığını doğruladı.

### Yapılan Revizyon

Adım 3, "İşlem Ekle" butonu yerine gerçek AI kategori önerisi kontrolünü hedef aldı.

### Doğrulama / Test Sonucu

Kod incelemesinde ilgili walkthrough adım/hedef eşlemesinin `tutorial_dialog.dart`
içinde korunduğu doğrulandı; güncel toplam Flutter test sonucu bu belgenin sonundaki
"Final Test Audit" bölümünde belirtilmiştir.

---

## AI-LOG-024 — Dashboard Otomatik Yenileme (Auto Refresh)

**Tarih:** 16.08.2026  
**Kullanılan AI:** Codex  
**Kullanılan Prompt:** `prompts/31_dashboard_auto_refresh_on_financial_change.txt`

### Amaç / Problem

Manuel testte, kullanıcı gelir/gider ekleyip sildiğinde İşlemler ekranı güncelleniyor,
ancak Ana Sayfa'daki finansal özet (TotalIncome, TotalExpense, Balance, kategori/bütçe
özetleri, 6 aylık trend) eski değerlerde kalabiliyordu.

### AI Önerisi / Uygulaması

Codex, yeni bir state-management paketi eklemeden, mevcut `ChangeNotifier`/`MainShell`
yapısına basit bir "financialDataChanged" bildirim mekanizması ekledi: Income/Expense
create/delete başarılı olduğunda `MainShell`'e bildirim yapılıyor, Dashboard
`GET /api/dashboard/monthly` ile yeniden yükleniyor. AI kategori önerisi tek başına bu
tetiklemeyi yapmıyor; yalnızca gerçek finansal mutation başarıyla tamamlandığında
tetikleniyor.

### İnsan İncelemesi / Kararı

İnsan, finansal hesaplamanın Flutter'a taşınmadığını, polling/timer eklenmediğini ve
Dashboard refresh'in başarısız olması durumunda başarılı bir Income/Expense kaydının
yanlışlıkla "başarısız" gösterilmediğini doğruladı.

### Yapılan Revizyon

`onFinancialDataChanged` bildirim akışı; Income/Expense create/delete sonrası tetiklenir,
AI kategori önerisi tek başına tetiklemez.

### Doğrulama / Test Sonucu

Kod incelemesinde `mobile/lib/screens/transactions/transactions_screen.dart` ve
`mobile/lib/screens/main_shell.dart` içinde bu bildirim akışının hâlâ mevcut olduğu
doğrulandı.

---

## AI-LOG-025 — AI Aylık Özet: Kullanıcı Dostu Çıktı Revizyonu

**Tarih:** 16.08.2026  
**Kullanılan AI:** Codex  
**Kullanılan Prompt:** `prompts/32_ai_monthly_summary_user_friendly_output_fix.txt`

### Amaç / Problem

Manuel mobil testte AI Aylık Özet bazen ham teknik backend alanlarını kullanıcıya
gösteriyordu. Gerçek örnek çıktı:

`"Önceki aya ilişkin gider değişimi bilgisi yok (previousMonthExpenseChangePercent: null)."`

Kullanıcının DTO alan adı, camelCase property adı, JSON key, `null` veya backend/internal
terminoloji görmesi kabul edilemezdi.

### AI Önerisi / Uygulaması

Codex, iki katmanlı bir çözüm uyguladı:

1. System/developer promptuna, modelin yalnızca doğal Türkçe yazması, JSON/camelCase alan
   adlarını, `null`, `DTO`, `payload`, `field`, `property` gibi terimleri kullanmaması
   gerektiğini açıkça belirten kurallar eklendi.
2. Backend tarafında, AI'dan dönen `analysis` metninde `previousMonthExpenseChangePercent`,
   `totalIncome`, `categoryExpenses`, `AlertStatus`, ham JSON gibi teknik sızıntı
   pattern'lerini arayan bir doğrulama eklendi; sızıntı tespit edilirse kontrollü
   fallback'e düşülüyor.

Mevcut `allowedNumbers` sayısal güvenlik doğrulaması bozulmadan korundu.

### İnsan İncelemesi / Kararı

İnsan, backend leakage validation'ının aşırı agresif olup normal Türkçe cümleleri
reddetmediğini, Flutter tarafında herhangi bir string-replace workaround eklenmediğini
(doğru sınırın backend olduğunu) ve API sözleşmesinin değişmediğini doğruladı.

### Yapılan Revizyon

`AiMonthlyAnalysisService` içine teknik alan adı/JSON/`null` sızıntısı doğrulaması ve
kontrollü fallback davranışı eklendi.

### Doğrulama / Test Sonucu

Kod incelemesinde `backend/SmartBudget.Api/Services/AI/AiMonthlyAnalysisService.cs`
içinde `previousMonthExpenseChangePercent` gibi yasaklı pattern'leri arayan doğrulamanın
hâlâ mevcut olduğu doğrulandı.

---

## AI-LOG-026 — Bill → Expense Senkronizasyonu

**Tarih:** 16.08.2026  
**Kullanılan AI:** Codex  
**Kullanılan Prompt:** `prompts/33_bill_expense_dashboard_sync.txt`

### Amaç / Problem

Manuel mobil testte gerçek bir domain tutarsızlığı bulundu: İşlemler ekranından "Fatura"
kategorili bir Expense girilirse Dashboard'a yansıyordu, ancak Faturalar ekranından bir
Bill oluşturulduğunda Dashboard bunu gider olarak görmüyordu. Aynı ekonomik olay, hangi
ekrandan girildiğine göre Dashboard'da farklı sonuç veriyordu.

### AI Önerisi / Uygulaması

Codex, DashboardService'e ikinci bir "Expenses + Bills" toplama mantığı eklemek yerine,
`Expense` entity'sine nullable `BillId` alanı ekledi ve `BillService` üzerinden bir Bill
oluşturulduğunda aynı işlem içinde otomatik olarak `Category = Fatura`, `BillId = <Bill.Id>`
alanlarına sahip bağlı bir Expense de oluşturdu. Bill silindiğinde bağlı Expense da
silindi. Bill-linked bir Expense'in İşlemler ekranından bağımsız silinmesi engellendi
(409/conflict davranışı).

### İnsan İncelemesi / Kararı

İnsan, Dashboard'ın tek gerçeklik kaynağının hâlâ `Expense` tablosu olduğunu, Bill'in
ayrıca ikinci kez toplanmadığını (double counting olmadığını), Bill+Expense oluşturmanın
atomic olduğunu ve migration'ın yalnızca bu ilişki için minimum olduğunu doğruladı.

### Yapılan Revizyon

`Expense.BillId` (nullable) eklendi; Bill create/delete akışı bağlı Expense'i
oluşturur/siler; Bill-linked Expense bağımsız silinemez.

### Doğrulama / Test Sonucu

Kod incelemesinde `backend/SmartBudget.Api/Entities/Expense.cs:13` içinde
`public Guid? BillId { get; set; }` alanının hâlâ mevcut olduğu doğrulandı.

---

## AI-LOG-027 — Codex Token Limiti Sonrası Claude Code'a Geçiş

**Tarih:** 16.08.2026  
**Kullanılan AI:** (araç geçişi — bu entry'nin konusu)

### Amaç / Problem

Proje boyunca kod üretimi için Codex kullanılıyordu (bkz. AI-LOG-001 – AI-LOG-026).
`prompts/33_bill_expense_dashboard_sync.txt` sonrasında Codex oturumunun token limitine
ulaşması nedeniyle geliştirme sürecine devam edilemedi.

### İnsan Kararı

İnsan, kalan görevler (recurring financial records ve sonrasındaki tüm revizyonlar,
final dokümantasyon/audit dahil) için AI aracını Claude Code'a değiştirmeye karar verdi.
Bu bir teknik/mimari karar değil, araç kullanılabilirliği kararıdır.

### Etkisi

`prompts/34_recurring_financial_records.txt` itibarıyla (AI-LOG-028'den başlayarak) bu
günlükteki "Kullanılan AI" alanı Codex yerine Claude Code olarak değişmektedir.
PROJECT.md, mevcut mimari kararlar ve daha önce Codex tarafından oluşturulan kod tabanı
source-of-truth olarak aynen korunmuş, geçiş nedeniyle hiçbir mevcut davranış
değiştirilmemiştir.

### Sonuç

Araç geçişi şeffaflık amacıyla bu günlüğe ayrı bir kayıt olarak eklenmiştir; bu geçiş
tek başına bir kod değişikliği değildir.

---

## AI-LOG-028 — Tekrarlayan (Recurring) Finansal Kayıtlar

**Tarih:** 16.08.2026  
**Kullanılan AI:** Claude Code  
**Kullanılan Prompt:** `prompts/34_recurring_financial_records.txt`

### Amaç / Problem

Kullanıcıların düzenli tekrar eden gelir (ör. maaş), gider (ör. kira) ve fatura
kayıtlarını her ay yeniden manuel girmek zorunda kalmadan tanımlayabilmesi için bir
"planlanan/tekrarlayan kayıt" özelliği eklemek. Bu ilk aşamada plan; tanımlanan bir
kuralın hangi ay için "gerçekleştirilmiş" sayıldığını izleyen, ancak gerçekleşmeyi
kullanıcının manuel tetiklemesini gerektiren bir tasarımdı.

### AI Önerisi / Uygulaması

Claude Code; `RecurringFinancialRule` (plan/şablon) ve `RecurringOccurrence`
(Rule+Year+Month üzerinde unique, hangi ayın gerçekleştirildiğini izleyen kayıt)
entity'lerini, ilgili DTO'ları, `RecurringRuleService`'i ve `RecurringRulesController`'ı
ekledi. Realize akışı "reserve → create → finalize" deseniyle kuruldu: önce
`CreatedRecordId=null` ile bir occurrence rezerve edilip unique constraint ile
race-condition korunuyor, ardından mevcut `IncomeService`/`ExpenseService`/`BillService`
üzerinden gerçek kayıt oluşturuluyor. Flutter tarafında İşlemler/Faturalar ekranlarına
tekrarlama alanları ve "Bu Ay İçin Oluştur" manuel realize butonu eklendi;
`AddRecordOutcome` tabanlı navigasyon ve "Planlananlar" filtre sekmesi kuruldu.

### İnsan İncelemesi / Kararı

İnsan, Dashboard/Budget hesaplamalarının değiştirilmediğini (yalnız gerçekleşmiş
Income/Expense/Bill üzerinden hesap yapılmaya devam ettiğini), Bill realize akışının
mevcut Bill→Expense senkronizasyonunu kullandığını, yeni bir repository/UoW/CQRS/MediatR
veya state-management paketi eklenmediğini ve arka planda hiçbir scheduler
(Hangfire/Quartz) kullanılmadığını doğruladı. Migration
(`20260816150539_AddRecurringFinancialRecords`) development PostgreSQL'e uygulanıp gerçek
smoke testle doğrulandı.

### Yapılan Revizyon

Bu aşamada büyük bir insan revizyonu olmadı; ilk implementasyon kabul edildi. Ancak bu
tasarımın "her ay manuel buton" davranışı, hemen ardından AI-LOG-029'da insan tarafından
yetersiz bulunup revize edildi.

### Doğrulama / Test Sonucu

Backend ve Flutter testleri o aşamada başarıyla geçti; gerçek PostgreSQL smoke testinde
test verileri oluşturulup temizlendi. Güncel toplam test sayıları bu belgenin sonundaki
"Final Test Audit" bölümünde ayrıca belirtilmiştir.

---

## AI-LOG-029 — Recurring Otomatik Gerçekleşme: Manuel Buton Tasarımının Reddi ve Revizyonu

**Tarih:** 16.08.2026  
**Kullanılan AI:** Claude Code  
**Kullanılan Prompt:** `prompts/35_recurring_auto_realization.txt`

### Amaç / Problem

AI-LOG-028'deki ilk recurring tasarımında, örneğin "Her ayın 16'sı, 45.000 TL maaş"
şeklinde tanımlanan bir kural, her ay kullanıcının "Bu Ay İçin Oluştur" butonuna basmasını
gerektiriyordu.

### İnsan Tarafından Tespit Edilen Problem ve Reddi

İnsan, bu davranışın kullanıcı beklentisiyle uyuşmadığına karar verdi: bir maaş kuralı
tanımlayan kullanıcı, her ay tekrar bir butona basmayı beklemez. Manuel-realize-zorunlu
tasarım bu nedenle normal kullanıcı akışı için reddedildi.

### İnsan Tarafından Verilen Revizyon Talebi

`prompts/35_recurring_auto_realization.txt` ile şu davranış istendi: Income/Expense ve
sabit tutarlı (Amount dolu) Bill kuralları, `StartDate.Day` tekrar günü Europe/Istanbul
takviminde geldiğinde backend tarafından otomatik olarak gerçekleştirilmelidir. Tutarı
bilinmeyen (Amount=null) Bill kuralları için otomatik/sahte bir kayıt OLUŞTURULMAMALI;
kural "due" durumda kalmalı ve kullanıcı gerçek tutarı "Faturayı Gir" ile girmelidir.

### AI Uygulaması

Claude Code; `RecurrenceDateHelper.GetOccurrenceDate` (29/30/31 kısa ay clamp'i),
`RecurringRuleService.RunAutomaticRealizationAsync`/`TryAutoRealizeAsync` ve basit bir
`BackgroundService` (`RecurringRuleRealizationHostedService`, ilk sürüm saatlik polling)
ekledi. Mevcut `Rule+Year+Month` unique constraint'i duplicate koruması olarak
kullanılmaya devam etti. Flutter tarafında Income/Expense için zorunlu "Bu Ay İçin
Oluştur" butonu kaldırılıp yerine backend-hesaplı "Bekleniyor/Gerçekleşti" durum etiketi
ve "Sonraki: ..." tarihi gösterildi; Bill tarafında buton yalnızca tutarı bilinmeyen
kurallar için "Faturayı Gir" olarak kaldı.

### İnsan İncelemesi / Kararı

İnsan; Dashboard/Budget'a hâlâ yalnızca gerçekleşmiş kayıtların dahil olduğunu, sahte/0 TL
Bill üretilmediğini, `TimeProvider` üzerinden test edilebilir Europe/Istanbul zaman
hesabı kullanıldığını ve startup catch-up davranışının (backend gece kapalıyken kaçırılan
günün, tekrar açıldığında hemen realize edilmesi) çalıştığını doğruladı.

### Doğrulama / Test Sonucu

Bu aşamada eklenen `RecurringRuleAutomationTests` testleri (Income/Expense/fixed Bill
auto-realize, unknown-amount Bill'in due kalması, duplicate koruması, 29/30/31 davranışı,
EndDate/IsActive, startup catch-up dahil) o dönemde başarıyla geçti; gerçek PostgreSQL
smoke testiyle ek doğrulama yapıldı. Güncel toplam test sayıları bu belgenin sonundaki
"Final Test Audit" bölümünde belirtilmiştir.

---

## AI-LOG-030 — Saatlik Polling'in Reddi ve Europe/Istanbul Gece Yarısı Scheduler Revizyonu

**Tarih:** 16.08.2026  
**Kullanılan AI:** Claude Code  
**Kullanılan Prompt:** `prompts/36_recurring_midnight_scheduler_revision.txt`

### Amaç / Problem

AI-LOG-029'da eklenen `RecurringRuleRealizationHostedService`'in ilk sürümü, sabit
60 dakikalık bir `PollInterval` ile periyodik olarak due kuralları kontrol ediyordu.

### İnsan Tarafından Tespit Edilen Problem ve Reddi

İnsan, saatlik polling yaklaşımının gereksiz ve kaba olduğuna karar verdi: gerçekleşme
zamanı zaten belli (Europe/Istanbul gece yarısı) olduğu için sabit aralıklı bir polling
yerine tam olarak bir sonraki gece yarısını hedefleyen bir scheduling mekanizması
istendi.

### İnsan Tarafından Verilen Revizyon Talebi

`prompts/36_recurring_midnight_scheduler_revision.txt` ile: başlangıçta bir kez catch-up
kontrolü yapılmalı, ardından döngü her seferinde bir sonraki Europe/Istanbul gece yarısını
yeniden hesaplayıp o ana kadar beklemeli (`Task.Delay(TimeSpan.FromDays(1))` gibi sabit bir
aralık KULLANILMAMALI); Hangfire/Quartz/üçüncü parti scheduler veya migration
eklenmemeli; `RecurringRuleService`'in due-check/realize iş mantığına dokunulmamalı.

### AI Uygulaması

Claude Code, `TimeProvider`-tabanlı, saf ve test edilebilir bir
`RecurringScheduleHelper.GetNextIstanbulMidnightUtc`/`GetDelayUntilNextIstanbulMidnight`
yardımcı sınıfı ekledi (`TimeZoneInfo.ConvertTime`/`GetUtcOffset` ile Europe/Istanbul
hesaplaması). `RecurringRuleRealizationHostedService.ExecuteAsync`, sabit `PollInterval`
yerine: başlangıçta bir kez çalış → bir sonraki Istanbul gece yarısına kadar bekle →
tekrar çalış → yeniden hesapla şeklinde yeniden yazıldı; `Task.Delay(TimeSpan, TimeProvider,
CancellationToken)` overload'ı kullanıldı.

### İnsan İncelemesi / Kararı

İnsan; `RecurringRuleService`'in iş mantığının değiştirilmediğini, Flutter'a
dokunulmadığını, migration oluşturulmadığını ve tek bir başarısız run'ın hosted service'i
tamamen durdurmadığını (log'layıp bir sonraki gece yarısını normal şekilde
zamanladığını) doğruladı.

### Yapılan Revizyon

`RecurringScheduleHelper` (yeni, saf fonksiyonlar) ve
`RecurringRuleRealizationHostedService`'in scheduling döngüsü (saatlik polling yerine
Europe/Istanbul gece yarısı hedefleme) değiştirildi.

### Doğrulama / Test Sonucu

Bu aşamada eklenen `RecurringRuleSchedulingTests` (gece yarısı delay hesabı, startup
catch-up, başarısız run'ın scheduler'ı durdurmaması dahil, saat bekleyen gerçek testler
değil `TimeProvider` tabanlı sahte zaman testleri) o dönemde başarıyla geçti. Kod
incelemesinde `backend/SmartBudget.Api/Common/RecurringScheduleHelper.cs` ve
`backend/SmartBudget.Api/Services/RecurringRuleRealizationHostedService.cs` içindeki bu
davranışın hâlâ mevcut olduğu doğrulandı. Güncel toplam test sayıları bu belgenin
sonundaki "Final Test Audit" bölümünde belirtilmiştir.

---

## AI-LOG-031 — Recurring Create-Time Immediate Realization (Restart Gereksinimini Kaldırma)

**Tarih:** 16.08.2026
**Kullanılan AI:** Claude Code
**Kullanılan Prompt:** (bu görev için ayrı bir `prompts/NN_*.txt` dosyası oluşturulmadı; talimat doğrudan sohbet üzerinden verildi)

### Amaç / Problem

Gerçek manuel testte (2026-08-16, ~22:35 Europe/Istanbul) insan, "her ayın 16'sı, 45.000 TL
maaş" şeklinde bugüne due bir recurring Income kuralı oluşturdu. Otomasyon iş mantığının
kendisi doğru çalışıyordu — backend container daha önce ayağa kalkmış olduğu için startup
catch-up bu kural oluşturulmadan ÖNCE zaten tamamlanmıştı — ancak yeni oluşturulan kural
için gerçek Income kaydı **hemen** oluşmadı; yalnızca `docker compose restart api` ile
(startup catch-up'ın yeniden tetiklenmesiyle) gerçekleşti.

### İnsan Tarafından Tespit Edilen UX Boşluğu

İnsan, bu davranışın kabul edilemez olduğunu belirtti: kullanıcı bugüne due bir recurring
kural oluşturduğunda backend restart'ını veya bir sonraki Europe/Istanbul gece yarısı
scheduler çalışmasını beklemek zorunda kalmamalıdır. Bu, mevcut otomasyonun (AI-LOG-029)
bir eksiği değil, kural **oluşturma anı** ile bir sonraki scheduler tetiklemesi arasındaki
boşluğu kapatan ek bir tetikleyicinin eksikliğiydi.

### Uygulanan Çözüm: Create-Time Immediate Realization

`RecurringRuleService.CreateAsync`, kural veritabanına kaydedildikten hemen sonra, mevcut
otomatik gerçekleştirme yolunu (`TryAutoRealizeAsync` → `RealizeCoreAsync`) **aynen yeniden
kullanarak** bir kez immediate-realize dener. Yeni bir business logic kopyalanmadı;
`RecurringRuleRealizationHostedService`'in scheduling döngüsüne (startup catch-up → sonraki
Europe/Istanbul gece yarısı → çalış → tekrarla) hiç dokunulmadı — bu, yalnızca oluşturma
anı ile bir sonraki scheduler çalışması arasındaki boşluğu kapatan ek, güvenli bir
tetikleyicidir. Immediate realization başarısız olursa (örn. arka plan scheduler'ıyla
race condition sonucu `ConflictException`) hata yutulup loglanır; kural oluşturma isteği
başarısız sayılmaz ve kullanıcıya gereksiz 500 dönmez.

### İnsan İncelemesi / Kararı

İnsan; Income/Expense/sabit tutarlı Bill için due-ise-hemen-gerçekleştir davranışının,
tutarı bilinmeyen Bill için "due/faturayı gir" davranışının bozulmadığını, `Rule+Year+Month`
unique constraint'inin son savunma olarak korunduğunu, `BillService`'in kendi transaction'ı
ile iç içe (nested) transaction problemi oluşmadığını ve response'taki
`IsRealizedForCurrentMonth`/`NextDueDate` alanlarının realization sonrası gerçek durumu
yansıttığını doğruladı.

### Doğrulama / Test Sonucu

Backend: `dotnet build` 0 hata/0 uyarı; `dotnet test` **289/289 başarılı** (277 mevcut +
10 yeni: 9 `RecurringRuleServiceTests` + 1 `RecurringRuleAutomationTests`, ayrıca 8 mevcut
`RecurringRuleAutomationTests` testi yeni davranışla uyumlu hale getirildi, hiçbiri
zayıflatılmadı). Flutter: `flutter test` **161/161 başarılı** (158 mevcut + 3 yeni:
`transactions_screen_test.dart`'ta 2, `bills_screen_test.dart`'ta 1); `flutter analyze`
temiz; `flutter build apk --debug` başarılı.

Gerçek Docker + PostgreSQL smoke testinde (development ortamı, `docker compose restart api`
**kullanılmadan**): bugüne due bir recurring Income oluşturuldu → response
`isRealizedThisMonth: true`, `nextDueDate: 2026-09-16` döndü → `GET /api/dashboard/monthly`
`TotalIncome`'un 0'dan 45.000'e hemen çıktığı doğrulandı → aynı ay için manuel realize
denemesi `409 Conflict` (500 değil) döndürdü → gelecek tarihli bir Income kuralı
`isRealizedThisMonth: false` olarak kaldı → tutarı bilinmeyen bir Bill kuralı otomatik
Bill/Expense oluşturmadı. Test verileri (yalnızca bu smoke test için oluşturulan kullanıcı)
temizlendi; kullanıcının kendi gerçek hesabına dokunulmadı. Migration listesi 3 olarak
değişmeden kaldı; migration oluşturulmadı.

---

## AI-LOG-032 — Future StartDate Due-Date Bug Şüphesinin Doğrulanması (Kod Değişikliği Gerekmedi)

**Tarih:** 16.08.2026
**Kullanılan AI:** Claude Code
**Kullanılan Prompt:** (bu görev için ayrı bir `prompts/NN_*.txt` dosyası oluşturulmadı; talimat doğrudan sohbet üzerinden verildi, `prompts/39_recurring_create_immediate_due_fix.txt` referans olarak okundu)

### Amaç / Problem

AI-LOG-031'deki create-time immediate realization revizyonu sonrası, insan tarafından
raporlanan bir manuel test senaryosu şöyleydi: bugün 2026-08-16 iken, StartDate=2026-08-17
(yarın) olan bir recurring Income oluşturulduğunda, kuralın hemen (bugün) gerçekleştiği ve
Dashboard bakiyesinin anında arttığı iddia edildi. Beklenen davranış, bu gelirin yalnızca
StartDate günü (17 Ağustos) geldiğinde gerçekleşmesiydi. Teorik kök neden olarak, due
kontrolünün "aynı ay içinde mi" seviyesinde kalıp gün bazlı karşılaştırma yapmadığı öne
sürüldü.

### İnceleme ve Doğrulama

Claude Code, `RecurringRuleService.TryAutoRealizeAsync` metodunu satır satır inceledi:

```csharp
var occurrenceDate = RecurrenceDateHelper.GetOccurrenceDate(
    rule.StartDate, today.Year, today.Month);

if (occurrenceDate < rule.StartDate || occurrenceDate > rule.EndDate)
    return false;

if (today < occurrenceDate)
    return false;
```

Bu kod, tam olarak istenen "occurrenceDate <= currentDate" kuralını zaten uyguluyordu:
`today < occurrenceDate` kontrolü, gün bazlı due karşılaştırmasını (yalnızca "aynı ay"
değil) doğru şekilde yapıyordu. Bunu doğrulamak için önce **var olan production koduna
karşı** tam olarak raporlanan senaryoyu (today=2026-08-16, StartDate=2026-08-17) birebir
yeniden üreten yeni bir unit test yazıldı; bu test **kod hiç değiştirilmeden** başarıyla
geçti (gerçek Income oluşmadı, occurrence oluşmadı, `IsRealizedThisMonth=false`,
`NextDueDate=2026-08-17`, Dashboard `TotalIncome=0`). Ardından aynı senaryo development
Docker + gerçek PostgreSQL ortamında, imaj yeniden build edilip **restart kullanılmadan**
tekrar denendi ve aynı sonuç doğrulandı.

### Sonuç: Kod Defekti Bulunamadı

Mevcut `RecurringRuleService.cs` ve `RecurrenceDateHelper.cs` içinde raporlanan bug'a
karşılık gelen bir defekt tespit edilmedi; `TryAutoRealizeAsync` (hem create-time immediate
realization hem `RunAutomaticRealizationAsync` scheduler yolu tarafından ortak kullanılan
tek metot) zaten doğru gün-bazlı due kuralını uyguluyordu. En olası açıklama, raporlanan
manuel testin, AI-LOG-031'deki create-time-immediate-realization düzeltmesinden önce build
edilmiş eski bir Docker imajına karşı yapılmış olmasıdır.

Bu nedenle **`RecurringRuleService.cs`, `RecurrenceDateHelper.cs` veya
`RecurringRuleRealizationHostedService.cs` içinde hiçbir kod değişikliği yapılmadı.**
İnsan tarafından istenen "uydurma hata ekleme" kısıtı gereği, var olmayan bir kod defekti
için sahte bir "düzeltme" yazılmadı; bunun yerine bu tam senaryoyu (ve ilişkili Income/
Expense/Bill varyasyonlarını) kalıcı olarak kilitleyen kapsamlı regression testleri
eklendi.

### Eklenen Regression Testleri

`RecurringRuleServiceTests.cs`'e üç yeni test eklendi:

- `Create_income_rule_starting_tomorrow_does_not_realize_today`
- `Create_expense_rule_starting_tomorrow_does_not_realize_today`
- `Create_fixed_amount_bill_rule_starting_tomorrow_does_not_realize_today`

Bu senaryonun diğer boyutları (today=StartDate → hemen realize; ayın geçmiş gününde
başlayan due kural → current-month catch-up; scheduler'ın future-day rule'u erken
realize etmemesi/gerçek due günde realize etmesi; 31-day clamp; Europe/Istanbul UTC
sınırı; duplicate protection) zaten AI-LOG-029/030/031 kapsamında eklenen mevcut
testlerle kapsanıyordu ve bu görevde ayrıca doğrulandı.

### Doğrulama / Test Sonucu

Backend: `dotnet build` 0 hata/0 uyarı; `dotnet test` **292/292 başarılı** (289 mevcut + 3
yeni). Flutter: değiştirilmedi (backend'de kod defekti bulunmadığı için Flutter'da da
değişiklik gerekmedi); bu nedenle Flutter testleri bu görev kapsamında yeniden
çalıştırılmadı. Gerçek Docker + PostgreSQL smoke testinde (`docker compose restart api`
**kullanılmadan**): yarın başlayan bir Income kuralı oluşturuldu → response
`isRealizedThisMonth: false`, `nextDueDate: 2026-08-17`, Dashboard `TotalIncome` 0'da
sabit kaldı, `RecurringOccurrences` tablosunda bu kural için satır oluşmadı (veritabanı
seviyesinde doğrulandı) → aynı oturumda bugüne due başka bir Income kuralı oluşturuldu →
`isRealizedThisMonth: true`, Dashboard `TotalIncome` anında 12.000'e çıktı. Test verileri
temizlendi; kullanıcının gerçek hesabına dokunulmadı; migration listesi 3 olarak
değişmedi, yeni migration oluşturulmadı.

---

## Final Test Audit — 16.08.2026 Güncellemesi (Recurring Create-Time Realization Fix Sonrası)

Bu bölüm, bir önceki "Final Test Audit" bölümünü (final dokümantasyon/audit görevinin
kendi anlık durumu olarak) değiştirmez; yalnızca AI-LOG-031 kapsamındaki değişiklik sonrası
gerçekten çalıştırılan komutların güncel sonucunu ekler.

**Backend:** `dotnet build` 0 hata/0 uyarı — `dotnet test` **289/289 başarılı**
**Flutter:** `dart format lib test` 1 dosya formatlandı — `flutter analyze` temiz —
`flutter test` **161/161 başarılı** — `flutter build apk --debug` başarılı
**Migration listesi:** değişmedi (3 migration; bu görevde yeni migration oluşturulmadı)

---

## Final Test Audit (16.08.2026 — `prompts/37_final_documentation_and_audit.txt` kapsamında)

Bu bölüm, bu günlükteki geçmiş entry'lerin (AI-LOG-001 – AI-LOG-030) tarihsel içeriğini
değiştirmez. Yalnızca final dokümantasyon/audit görevi sırasında gerçekten çalıştırılan
komutların güncel, tek seferlik sonucunu kayıt altına alır.

**Backend:**

- `dotnet build`: 0 hata / 0 uyarı
- `dotnet test`: 277/277 başarılı

**Flutter:**

- `dart format lib test`: 81 dosya, 0 değişiklik (zaten formatlı)
- `flutter analyze`: No issues found!
- `flutter test`: 158/158 başarılı
- `flutter build apk --debug`: başarılı (`build/app/outputs/flutter-apk/app-debug.apk`)

**Migration listesi (`dotnet ef migrations list`):**

1. `20260815204220_InitialCreate`
2. `20260816095144_AddBillExpenseLink`
3. `20260816150539_AddRecurringFinancialRecords`

Bu sayılar yalnızca final audit anındaki gerçek komut çıktılarını yansıtır; yukarıdaki
geçmiş entry'lerde geçen tarihsel test sayıları (ör. AI-LOG-011, AI-LOG-017) o entry'nin
kaydedildiği tarihe aittir ve geriye dönük olarak değiştirilmemiştir.