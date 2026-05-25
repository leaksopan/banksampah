# Design Guidelines — Bank Sampah Pemda

Dokumen ini menjadi panduan desain UI untuk aplikasi **Bank Sampah Pemda**. Tujuannya adalah menjaga tampilan aplikasi tetap konsisten, modern, mudah digunakan, dan sesuai dengan karakter sistem: transparan, akuntabel, auditable, serta ramah lingkungan.

---

## 1. Design Direction

Aplikasi menggunakan gaya visual:

**Glossy Aqua Glassmorphism**

Karakter utama:

- Modern seperti aplikasi fintech / mobile wallet.
- Fresh, terang, ramah, dan tidak terlihat seperti aplikasi pemerintah lama.
- Menggunakan aqua, cyan, turquoise, mint green, putih transparan, dan slate.
- Banyak menggunakan kartu mengambang, rounded corners besar, soft shadows, dan efek glass.
- Mobile-first, tetapi tetap bisa diturunkan menjadi web dashboard.

Kesan yang harus muncul:

- Bersih
- Transparan
- Terpercaya
- Ramah lingkungan
- Profesional
- Mudah dipakai pegawai dan admin OPD

Kesan yang harus dihindari:

- Dashboard enterprise yang terlalu kaku
- Warna hijau tua jadul
- Tabel terlalu padat di mobile
- Border tebal
- Ikon 3D lama / skeuomorphic
- Tampilan seperti aplikasi administrasi legacy

---

## 2. Product Personality

Aplikasi ini adalah sistem Bank Sampah untuk lingkungan pemerintah daerah. Secara fungsi, aplikasi harus terasa akuntabel dan serius. Secara tampilan, aplikasi harus tetap ringan, segar, dan mudah dipahami.

Personality desain:

| Sifat | Implementasi Visual |
|---|---|
| Transparan | Glass card, status jelas, timeline audit |
| Ramah lingkungan | Warna mint, emerald, recycle icon, soft illustration |
| Terpercaya | Layout rapi, angka saldo jelas, badge status konsisten |
| Modern | Rounded card, gradient, white glass navigation |
| Mudah dipakai | CTA besar, form sederhana, card list di mobile |

---

## 3. Color Palette

### Primary Palette

| Token | Hex | Penggunaan |
|---|---:|---|
| Aqua Blue | `#38BDF8` | Header gradient, highlight utama |
| Cyan | `#22D3EE` | Background accent, button secondary |
| Mint Green | `#5EEAD4` | Glass overlay, environmental accent |
| Emerald | `#10B981` | Primary action, success state |
| Emerald Dark | `#047857` | Text/button contrast di atas background terang |

### Neutral Palette

| Token | Hex | Penggunaan |
|---|---:|---|
| Soft White | `#F8FAFC` | Background utama |
| Surface | `#FFFFFF` | Card solid, modal, sheet |
| Text Primary | `#0F172A` | Heading dan angka penting |
| Text Secondary | `#64748B` | Label, caption, secondary information |
| Border Soft | `#E2E8F0` | Border ringan jika dibutuhkan |

### Semantic Palette

| Token | Hex | Penggunaan |
|---|---:|---|
| Success | `#22C55E` | Posted, Approved, Paid, saldo positif |
| Warning | `#F59E0B` | Pending, Draft, butuh approval |
| Danger | `#EF4444` | Rejected, Voided, error, selisih negatif |
| Info | `#0EA5E9` | Informasi, filter aktif, neutral status |

---

## 4. Gradient System

Gunakan gradient yang lembut, terang, dan glossy.

### Main Aqua Gradient

```css
linear-gradient(135deg, #38BDF8 0%, #22D3EE 45%, #5EEAD4 100%)
```

Dipakai untuk:

- Header mobile
- Balance card
- Login background
- Dashboard hero card

### Emerald Fresh Gradient

```css
linear-gradient(135deg, #10B981 0%, #5EEAD4 100%)
```

Dipakai untuk:

- CTA utama
- Success card
- Card saldo tersedia

### Soft Background Gradient

```css
linear-gradient(180deg, #E0F7FA 0%, #F8FAFC 55%, #FFFFFF 100%)
```

Dipakai untuk:

- Background halaman mobile
- Splash/login
- Empty state background

---

## 5. Glassmorphism Rules

Gunakan glass effect secara konsisten, tetapi jangan berlebihan.

### Glass Card Style

```css
background: rgba(255, 255, 255, 0.72);
backdrop-filter: blur(18px);
border: 1px solid rgba(255, 255, 255, 0.45);
box-shadow: 0 16px 40px rgba(15, 23, 42, 0.10);
border-radius: 24px;
```

### Strong Glass Card

Untuk card di atas gradient kuat:

```css
background: rgba(255, 255, 255, 0.86);
backdrop-filter: blur(24px);
border: 1px solid rgba(255, 255, 255, 0.60);
box-shadow: 0 20px 50px rgba(15, 23, 42, 0.14);
border-radius: 28px;
```

### Floating Bottom Navigation

```css
background: rgba(255, 255, 255, 0.78);
backdrop-filter: blur(20px);
border-radius: 28px;
box-shadow: 0 12px 32px rgba(15, 23, 42, 0.12);
```

---

## 6. Typography

Gunakan font modern yang bersih dan rounded.

Rekomendasi:

1. **Plus Jakarta Sans**
2. **Inter**
3. **Google Sans**

### Type Scale

| Style | Size | Weight | Penggunaan |
|---|---:|---:|---|
| Display Balance | 32–40 | 700 | Saldo utama |
| Page Title | 24–28 | 700 | Judul halaman |
| Section Title | 18–20 | 600 | Judul section |
| Card Title | 15–16 | 600 | Judul card |
| Body | 14–16 | 400/500 | Isi utama |
| Caption | 12–13 | 400 | Label, timestamp, helper text |
| Badge | 11–12 | 600 | Status badge |

### Number Formatting

- Mata uang: `Rp 1.234.567`
- Berat: `12,5 kg`
- Tanggal: `23 Mei 2026`
- Waktu: `10:45 WITA`

---

## 7. Iconography

Gunakan icon modern outline / rounded. Referensi gaya:

- Lucide Icons
- Heroicons
- Material Symbols Rounded

### Icon Mapping

| Modul | Icon Direction |
|---|---|
| Dashboard | home, layout-dashboard |
| Setoran | recycle, scale, package-plus |
| Penjualan | truck, shopping-bag, hand-coins |
| Penarikan | banknote, credit-card, wallet |
| Saldo | wallet, coins |
| Stok | warehouse, boxes |
| Pegawai | users, id-card |
| Vendor | building-store, truck |
| Lokasi/TPS | map-pin, warehouse |
| Approval | shield-check, check-circle |
| Laporan | file-text, file-spreadsheet, chart-bar |
| Audit | history, file-check |
| Pengaturan | settings, sliders-horizontal |

### Icon Rules

- Gunakan stroke konsisten: 1.75–2 px.
- Jangan pakai icon terlalu detail.
- Icon dalam menu memakai glass tile 48–56 px.
- Icon aktif boleh memakai gradient circle.

---

## 8. Border Radius & Spacing

### Radius

| Komponen | Radius |
|---|---:|
| Small input | 14–16 px |
| Button | 16–20 px |
| Card | 22–28 px |
| Hero card | 28–32 px |
| Bottom nav | 28–32 px |
| Modal / drawer | 24–32 px |

### Spacing

Gunakan sistem 4-point spacing:

| Token | Value |
|---|---:|
| xs | 4 px |
| sm | 8 px |
| md | 12 px |
| lg | 16 px |
| xl | 24 px |
| 2xl | 32 px |
| 3xl | 40 px |

Mobile page padding ideal: `20–24px`.

---

## 9. Layout Principles

### Mobile-first

Mobile adalah prioritas utama. Untuk mobile:

- Hindari tabel padat.
- Gunakan card list.
- CTA utama diletakkan sticky di bawah jika form panjang.
- Bottom navigation dibuat floating glass.
- Gunakan header gradient dengan konten utama masuk ke area rounded card.

### Desktop/Web

Untuk web:

- Gunakan sidebar kiri.
- Gunakan top bar untuk search, notifikasi, profile, dan OPD aktif.
- Tabel boleh digunakan, tetapi tetap lega.
- Filter dibuat dalam bentuk pill/chip dan date range picker.
- Dashboard memakai grid cards.

---

## 10. Component Guidelines

## 10.1 Balance Card

Balance card adalah komponen paling penting untuk Pegawai.

Isi utama:

- Saldo Tersedia
- Saldo Pending
- Tombol “Tarik Saldo”
- Info kecil: “Saldo Pending menunggu realisasi penjualan”

Style:

- Gradient aqua/mint.
- Angka saldo besar.
- Gunakan white text atau dark text tergantung kontras.
- Bisa memakai decorative blur circle.

---

## 10.2 KPI Card

Dipakai di dashboard admin dan super admin.

Isi:

- Icon
- Label
- Angka utama
- Subtext perubahan/periode

Style:

- Glass card putih transparan.
- Icon di circular soft background.
- Angka dibuat tebal.

---

## 10.3 Transaction Card

Dipakai untuk setoran, penjualan, penarikan, dan mutasi saldo di mobile.

Struktur:

- Kiri: icon/module indicator
- Tengah: title + subtitle + timestamp
- Kanan: nilai/status
- Footer optional: No Bukti

Contoh isi:

- `Setoran Botol PET`
- `260523BSP#BKPSDM-000001`
- `10,5 kg • Rp 31.500`
- Badge: `Posted`

---

## 10.4 Data Table

Untuk web/admin.

Rules:

- Header tidak terlalu gelap.
- Row height minimal 56 px.
- Gunakan zebra halus atau hover state.
- Status dalam bentuk badge.
- Action dalam icon button / kebab menu.
- Selalu sediakan search dan filter.

---

## 10.5 Status Badge

| Status | Warna | Label |
|---|---|---|
| Draft | Gray/Slate | Draft |
| Pending | Amber | Pending |
| Pending Approval | Amber | Menunggu Approval |
| Approved | Sky Blue | Disetujui |
| Posted | Success | Posted |
| Paid | Success | Dibayar |
| Rejected | Danger | Ditolak |
| Voided | Danger | Dibatalkan |
| Partial Realized | Info | Realisasi Sebagian |
| Full Realized | Success | Realisasi Penuh |

Badge style:

```css
border-radius: 999px;
padding: 4px 10px;
font-size: 12px;
font-weight: 600;
```

---

## 10.6 Form Input

Input harus terasa ringan dan modern.

Style:

- Rounded 16–18 px.
- Background putih transparan atau soft white.
- Label jelas.
- Helper text untuk field yang rawan salah.
- Error state jelas tapi tidak agresif.

Form transaksi panjang harus dibuat stepper/card section:

1. Informasi utama
2. Detail transaksi
3. Ringkasan
4. Konfirmasi

---

## 11. Navigation

## 11.1 Mobile Bottom Navigation

Menu utama:

1. Dashboard
2. Setoran
3. Saldo
4. Riwayat
5. Profil

Style:

- Floating white glass.
- Icon + label kecil.
- Active state memakai aqua/emerald gradient.
- Posisi fixed bottom.

## 11.2 Admin Mobile Menu

Gunakan grid icon glass tile:

- Dashboard
- Setoran
- Penjualan
- Penarikan
- Stok
- Master
- Laporan
- Pengaturan

## 11.3 Desktop Sidebar

Menu desktop:

- Dashboard
- Setoran
- Penjualan
- Penarikan
- Stok
- Master Data
- Laporan
- Audit Trail
- Pengaturan

Sidebar style:

- Soft white / glass.
- Active menu memakai gradient pill.
- Icon outline modern.

---

## 12. Screen Guidelines

## 12.1 Login Screen

Elemen:

- Logo Bank Sampah Pemda
- Tagline: “Sampahmu, Tabunganmu”
- Tombol “Masuk dengan Google”
- Feature chips: Transparan, Akuntabel, Auditable
- Ilustrasi recycle/wallet/leaf

Style:

- Aqua gradient background.
- Center glass card.
- Banyak whitespace.

---

## 12.2 Pegawai Dashboard

Elemen:

- Greeting: “Halo, [Nama Pegawai]”
- Saldo Tersedia
- Saldo Pending
- Total Berat Setor
- Total Ditarik
- CTA Tarik Saldo
- Setoran Terakhir
- Realisasi Terakhir

Catatan UX:

- Jelaskan bahwa Pending belum bisa ditarik.
- Tersedia harus paling dominan.

---

## 12.3 Admin OPD Dashboard

Elemen:

- OPD selector
- Ringkasan hari ini
- KPI cards
- Quick actions
- Top stok sampah
- Approval pending

Catatan UX:

- Admin perlu cepat input setoran dan penjualan.
- Tindakan yang butuh approval harus mudah terlihat.

---

## 12.4 Setoran Baru

Elemen:

- Pilih pegawai
- Pilih lokasi/TPS
- Tanggal setoran
- Detail jenis sampah
- Qty, satuan, harga beli, subtotal
- Total berat dan total nilai estimasi

Catatan UX:

- Multi-detail harus mudah ditambah/hapus.
- Di mobile gunakan card per item sampah.
- Total sticky di bawah.

---

## 12.5 Penjualan Baru

Elemen:

- Pilih vendor
- Pilih lokasi/TPS
- Detail sampah dijual
- Stok tersedia
- Qty jual
- Harga jual aktual
- Estimasi HPP dan selisih

Catatan UX:

- Tampilkan warning jika qty melebihi stok.
- Jelaskan bahwa realisasi saldo terjadi setelah approval dan posting.

---

## 12.6 Penarikan Saldo

Elemen:

- Saldo Tersedia
- Saldo Pending
- Jumlah penarikan
- Metode cash/transfer
- Data rekening
- Riwayat penarikan

Catatan UX:

- Batasi input maksimal sebesar Saldo Tersedia.
- Tampilkan minimal penarikan.

---

## 12.7 Laporan dan Audit

Elemen:

- Filter periode
- Filter OPD/lokasi/pegawai/vendor
- Summary cards
- Table web / card mobile
- Export Excel/PDF
- Timeline audit

Catatan UX:

- Laporan harus terasa rapi dan dapat dipercaya.
- Jangan mengorbankan readability demi efek visual.

---

## 13. Motion & Interaction

Gunakan animasi halus, bukan berlebihan.

Rekomendasi:

- Card appear: fade + slide up 120–180ms.
- Button press: scale 0.98.
- Bottom sheet: slide up + blur backdrop.
- Badge status change: subtle fade.
- Loading: shimmer glass skeleton.

Durasi ideal:

- Micro interaction: 100–150ms
- Page transition: 180–250ms
- Modal/sheet: 220–300ms

---

## 14. Empty State

Empty state harus ramah dan informatif.

Contoh:

### Belum Ada Setoran

Title: `Belum ada setoran`

Description: `Setoran sampah yang sudah dicatat akan muncul di sini.`

CTA: `Input Setoran Baru`

Icon: recycle / package-plus

---

## 15. Error State

Error harus jelas dan tidak menakutkan.

Contoh:

- `Stok tidak cukup. Stok tersedia 8 kg, kebutuhan 12 kg.`
- `Saldo tersedia belum cukup untuk penarikan ini.`
- `Data pegawai tidak aktif.`
- `Koneksi bermasalah. Coba lagi beberapa saat.`

Gunakan card error soft red, bukan alert besar yang kasar.

---

## 16. Accessibility

Minimal requirement:

- Kontras teks harus cukup di atas gradient.
- Jangan hanya mengandalkan warna untuk status; selalu gunakan label.
- Ukuran tap target minimal 44x44 px.
- Text utama minimal 14 px.
- Form error harus punya pesan teks.
- Icon-only button harus punya tooltip/label.

---

## 17. Responsive Rules

### Mobile `< 600px`

- Card list, bukan tabel.
- Bottom navigation.
- Form stepper/card.
- CTA sticky.
- Header compact.

### Tablet `600–1024px`

- Two-column layout jika memungkinkan.
- Navigation rail.
- Tabel boleh dipakai untuk data sederhana.

### Desktop `> 1024px`

- Sidebar.
- Grid dashboard.
- Data table lengkap.
- Drawer kanan untuk detail/edit.

---

## 18. Prompt Style untuk Google Stitch

Gunakan prompt style ini untuk menjaga konsistensi hasil generate:

```text
Glossy aqua glassmorphism, mint gradient, translucent cards, floating rounded panels, soft blur, soft shadows, white glass bottom navigation, modern fintech wallet app, playful but professional, not legacy government UI.
```

Tambahan untuk transaksi mobile:

```text
For mobile transaction screens, avoid dense enterprise tables. Use stacked glossy cards, floating summary panels, rounded input fields, pill filters, and soft glass bottom action bars. Tables can exist on web version, but mobile version must use beautiful card lists.
```

Tambahan untuk dashboard:

```text
Make it look like a modern SaaS dashboard combined with a glossy mobile wallet app. Use clean spacing, elegant cards, large readable numbers, subtle status badges, and contemporary iconography.
```

---

## 19. Do & Don’t

### Do

- Gunakan aqua/mint gradient.
- Gunakan card rounded besar.
- Gunakan white translucent surfaces.
- Tampilkan saldo dan status secara jelas.
- Buat mobile UI terasa seperti wallet app.
- Gunakan icon modern outline.
- Buat form transaksi sederhana dan bertahap.

### Don’t

- Jangan pakai hijau tua dominan seperti aplikasi lama.
- Jangan membuat mobile screen penuh tabel.
- Jangan pakai border hitam/abu tebal.
- Jangan pakai icon jadul/3D berat.
- Jangan membuat dashboard terlalu dense.
- Jangan menghilangkan label status.
- Jangan memakai gradient terlalu ramai sampai teks susah dibaca.

---

## 20. Design Checklist

Sebelum sebuah screen dianggap sesuai guideline, cek:

- [ ] Menggunakan palette aqua/mint/emerald/slate.
- [ ] Memiliki spacing lega.
- [ ] Memakai rounded card modern.
- [ ] Tidak terlihat seperti aplikasi admin jadul.
- [ ] Mobile menggunakan card list, bukan tabel padat.
- [ ] CTA utama jelas.
- [ ] Status menggunakan badge + label.
- [ ] Angka uang/berat mudah dibaca.
- [ ] Icon konsisten modern outline.
- [ ] Glass effect tidak mengganggu readability.
- [ ] Halaman bisa dipahami oleh pegawai/admin tanpa training panjang.

---

## 21. Reference Mood

Mood visual mengikuti referensi glossy aqua mobile UI:

- Background cyan muda.
- Kartu putih transparan.
- Panel gradient aqua-mint.
- Bottom navigation putih transparan.
- Rounded phone-first layout.
- Minimal, soft, dan friendly.

Namun aplikasi tetap harus menjaga karakter sistem pemerintah:

- Data jelas.
- Status jelas.
- Audit trail jelas.
- Form validasi jelas.
- Laporan mudah dibaca.
# Referensi Visual Mobile

Referensi utama untuk UI mobile ada di `.docs/Referensi.png`.

Prinsip yang wajib diikuti:

- Mobile-first; desain layar HP menjadi default, desktop hanya adaptasi belakangan.
- Saat dibuka di browser desktop, canvas app tetap dibatasi seperti layar HP, maksimal 430 px,
  bukan melebar mengikuti browser.
- Navigasi utama HP memakai bottom navigation bar / bottom tab bar, bukan sidebar kiri.
- Gunakan header visual lembut, warna biru-hijau, surface putih/transparan, dan sudut membulat.
- Dashboard awal boleh kosong, tetapi tetap harus terasa seperti aplikasi HP siap pakai.
- Jangan memakai `NavigationRail` atau navbar kiri untuk flow end-user mobile.
