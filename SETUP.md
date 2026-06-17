# Setup & Build Aplikasi Mobile CBT SMK HUTAMA

Aplikasi Flutter ini terhubung ke **database lewat REST API** (Next.js + PostgreSQL)
yang berjalan di server VPS. Tidak ada koneksi database langsung dari HP — semua via API.

## 1. Konfigurasi koneksi server

Default sudah mengarah ke server produksi (lihat `lib/core/constants/env.dart`):

```
API_BASE_URL = http://43.133.134.10/api
API_ORIGIN   = http://43.133.134.10
```

Untuk override (misal saat develop di emulator):

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api --dart-define=API_ORIGIN=http://10.0.2.2:3000
```

Kalau nanti server sudah pakai domain + HTTPS:

```bash
flutter build apk --dart-define=API_BASE_URL=https://cbt.smkhutama.sch.id/api --dart-define=API_ORIGIN=https://cbt.smkhutama.sch.id
```

## 2. Generate folder platform (Android/iOS)

Folder `android/` belum ada di project ini, jadi perlu di-generate sekali:

```bash
cd mobile
flutter create .
flutter pub get

# Generate ikon launcher dari logo SMK Hutama (assets/images/logo.png)
dart run flutter_launcher_icons

# Generate native splash screen (logo SMK Hutama, background putih)
dart run flutter_native_splash:create
```

## 3. Izinkan koneksi HTTP & atur nama aplikasi

Setelah folder `android/` dibuat, edit `android/app/src/main/AndroidManifest.xml`,
pada tag `<application ...>`:

```xml
<application
    android:label="SiHutama"
    android:usesCleartextTraffic="true"
    ... >
```

- `android:label` = nama yang tampil di bawah ikon aplikasi (HP).
- `android:usesCleartextTraffic="true"` diperlukan selama server masih HTTP.
  Setelah server pakai HTTPS, baris ini sebaiknya dihapus demi keamanan.

## 4. Jalankan / Build

```bash
# Jalankan di emulator / HP yang terhubung
flutter run

# Build APK rilis (terhubung ke server VPS default)
flutter build apk --release

# Hasil: build/app/outputs/flutter-apk/app-release.apk
```

## Catatan
- Nama aplikasi: **SiHutama** (CBT Ujian + Bimbingan Konseling).
- Ikon launcher & logo login memakai logo SMK Hutama (`assets/images/logo.png`).
- Login memakai akun yang sama dengan website (Siswa, Guru, Guru BK).
- Autentikasi memakai JWT (token disimpan aman di `flutter_secure_storage`).
- Tema: terang (light) sesuai permintaan.
- Fitur Siswa: dashboard, ujian (token + pengerjaan), nilai, dan **Bimbingan Konseling**
  (lihat poin, riwayat konseling, ajukan permohonan).
- Fitur Guru BK: dashboard (statistik + konseling terbaru), **Permohonan** (tanggapi/ubah status),
  dan daftar **Sesi Konseling**.
