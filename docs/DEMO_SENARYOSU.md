# SmartBudget AI — Demo Senaryosu

Toplam süre: ~5 dakika. Aşağıdaki adımlar sırasıyla uygulanır; her adımın altında demo sırasında sözlü olarak anlatılabilecek kısa teknik notlar bulunur.

## Happy Path (Mutlu Senaryo)

### 1. Login

Kayıtlı bir test kullanıcısıyla giriş yapılır.

> **Not:** Kimlik JWT ile doğrulanır; token `flutter_secure_storage` içinde güvenli saklanır. `UserId` hiçbir zaman istemciden gönderilmez — her istek JWT claim'inden okunur.

### 2. Dashboard

Ana Sayfa açılır; toplam gelir, gider, bakiye, kategori dağılımı ve bütçe durumu gösterilir.

> **Not:** Bu rakamlar tamamen backend'de hesaplanır (`DashboardService`); Flutter herhangi bir toplama işlemi yapmaz.

### 3. Tekrarlayan Maaş Göster

Planlananlar görünümünde, önceden tanımlanmış bir "her ayın X'i, Y TL maaş" recurring kuralı ve durumu (Bekleniyor/Gerçekleşti) gösterilir.

> **Not:** Bu kural zamanı geldiğinde kullanıcı hiçbir işlem yapmadan backend'de çalışan `RecurringRuleRealizationHostedService` tarafından Europe/Istanbul takvimine göre otomatik gerçekleştirilir; manuel "Bu Ay İçin Oluştur" butonuna artık gerek yoktur.

### 4. Gider + AI Kategori Önerisi

Yeni bir gider eklenir (örn. "market alışverişi", 350 TL). Açıklama girildikten sonra AI kategori önerisi istenir; önerilen kategori (Market) gösterilir ve kabul edilir.

> **Not:** AI yalnızca tanımlı kategori whitelist'inden (Market, Ulaşım, Fatura, Eğlence, Sağlık, Eğitim, Kira, Diğer) seçim yapabilir; öneri her zaman kullanıcı onayına tabidir, otomatik/zorunlu değildir.

### 5. Budget

Bütçeler ekranında Market kategorisi için tanımlı aylık bütçe ve az önce eklenen giderin kullanım yüzdesine hemen yansıdığı gösterilir.

> **Not:** Kullanım yüzdesi backend'de `spent / limit` ile hesaplanır; %80'de "Warning", %100'de "Exceeded" durumu üretilir.

### 6. Bill (Fatura)

Faturalar ekranından yeni bir elektrik faturası eklenir (tutar + opsiyonel tüketim).

> **Not:** Bill oluşturulurken aynı işlem içinde otomatik olarak bağlı bir Expense de oluşturulur (`Expense.BillId`); bu, Bill → Expense senkronizasyonudur.

### 7. Bill → Expense Etkisini Dashboard'da Göster

Ana Sayfa'ya dönülüp toplam giderin, az önce eklenen fatura tutarı kadar arttığı gösterilir.

> **Not:** Dashboard, Bill'i ayrıca ikinci kez toplamaz — yalnızca Bill'den otomatik oluşan Expense üzerinden hesap yapar; bu double counting'i mimari olarak imkânsız kılar.

### 8. AI Aylık Analizi

Ana Sayfa'dan AI aylık analiz çalıştırılır; backend'in hesapladığı rakamların sade, kullanıcı dostu bir Türkçe yorumu gösterilir.

> **Not:** AI'a yalnızca backend'in zaten hesapladığı özet veri gönderilir (ham işlem kayıtları değil); çıktı, teknik alan adı/JSON/`null` sızıntısına karşı backend'de ayrıca doğrulanır.

### 9. Planlanan vs. Gerçekleşen Mantığını Göster

Planlananlar görünümüne tekrar dönülüp, henüz tekrar günü gelmemiş bir kural ("Bekleniyor") ile bu ay zaten gerçekleşmiş bir kural ("Gerçekleşti") yan yana gösterilir.

> **Not:** Planlanan (recurring) kayıtlar hiçbir zaman gelecekteki actual kayıtları toplu olarak önceden oluşturmaz; Dashboard yalnızca gerçekleşmiş (actual) kayıtlardan hesaplanır — planlanan kayıtlar Dashboard toplamına asla dahil edilmez.

## Hata Senaryosu

**Tutarı bilinmeyen faturanın otomatik gerçekleşmediğini göster:** Tutarı boş bırakılmış (Amount=null) bir tekrarlayan doğalgaz faturası kuralı seçilir. Kuralın ilgili ay için "Bu ay girilmesi bekleniyor" durumunda kaldığı, sahte veya 0 TL'lik bir faturanın **oluşturulmadığı** gösterilir. Ardından "Faturayı Gir" butonuyla gerçek tutar girilip fatura + bağlı gider oluşturulur.

> **Not:** Bu, sistemin bilerek "veri uydurmama" ilkesini gösterir — tutar bilinmediği sürece backend hiçbir zaman tahmini/sahte bir finansal kayıt üretmez.

*(Alternatif hata senaryoları: aynı kategori/ay/yıl için ikinci bir bütçe oluşturmayı denemek — sistem reddeder; veya bir gider alanını boş/negatif bırakarak validation hatası göstermek.)*
