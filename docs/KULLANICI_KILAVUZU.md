# SmartBudget AI — Kullanıcı Kılavuzu

Bu kılavuz, SmartBudget AI mobil uygulamasını teknik bilgisi olmayan bir kullanıcı için baştan sona açıklar. Ekran adları ve akışlar mevcut uygulamayla birebir uyumludur.

## Uygulamaya Kayıt

1. Uygulamayı açtığınızda karşınıza **Giriş** ekranı gelir. Hesabınız yoksa alttaki "Kayıt Ol" bağlantısına dokunun.
2. E-posta adresinizi ve en az 8 karakterli bir parola girin.
3. Kayıt işlemi tamamlandığında Giriş ekranına yönlendirilirsiniz.
4. Aynı e-posta adresiyle daha önce kayıt olunmuşsa sistem size bunu bildirir; farklı bir e-posta ile tekrar deneyin.

## Giriş

1. Kayıt olduğunuz e-posta ve parolayı girip "Giriş Yap" butonuna dokunun.
2. Bilgileriniz doğruysa uygulama ana ekranlarına (Ana Sayfa, İşlemler, Bütçeler, Faturalar, Profil) yönlendirilirsiniz.
3. İlk kez giriş yapıyorsanız uygulama size kısa bir tanıtım turu (walkthrough) gösterir; bu turu istediğiniz zaman sağ üstteki `?` butonundan tekrar açabilirsiniz.
4. Parolanız yanlışsa uygulama size anlaşılır bir hata mesajı gösterir; hesabınıza erişim sağlanmaz.

## Dashboard (Ana Sayfa)

Ana Sayfa, o ayki genel finansal durumunuzu tek bakışta gösterir:

- Toplam gelir, toplam gider ve bakiyeniz,
- Kategori bazlı harcama dağılımınız,
- Bütçe kullanım durumunuz (normal, uyarı veya aşım),
- Bir önceki aya göre harcama değişiminiz,
- Son 6 aylık harcama trendi grafiği.

Bu değerler her zaman sunucu tarafından hesaplanır; telefonunuz herhangi bir toplama işlemi yapmaz. Gelir/gider ekleyip sildiğinizde veya bir fatura oluşturduğunuzda Ana Sayfa'ya döndüğünüzde rakamlar otomatik olarak güncel halini gösterir — ekranı elle yenilemeniz gerekmez, ancak isterseniz aşağı çekerek de (pull-to-refresh) yenileyebilirsiniz.

## Gelir Ekleme

1. İşlemler sekmesine gidip "Gelir Ekle" butonuna dokunun.
2. Tutarı ve isterseniz kısa bir açıklama girin, tarihi seçin.
3. Kaydettiğinizde gelir listenizde görünür ve Ana Sayfa'daki toplam gelire hemen yansır.
4. Bir gelir kaydını silmek isterseniz, İşlemler listesinden ilgili kaydı seçip silebilirsiniz.

## Gider Ekleme

1. İşlemler sekmesinden "Gider Ekle" butonuna dokunun.
2. Tutarı, açıklamayı ve tarihi girin.
3. Bir kategori seçin (Market, Ulaşım, Fatura, Eğlence, Sağlık, Eğitim, Kira, Diğer) — kategoriyi kendiniz seçebilir veya AI'dan öneri isteyebilirsiniz (aşağıya bakın).
4. Kaydettiğinizde gider hem İşlemler listesinde hem de Ana Sayfa'daki toplamlarda ve ilgili bütçenizin kullanım oranında görünür.

## AI Kategori Önerisi

1. Gider eklerken açıklama alanına ne için harcadığınızı yazın (örn. "market alışverişi").
2. "AI ile Öner" (veya karşılık gelen) kontrolüne dokunduğunuzda uygulama açıklamanızı analiz ederek size bir kategori önerisi sunar.
3. Öneriyi kabul edip etmemek tamamen size aittir; istediğiniz zaman farklı bir kategori seçebilirsiniz. AI hiçbir zaman kategoriyi sizin adınıza zorunlu olarak seçmez.
4. AI önerisi bir nedenle gelmezse (bağlantı sorunu, zaman aşımı vb.) gider eklemeye manuel kategori seçerek devam edebilirsiniz; bu durum gider kaydetmenizi engellemez.

## Bütçe Oluşturma

1. Bütçeler sekmesinden "Yeni Bütçe Ekle" butonuna dokunun.
2. Bir kategori, ay/yıl ve pozitif bir tutar limiti girin.
3. Aynı kategori ve aynı ay/yıl için zaten aktif bir bütçeniz varsa uygulama ikinci bir bütçe oluşturmanıza izin vermez.
4. Bütçe listenizde her kategori için harcadığınız tutarı, kullanım yüzdesini ve durumu (normal, %80 ve üzeri uyarı, %100 ve üzeri aşım) görebilirsiniz.
5. Bir bütçenin yalnızca limit tutarını sonradan güncelleyebilir veya bütçeyi tamamen silebilirsiniz.

## Fatura Ekleme

1. Faturalar sekmesinden "Fatura Ekle" butonuna dokunun.
2. Fatura türünü seçin: Elektrik, Su veya Doğalgaz.
3. Tutarı ve fatura tarihini girin; tüketim değerini (kWh veya m³) girmek isteğe bağlıdır.
4. Faturayı kaydettiğinizde uygulama otomatik olarak buna karşılık gelen bir gider kaydı da oluşturur; bu sayede fatura harcamanız Ana Sayfa'daki toplam giderinize ve varsa "Fatura" kategorisi bütçenize otomatik yansır — ayrıca ikinci bir işlem yapmanıza gerek yoktur.
5. Bir faturayı sildiğinizde, ona bağlı oluşan gider kaydı da otomatik olarak silinir.

## Fatura Trendleri

Faturalar ekranında, seçtiğiniz fatura türü (Elektrik/Su/Doğalgaz) için son 6 aylık tutar ve tüketim değişimini grafik olarak görebilirsiniz. Seçtiğiniz türde hiç veri yoksa uygulama boş/sıfır satırlar yerine "Son 6 ay için fatura verisi yok." mesajını gösterir.

## Tekrarlayan Gelir

Her ay düzenli olarak aldığınız bir maaş veya gelir varsa bunu yalnızca bir kez tanımlayabilirsiniz:

1. Gelir ekleme ekranında "Tekrarlama" bölümünü açın.
2. Başlangıç tarihini (örn. 16 Ağustos) ve isterseniz kaç ay süreceğini girin.
3. Kaydettiğinizde bu kural, seçtiğiniz günün her ay tekrarı olarak "Planlananlar" görünümünde listelenir.

**Önemli:** Tanımladığınız bu gelir, her ayın ilgili gününde sizin herhangi bir işlem yapmanıza gerek kalmadan otomatik olarak gerçek bir gelir kaydına dönüşür ve Ana Sayfa'daki toplamlarınıza yansır.

## Tekrarlayan Gider

Kira gibi her ay ödediğiniz sabit bir gideri de aynı şekilde tanımlayabilirsiniz:

1. Gider ekleme ekranında "Tekrarlama" bölümünü açıp tutarı, kategoriyi ve başlangıç tarihini girin.
2. Kaydettiğinizde kural "Planlananlar" görünümünde listelenir.

Tutarı belli olduğu için bu gider de, ilgili ayın günü geldiğinde sizin bir işlem yapmanıza gerek kalmadan otomatik olarak gerçek bir gider kaydına dönüşür.

## Tekrarlayan Fatura

Elektrik, su veya doğalgaz faturanız her ay düzenli olarak geliyorsa, fatura ekleme ekranından bir tekrarlama tanımlayabilirsiniz. İki durum vardır:

- **Tutar her ay aynıysa** (sabit tutarlı fatura): tutarı da girerseniz, fatura her ay otomatik olarak oluşturulur.
- **Tutar her ay değişiyorsa** (örn. tüketime göre değişen elektrik faturası): tutarı boş bırakabilirsiniz. Bu durumda aşağıdaki "Tutarı bilinmeyen faturayı girme" bölümü geçerli olur.

## Planlananlar

İşlemler ve Faturalar ekranlarındaki "Planlananlar" görünümünde tanımladığınız tüm tekrarlayan kuralları görebilirsiniz. Her kural için:

- Tutar ve tekrar günü (örn. "Her ayın 16'sında"),
- Bir sonraki gerçekleşme tarihi,
- Durum: **Bekleniyor** (bu ay için henüz gerçekleşmedi) veya **Gerçekleşti** (bu ay için zaten gerçek bir kayıt oluştu)

bilgileri gösterilir. Bu durum bilgisi her zaman sunucudan gelir; telefonunuz kendi başına bir hesaplama yapmaz.

## Otomatik Gerçekleşme

SmartBudget AI'nin en önemli kolaylıklarından biri budur: **tekrarlayan bir kayıt tanımladıktan sonra, her ay tekrar bir butona basmanız gerekmez.**

Örneğin "her ayın 16'sı, 45.000 TL maaş" şeklinde bir kural tanımladıysanız, ayın 16'sı geldiğinde sistem bu geliri sizin için kendiliğinden oluşturur ve Ana Sayfa'daki toplamlarınıza ekler. Siz uygulamayı o gün açmasanız bile, bir sonraki girişinizde veya Ana Sayfa'yı yenilediğinizde güncel durumu görürsünüz.

Bu otomatik gerçekleşme; tutarı belli olan gelirler, giderler ve sabit tutarlı faturalar için geçerlidir. Tutarı önceden bilinmeyen faturalar (örn. değişken elektrik faturası) otomatik oluşturulmaz — bunun nedeni aşağıda açıklanmıştır.

## Tutarı Bilinmeyen Faturayı Girme

Tutarını önceden girmediğiniz bir tekrarlayan fatura kuralınız varsa, sistem sizin adınıza sahte veya 0 TL'lik bir fatura **oluşturmaz**. Bunun yerine ilgili ay için kural "Bu ay girilmesi bekleniyor" durumunda kalır.

1. Faturalar ekranındaki "Planlananlar" bölümünde bu kuralı bulun.
2. "Faturayı Gir" butonuna dokunun.
3. Gerçek tutarı (ve isterseniz tüketim değerini) girip kaydedin.
4. Kaydettiğinizde gerçek fatura ve buna bağlı gider kaydı normal şekilde oluşturulur; Ana Sayfa'ya yansır.

## Aylık AI Analizi

1. Ana Sayfa'da "AI Aylık Analizi" bölümüne/butonuna dokunun.
2. Uygulama, o ay için zaten hesapladığı gerçek rakamları (toplam gelir, gider, bütçe kullanımı, kategori dağılımı vb.) AI'ya göndererek bunları sade ve anlaşılır bir Türkçe metinle özetlemesini ister.
3. AI yalnızca size sunulan gerçek rakamları yorumlar; kendi başına yeni bir rakam üretmez, yatırım tavsiyesi vermez ve olmayan bir veri hakkında tahminde bulunmaz.
4. AI servisine bir nedenle ulaşılamazsa, Ana Sayfa'daki hesaplanmış rakamlar ve grafikler yine de görünür kalır; yalnızca AI yorumunun o an oluşturulamadığı belirtilir.

## Tutorial'ı Tekrar Açma

İlk kullanım turunu (walkthrough) daha sonra tekrar görmek isterseniz, Ana Sayfa, İşlemler, Bütçeler, Faturalar veya Profil ekranlarının sağ üst köşesindeki `?` (Yardım) butonuna dokunun. Tur baştan başlar ve size gerçek ekranlar üzerinde ilgili özelliği vurgulayarak gösterir. Bu işlem herhangi bir veri oluşturmaz veya mevcut ayarlarınızı değiştirmez.

## Çıkış

Profil sekmesinden "Çıkış Yap" seçeneğine dokunduğunuzda oturumunuz sonlandırılır ve güvenli biçimde saklanan oturum bilginiz cihazdan silinir. Tekrar giriş yaptığınızda tanıtım turu otomatik olarak tekrar açılmaz (isterseniz `?` butonundan manuel açabilirsiniz); tüm gelir, gider, bütçe, fatura ve tekrarlayan kayıtlarınız korunmuş olarak sizi bekler.
