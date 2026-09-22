# Ghepek.in

Aplikasi kasir digital offline untuk UMKM kuliner berbasis Flutter.

## Ringkasan fitur

- CRUD produk
- Penjualan multi-produk
- Pengeluaran operasional dan restock
- Stok otomatis berkurang/bertambah
- Dashboard pemasukan, pengeluaran, laba bersih
- Grafik tren 7 hari
- Laporan harian, mingguan, bulanan
- Notifikasi stok menipis dan defisit
- Riwayat transaksi dengan hapus dan restore stok
- Pencarian dan sorting produk, termasuk terlaris hari ini

## Teknologi

- Flutter
- Riverpod
- go_router
- SQLite via sqflite
- fl_chart
- flutter_local_notifications

## Struktur singkat

- `lib/core` — database, service notifikasi, utilitas
- `lib/features/product` — manajemen produk
- `lib/features/transaction` — penjualan, pengeluaran, riwayat
- `lib/features/dashboard` — ringkasan utama
- `lib/features/report` — laporan periode

## Cara menjalankan

```bash
git clone https://github.com/Partykel/GhepekIn-OfflineStockApp.git
cd GhepekIn-OfflineStockApp
flutter pub get
flutter run
```

## Build APK

```bash
flutter build apk
```

## Catatan implementasi

- Data disimpan lokal di SQLite.
- Stok dan histori transaksi dihitung dari data transaksi, bukan field total yang diredundansi.
- Penghapusan transaksi penjualan akan mengembalikan stok.
- Penghapusan pengeluaran kategori `Beli Stok` juga mengembalikan stok.

## Pengembangan lanjutan

Jika ingin melanjutkan ke versi berikutnya, kandidat yang paling masuk akal adalah:

- export backup
- pencarian laporan lebih detail
- filter riwayat berdasarkan tanggal
- printer struk
- sinkronisasi cloud
