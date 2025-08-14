## Pi Course Mobile (Flutter)

Basit bir MVP istemci. Backend: Django + DRF.

### Gereksinimler
- Flutter 3.22+ (Dart 3.8+)
- Android SDK (Android Studio / cmdline-tools)

### Yapı ve Teknolojiler
- State management: Riverpod
- Router: go_router
- HTTP: dio
- Model: json_serializable (şimdilik manuel model, generator gerektirmez)
- Token: flutter_secure_storage

### Çalıştırma
1) Backend’i çalıştırın (varsayılan `http://localhost:8000`). Android emülatörde `10.0.2.2` kullanılmalı.
2) Proje kökünde aşağıdaki komutu çalıştırın:

```bash
flutter pub get
flutter run --dart-define=BASE_URL=http://10.0.2.2:8000
```

Fiziksel cihazda/ios’ta backend IP’sini güncelleyin.

### Ekranlar
- Giriş/Kayıt
- Eğitmen Listesi (filtre/arama/sıralama)
- Eğitmen Detayı (Ders Talep Et)
- Ders Talebi Oluştur
- Taleplerim (öğrenci/tutor görünümü, tutor approve/reject)

### Notlar
- Basit hata gösterimleri `SnackBar` ile.
- JWT erişim token’ı `flutter_secure_storage` içinde saklanır.

