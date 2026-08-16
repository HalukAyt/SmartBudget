# SmartBudget AI Mobile

Flutter istemcisi Android ve iOS hedefleri için yapılandırılmıştır.

## Development API URL

Varsayılan URL Android emülatörü için `http://10.0.2.2:5259` değeridir.
iOS simülatörü veya farklı bir geliştirme sunucusu için URL çalışma anında verilir:

```text
flutter run --dart-define=API_BASE_URL=http://localhost:5259
```

Gerçek cihazda bilgisayarın erişilebilir yerel ağ adresi kullanılmalıdır. Production
ortamında HTTPS URL verilmelidir; repository içinde deployment adresi veya secret yoktur.

## Doğrulama

```text
flutter pub get
dart format .
flutter analyze
flutter test
flutter build apk --debug
```
