# PiCourse - Özel Ders Platformu API

Öğrenciler ile eğitmenleri buluşturan Django REST Framework tabanlı bir API.

## Özellikler

- **Kullanıcı Yönetimi**: Öğrenci ve Eğitmen kayıtları, role dayalı kimlik doğrulama
- **Ders Konu Yönetimi**: Özel ders için ders konularının yönetimi
- **Eğitmen Profilleri**: Biyografi, saatlik ücret, puanlama ve konu uzmanlığı
- **Öğrenci Profilleri**: Sınıf seviyesi bilgisi
- **Ders Talepleri**: Öğrenciler ders talebi oluşturabilir, eğitmenler onaylayabilir veya reddedebilir
- **JWT Kimlik Doğrulama**: JSON Web Token ile güvenli API erişimi
- **Role Dayalı Yetkilendirme**: Öğrenci ve eğitmen için farklı erişim seviyeleri
- **API Dokümantasyonu**: Swagger/OpenAPI dökümantasyonu

## Teknoloji Yığını

- **Backend**: Django 5.2.5 + Django REST Framework
- **Kimlik Doğrulama**: JWT (djangorestframework-simplejwt)
- **Dokümantasyon**: drf-spectacular (Swagger/OpenAPI)
- **Veritabanı**: SQLite (geliştirme), PostgreSQL (canlı ortam)
- **Filtreleme**: Gelişmiş sorgulama için django-filter

## Kullanılan Kütüphaneler ve Nedenleri

### **Core Django Kütüphaneleri**
- **Django 5.2.5**: Ana web framework - güvenilir, güncel ve production-ready
- **Django REST Framework 3.14.0**: API geliştirme için standart Django eklentisi

### **Authentication & Security**
- **djangorestframework-simplejwt 5.3.0**: JWT token tabanlı kimlik doğrulama - stateless, scalable ve mobile app'ler için ideal
- **django-cors-headers**: Cross-Origin Resource Sharing desteği - frontend ve mobile app'lerden API'ye erişim için gerekli

### **API Documentation & Schema**
- **drf-spectacular 0.27.0**: OpenAPI 3.0 şeması ve Swagger UI - profesyonel API dokümantasyonu için endüstri standardı

### **Data Filtering & Querying**
- **django-filter 23.5**: Gelişmiş filtreleme ve arama özellikleri - eğitmen listesinde subject, rating ve search filtreleri için

### **Utilities**
- **pytz 2023.3**: Timezone desteği - ders taleplerinde tarih/saat yönetimi için

### **Development & Testing**
- **SQLite**: Development database - hızlı geliştirme ve test için
- **Docker**: Containerization - tutarlı development environment ve deployment için

Bu kütüphaneler seçildi çünkü:
- **Production-ready**: Endüstri standardında, güvenilir
- **Django ecosystem**: Birbiriyle uyumlu, iyi entegre
- **Performance**: N+1 problem çözümü, optimize edilmiş queries
- **Developer Experience**: Swagger UI, rate limiting, comprehensive testing

## Kurulum

### Yöntem 1: Docker ile (Önerilen)

1. **Depoyu klonla**
   ```bash
   git clone <repository-url>
   cd piCourse
   ```

2. **Docker servislerini başlat**
   ```bash
   make up
   ```

3. **Veritabanını migrate et**
   ```bash
   make shell
   python manage.py migrate
   ```

4. **Örnek verilerle veritabanını doldur**
   ```bash
   python manage.py seed_data
   exit
   ```

5. **Tarayıcıda aç**
   ```
   http://localhost:8000
   ```

### Yöntem 2: Manuel Kurulum

1. **Depoyu klonla**
   ```bash
   git clone <repository-url>
   cd piCourse
   ```

2. **Sanal ortam oluştur**
   ```bash
   python -m venv .venv
   source .venv/bin/activate  # Windows: .venv\Scripts\activate
   ```

3. **Bağımlılıkları yükle**
   ```bash
   pip install -r requirements.txt
   ```

4. **Migrasyonları çalıştır**
   ```bash
   python manage.py makemigrations
   python manage.py migrate
   ```

5. **Süper kullanıcı oluştur (isteğe bağlı)**
   ```bash
   python manage.py createsuperuser
   ```

6. **Örnek verilerle veritabanını doldur**
   ```bash
   python manage.py seed_data
   ```

7. **Geliştirme sunucusunu çalıştır**
   ```bash
   python manage.py runserver
   ```

### Docker Komutları

```bash
make up        # Servisleri başlat
make down      # Servisleri durdur
make build     # Docker image'ları oluştur
make logs      # Logları görüntüle
make shell     # Web container'ına eriş
```

## API Uç Noktaları

### Kimlik Doğrulama
- `POST /api/auth/register/` - Kullanıcı kaydı (öğrenci/eğitmen)
- `POST /api/auth/login/` - Kullanıcı girişi (JWT)

### Kullanıcı Profili
- `GET /api/me/` - Mevcut kullanıcı profilini getir
- `PATCH /api/me/` - Mevcut kullanıcı profilini güncelle

### Ders Konuları
- `GET /api/subjects/` - Tüm ders konularını listele

### Eğitmenler
- `GET /api/tutors/` - Filtreleme ve arama ile eğitmenleri listele
- `GET /api/tutors/{id}/` - Eğitmen detayını getir

### Ders Talepleri
- `POST /api/lesson-requests/` - Ders talebi oluştur (sadece öğrenciler)
- `GET /api/lesson-requests/` - Kullanıcının ders taleplerini listele
- `PATCH /api/lesson-requests/{id}/` - Ders talebinin durumunu güncelle (sadece eğitmenler)

### Dokümantasyon
- `/api/docs/` - Swagger UI
- `/api/redoc/` - ReDoc dokümantasyonu
- `/api/schema/` - OpenAPI şeması

## Beklenen API Örnekleri

### Kayıt
```
POST /api/auth/register
{
  "email": "ali@picourse.com",
  "password": "Passw0rd!",
  "role": "student"
}
```

---

### Giriş (JWT)
```
POST /api/auth/login
{
  "email": "ali@picourse.com",
  "password": "Passw0rd!"
}
```
**Yanıt (200):**
```json
{
  "access": "<jwt>",
  "refresh": "<jwt>"
}
```

---

### Eğitmen Listesi
```
GET /api/tutors?subject=2&ordering=-rating&search=physics
```
**Yanıt (200):**
```json
{
  "count": 2,
  "results": [
    {
      "id": 5,
      "name": "Dr. Ayşe Demir",
      "subjects": [
        { "id": 2, "name": "Physics" }
      ],
      "hourly_rate": 500,
      "rating": 4.8,
      "bio": "ODTÜ fizik doktora ..."
    }
  ]
}
```

---

### Ders Talebi Oluşturma (öğrenci)
```
POST /api/lesson-requests
Authorization: Bearer <access>
{
  "tutor_id": 5,
  "subject_id": 2,
  "start_time": "2025-08-15T10:00:00Z",
  "duration_minutes": 60,
  "note": "Kuantum girişi"
}
```

---

### Talebi Onaylama (eğitmen)
```
PATCH /api/lesson-requests/12
Authorization: Bearer <access>
{
  "status": "approved"
}
```

## Filtreleme ve Arama

### Eğitmenler Uç Noktası
- **Konuya göre filtrele**: `GET /api/tutors/?subject=1`
- **Arama**: `GET /api/tutors/?search=math`
- **Puana göre sırala**: `GET /api/tutors/?ordering=-rating`
- **Filtreleri birleştir**: `GET /api/tutors/?subject=1&search=math&ordering=-rating`

### Ders Talepleri Uç Noktası
- **Role göre filtrele**: `GET /api/lesson-requests/?role=student`
- **Duruma göre filtrele**: `GET /api/lesson-requests/?status=pending`

## Testler

Testleri çalıştır:
```bash
python manage.py test
```

Test kapsamı şunları içerir:
- Kullanıcı kaydı ve kimlik doğrulama
- Role dayalı yetkilendirme
- Ders talebi oluşturma ve yönetme
- API uç noktalarının işlevselliği

## Örnek Veriler

`seed_data` komutu şunları oluşturur:
- **5 Ders Konusu**: Matematik, Fizik, Kimya, İngilizce, Tarih
- **2 Öğrenci**: John Doe (10. sınıf), Jane Smith (11. sınıf)
- **3 Eğitmen**: Dr. Alice Johnson (Matematik/Fizik), Prof. Bob Wilson (Kimya), Ms. Carol Brown (İngilizce/Tarih)
- **3 Ders Talebi**: Test amaçlı farklı durumlar

## Geliştirme

### Proje Yapısı
```
piCourse/
├── core/                    # Ana uygulama
│   ├── models.py            # Veri modelleri
│   ├── views.py             # API görünümleri
│   ├── serializers.py       # Veri dönüştürücüler
│   ├── urls.py               # URL yönlendirmeleri
│   ├── admin.py              # Admin paneli
│   ├── tests.py              # Test senaryoları
│   └── management/           # Yönetim komutları
│       └── commands/
│           └── seed_data.py
├── piCourse/                 # Proje ayarları
│   ├── settings.py           # Django ayarları
│   └── urls.py               # Ana URL yapılandırması
├── requirements.txt          # Python bağımlılıkları
└── README.md                 # Bu dosya
```

### Yeni Özellik Ekleme
1. `core/models.py` içine model oluştur
2. `core/serializers.py` içine serializer ekle
3. `core/views.py` içine view ekle
4. `core/urls.py` içinde URL tanımla
5. `core/tests.py` içine test ekle
6. `core/admin.py` içinde admin panelini güncelle

## Güvenlik Özellikleri

- JWT tabanlı kimlik doğrulama
- Role dayalı erişim kontrolü
- Girdi doğrulama ve temizleme
- CSRF koruması
- Güvenli parola yönetimi

## Canlı Ortam Kurulumu

1. `DEBUG = False` ayarla
2. Hassas ayarlar için ortam değişkenleri kullan
3. Uygun veritabanını yapılandır (PostgreSQL önerilir)
4. Statik dosya servislerini ayarla
5. HTTPS yapılandır
6. Üretim için WSGI sunucusu kullan (Gunicorn gibi)

## Katkıda Bulunma

1. Depoyu forkla
2. Yeni bir özellik dalı aç
3. Değişikliklerini yap
4. Yeni işlevler için test ekle
5. Pull request gönder

## Destek

Sorular ve destek için GitHub üzerinde bir issue açabilirsiniz.
