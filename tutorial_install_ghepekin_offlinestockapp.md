# Tutorial Install `GhepekIn-OfflineStockApp` dengan `git clone`

Panduan ini menjelaskan cara mengambil source code dari GitHub, menyiapkan environment Flutter, lalu menjalankan aplikasi sampai bisa **build** dan **run** di Android.

Repo yang dipakai:
```bash
https://github.com/Partykel/GhepekIn-OfflineStockApp.git
```

## 1) Persiapan awal

Sebelum clone repo, pastikan kamu sudah punya:

- Git
- Flutter SDK
- Android Studio
- Android SDK + Android Emulator, atau HP Android yang sudah aktif USB debugging

Repo ini adalah project Flutter dengan folder utama `android/`, `lib/`, dan `test/`, jadi kamu memang perlu environment Flutter untuk menjalankannya.

## 2) Install Git

Kalau Git belum ada, install dulu dari situs resmi Git.

Setelah itu cek di terminal:

```bash
git --version
```

Kalau muncul versi Git, berarti sudah siap.

## 3) Install Flutter

Download dan pasang Flutter SDK dari dokumentasi resmi Flutter.

Setelah install, cek dengan:

```bash
flutter --version
flutter doctor
```

`flutter doctor` dipakai untuk mengecek apakah Flutter, Android toolchain, dan device sudah siap.

## 4) Install Android Studio

Install Android Studio, lalu pastikan plugin Flutter dan Dart sudah aktif.

Langkah singkatnya:

1. Buka Android Studio
2. Masuk ke **Settings / Preferences**
3. Buka **Plugins**
4. Cari **Flutter**
5. Install Flutter plugin
6. Ikuti prompt untuk install Dart plugin jika diminta
7. Restart Android Studio

Setelah itu buka **SDK Manager** dan pastikan komponen Android SDK, platform Android, dan build tools sudah terpasang.

## 5) Clone repository

Buka terminal di folder tempat kamu ingin menyimpan project, lalu jalankan:

```bash
git clone https://github.com/Partykel/GhepekIn-OfflineStockApp.git
```

Masuk ke folder project:

```bash
cd GhepekIn-OfflineStockApp
```

## 6) Buka project di Android Studio

Di Android Studio:

1. Klik **Open**
2. Pilih folder `GhepekIn-OfflineStockApp`
3. Tunggu proses indexing selesai

Kalau Android Studio minta sinkronisasi Flutter, biarkan selesai dulu.

## 7) Ambil dependency Flutter

Di root project, jalankan:

```bash
flutter pub get
```

Perintah ini akan membuat folder `.dart_tool/` secara lokal. Folder ini tidak perlu di-push ke GitHub karena sifatnya hasil generate.

## 8) Cek environment dengan `flutter doctor`

Jalankan:

```bash
flutter doctor
```

Kalau ada tanda `[!]` atau `[x]`, baca pesan error-nya. Biasanya yang perlu diperbaiki adalah:

- Android SDK belum lengkap
- license Android belum diterima
- emulator belum dibuat
- device belum terdeteksi

Kalau perlu, terima license Android dengan:

```bash
flutter doctor --android-licenses
```

## 9) Siapkan device untuk run

Kamu punya 2 opsi:

### Opsi A — Android Emulator

1. Buka Android Studio
2. Masuk ke **Device Manager**
3. Buat emulator baru jika belum ada
4. Jalankan emulator

### Opsi B — HP Android fisik

1. Aktifkan **Developer Options**
2. Aktifkan **USB debugging**
3. Hubungkan HP ke laptop dengan kabel USB
4. Pastikan HP muncul di daftar device

Cek device yang terhubung dengan:

```bash
flutter devices
```

## 10) Jalankan aplikasi

Setelah dependency aman dan device sudah terdeteksi, jalankan:

```bash
flutter run
```

Kalau ada lebih dari satu device, pilih device yang kamu mau dari daftar yang muncul.

## 11) Build aplikasi Android

Kalau aplikasi sudah bisa jalan dan kamu ingin build file APK, gunakan:

```bash
flutter build apk
```

Hasil build akan muncul di folder generate lokal `build/`, dan folder itu memang sebaiknya tidak ikut masuk GitHub.

Kalau ingin build release APK:

```bash
flutter build apk --release
```

## 12) Kalau mau buka dari Android Studio dan run langsung

Setelah project terbuka:

1. Pilih device emulator atau HP yang aktif
2. Klik tombol **Run**
3. Tunggu proses build selesai

Android Studio akan membuat file kerja lokal seperti `.idea/` dan folder build saat dibutuhkan. Itu normal.

## 13) Kalau muncul error

### Error `flutter pub get` gagal

Biasanya karena:
- koneksi internet bermasalah
- versi package tidak cocok
- ada dependency yang belum terunduh

Coba ulang:

```bash
flutter pub get
```

### Error device tidak terdeteksi

Coba:

```bash
flutter devices
```

Kalau device tidak muncul:
- cek emulator sudah hidup
- cek USB debugging
- cek driver USB di Windows jika pakai HP

### Error Android license

Jalankan:

```bash
flutter doctor --android-licenses
```

Lalu ketik `y` untuk semua lisensi.

## 14) Ringkasan cepat

Urutan paling aman:

```bash
git clone https://github.com/Partykel/GhepekIn-OfflineStockApp.git
cd GhepekIn-OfflineStockApp
flutter pub get
flutter doctor
flutter run
```

Kalau ingin build APK:

```bash
flutter build apk
```

## 15) Catatan penting soal file yang tidak masuk repo

Folder seperti `build/`, `.dart_tool/`, dan `.idea/` akan muncul di lokal saat kamu menjalankan project atau membuka Android Studio. Itu normal. Folder-foler itu tidak perlu di-push ke GitHub karena isinya hasil generate dan konfigurasi lokal.

## 16) Penutup

Kalau semua langkah di atas berhasil, artinya project sudah:

- berhasil di-clone
- dependency sudah terpasang
- environment Flutter siap
- aplikasi sudah bisa di-run
- APK bisa di-build

Kalau mau, langkah berikutnya adalah menambahkan screenshot, deskripsi fitur, dan struktur folder ke README supaya repo terlihat lebih rapi dan mudah dinilai.
