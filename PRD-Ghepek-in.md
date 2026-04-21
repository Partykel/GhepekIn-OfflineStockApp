# PRD: Ghepek.in — Aplikasi Kasir Digital UMKM Kuliner

| | |
|---|---|
| **Versi** | 2.0 |
| **Status** | Draft |
| **Terakhir Diperbarui** | April 2026 |
| **Platform** | Mobile Android — Flutter |
| **Tipe Proyek** | Tugas Kuliah / Prototype UMKM |

---

## Daftar Isi

1. [Executive Summary](#1-executive-summary)
2. [Goals & Success Metrics](#2-goals--success-metrics)
3. [User Persona & User Stories](#3-user-persona--user-stories)
4. [Functional Requirements](#4-functional-requirements)
5. [Non-Functional Requirements](#5-non-functional-requirements)
6. [Tech Stack](#6-tech-stack)
7. [Arsitektur Aplikasi](#7-arsitektur-aplikasi)
8. [Database Schema](#8-database-schema)
9. [Navigation Flow](#9-navigation-flow)
10. [Security Considerations](#10-security-considerations)
11. [Project Milestones](#11-project-milestones)
12. [Out of Scope](#12-out-of-scope)
13. [Dependencies (pubspec.yaml)](#13-dependencies-pubspecyaml)

---

## 1. Executive Summary

Ghepek.in adalah aplikasi kasir mobile berbasis Flutter yang dirancang khusus untuk pelaku UMKM kuliner skala kecil. Aplikasi ini menggantikan pencatatan keuangan manual (buku kas tulis) dengan sistem digital yang sederhana, cepat, dan dapat diakses kapan saja melalui smartphone.

**Masalah yang diselesaikan:**
- Pencatatan keuangan manual yang rawan salah hitung dan hilang
- Tidak ada visibilitas laba/rugi harian secara real-time
- Stok produk tidak terpantau — sering kehabisan tanpa disadari

**Solusi:**
- Input transaksi digital yang cepat (target < 30 detik per transaksi)
- Dashboard laba/rugi otomatis tanpa kalkulator manual
- Sistem pantau stok dengan notifikasi otomatis ketika menipis

Semua fitur berjalan **offline penuh** — data disimpan secara lokal di perangkat menggunakan SQLite, tidak memerlukan koneksi internet maupun server eksternal.

---

## 2. Goals & Success Metrics

| Goal | Metrik | Target |
|------|--------|--------|
| Menggantikan pencatatan manual | Jumlah transaksi tercatat per hari | ≥ 20 transaksi/hari |
| Mempercepat proses transaksi | Waktu input 1 transaksi | < 30 detik |
| Memberikan visibilitas keuangan | Akurasi kalkulasi laba/rugi di dashboard | 100% akurat |
| Kontrol stok | Notifikasi stok menipis tidak spam | Maks 1x notifikasi/produk/hari |
| Retensi pengguna | Pengguna aktif kembali di minggu ke-2 | ≥ 70% |

---

## 3. User Persona & User Stories

### Persona: Budi — Pemilik Warung Camilan

| Atribut | Detail |
|---------|--------|
| Usia | 28 tahun |
| Pekerjaan | Pemilik tunggal Ghepek.in |
| Pain points | Salah hitung rekap harian, tidak tahu produk terlaris, sering kehabisan stok |
| Goals | Tahu untung/rugi setiap hari tanpa perlu latar belakang akuntansi |
| Kemampuan teknologi | Bisa pakai smartphone, belum pernah pakai aplikasi kasir |

---

### User Stories

| ID | Sebagai... | Saya ingin... | Agar... | Prioritas |
|----|-----------|--------------|---------|-----------|
| US-01 | Pemilik | Mencatat transaksi penjualan dengan cepat | Tidak ada penjualan yang terlewat | 🔴 High |
| US-02 | Pemilik | Melihat total pemasukan & pengeluaran hari ini | Saya tahu kondisi keuangan real-time | 🔴 High |
| US-03 | Pemilik | Melihat laba bersih otomatis | Tidak perlu hitung manual dengan kalkulator | 🔴 High |
| US-04 | Pemilik | Mencatat pengeluaran (beli bahan/operasional) | Perhitungan laba lebih akurat | 🔴 High |
| US-05 | Pemilik | Menambah, mengedit, dan menghapus produk | Data produk selalu up-to-date | 🔴 High |
| US-06 | Pemilik | Memantau jumlah stok setiap produk | Saya tidak kehabisan barang dagangan | 🔴 High |
| US-07 | Pemilik | Mencatat restok saat beli bahan baru | Stok di aplikasi tetap akurat | 🔴 High |
| US-08 | Pemilik | Mendapat notifikasi ketika stok menipis | Saya bisa segera restok tepat waktu | 🟡 Medium |
| US-09 | Pemilik | Mendapat notifikasi jika pengeluaran > pemasukan | Saya waspada sebelum merugi | 🟡 Medium |
| US-10 | Pemilik | Melihat laporan harian, mingguan, dan bulanan | Saya bisa evaluasi performa usaha | 🟡 Medium |
| US-11 | Pemilik | Melihat produk terlaku hari ini | Saya bisa fokus jual produk yang menguntungkan | 🟢 Low |

---

## 4. Functional Requirements

### 4.1 Modul Produk

- CRUD produk: nama, harga jual, harga modal, stok awal, satuan (bungkus/botol/pcs), batas minimum stok
- Stok otomatis berkurang setiap ada transaksi penjualan yang tersimpan
- Status stok ditampilkan: **Aman** / **Menipis** / **Habis** berdasarkan perbandingan `stock` vs `min_stock`
- Daftar produk dapat dicari dan diurutkan berdasarkan nama, stok, atau terlaku

### 4.2 Modul Transaksi Penjualan

- Pilih satu atau lebih produk dari daftar → input jumlah → konfirmasi → simpan
- Stok otomatis berkurang dan dicatat di `stock_adjustments` saat transaksi tersimpan
- Harga yang tersimpan adalah harga pada saat transaksi (`price_at_sale`) — tidak berubah meskipun harga produk diedit kemudian, agar laporan historis tetap akurat
- Riwayat transaksi bisa dilihat dan dihapus; jika dihapus, stok dikembalikan secara otomatis

### 4.3 Modul Pengeluaran

- Input pengeluaran: nominal, kategori (Beli Stok / Operasional / Lainnya), keterangan opsional
- Khusus kategori **Beli Stok**: pengguna memilih produk yang direstok dan jumlahnya — stok otomatis bertambah dan tercatat di `stock_adjustments`
- Riwayat pengeluaran bisa dilihat dan dihapus

### 4.4 Modul Dashboard

Ditampilkan sebagai halaman utama setiap kali aplikasi dibuka, berisi data hari ini:

- Total pemasukan (dihitung dari transaksi penjualan)
- Total pengeluaran (dihitung dari transaksi pengeluaran)
- **Laba bersih = Pemasukan − Pengeluaran** (dihitung otomatis, tidak ada input manual)
- Grafik batang sederhana: tren pemasukan 7 hari terakhir
- Daftar 3 produk terlaku hari ini

### 4.5 Modul Laporan

- Laporan **harian**: ringkasan semua transaksi beserta total laba/rugi
- Laporan **mingguan**: tabel per hari + grafik tren
- Laporan **bulanan**: tabel per minggu + grafik tren

### 4.6 Modul Notifikasi Lokal

Notifikasi berjalan tanpa internet menggunakan `flutter_local_notifications`:

- **Notifikasi stok menipis**: muncul ketika `stock <= min_stock`, dibatasi maksimal 1 kali per produk per hari menggunakan field `last_notified_at` di tabel `products`. Dicek setiap kali transaksi penjualan disimpan.
- **Notifikasi defisit**: muncul ketika total pengeluaran hari ini melebihi total pemasukan hari ini. Dicek setiap kali transaksi pengeluaran baru disimpan.

---

## 5. Non-Functional Requirements

| Kategori | Requirement |
|----------|-------------|
| **Performa** | Waktu load halaman dashboard < 2 detik |
| **Offline** | 100% fitur berjalan tanpa koneksi internet |
| **Kompatibilitas** | Android 8.0 (API level 26) ke atas |
| **Ukuran APK** | Target < 25 MB |
| **Keamanan data** | Semua data tersimpan lokal di device, tidak dikirim ke server manapun |
| **Usability** | Dapat dioperasikan tanpa pelatihan oleh pengguna awam |
| **Reliabilitas** | Data tidak hilang jika aplikasi ditutup paksa (SQLite auto-commit per transaksi) |
| **Konsistensi data** | Total transaksi selalu dihitung dari `transaction_items`, tidak ada field redundan |

---

## 6. Tech Stack

| Layer | Teknologi | Versi | Alasan Pemilihan |
|-------|-----------|-------|-----------------|
| **Framework** | Flutter + Dart | SDK `^3.11.1` | Cross-platform, satu codebase untuk Android |
| **Database** | SQLite via `sqflite` | `^2.4.2` | Offline-first, gratis, tidak butuh server |
| **State Management** | Riverpod | `^3.3.1` | Standar state management Flutter 2026 |
| **Navigasi** | `go_router` | `^17.2.0` | Official Flutter routing package, declarative |
| **Grafik** | `fl_chart` | `^0.71.0` | Library chart paling populer di ekosistem Flutter |
| **Notifikasi Lokal** | `flutter_local_notifications` | `^18.0.0` | Notifikasi tanpa internet |
| **Format Angka & Tanggal** | `intl` | `^0.20.1` | Format Rupiah (Rp), format tanggal Indonesia |

> **Catatan:** Tidak ada backend server atau cloud database pada versi ini. Seluruh data tersimpan lokal di perangkat. Jika di masa depan dibutuhkan sinkronisasi antar device, arsitektur dapat dimigrasi ke Firebase Firestore tanpa mengubah struktur data secara signifikan.

---

## 7. Arsitektur Aplikasi

### Diagram Arsitektur

```
┌──────────────────────────────────────────────┐
│                Flutter App                   │
│                                              │
│  ┌─────────────┐    ┌──────────────────────┐ │
│  │  UI Layer   │───▶│   State Layer        │ │
│  │  (Screens & │    │   (Riverpod          │ │
│  │   Widgets)  │◀───│    Providers)        │ │
│  └─────────────┘    └──────────┬───────────┘ │
│                                │             │
│                     ┌──────────▼───────────┐ │
│                     │  Repository Layer    │ │
│                     │  (Business Logic &   │ │
│                     │   Data Access)       │ │
│                     └──────────┬───────────┘ │
│                                │             │
│                     ┌──────────▼───────────┐ │
│                     │  SQLite Database     │ │
│                     │  (sqflite)           │ │
│                     └──────────────────────┘ │
│                                              │
│  ┌───────────────────────────────────────┐   │
│  │  Notification Service                 │   │
│  │  (flutter_local_notifications)        │   │
│  └───────────────────────────────────────┘   │
└──────────────────────────────────────────────┘
```

### Struktur Folder

```
lib/
├── main.dart
├── app/
│   └── router.dart                   # Konfigurasi go_router
│
├── core/
│   ├── database/
│   │   ├── db_helper.dart            # Inisialisasi & koneksi SQLite
│   │   └── db_migrations.dart        # Script perubahan schema antar versi
│   ├── services/
│   │   └── notification_service.dart # Konfigurasi flutter_local_notifications
│   └── utils/
│       ├── currency_formatter.dart   # Format Rupiah: Rp 10.000
│       └── date_formatter.dart       # Format tanggal Indonesia
│
├── features/
│   ├── dashboard/
│   │   ├── screens/dashboard_screen.dart
│   │   ├── widgets/                  # SummaryCard, MiniChart, TopProductsList
│   │   └── providers/dashboard_provider.dart
│   │
│   ├── transaction/
│   │   ├── screens/
│   │   │   ├── add_sale_screen.dart
│   │   │   ├── add_expense_screen.dart
│   │   │   └── transaction_history_screen.dart
│   │   ├── models/
│   │   │   ├── transaction.dart
│   │   │   └── transaction_item.dart
│   │   ├── repositories/transaction_repository.dart
│   │   └── providers/transaction_provider.dart
│   │
│   ├── product/
│   │   ├── screens/
│   │   │   ├── product_list_screen.dart
│   │   │   └── add_edit_product_screen.dart
│   │   ├── models/product.dart
│   │   ├── repositories/product_repository.dart
│   │   └── providers/product_provider.dart
│   │
│   └── report/
│       ├── screens/
│       │   ├── report_screen.dart
│       │   └── report_detail_screen.dart
│       └── providers/report_provider.dart
│
└── shared/
    ├── widgets/                      # AppButton, AppTextField, EmptyState, dll
    └── constants/
        ├── app_colors.dart
        └── app_strings.dart
```

---

## 8. Database Schema

### Keputusan Desain Penting

Sebelum membaca schema, ada dua keputusan desain utama yang perlu dipahami:

1. **Total transaksi tidak disimpan sebagai field tersendiri** — nilai total selalu dihitung secara dinamis dari `SUM(quantity × price_at_sale)` di tabel `transaction_items`. Ini mencegah inkonsistensi antara dua sumber data yang bisa saja berbeda.

2. **Setiap perubahan stok direkam eksplisit di `stock_adjustments`** — baik pengurangan otomatis saat penjualan maupun penambahan saat restok, semua tercatat lengkap dengan alasannya. Ini memungkinkan audit trail stok yang lengkap dan dapat ditelusuri.

---

### Tabel: `products`

```sql
CREATE TABLE products (
  id               INTEGER PRIMARY KEY AUTOINCREMENT,
  name             TEXT    NOT NULL,
  sell_price       REAL    NOT NULL,           -- Harga jual ke pelanggan
  cost_price       REAL    NOT NULL,           -- Harga modal / beli bahan
  stock            INTEGER NOT NULL DEFAULT 0,
  min_stock        INTEGER NOT NULL DEFAULT 5, -- Threshold notifikasi stok menipis
  unit             TEXT    NOT NULL DEFAULT 'pcs', -- Satuan: pcs, bungkus, botol, dll
  last_notified_at TEXT,                       -- Timestamp notifikasi stok terakhir
                                               -- NULL = belum pernah dinotifikasi
                                               -- Digunakan untuk cegah notifikasi spam
  created_at       TEXT    NOT NULL DEFAULT (datetime('now', 'localtime')),
  updated_at       TEXT    NOT NULL DEFAULT (datetime('now', 'localtime'))
);
```

---

### Tabel: `transactions`

```sql
CREATE TABLE transactions (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  type        TEXT    NOT NULL CHECK (type IN ('income', 'expense')),
                                               -- 'income'  = transaksi penjualan
                                               -- 'expense' = transaksi pengeluaran
  category    TEXT,                            -- Untuk expense: 'stok', 'operasional', 'lainnya'
                                               -- Untuk income: NULL
  note        TEXT,                            -- Keterangan bebas, opsional
  created_at  TEXT    NOT NULL DEFAULT (datetime('now', 'localtime')),
  updated_at  TEXT    NOT NULL DEFAULT (datetime('now', 'localtime'))
);
```

> Tidak ada field `amount` — total dihitung dari `transaction_items` untuk menjaga satu sumber kebenaran.

---

### Tabel: `transaction_items`

```sql
CREATE TABLE transaction_items (
  id              INTEGER PRIMARY KEY AUTOINCREMENT,
  transaction_id  INTEGER NOT NULL,
  product_id      INTEGER,                     -- NULL diizinkan untuk pengeluaran
                                               -- yang tidak terkait produk spesifik
  quantity        INTEGER NOT NULL DEFAULT 1,
  price_at_sale   REAL    NOT NULL,            -- Snapshot harga saat transaksi terjadi
                                               -- Tidak berubah meski harga produk diedit

  FOREIGN KEY (transaction_id) REFERENCES transactions(id) ON DELETE CASCADE,
  FOREIGN KEY (product_id)     REFERENCES products(id)     ON DELETE SET NULL
);
```

> `ON DELETE CASCADE` — jika transaksi dihapus, semua item terkait ikut terhapus otomatis.
> `ON DELETE SET NULL` — jika produk dihapus, riwayat transaksi tetap ada dengan `product_id = NULL`.

---

### Tabel: `stock_adjustments`

```sql
CREATE TABLE stock_adjustments (
  id              INTEGER PRIMARY KEY AUTOINCREMENT,
  product_id      INTEGER NOT NULL,
  quantity_change INTEGER NOT NULL,            -- Positif = stok bertambah (restok)
                                               -- Negatif = stok berkurang (terjual/koreksi)
  reason          TEXT    NOT NULL,            -- 'sale'       = terjual (otomatis)
                                               -- 'restock'    = beli stok baru (manual)
                                               -- 'correction' = koreksi manual
  transaction_id  INTEGER,                     -- Referensi ke transaksi jika ada, NULL jika tidak
  created_at      TEXT    NOT NULL DEFAULT (datetime('now', 'localtime')),

  FOREIGN KEY (product_id)     REFERENCES products(id)     ON DELETE CASCADE,
  FOREIGN KEY (transaction_id) REFERENCES transactions(id) ON DELETE SET NULL
);
```

---

### ERD (Entity Relationship Diagram)

```
┌──────────────────┐        ┌─────────────────────┐        ┌──────────────────┐
│    products      │        │  transaction_items   │        │  transactions    │
│──────────────────│        │─────────────────────│        │──────────────────│
│ id (PK)          │◀───────│ product_id (FK, NULL)│        │ id (PK)          │
│ name             │        │ transaction_id (FK)  │───────▶│ type             │
│ sell_price       │        │ quantity             │        │ category         │
│ cost_price       │        │ price_at_sale        │        │ note             │
│ stock            │        └─────────────────────┘        │ created_at       │
│ min_stock        │                                        │ updated_at       │
│ unit             │                                        └──────────────────┘
│ last_notified_at │
│ created_at       │        ┌─────────────────────┐
│ updated_at       │◀───────│  stock_adjustments   │
└──────────────────┘        │─────────────────────│
                            │ id (PK)             │
                            │ product_id (FK)     │
                            │ quantity_change     │
                            │ reason              │
                            │ transaction_id (FK?)│
                            │ created_at          │
                            └─────────────────────┘
```

---

### Contoh Query Penting

**Total pemasukan hari ini:**
```sql
SELECT COALESCE(SUM(ti.quantity * ti.price_at_sale), 0) AS total_income
FROM transactions t
JOIN transaction_items ti ON ti.transaction_id = t.id
WHERE t.type = 'income'
  AND DATE(t.created_at) = DATE('now', 'localtime');
```

**Total pengeluaran hari ini:**
```sql
SELECT COALESCE(SUM(ti.price_at_sale), 0) AS total_expense
FROM transactions t
JOIN transaction_items ti ON ti.transaction_id = t.id
WHERE t.type = 'expense'
  AND DATE(t.created_at) = DATE('now', 'localtime');
```

**3 produk terlaku hari ini:**
```sql
SELECT p.name, SUM(ti.quantity) AS total_sold
FROM transaction_items ti
JOIN transactions t ON t.id = ti.transaction_id
JOIN products p ON p.id = ti.product_id
WHERE t.type = 'income'
  AND DATE(t.created_at) = DATE('now', 'localtime')
GROUP BY ti.product_id
ORDER BY total_sold DESC
LIMIT 3;
```

**Produk yang perlu dinotifikasi stok (belum dinotifikasi hari ini):**
```sql
SELECT id, name, stock, min_stock
FROM products
WHERE stock <= min_stock
  AND (
    last_notified_at IS NULL
    OR DATE(last_notified_at) < DATE('now', 'localtime')
  );
```

---

## 9. Navigation Flow

```
Splash Screen
    │
    └──▶ Home (Dashboard)
              │
              ├──▶ [+] Tambah Penjualan
              │         └── Pilih Produk → Input Jumlah → Konfirmasi → Simpan
              │             (stok berkurang otomatis + dicatat di stock_adjustments)
              │
              ├──▶ [+] Tambah Pengeluaran
              │         └── Pilih Kategori → Input Nominal
              │             → Jika 'Beli Stok': pilih produk & jumlah → Simpan
              │             (stok bertambah otomatis jika kategori 'Beli Stok')
              │
              ├──▶ Manajemen Produk
              │         ├── Daftar Produk (+ indikator status stok)
              │         ├── Tambah Produk Baru
              │         └── Edit / Hapus Produk
              │
              ├──▶ Laporan
              │         ├── Harian
              │         ├── Mingguan
              │         └── Bulanan
              │
              └──▶ Riwayat Transaksi
                        ├── Semua Transaksi (income + expense)
                        └── Detail & Hapus Transaksi
```

---

## 10. Security Considerations

Karena aplikasi ini sepenuhnya lokal tanpa server, attack surface sangat kecil. Namun beberapa risiko tetap perlu dimitigasi:

| Risiko | Tingkat | Mitigasi |
|--------|---------|----------|
| Input tidak valid (harga negatif, stok minus) | Medium | Validasi di sisi UI sebelum simpan; gunakan `CHECK` constraint di SQLite |
| SQL Injection | Low | Selalu gunakan parameterized queries di sqflite — jangan pernah string interpolation langsung ke query SQL |
| Data korup karena crash di tengah operasi multi-step | Medium | Bungkus operasi multi-tabel (simpan transaksi + update stok + catat adjustment) dalam satu SQLite transaction |
| Data hilang karena device rusak atau hilang | High | Tambahkan fitur export/backup ke file JSON atau Google Drive (roadmap v2.0) |
| Penghapusan tidak sengaja | Medium | Tampilkan dialog konfirmasi sebelum hapus transaksi atau produk |

---

## 11. Project Milestones

| Fase | Deliverable | Estimasi |
|------|-------------|----------|
| **Fase 1 — Setup** | Setup project Flutter, konfigurasi sqflite, struktur folder, go_router | 1 minggu |
| **Fase 2 — Core Data** | CRUD produk, schema database 4 tabel, db_helper, migrasi | 1 minggu |
| **Fase 3 — Transaksi** | Input penjualan, input pengeluaran, stock_adjustments berjalan | 2 minggu |
| **Fase 4 — Dashboard** | Dashboard laba/rugi otomatis, grafik tren, produk terlaku | 1 minggu |
| **Fase 5 — Laporan & Notif** | Laporan harian/mingguan/bulanan, notifikasi lokal | 1 minggu |
| **Fase 6 — Polish** | UI/UX refinement, validasi input, testing, dokumentasi | 1 minggu |
| **Total** | | **± 7 minggu** |

---

## 12. Out of Scope

Fitur berikut **sengaja tidak dimasukkan** untuk menjaga scope tetap realistis pada skala tugas kuliah:

- Sinkronisasi data ke cloud atau multi-device
- Fitur login dan manajemen akun pengguna
- Multi-kasir atau manajemen karyawan
- Cetak struk fisik (printer Bluetooth)
- Integrasi payment gateway (QRIS, transfer bank)
- Export laporan ke PDF
- Versi iOS
- Backup otomatis ke cloud

Seluruh poin di atas dapat menjadi roadmap pengembangan **versi 2.0** setelah versi dasar selesai dan divalidasi pengguna awal.

---

## 13. Dependencies (pubspec.yaml)

```yaml
name: ghepek_in
description: "Aplikasi kasir digital untuk UMKM kuliner — Ghepek.in"
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: ^3.11.1

dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8

  # Database
  sqflite: ^2.4.2
  path: ^1.9.0

  # State Management
  flutter_riverpod: ^3.3.1
  riverpod_annotation: ^4.0.2

  # Navigasi
  go_router: ^17.2.0

  # Grafik
  fl_chart: ^0.71.0

  # Notifikasi Lokal
  flutter_local_notifications: ^18.0.0

  # Format Angka & Tanggal
  intl: ^0.20.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
  build_runner: ^2.4.0
  riverpod_generator: ^4.0.3

flutter:
  uses-material-design: true
```

> Setelah menambahkan dependency, jalankan `flutter pub get`. Gunakan `flutter pub outdated` untuk memastikan semua package tetap up-to-date.

---

*PRD ini adalah dokumen perencanaan resmi untuk aplikasi Ghepek.in versi 1.0. Setiap perubahan scope atau keputusan teknis sebaiknya diperbarui di dokumen ini sebelum diimplementasi.*
