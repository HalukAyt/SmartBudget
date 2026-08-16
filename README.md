# SmartBudget AI

SmartBudget AI, kullanıcıların gelir, gider, kategori bütçesi ve ev faturalarını (elektrik, su, doğalgaz) tek bir mobil uygulamada takip edebildiği bir kişisel/aile bütçe uygulamasıdır. Backend, kategori önerisi ve aylık harcama yorumu için kontrollü biçimde bir AI (LLM) servisinden yararlanır; ancak finansal hesaplamaların tek doğruluk kaynağı her zaman backend'dir — AI hiçbir zaman toplam, yüzde veya bakiye hesaplamaz.

Bu proje, `PROJECT.md` dosyasının projenin **tek doğruluk kaynağı (source of truth)** olarak kabul edildiği, her görevin numaralandırılmış bir `prompts/NN_*.txt` dosyasıyla verildiği ve `docs/AI_CALISMA_GUNLUGU.md` içinde insan tarafından incelenip kayıt altına alındığı, prompt-driven / insan denetimli bir AI geliştirme sürecinin ürünüdür.

## Teknoloji Yığını

- **Backend:** ASP.NET Core 8 Web API (C#), Entity Framework Core (Npgsql/PostgreSQL provider), JWT Bearer authentication
- **Veri tabanı:** PostgreSQL
- **Mobil:** Flutter / Dart (yalnızca `ChangeNotifier` tabanlı state yönetimi; üçüncü parti state-management paketi yoktur)
- **AI:** OpenAI Responses API (yalnızca backend üzerinden çağrılır; API anahtarı mobil istemciye asla verilmez)
- **Test:** xUnit (backend), `flutter_test` (mobil)

## Klasör Yapısı

```text
SmartBudget/
├─ backend/
│  ├─ SmartBudget.Api/            # ASP.NET Core Web API projesi
│  │  ├─ Controllers/
│  │  ├─ Services/ (AI/ dahil)
│  │  ├─ Entities/
│  │  ├─ DTOs/
│  │  ├─ Data/ (AppDbContext, Configurations/, Migrations/)
│  │  ├─ HealthChecks/
│  │  ├─ Enums/, Authentication/, Middleware/, Common/
│  │  ├─ Dockerfile, .dockerignore
│  │  └─ Program.cs
│  └─ SmartBudget.Api.Tests/      # xUnit test projesi
├─ mobile/
│  ├─ lib/
│  │  ├─ config/, screens/, services/, models/, widgets/, storage/
│  │  └─ main.dart, app.dart
│  └─ test/
├─ docs/                          # ANALIZ.md, TEKNIK_MIMARI_TASLAK.md, AI_CALISMA_GUNLUGU.md, DESIGN.md,
│                                    KULLANICI_KILAVUZU.md, DEMO_SENARYOSU.md, FINAL_AUDIT.md
├─ prompts/                       # Numaralandırılmış görev promptları (00 → 41)
├─ docker-compose.yml             # PostgreSQL + backend API için local evaluation topology
├─ .env.example                   # Docker ortam değişkeni şablonu (placeholder, gerçek secret içermez)
└─ PROJECT.md                     # Projenin kaynak-of-truth context dosyası
```

## Docker ile Çalıştırma (Önerilen — Local Değerlendirme)

Projeyi tek makinede, PostgreSQL kurulumu veya `dotnet`/`user-secrets` konfigürasyonu yapmadan ayağa kaldırmanın en hızlı yolu Docker Compose'dur. Backend container'ı başlarken bekleyen migration'ları otomatik uygular; ayrıca `dotnet ef database update` çalıştırmanız gerekmez.

**Gereksinim:** Docker Desktop (veya Docker Engine + Compose plugin).

### 1. `.env` dosyasını oluşturun

```bash
cp .env.example .env
```

PowerShell karşılığı:

```powershell
Copy-Item .env.example .env
```

### 2. `.env` içindeki placeholder değerleri doldurun

- `POSTGRES_PASSWORD`: kendi seçtiğiniz local bir parola.
- `JWT_KEY`: en az 32 karakter/byte uzunluğunda rastgele bir değer (API bundan kısa bir key ile başlamayı reddeder). Üretmek için: `openssl rand -base64 32` (macOS/Linux) veya PowerShell'de `[Convert]::ToBase64String((1..32 | % { Get-Random -Max 256 }))`.
- `AI_API_KEY`: gerçek bir OpenAI API anahtarınız varsa girin; yoksa placeholder'ı olduğu gibi bırakabilirsiniz — uygulamanın auth/gelir/gider/bütçe/fatura/dashboard/recurring özellikleri bundan etkilenmez, yalnızca AI endpointleri mevcut fallback davranışını kullanır.

**`.env` dosyasını asla commit etmeyin** — `.gitignore` içinde zaten hariç tutulmuştur.

### 3. Container'ları başlatın

```bash
docker compose up --build
```

Bu komut PostgreSQL'i (healthcheck ile) ve backend API'yi build edip başlatır; API, PostgreSQL sağlıklı hale gelene kadar başlamaz ve açılışta 3 migration'ı (`InitialCreate`, `AddBillExpenseLink`, `AddRecurringFinancialRecords`) otomatik uygular.

### 4. API erişimi

- Host makineden (tarayıcı, Postman, `curl`): `http://localhost:8080`
- Swagger UI (varsayılan `.env.example` ayarıyla, `ASPNETCORE_ENVIRONMENT=Development` iken): `http://localhost:8080/swagger`
- Health check: `http://localhost:8080/health`

### 5. Android Emulator Bağlantısı

Flutter uygulamasını Docker'daki API'ye bağlamak için Android emulator'den şu adres kullanılmalıdır (host'un `localhost`'una karşılık gelir):

```bash
cd mobile
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

Özet:

| Ortam | Adres |
|---|---|
| Browser / host makine | `http://localhost:8080` |
| Android emulator | `http://10.0.2.2:8080` |

### 6. Container'ları durdurma

```bash
docker compose down
```

Bu komut **veriyi silmez** — `postgres_data` named volume korunur, bir sonraki `docker compose up` aynı veriyle devam eder.

### 7. Veritabanı dahil tamamen sıfırlama

```bash
docker compose down -v
```

**Dikkat:** `-v` bayrağı `postgres_data` volume'unu da siler; tüm local evaluation verisi kalıcı olarak kaybolur.

### Troubleshooting

```bash
docker compose logs -f api        # backend loglarını canlı izle
docker compose logs -f postgres   # PostgreSQL loglarını canlı izle
docker compose ps                 # container/health durumunu göster
```

## Manuel Kurulum (Docker kullanmadan)

Docker yerine backend'i doğrudan `dotnet` ile, Flutter'ı da doğrudan cihaz/emulator üzerinde çalıştırmak isterseniz aşağıdaki adımları izleyin.

## Gereksinimler

- .NET 8 SDK
- PostgreSQL (yerel veya erişilebilir bir sunucu)
- Flutter SDK (`environment: sdk: ">=3.8.0 <4.0.0"`)
- Android Studio / bir Android emulator veya fiziksel cihaz (mobil test için)
- Bir OpenAI API anahtarı (AI özellikleri için; anahtar olmadan da uygulamanın temel özellikleri — auth, gelir/gider, bütçe, fatura, dashboard — çalışır, yalnızca AI çağrıları başarısız/unavailable döner)

## PostgreSQL Kurulumu

1. Yerel veya erişilebilir bir PostgreSQL sunucusu hazırlayın.
2. SmartBudget için boş bir veritabanı oluşturun (örn. `smartbudget_dev`).
3. Bağlantı dizesini kaynak koda **yazmayın** — bir sonraki bölümdeki `dotnet user-secrets` ile ayarlayın.

## Backend Konfigürasyonu — `dotnet user-secrets`

`backend/SmartBudget.Api/appsettings.json` içindeki hassas alanlar (`ConnectionStrings:DefaultConnection`, `Jwt:Key`, `AI:ApiKey`) **boş placeholder** olarak bırakılmıştır ve repository'ye gerçek değerler asla commit edilmemelidir. Development ortamında `dotnet user-secrets` kullanın:

```bash
cd backend/SmartBudget.Api
dotnet user-secrets init
dotnet user-secrets set "ConnectionStrings:DefaultConnection" "<YOUR_CONNECTION_STRING>"
dotnet user-secrets set "Jwt:Key" "<YOUR_JWT_KEY>"
dotnet user-secrets set "AI:ApiKey" "<YOUR_OPENAI_API_KEY>"
```

Örnek bağlantı dizesi biçimi (gerçek kullanıcı adı/parola ile kendiniz doldurun):

```text
Host=localhost;Port=5432;Database=smartbudget_dev;Username=<YOUR_DB_USERNAME>;Password=<YOUR_DB_PASSWORD>
```

`Jwt:Key`, yeterince uzun (en az 32+ karakter), rastgele üretilmiş bir imzalama anahtarı olmalıdır. Production'da bu değerler kaynak koddan tamamen ayrı bir secret store / environment variable mekanizmasıyla sağlanmalıdır.

## AI Key Konfigürasyonu

AI özellikleri (`POST /api/ai/categorize-expense`, `POST /api/ai/monthly-summary`) `AI:ApiKey` konfigürasyon değerini kullanır. Bu değer yalnızca backend tarafında okunur; Flutter uygulamasına hiçbir zaman gönderilmez veya gömülmez. Anahtarınız yoksa AI endpointleri kontrollü bir fallback/unavailable sonucu döner — bu, uygulamanın diğer özelliklerini (auth, gelir/gider, bütçe, fatura, dashboard, recurring kayıtlar) etkilemez.

## Backend Çalıştırma

```bash
cd backend/SmartBudget.Api
dotnet restore
dotnet run
```

Varsayılan development adresi: `http://localhost:5259`

## Migration

```bash
cd backend/SmartBudget.Api
dotnet ef database update
```

Mevcut migration'lar:

1. `InitialCreate`
2. `AddBillExpenseLink`
3. `AddRecurringFinancialRecords`

Yeni bir migration oluşturmanız gerekirse:

```bash
dotnet ef migrations add <MigrationName>
```

## Flutter Çalıştırma

```bash
cd mobile
flutter pub get
flutter run
```

### Android Emulator Base URL

Flutter varsayılan olarak Android emulator'den backend'e şu adresle bağlanır:

```text
http://10.0.2.2:5259
```

(`10.0.2.2`, Android emulator içinden host makinenin `localhost`'una karşılık gelir.) Farklı bir ortam için (iOS simulator, fiziksel cihaz) base URL'i derleme zamanında geçersiz kılabilirsiniz:

```bash
flutter run --dart-define=API_BASE_URL=http://localhost:5259
```

## Test Komutları

**Backend:**

```bash
cd backend/SmartBudget.Api.Tests
dotnet build
dotnet test
```

**Flutter:**

```bash
cd mobile
dart format lib test
flutter analyze
flutter test
```

## Build Komutları

**Backend (release build):**

```bash
cd backend/SmartBudget.Api
dotnet build -c Release
```

**Flutter (debug APK):**

```bash
cd mobile
flutter build apk --debug
```

## Güvenlik Notları

- `UserId` hiçbir API request body'sinde kabul edilmez; kullanıcı kimliği her istekte yalnızca JWT claim'inden okunur.
- Başka bir kullanıcıya ait kayda erişim denemesi `403 Forbidden` yerine `404 Not Found` döner — bu, kaydın var olup olmadığının dahi sızdırılmamasını sağlar.
- Parolalar düz metin olarak saklanmaz; güvenli biçimde hash'lenir.
- JWT imzalama anahtarı ve OpenAI API anahtarı yalnızca `dotnet user-secrets` (development) veya bir secret store/environment variable (production) üzerinden sağlanır; kaynak koda veya repository'ye asla yazılmaz.
- AI'a yalnızca ilgili işlevin ihtiyaç duyduğu minimum veri gönderilir (örn. aylık analiz için ham işlem kayıtları değil, backend tarafından zaten hesaplanmış özet değerler).
- AI çıktıları güvenilmeyen veri olarak ele alınır: kategori önerisi sabit bir whitelist ile, aylık analiz metni ise teknik alan adı/JSON/`null` sızıntısına karşı backend tarafında doğrulanır; geçersiz/şüpheli çıktı kullanıcıya aynen gösterilmez.
- Production ortamında API hata yanıtlarında stack trace veya iç altyapı bilgisi gösterilmez.
- Docker Compose ile çalıştırırken PostgreSQL parolası, JWT anahtarı ve OpenAI API anahtarı yalnızca `.env` dosyası üzerinden environment variable olarak geçirilir; hiçbir gerçek secret `docker-compose.yml`, `Dockerfile` veya `.env.example` içine yazılmaz. `.env` `.gitignore` içinde hariç tutulmuştur ve container loglarına secret basılmaz.



## Son Doğrulama

- Backend: **292/292 test başarılı**
- Flutter: **161/161 test başarılı**
- `flutter analyze`: **No issues found**
- Docker Compose smoke test: **başarılı**
- PostgreSQL container: **healthy**
- API container: **healthy**
