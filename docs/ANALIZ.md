# SmartBudget AI — Analiz Dokümanı

> **Doküman durumu:** İlk AI taslağıdır; insan incelemesi ve onayı gerektirir.  
> **Revizyon durumu:** İnsan incelemesi sonrası hazırlanan ikinci AI sürümüdür.  
> **Ana kaynak:** `PROJECT.md`  
> **Kapsam yaklaşımı:** Bu doküman MVP gereksinimlerini esas alır. Opsiyonel özellikler, MVP tamamlandıktan sonra ayrıca değerlendirilmek üzere kapsamdan ayrılmıştır.

## 1. Problem Tanımı

Kullanıcıların gelir, gider, kategori bütçesi ve temel ev faturası verileri farklı yerlerde tutulabildiği için aylık mali durumlarını bütüncül biçimde takip etmeleri zorlaşmaktadır. Harcamaların elle kategorize edilmesi ek çaba gerektirir; kategori limitlerine yaklaşma veya bu limitleri aşma durumu zamanında fark edilmeyebilir. Elektrik, su ve doğalgaz faturalarının tutar ve tüketim değişimleri ile aylık harcama eğilimleri de ham veriler üzerinden kolay anlaşılmayabilir.

SmartBudget AI bu problemi, kullanıcının kendi finansal kayıtlarını tek bir mobil uygulamada izlemesini; uygulama tarafından hesaplanan sonuçları grafikler, bütçe uyarıları ve kontrollü AI yorumlarıyla anlamasını sağlayarak ele alır. AI yardımcıdır; finansal hesaplama, doğrulama, yetkilendirme veya nihai karar mekanizması değildir.

## 2. Projenin Amacı

Projenin amacı kullanıcının:

- Gelir ve giderlerini kaydetmesi, listelemesi ve silebilmesi,
- Giderlerini tanımlı kategoriler bazında takip edebilmesi,
- Gider kategorisini manuel seçebilmesi veya AI önerisinden yararlanabilmesi,
- Kategori bazında aylık bütçe limiti belirleyip kullanım oranını görebilmesi,
- Bütçesinin %80'ine ulaştığında ve bütçesini aştığında uygun uyarıyı görebilmesi,
- Elektrik, su ve doğalgaz faturalarını kaydedebilmesi,
- Aylık harcama, fatura ve tüketim eğilimlerini grafiklerle görebilmesi,
- Backend tarafından hesaplanan aylık verilerin AI tarafından oluşturulan anlaşılır yorumunu okuyabilmesi

sağlamaktır.

Projenin ikincil amacı, AI'ın geliştirme sürecindeki kullanımını kontrollü, izlenebilir ve insan tarafından denetlenebilir tutmaktır.

## 3. Hedef Kullanıcılar

- Kişisel veya aile bütçesini mobil ortamda takip etmek isteyen kullanıcılar,
- Gelir ve giderlerini kategori bazında izlemek isteyen kullanıcılar,
- Kategori bütçelerine yaklaşma ve aşma durumlarını görmek isteyen kullanıcılar,
- Elektrik, su ve doğalgaz faturalarının aylık tutar/tüketim eğilimlerini izlemek isteyen kullanıcılar,
- Ham finansal verileri değiştirmeyen, sade bir AI yorumundan yararlanmak isteyen kullanıcılar.

## 4. Fonksiyonel Gereksinimler

### 4.1 Kimlik doğrulama ve erişim

- **FR-01:** Kullanıcı e-posta ve en az 8 karakterli parola ile kayıt olabilmelidir.
- **FR-02:** Kayıtlı kullanıcı giriş yapabilmelidir.
- **FR-03:** Korunan işlevlere yalnızca kimliği doğrulanmış kullanıcı erişebilmelidir.
- **FR-04:** Kullanıcı yalnızca kendisine ait gelir, gider, bütçe ve fatura kayıtlarını görebilmeli, oluşturabilmeli, değiştirebilmeli veya silebilmelidir; ilgili işlevin desteklemediği işlemler bu gereksinimin dışındadır.

### 4.2 Gelir yönetimi

- **FR-05:** Kullanıcı pozitif tutarlı bir gelir kaydı ekleyebilmelidir.
- **FR-06:** Kullanıcı kendi gelir kayıtlarını listeleyebilmelidir.
- **FR-07:** Kullanıcı kendi gelir kaydını silebilmelidir.

### 4.3 Gider ve kategori yönetimi

- **FR-08:** Kullanıcı pozitif tutar, boş olmayan açıklama, tarih ve geçerli kategoriyle gider ekleyebilmelidir.
- **FR-09:** Kullanıcı kendi gider kayıtlarını listeleyebilmeli ve tek bir kaydın detayına erişebilmelidir.
- **FR-10:** Kullanıcı kendi gider kaydını silebilmelidir.
- **FR-11:** Sistem temel kategorileri sunmalıdır: Market, Ulaşım, Fatura, Eğlence, Sağlık, Eğitim, Kira ve Diğer.
- **FR-12:** Kullanıcı gider kategorisini manuel seçebilmelidir.
- **FR-13:** Sistem, gider açıklamasından hareketle AI destekli kategori önerebilmelidir.
- **FR-14:** AI yalnızca tanımlı kategori listesinden seçim yapmalı; yeni kategori oluşturmamalıdır. Confidence değeri doğrulanmalı ancak zorunlu kabul eşiği uygulanmamalı; kategori kabul kararı yalnızca yanıtın geçerli JSON olması ve kategorinin whitelist içinde bulunmasına dayanmalıdır.
- **FR-15:** AI yanıtı geçersiz, boş, zaman aşımına uğramış veya erişilemez olduğunda kullanıcı manuel kategori seçerek gider işlemine devam edebilmelidir.

### 4.4 Bütçe yönetimi ve uyarılar

- **FR-16:** Kullanıcı kategori, ay ve yıl için pozitif tutarlı aylık bütçe oluşturabilmelidir.
- **FR-17:** Aynı kullanıcı, kategori, ay ve yıl için birden fazla aktif bütçe oluşturamamalıdır.
- **FR-18:** Kullanıcı kendi bütçelerini görüntüleyebilmeli, güncelleyebilmeli ve silebilmelidir.
- **FR-19:** Sistem kategori bütçesinin kullanım yüzdesini finansal kayıtlardan hesaplamalıdır.
- **FR-20:** Kullanım oranı %80 veya üzerindeyken uyarı, %100 veya üzerindeyken aşım durumu gösterilmelidir.

### 4.5 Fatura ve tüketim takibi

- **FR-21:** Kullanıcı elektrik, su veya doğalgaz türünde, `Amount > 0` koşulunu sağlayan fatura kaydı ekleyebilmelidir. `ConsumptionValue` MVP'de opsiyonel olmalı; sağlandığında elektrik için kWh, su ve doğalgaz için m³ birimiyle ele alınmalıdır.
- **FR-22:** Kullanıcı kendi faturalarını listeleyebilmeli ve silebilmelidir.
- **FR-23:** Sistem aylık fatura tutarı ve tüketim eğilimlerini varsayılan olarak son 6 ayı kapsayan grafiklerle göstermelidir.

### 4.6 Dashboard ve aylık analiz

- **FR-24:** Dashboard aylık gelir, gider ve ilgili özet verilerini göstermelidir.
- **FR-25:** Sistem toplam aylık gelir, toplam aylık gider, kategori bazlı gider, bütçe kullanım oranı, geçen aya göre değişim, en fazla harcama yapılan kategori ve en fazla artış gösteren kategori gibi değerleri uygulama mantığıyla hesaplamalıdır.
- **FR-26:** Aylık harcama ve fatura/tüketim eğilimleri varsayılan olarak son 6 ayı kapsayan grafiklerle sunulmalıdır.
- **FR-27:** AI, yalnızca backend tarafından hesaplanan aylık verileri değiştirmeden ve olmayan verileri tahmin etmeden anlaşılır biçimde yorumlamalıdır.
- **FR-28:** AI aylık analiz hizmeti başarısız olduğunda temel hesaplanan veriler ve grafikler erişilebilir kalmalıdır.

### 4.7 Kullanıcı durumları ve hata yönetimi

- **FR-29:** Mobil uygulama veri yüklenirken loading, veri yokken empty ve işlem başarısızken error durumu göstermelidir.
- **FR-30:** Doğrulama ve API hataları kullanıcıya anlaşılır biçimde sunulmalıdır; production ortamında stack trace gösterilmemelidir.

### 4.8 Tekrarlayan (Recurring) Finansal Kayıtlar, Otomatik Gerçekleşme ve Fatura-Gider Senkronizasyonu

- **FR-31:** Bill oluşturulduğunda (manuel veya otomatik gerçekleşme yoluyla) kendisine bağlı tam olarak bir Expense kaydı da oluşturulmalıdır (Bill → Expense senkronizasyonu). Dashboard yalnızca bu Expense üzerinden hesap yapmalı; Bill ayrıca ikinci kez toplanmamalıdır.
- **FR-32:** Bill silindiğinde bağlı Expense kaydı da silinmelidir; Bill'e bağlı bir Expense, İşlemler ekranından bağımsız olarak silinememelidir.
- **FR-33:** Kullanıcı gelir, gider veya sabit tutarlı fatura için aylık tekrarlama (başlangıç tarihi, opsiyonel süre/bitiş tarihi) tanımlayabilmelidir.
- **FR-34:** Tutarı belli olan (Income, Expense veya sabit tutarlı Bill) recurring kurallar, başlangıç tarihinin günü tekrar günü olarak Europe/Istanbul takviminde geldiğinde backend tarafından otomatik olarak gerçekleştirilmelidir; kullanıcının bunun için manuel bir işlem yapması gerekmemelidir.
- **FR-35:** Tutarı bilinmeyen (Amount=null) recurring Bill kuralları otomatik gerçekleştirilmemelidir; ilgili ay için "due" (girilmesi bekleniyor) durumda kalmalı ve kullanıcı gerçek tutarı (ve varsa tüketim değerini) manuel olarak girerek gerçekleştirmelidir.
- **FR-36:** Aynı recurring kural için aynı takvim ayında en fazla bir gerçek kayıt oluşturulabilmelidir; arka plan servisi birden fazla kez çalışsa veya eşzamanlı çalışsa bile ikinci kayıt oluşmamalıdır.
- **FR-37:** Planlanan recurring kayıtlar, gelecekteki actual finansal kayıtları toplu olarak önceden oluşturmamalıdır; her kural yalnızca ilgili ay geldiğinde tek bir gerçek kayıt üretmelidir.
- **FR-38:** Backend süreci geçici olarak kapalıyken kaçırılan güncel günün/ayın due kaydı, süreç yeniden başladığında (ilgili occurrence henüz oluşturulmamışsa) hemen tamamlanmalıdır; geçmiş ayların tamamı geriye dönük olarak keyfi biçimde doldurulmamalıdır.
- **FR-39:** Tekrar günü ilgili ayda yoksa (örn. 29, 30 veya 31), o ayın son günü tekrar günü olarak kullanılmalıdır.
- **FR-40:** Kullanıcı "Planlananlar" görünümünde her recurring kural için Bekleniyor/Gerçekleşti durumunu ve bir sonraki gerçekleşme tarihini görebilmelidir; bu bilgi backend tarafından hesaplanıp sunulmalı, Flutter tarafında yeniden hesaplanmamalıdır.

> **Planned vs. Actual — temel kural:** Planlanan recurring kayıtlar gelecekteki actual (gerçekleşmiş) finansal kayıtları topluca oluşturmaz. Income, Expense ve sabit tutarlı Bill kuralları due olduğunda backend tarafından otomatik olarak gerçekleştirilir. Tutarı bilinmeyen Bill kuralları ise due durumda kalır ve kullanıcı gerçek tutarı girer. Dashboard her koşulda yalnızca gerçekleşmiş (actual) finansal kayıtlardan hesaplanır; planlanan/due durumdaki kayıtlar Dashboard toplamlarına hiçbir biçimde dahil edilmez.

## 5. Fonksiyonel Olmayan Gereksinimler

- **NFR-01 — Güvenlik:** Parolalar en az 8 karakter olmalı; düz metin tutulmamalı ve güvenli biçimde hash'lenmelidir.
- **NFR-02 — Yetkilendirme:** Korunan kaynaklarda kimlik ve kayıt sahipliği her istekte kontrol edilmelidir. Request body içindeki `UserId` güvenilir kabul edilmemelidir.
- **NFR-03 — Gizlilik:** Hassas veriler loglanmamalı; AI servisine gereksiz kişisel veri gönderilmemelidir.
- **NFR-04 — Secret yönetimi:** AI API anahtarı mobil uygulamaya verilmemeli, kaynak koda veya repository'ye yazılmamalıdır.
- **NFR-05 — Dayanıklılık:** AI servisindeki hata temel gelir, gider, bütçe, fatura ve dashboard işlevlerini durdurmamalıdır.
- **NFR-06 — Veri doğruluğu:** Toplam, yüzde, fark ve trend hesaplamaları AI tarafından değil, uygulamanın kontrolündeki backend mantığıyla yapılmalıdır.
- **NFR-07 — AI doğrulaması:** AI çıktıları güvenilmeyen veri olarak ele alınmalı; format, boş değer, izinli kategori ve gerekli sınırlar doğrulanmalıdır.
- **NFR-08 — Kullanılabilirlik:** Mobil ekranlarda yükleniyor, hata ve boş durumları açıkça gösterilmelidir.
- **NFR-09 — Test edilebilirlik:** Kimlik doğrulama, doğrulama, sahiplik, bütçe eşikleri, fatura ve AI fallback davranışları test edilebilir olmalıdır.
- **NFR-10 — İzlenebilirlik:** Önemli AI promptları ve kritik insan müdahaleleri proje çalışma kayıtlarında saklanmalıdır.
- **NFR-11 — Bakım yapılabilirlik:** İş kuralları arayüz/taşıma katmanından ayrılmalı ve mevcut çalışan özellikler yeni eklemeler sırasında gereksiz biçimde değiştirilmemelidir.
- **NFR-12 — Tarih tutarlılığı:** Tarih ve aylık raporlama işlemlerinde Europe/Istanbul zaman dilimi esas alınmalıdır.
- **NFR-13 — Recurring zamanlama test edilebilirliği:** Recurring kayıtların otomatik gerçekleşme kararı doğrudan sunucu saatine (`DateTime.Now`/`UtcNow`) değil, test edilebilir bir zaman soyutlamasına dayanmalı ve Europe/Istanbul takvimine göre hesaplanmalıdır.

> **Varsayım V-01:** Ölçülebilir performans, erişilebilirlik ve servis kullanılabilirliği hedefleri `PROJECT.md` içinde tanımlanmamıştır; insan incelemesinde ayrıca netleştirilmelidir.

## 6. Kapsam

MVP kapsamı şunlardır:

- Kayıt olma, giriş yapma ve JWT tabanlı kimlik doğrulama,
- Gelir ekleme, listeleme ve silme,
- Gider ekleme, listeleme, detay görüntüleme ve silme,
- Sabit harcama kategorilerinin görüntülenmesi,
- Manuel ve AI destekli gider kategorileme,
- Aylık kategori bütçesi oluşturma, görüntüleme, güncelleme ve silme,
- Bütçe kullanım yüzdesi ile %80 uyarısı ve %100 aşım durumunun gösterimi,
- Elektrik, su ve doğalgaz faturası ekleme, listeleme ve silme,
- Bill oluşturulduğunda otomatik olarak bağlı bir Expense kaydı oluşturulması (Bill → Expense senkronizasyonu),
- Gelir, gider ve sabit tutarlı fatura için aylık tekrarlayan (recurring) kayıt tanımlama; tutarı belli olan kuralların backend tarafından otomatik gerçekleştirilmesi; tutarı bilinmeyen faturalar için manuel "Faturayı Gir" akışı,
- Aylık harcama ile fatura/tüketim trendlerinin grafiklerle gösterimi,
- Dashboard,
- AI destekli aylık harcama yorumu,
- Temel hata yönetimi, güvenlik kontrolleri ve test senaryoları,
- Login, Register, Dashboard, Expenses, Add Expense, Income, Add Income, Budgets, Bills ve AI Analysis ekranları. Splash ekranı mobil uygulama akışında bulunabilir ancak zorunlu bir MVP fonksiyonel gereksinimi değildir.

## 7. Kapsam Dışı

### 7.1 MVP dışında bırakılan opsiyonel özellikler

Aşağıdaki özellikler ancak MVP tamamlandıktan ve ayrıca onaylandıktan sonra değerlendirilebilir; bu taslakta uygulanacak gereksinim olarak kabul edilmemiştir:

- Fatura fotoğrafı yükleme,
- Fotoğraftan fatura tutarı veya tarihi okuma,
- OCR/Vision model entegrasyonu,
- Bildirim sistemi,
- PDF veya CSV dışa aktarma.

### 7.2 Proje kapsamı dışında olan özellikler

- Gerçek banka veya Open Banking entegrasyonu,
- Gerçek kredi kartı işlemleri,
- Para transferi,
- Banka hesabından otomatik işlem çekme,
- Muhasebe veya ERP entegrasyonu,
- Yatırım işlemleri,
- Finansal yatırım danışmanlığı.

## 8. Varsayımlar

- **V-01:** Performans, erişilebilirlik ve kullanılabilirlik için sayısal hedefler sonraki insan incelemesinde belirlenecektir.
- **V-02:** Bütçe uyarıları MVP'de uygulama içi durum/mesaj olarak gösterilecektir; ayrı bildirim sistemi opsiyonel kapsamda olduğundan push bildirim varsayılmamıştır.
- **V-03:** Gelir açıklamasının zorunlu olup olmadığı belirtilmemiştir; yalnızca gelir tutarının pozitif olma kuralı kesin kabul edilmiştir.
- **V-04:** AI kategori önerisinin kullanıcıya doğrudan öneri olarak mı gösterileceği, yoksa geçerli olduğunda önceden seçili mi geleceği belirtilmemiştir. Her iki durumda da manuel kategori seçimi korunmalıdır.
- **V-05:** Kullanıcı hesabı/parolası kurtarma, profil yönetimi ve hesap silme özellikleri tanımlanmadığı için MVP kapsamında varsayılmamıştır.

## 9. Kısıtlar

- Mobil uygulama Flutter/Dart, backend ASP.NET Core Web API/C#, veri tabanı PostgreSQL temellidir.
- Kimlik doğrulama JWT tabanlıdır.
- AI entegrasyonu yalnızca backend üzerinden yapılmalıdır; AI anahtarı mobil istemciye gönderilemez.
- Gider kategorileri sabit whitelist ile sınırlıdır; AI yeni kategori oluşturamaz.
- AI confidence değeri doğrulanır ancak zorunlu kabul eşiği kullanılmaz; kategori kabulü geçerli JSON ve category whitelist kontrolüne bağlıdır.
- Kullanıcı kimliği istemci tarafından gönderilen `UserId` değerinden alınamaz; doğrulanmış kullanıcı bağlamından belirlenmelidir.
- AI finansal hesaplama yapamaz ve uygulamanın hesapladığı rakamları değiştiremez.
- AI yatırım tavsiyesi veremez ve mevcut olmayan veri hakkında tahmin yapamaz.
- AI yanıtı doğrulanmadan kalıcı veriye dönüştürülemez.
- AI servisinin kullanılabilirliği temel uygulama işlevleri için bağımlılık olamaz.
- Fatura tutarı sıfırdan büyük olmalı; opsiyonel tüketim değeri elektrik için kWh, su ve doğalgaz için m³ birimiyle ele alınmalıdır.
- Trend grafikleri varsayılan olarak son 6 ayı göstermeli; tarih ve aylık raporlama işlemleri Europe/Istanbul zaman dilimini esas almalıdır.
- Recurring otomatik gerçekleştirme, ana ASP.NET Core sürecinin içinde çalışan sade bir hosted/background service ile yapılır; Hangfire, Quartz veya benzeri üçüncü parti scheduler/queue altyapısı kullanılmaz. Bu servis yalnızca backend process çalışırken işler; ayrı bir dış scheduler/cron altyapısı yoktur. Bu, tek instance'lı MVP için kabul edilmiş bir sınırdır.
- MVP'nin kapsamı, süre kalırsa değerlendirilecek opsiyonel özelliklerle genişletilemez.

## 10. Kullanıcı Hikâyeleri

- **UH-01:** Bir ziyaretçi olarak kayıt olmak istiyorum, böylece SmartBudget AI hesabı oluşturabilirim.
- **UH-02:** Bir kayıtlı kullanıcı olarak giriş yapmak istiyorum, böylece yalnızca bana ait bütçe verilerine erişebilirim.
- **UH-03:** Bir kullanıcı olarak gelirlerimi eklemek, listelemek ve silmek istiyorum, böylece aylık gelirimi takip edebilirim.
- **UH-04:** Bir kullanıcı olarak giderlerimi manuel kategoriyle eklemek, listelemek ve silmek istiyorum, böylece harcamalarımı kategori bazında takip edebilirim.
- **UH-05:** Bir kullanıcı olarak gider kategorisi için AI önerisi almak istiyorum, böylece manuel sınıflandırma çabam azalabilir.
- **UH-06:** Bir kullanıcı olarak AI kategorileme çalışmadığında kategoriyi manuel seçmek istiyorum, böylece gider kaydetmeye devam edebilirim.
- **UH-07:** Bir kullanıcı olarak kategori bazlı aylık bütçe oluşturmak ve yönetmek istiyorum, böylece harcama sınırlarımı takip edebilirim.
- **UH-08:** Bir kullanıcı olarak bütçe kullanım oranımı ve limit uyarılarımı görmek istiyorum, böylece limite yaklaşınca veya limiti aşınca durumu fark edebilirim.
- **UH-09:** Bir kullanıcı olarak elektrik, su ve doğalgaz faturalarımı kaydetmek, listelemek ve silmek istiyorum, böylece fatura geçmişimi takip edebilirim.
- **UH-10:** Bir kullanıcı olarak aylık harcama ve fatura/tüketim trendlerini grafiklerle görmek istiyorum, böylece değişimleri kolayca anlayabilirim.
- **UH-11:** Bir kullanıcı olarak dashboard üzerinde aylık finansal özetimi görmek istiyorum, böylece genel durumumu tek yerden değerlendirebilirim.
- **UH-12:** Bir kullanıcı olarak aylık harcamalarımın AI tarafından sade biçimde yorumlanmasını istiyorum, böylece hesaplanan verilerdeki önemli noktaları daha kolay anlayabilirim.
- **UH-13:** Bir kullanıcı olarak yalnızca kendi kayıtlarıma erişmek istiyorum, böylece finansal verilerim diğer kullanıcılardan korunur.
- **UH-14:** Bir kullanıcı olarak düzenli tekrar eden maaşımı/kira giderimi/faturamı bir kez tanımlamak istiyorum, böylece her ay tekrar manuel işlem yapmadan bu kayıtların zamanı geldiğinde otomatik oluşturulduğunu görebilirim.

## 11. Kullanıcı Hikâyeleri İçin Kabul Kriterleri

### UH-01 — Kayıt olma

**Senaryo: Başarılı kayıt**  
**Given** daha önce kullanılmamış bir e-posta ve en az 8 karakterli parola girilmişken  
**When** ziyaretçi kayıt işlemini gönderdiğinde  
**Then** kullanıcı hesabı oluşturulmalı ve parola düz metin olarak saklanmamalıdır.

**Senaryo: Kısa parola**  
**Given** ziyaretçi 8 karakterden kısa bir parola girmişken  
**When** kayıt işlemini gönderdiğinde  
**Then** kayıt reddedilmeli ve kullanıcı hesabı oluşturulmamalıdır.

**Senaryo: Yinelenen e-posta**  
**Given** e-posta daha önce kayıtlıyken  
**When** ziyaretçi aynı e-posta ile kayıt olmak istediğinde  
**Then** yeni hesap oluşturulmamalı ve anlaşılır bir hata gösterilmelidir.

### UH-02 — Giriş yapma

**Senaryo: Başarılı giriş**  
**Given** kullanıcı doğru e-posta ve parolayı sağlamışken  
**When** giriş isteği gönderildiğinde  
**Then** kimliği doğrulanmalı ve korunan işlevler için geçerli oturum/token sağlanmalıdır.

**Senaryo: Hatalı parola veya eksik token**  
**Given** parola yanlış veya korunan istekte token yokken  
**When** kullanıcı giriş yapmaya ya da korunan kaynağa erişmeye çalıştığında  
**Then** erişim reddedilmeli ve korunan veri döndürülmemelidir.

### UH-03 — Gelir yönetimi

**Senaryo: Gelir ekleme ve listeleme**  
**Given** kullanıcı giriş yapmış ve pozitif bir gelir tutarı girmişken  
**When** gelir kaydını oluşturup gelir listesini açtığında  
**Then** kayıt kendi gelirleri arasında doğru tutar ve tarih bilgisiyle görünmelidir.

**Senaryo: Gelir silme**  
**Given** kullanıcıya ait bir gelir kaydı varken  
**When** kullanıcı bu kaydı sildiğinde  
**Then** kayıt artık kullanıcının gelir listesinde görünmemelidir.

**Senaryo: Geçersiz tutar**  
**Given** gelir tutarı sıfır veya negatifken  
**When** kullanıcı kaydetmeye çalıştığında  
**Then** istek reddedilmeli ve gelir kaydı oluşturulmamalıdır.

### UH-04 — Manuel gider yönetimi

**Senaryo: Geçerli manuel kategoriyle gider ekleme**  
**Given** kullanıcı giriş yapmış; pozitif tutar, boş olmayan açıklama, tarih ve tanımlı bir kategori seçmişken  
**When** gideri kaydettiğinde  
**Then** gider kendi kayıtları arasında seçilen kategoriyle görünmelidir.

**Senaryo: Gider detayı ve silme**  
**Given** kullanıcıya ait bir gider kaydı varken  
**When** kullanıcı kaydın detayını görüntüleyip silme işlemini tamamladığında  
**Then** önce doğru detaylar gösterilmeli, silme sonrasında kayıt listeden kaldırılmalıdır.

**Senaryo: Geçersiz gider girdisi**  
**Given** tutar sıfır/negatif, açıklama boş veya kategori tanımsızken  
**When** kullanıcı gideri kaydetmeye çalıştığında  
**Then** istek reddedilmeli ve gider oluşturulmamalıdır.

### UH-05 — AI destekli gider kategorileme

**Senaryo: Geçerli AI önerisi**  
**Given** kullanıcı gider açıklaması sağlamış ve AI servisi geçerli JSON içinde whitelist'te bulunan bir kategori döndürmüşken  
**When** kategorileme sonucu işlendiğinde  
**Then** confidence için zorunlu eşik aranmadan öneri kullanıcıya sunulmalı ve yalnızca tanımlı kategorilerden biri kullanılmalıdır.

**Senaryo: Geçersiz confidence ile geçerli kategori**  
**Given** AI yanıtı geçerli JSON ve whitelist içinde bir kategori içerirken confidence değeri eksik, null, sayısal olmayan veya sınır dışıyken  
**When** kategorileme sonucu doğrulandığında  
**Then** confidence geçersiz olarak belirlenmeli ancak kategori yalnızca confidence nedeniyle reddedilmemelidir.

**Senaryo: Tanımsız kategori**  
**Given** AI “Coffee” gibi whitelist dışında bir kategori döndürmüşken  
**When** yanıt doğrulandığında  
**Then** yanıt reddedilmeli, yeni kategori oluşturulmamalı ve manuel seçim mümkün olmalıdır.

### UH-06 — AI kategorileme fallback'i

**Senaryo: Timeout, servis hatası veya geçersiz yanıt**  
**Given** AI yanıtı zaman aşımına uğramış, boş, parse edilemez veya beklenen formata aykırıyken  
**When** kullanıcı gider eklemeye devam ettiğinde  
**Then** uygulama çökmemeli, anlaşılır hata göstermeli ve kullanıcı manuel kategori seçerek gideri kaydedebilmelidir.

### UH-07 — Aylık kategori bütçesi yönetimi

**Senaryo: Bütçe oluşturma**  
**Given** kullanıcı kategori, ay, yıl ve pozitif limit belirlemiş ve aynı dönem/kategori için aktif bütçesi yokken  
**When** bütçeyi kaydettiğinde  
**Then** bütçe kendi bütçe listesinde görünmelidir.

**Senaryo: Yinelenen bütçe**  
**Given** aynı kullanıcı, kategori, ay ve yıl için aktif bütçe zaten varken  
**When** kullanıcı ikinci bir bütçe oluşturmaya çalıştığında  
**Then** istek reddedilmeli ve yinelenen aktif bütçe oluşturulmamalıdır.

**Senaryo: Bütçe güncelleme ve silme**  
**Given** kullanıcıya ait bir bütçe varken  
**When** kullanıcı geçerli bir limit ile güncellediğinde ve daha sonra sildiğinde  
**Then** önce yeni limit gösterilmeli, silme sonrasında bütçe listeden kaldırılmalıdır.

### UH-08 — Bütçe kullanım oranı ve uyarılar

**Senaryo: Uyarı eşiği**  
**Given** kategori harcaması aylık bütçenin en az %80'i, ancak %100'ünden azıyken  
**When** kullanım oranı hesaplanıp gösterildiğinde  
**Then** sistem “Warning” durumunu göstermelidir.

**Senaryo: Aşım eşiği**  
**Given** kategori harcaması aylık bütçenin %100'üne eşit veya daha fazlayken  
**When** kullanım oranı hesaplanıp gösterildiğinde  
**Then** sistem “Exceeded” durumunu göstermelidir.

### UH-09 — Fatura yönetimi

**Senaryo: Fatura ekleme ve listeleme**  
**Given** kullanıcı giriş yapmış; elektrik, su veya doğalgaz türünü, sıfırdan büyük tutarı ve fatura tarihini girmişken  
**When** faturayı kaydedip listeyi açtığında  
**Then** fatura kendi kayıtları arasında görünmelidir.

**Senaryo: Tüketim değeri olmadan fatura ekleme**  
**Given** kullanıcı geçerli fatura bilgileri girmiş ancak `ConsumptionValue` sağlamamışken  
**When** faturayı kaydettiğinde  
**Then** fatura başarıyla oluşturulmalıdır.

**Senaryo: Tüketim değerinin fatura türüne göre ele alınması**  
**Given** kullanıcı `ConsumptionValue` sağlamışken  
**When** elektrik, su veya doğalgaz faturası kaydedilip görüntülendiğinde  
**Then** tüketim değeri elektrik için kWh, su ve doğalgaz için m³ birimiyle ele alınmalıdır.

**Senaryo: Fatura silme**  
**Given** kullanıcıya ait bir fatura varken  
**When** kullanıcı faturayı sildiğinde  
**Then** fatura artık kendi listesinde görünmemelidir.

**Senaryo: Geçersiz fatura**  
**Given** fatura türü tanımsız veya tutar sıfır ya da negatifken  
**When** kullanıcı faturayı kaydetmeye çalıştığında  
**Then** istek reddedilmeli ve fatura oluşturulmamalıdır.

### UH-10 — Trend grafikleri

**Senaryo: Trend verisi mevcut**  
**Given** kullanıcıya ait son 6 aya yayılan harcama ve fatura/tüketim verisi varken  
**When** kullanıcı ilgili trend ekranını açtığında  
**Then** yalnızca kendi verilerinden ve Europe/Istanbul zaman dilimine göre oluşturulan son 6 aylık değişimler varsayılan grafiklerde gösterilmelidir.

**Senaryo: Trend verisi yok**  
**Given** seçilen görünüm için yeterli veri yokken  
**When** kullanıcı trend ekranını açtığında  
**Then** yanıltıcı grafik yerine uygun empty state gösterilmelidir.

### UH-11 — Dashboard

**Senaryo: Aylık özet**  
**Given** kullanıcının ilgili ayda gelir, gider ve bütçe kayıtları varken  
**When** dashboard açıldığında  
**Then** aylık özet yalnızca kullanıcının verileriyle ve Europe/Istanbul zaman dilimi esas alınarak uygulama tarafından hesaplanıp gösterilmelidir.

**Senaryo: Yükleme veya API hatası**  
**Given** dashboard isteği sürüyor veya başarısız olmuşken  
**When** ekran görüntülendiğinde  
**Then** uygun loading veya error state gösterilmelidir.

### UH-12 — AI aylık harcama analizi

**Senaryo: Başarılı yorum**  
**Given** backend aylık finansal metrikleri hesaplamış ve AI servisi geçerli bir yorum döndürmüşken  
**When** kullanıcı AI Analysis ekranını açtığında  
**Then** yorum hesaplanan rakamları değiştirmeden, olmayan veri eklemeden ve yatırım tavsiyesi vermeden gösterilmelidir.

**Senaryo: AI analiz hizmeti başarısız**  
**Given** AI servisi zaman aşımına uğramış, hata vermiş veya geçersiz yanıt döndürmüşken  
**When** kullanıcı aylık analizi görüntülediğinde  
**Then** uygulama çökmemeli, AI yorumunun üretilemediği belirtilmeli ve hesaplanan temel veriler erişilebilir kalmalıdır.

### UH-13 — Veri sahipliği

**Senaryo: Başka kullanıcı kaydına erişim**  
**Given** kimliği doğrulanmış kullanıcı başka bir kullanıcıya ait gelir, gider, bütçe veya fatura kimliğini biliyorken  
**When** bu kaydı görüntüleme, değiştirme veya silme isteği gönderdiğinde  
**Then** işlem reddedilmeli ve kaydın içeriği açığa çıkarılmamalıdır.

**Senaryo: Sahte UserId**  
**Given** kullanıcı istek gövdesine başka bir kullanıcıya ait `UserId` eklemişken  
**When** oluşturma veya erişim isteği işlendiğinde  
**Then** bu değer güvenilir kabul edilmemeli ve sahiplik doğrulanmış kullanıcı kimliğine göre belirlenmelidir.

### UH-14 — Tekrarlayan (recurring) kayıtlar ve otomatik gerçekleşme

**Senaryo: Otomatik gerçekleşme**
**Given** kullanıcı "her ayın 16'sı" tekrar günüyle 45.000 TL'lik bir maaş kuralı tanımlamışken
**When** Europe/Istanbul takviminde ayın 16'sı geldiğinde
**Then** kullanıcı herhangi bir buton işlemi yapmadan ilgili ay için gerçek bir Income kaydı otomatik olarak oluşturulmalı ve Dashboard'a yansımalıdır.

**Senaryo: Tutarı bilinmeyen fatura**
**Given** kullanıcı tutarı belirtilmeden (Amount=null) tekrarlayan bir doğalgaz faturası kuralı tanımlamışken
**When** ilgili ayın tekrar günü geldiğinde
**Then** sistem sahte/0 TL bir Bill oluşturmamalı; kural "girilmesi bekleniyor" durumunda kalmalı ve kullanıcı gerçek tutarı girdiğinde gerçek Bill (ve bağlı Expense) oluşturulmalıdır.

**Senaryo: Yinelenen otomatik gerçekleşme**
**Given** aynı recurring kural için ilgili ay zaten gerçekleştirilmişken
**When** arka plan servisi tekrar çalıştığında
**Then** aynı ay için ikinci bir gerçek kayıt oluşturulmamalıdır.

## 12. Temel Hata Senaryoları

| Kod | Senaryo | Beklenen davranış |
|---|---|---|
| H-01 | Kayıt sırasında e-posta zaten mevcut | Kayıt reddedilir, anlaşılır hata gösterilir. |
| H-02 | Girişte parola yanlış | Kimlik doğrulama başarısız olur, veri/token verilmez. |
| H-03 | Korunan istekte token yok veya geçersiz | `401 Unauthorized` karşılığı davranış uygulanır. |
| H-04 | Kullanıcı başka kullanıcı kaydına erişiyor | Erişim reddedilir; kayıt içeriği döndürülmez. |
| H-05 | Gelir/gider tutarı sıfır veya negatif | İstek doğrulama hatasıyla reddedilir. |
| H-06 | Gider açıklaması boş veya kategori geçersiz | Gider oluşturulmaz. |
| H-07 | Bütçe limiti sıfır/negatif veya bütçe yineleniyor | Bütçe oluşturma/güncelleme reddedilir. |
| H-08 | Fatura tutarı sıfır/negatif veya türü tanımsız | Fatura oluşturulmaz. |
| H-09 | AI kategorileme zaman aşımı veya servis hatası | Hata gösterilir; manuel kategori seçimiyle akış sürer. |
| H-10 | AI yanıtı boş, geçersiz JSON veya kategori whitelist dışında | Yanıt reddedilir; veritabanına kaydedilmez; fallback uygulanır. |
| H-11 | AI aylık analiz başarısız | Temel hesaplar ve grafikler çalışır; AI yorumu için hata durumu gösterilir. |
| H-12 | Genel API/ağ hatası | Uygulama çökmemeli; ilgili ekranda error state gösterilmelidir. |

## 13. Edge-case Senaryoları

- Bütçe kullanımı tam %80 olduğunda “Warning” gösterilmesi.
- Bütçe kullanımı tam %100 olduğunda “Exceeded” gösterilmesi; yalnızca warning olarak kalmaması.
- Harcamanın bütçeyi büyük oranda aşması durumunda kullanım yüzdesinin %100 ile yapay biçimde sınırlandırılmaması; aşımın anlaşılır gösterilmesi.
- Aynı kategori/ay/yıl bütçesinin eşzamanlı veya yinelenen isteklerle ikinci kez oluşturulmasının engellenmesi.
- Ay içinde gelir veya gider bulunmadığında toplamların kontrollü gösterilmesi ve AI'ın veri uydurmaması.
- Önceki ay verisi olmadığında “geçen aya göre değişim” için yanıltıcı oran üretilmemesi.
- Önceki ay değeri sıfırken değişim yüzdesinde sıfıra bölme yapılmaması.
- Kategori bütçesi tanımlı değilken bütçe kullanım oranı veya uyarısının varmış gibi gösterilmemesi.
- Birden fazla kategori aynı en yüksek tutara/artışa sahip olduğunda sonucun deterministik ve yanıltıcı olmayan biçimde sunulması. **Varsayım:** Eşitliklerin kullanıcıya nasıl gösterileceği netleştirilmelidir.
- AI yanıtında geçerli JSON ve whitelist içinde kategoriyle birlikte eksik, null, sayısal olmayan veya sınır dışı confidence bulunması halinde confidence değerinin geçersiz sayılması; kategorinin yalnızca bu nedenle reddedilmemesi.
- AI'ın büyük/küçük harf veya ek metin içeren, beklenen şemaya uymayan kategori yanıtının doğrulamadan geçmemesi.
- Kullanıcı AI isteği sürerken manuel kategori seçerse giderin tek kez ve kullanıcının nihai seçimiyle kaydedilmesi. **Varsayım:** Eşzamanlılık davranışı insan incelemesinde kesinleştirilmelidir.
- AI yanıtı kullanıcı ekrandan ayrıldıktan sonra gelirse hatalı veya çift kayıt oluşturulmaması.
- Silinmiş ya da başka kullanıcıya ait kayıt kimliğiyle detay/silme/güncelleme istendiğinde hiçbir veri sızıntısı olmaması.
- İstemcinin sahte `UserId` göndermesi halinde kaydın başka kullanıcıya bağlanmaması.
- Fatura tutarı sıfır olduğunda `Amount > 0` kuralı nedeniyle kaydın reddedilmesi.
- `ConsumptionValue` boş olduğunda geçerli faturanın oluşturulabilmesi; değer sağlandığında elektrik için kWh, su ve doğalgaz için m³ kullanılması.
- Europe/Istanbul zaman diliminde ay sonu ve yıl sonu sınırındaki kayıtların doğru raporlama ayına ve son 6 aylık trend aralığına dahil edilmesi.
- Çok uzun açıklama veya olağandışı karakter içeren girdilerin güvenli doğrulanması; AI prompt yapısını veya log güvenliğini bozmaması. **Varsayım:** Alan uzunluk sınırları belirlenmelidir.

## 14. AI Kullanılan Özellikler

### 14.1 Gider kategorisi önerme

AI, gider açıklamasını izinli kategorilerden biriyle eşleştirmek için kullanılır. Yanıt mümkünse yapılandırılmış formatta kategori ve confidence içerir. Uygulama:

- Yanıtı parse eder,
- Beklenen formatı ve boş değerleri kontrol eder,
- Kategoriyi whitelist ile doğrular,
- Confidence değerini doğrular,
- Confidence için zorunlu kabul eşiği uygulamaz ve geçersiz confidence değerini tek başına kategori ret nedeni yapmaz,
- Geçersiz yanıtı kalıcı veriye dönüştürmez,
- Timeout, servis hatası, boş/geçersiz yanıt veya izin dışı kategori halinde manuel seçim sunar.

AI yeni kategori oluşturamaz ve gider kaydetmenin zorunlu bağımlılığı olamaz.

### 14.2 Aylık harcama verilerini yorumlama

Backend toplam gelir/gider, kategori giderleri, bütçe kullanımı ve dönemsel değişimler gibi metrikleri hesaplar. AI yalnızca bu hazır veriyi kullanıcıya anlaşılır dille yorumlar. AI:

- Rakamları değiştiremez,
- Eksik veri hakkında tahmin üretemez,
- Finansal yatırım tavsiyesi veremez.

AI yanıtı üretilemez veya doğrulanamazsa hesaplanmış temel veriler ve grafikler gösterilmeye devam eder; yalnızca AI yorumunun mevcut olmadığı belirtilir.

### 14.3 Geliştirme sürecinde AI kullanımı

AI analiz, mimari/kod taslağı, refactoring önerisi, test senaryosu ve dokümantasyon taslağı üretmekte kullanılabilir. Bu çıktılar insan incelemesi olmadan kabul edilmez. Önemli promptlar ve kritik insan müdahaleleri ilgili proje kayıtlarında izlenir.

## 15. AI Kullanılmaması Gereken Alanlar

AI aşağıdaki alanlarda karar veya hesaplama mekanizması olarak kullanılmamalıdır:

- Toplam gelir/gider, yüzde, fark, trend ve bütçe kullanım hesapları,
- Girdi doğrulama ve iş kurallarının uygulanması,
- Kimlik doğrulama, JWT üretimi/doğrulaması ve yetkilendirme,
- Kayıt sahipliği kontrolü,
- Parola işleme, secret/API key yönetimi ve güvenlik kontrolleri,
- Bir AI yanıtının veritabanına kaydedilip kaydedilmeyeceğine ilişkin doğrulama,
- Yeni gider kategorisi oluşturma,
- Finansal yatırım tavsiyesi veya yatırım kararı verme,
- Kullanıcı adına para transferi, banka/kredi kartı işlemi veya başka finansal işlem yapma,
- Nihai teknik veya ürün kararlarını insan onayı olmadan verme.

## 16. Güvenlik ve Kişisel Veri Açısından Temel Riskler

| Risk | Olası etki | Temel kontrol |
|---|---|---|
| Kayıt sahipliği kontrolünün eksikliği (IDOR) | Başka kullanıcının gelir, gider, bütçe veya fatura verisinin görülmesi/değiştirilmesi/silinmesi | Kimliği JWT'den alma; her kaynakta sahiplik doğrulaması; istemci `UserId` değerine güvenmeme |
| Zayıf parola saklama | Hesapların ele geçirilmesi | Parolayı güvenli hash ile saklama; düz metin parola saklamama/loglamama |
| Geçersiz veya süresi dolmuş token kabulü | Yetkisiz erişim | Korunan işlevlerde doğrulanmış JWT ve authorization uygulama |
| AI API anahtarının sızması | Yetkisiz kullanım ve maliyet | Anahtarı yalnızca backend configuration/environment içinde tutma; mobil uygulamaya ve repository'ye koymama |
| Hassas verilerin loglanması | Finansal/kimlik verisi ifşası | Hassas alanları loglamama; production hata yanıtında stack trace göstermeme |
| AI servisine gereksiz kişisel veri gönderimi | Üçüncü taraf veri ifşası ve mahremiyet kaybı | Veri minimizasyonu; kategorilemede yalnızca gerekli içeriği, analizde yalnızca gerekli hesaplanmış verileri gönderme |
| Prompt injection veya kötü niyetli açıklama | AI'ın istenmeyen/şema dışı yanıt üretmesi | Kullanıcı girdisini güvenilmeyen veri sayma; çıktıyı katı şema ve whitelist ile doğrulama |
| AI halüsinasyonu veya rakam değiştirmesi | Yanlış finansal algı/karar | Hesapları backend'de yapma; AI çıktısını doğrulama; olmayan veriyi ve yatırım tavsiyesini reddetme |
| Geçersiz AI çıktısının doğrudan kaydı | Veri bütünlüğünün bozulması | Parse, null, sınır ve enum kontrollerinden sonra kabul; aksi halde fallback |
| Girdi doğrulama eksikliği | Hatalı/zararlı kayıtlar ve rapor bozulması | Tutar, açıklama, kategori, tür ve bütçe tekillik kurallarını backend'de doğrulama |
| Kullanıcılar arası verinin AI analizinde karışması | Ciddi finansal veri ihlali | AI girdisini oluşturmadan önce kullanıcı bazlı veri filtreleme ve sahiplik kontrolü |
| AI/ağ servis bağımlılığı | Temel uygulamanın kullanılamaması | Timeout ve hata yönetimi; manuel kategori ve AI'sız temel dashboard fallback'i |
| Kişisel veri saklama politikasının belirsizliği | Gereğinden uzun saklama ve mevzuat riski | **Varsayım:** Saklama, silme, açık rıza/aydınlatma ve ilgili mevzuat gereksinimleri insan/hukuk incelemesinde tanımlanmalıdır. |

## İnsan İncelemesinde Öncelikle Netleştirilecek Noktalar

Bu taslakta kesinleştirilmeyen ve kapsam genişletmeden ürün sahibi tarafından yanıtlanması gereken başlıca noktalar şunlardır:

1. Parola dışındaki alanların uzunluk sınırları,
2. Sayısal performans, erişilebilirlik ve kullanılabilirlik hedefleri,
3. Kişisel veri saklama, silme ve aydınlatma politikaları.

## Revizyon Özeti

- Fatura tutarı kuralı `Amount > 0` olarak güncellendi; `ConsumptionValue` opsiyonel yapıldı ve fatura türü bazlı ölçü birimleri belirtildi.
- AI confidence için zorunlu eşik kaldırıldı; kategori kabulü geçerli JSON ve whitelist kontrolüne bağlandı.
- Trend grafiklerinin varsayılan dönemi son 6 ay, tarih ve aylık raporlama zaman dilimi Europe/Istanbul olarak netleştirildi.
- Minimum parola uzunluğu 8 karakter olarak belirlendi.
- Splash ekranı zorunlu MVP fonksiyonel gereksinimlerinden çıkarıldı.
- İlgili varsayımlar, kısıtlar, kabul kriterleri, hata ve edge-case senaryoları tutarlı biçimde güncellendi.
- **16.08.2026 — Final dokümantasyon/audit revizyonu (`prompts/37_final_documentation_and_audit.txt`):** Bill → Expense senkronizasyonu (FR-31, FR-32) ve tekrarlayan (recurring) finansal kayıtlar / otomatik gerçekleşme (FR-33 – FR-40, NFR-13, UH-14) mevcut gerçek implementasyona göre dokümana eklendi. Planned-vs-actual ayrımı ("planlanan recurring kayıtlar gelecekteki actual kayıtları topluca oluşturmaz; Dashboard yalnızca gerçekleşmiş kayıtlardan hesaplanır") açıkça netleştirildi. Bu revizyon yalnızca dokümantasyon güncellemesidir; hiçbir kod/iş kuralı değiştirilmemiştir.
