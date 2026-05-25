# Instructions

- Following Playwright test failed.
- Explain why, be concise, respect Playwright best practices.
- Provide a snippet of code with the fix, if possible.

# Test info

- Name: e2e_smoke_test.spec.js >> Bank Sampah E2E Browser Smoke Tests >> 1. Simulasi Alur Otorisasi & Login Dashboard
- Location: playwright\e2e_smoke_test.spec.js:41:3

# Error details

```
Error: expect(locator).toBeVisible() failed

Locator: locator('text=Bank Sampah Pemda').or(locator('text=Admin BKPSDM Playwright'))
Expected: visible
Timeout: 15000ms
Error: element(s) not found

Call log:
  - Expect "toBeVisible" with timeout 15000ms
  - waiting for locator('text=Bank Sampah Pemda').or(locator('text=Admin BKPSDM Playwright'))

```

```yaml
- button "Enable accessibility"
```

# Test source

```ts
  1   | // playwright/e2e_smoke_test.spec.js
  2   | // Playwright E2E Integration & Browser Test untuk Bank Sampah Pemda
  3   | // Menjamin seluruh alur transaksi berjalan mulus tanpa error.
  4   | 
  5   | const { test, expect } = require('@playwright/test');
  6   | 
  7   | // Helper to reliably trigger accessibility in Flutter Web
  8   | async function enableAccessibility(page) {
  9   |   const accessibilityButton = page.locator('button:has-text("Enable accessibility")').or(page.locator('text=Enable accessibility')).first();
  10  |   await accessibilityButton.click({ timeout: 8000 }).catch(async () => {
  11  |     // Fallback tab keys if click fails or button is focused but needs enter
  12  |     await page.keyboard.press('Tab');
  13  |     await page.keyboard.press('Tab');
  14  |     await page.keyboard.press('Tab');
  15  |     await page.keyboard.press('Enter');
  16  |   });
  17  |   await page.waitForTimeout(3000);
  18  | }
  19  | 
  20  | test.describe('Bank Sampah E2E Browser Smoke Tests', () => {
  21  |   
  22  |   test.beforeEach(async ({ page }) => {
  23  |     // Pantau error di browser console
  24  |     page.on('console', msg => {
  25  |       if (msg.type() === 'error') {
  26  |         console.error(`[BROWSER ERROR] ${msg.text()}`);
  27  |       }
  28  |     });
  29  |     // Pantau request yang gagal
  30  |     page.on('requestfailed', request => {
  31  |       console.error(`[REQUEST FAILED] ${request.url()} - ${request.failure()?.errorText || 'Unknown Error'}`);
  32  |     });
  33  |     // Pantau HTTP responses dengan status error
  34  |     page.on('response', response => {
  35  |       if (response.status() >= 400) {
  36  |         console.error(`[RESPONSE ERROR] ${response.url()} - Status: ${response.status()}`);
  37  |       }
  38  |     });
  39  |   });
  40  | 
  41  |   test('1. Simulasi Alur Otorisasi & Login Dashboard', async ({ page }) => {
  42  |     // 1. Kunjungi landing page web bank sampah dengan double query auth bypass
  43  |     await page.goto('http://127.0.0.1:5050/?bypass_auth=true#/dashboard?bypass_auth=true');
  44  |     
  45  |     // Tunggu inisialisasi Flutter engine (sangat penting untuk headless browser)
  46  |     await page.waitForTimeout(10000);
  47  | 
  48  |     // Pastikan judul halaman sesuai (case-insensitive)
  49  |     await expect(page).toHaveTitle(/Bank Sampah/i);
  50  | 
  51  |     // Aktifkan aksesibilitas
  52  |     await enableAccessibility(page);
  53  | 
  54  |     // Simulasi Dashboard termuat
> 55  |     await expect(page.locator('text=Bank Sampah Pemda').or(page.locator('text=Admin BKPSDM Playwright'))).toBeVisible();
      |                                                                                                           ^ Error: expect(locator).toBeVisible() failed
  56  |   });
  57  | 
  58  |   test('2. Simulasi Alur Kerja Admin - Master Data & Bulk Import', async ({ page }) => {
  59  |     await page.goto('http://127.0.0.1:5050/?bypass_auth=true#/master?bypass_auth=true');
  60  |     await page.waitForTimeout(5000);
  61  | 
  62  |     // Aktifkan aksesibilitas
  63  |     await enableAccessibility(page);
  64  | 
  65  |     // Pastikan berada di tab Master Data
  66  |     await expect(page.locator('text=Master Data').or(page.locator('text=Pegawai'))).toBeVisible();
  67  | 
  68  |     // Pastikan tab Pegawai aktif dan tombol Bulk Import tersedia
  69  |     const bulkImportBtn = page.locator('text=Bulk Import');
  70  |     await expect(bulkImportBtn).toBeVisible();
  71  |     await bulkImportBtn.click();
  72  | 
  73  |     // Isikan template JSON pegawai untuk di-import
  74  |     const jsonTextArea = page.locator('textarea');
  75  |     await expect(jsonTextArea).toBeVisible();
  76  | 
  77  |     const sampleJSON = JSON.stringify([
  78  |       {
  79  |         "nama_pegawai": "Pegawai DLH Playwright",
  80  |         "nip": "199707072026051009",
  81  |         "email": "playwright.test@dlh.badung.go.id",
  82  |         "no_telepon": "089988776655"
  83  |       }
  84  |     ], null, 2);
  85  | 
  86  |     await jsonTextArea.fill(sampleJSON);
  87  | 
  88  |     // Kirim form bulk import
  89  |     const submitBtn = page.locator('text=Import Sekarang');
  90  |     await expect(submitBtn).toBeVisible();
  91  |   });
  92  | 
  93  |   test('3. Simulasi Transaksi - Setoran, Penjualan & Kartu Gudang', async ({ page }) => {
  94  |     // Buka menu input setoran
  95  |     await page.goto('http://127.0.0.1:5050/?bypass_auth=true#/setoran?bypass_auth=true');
  96  |     await page.waitForTimeout(5000);
  97  | 
  98  |     // Aktifkan aksesibilitas
  99  |     await enableAccessibility(page);
  100 | 
  101 |     await expect(page.locator('text=Setoran Baru').or(page.locator('text=Daftar Setoran'))).toBeVisible();
  102 | 
  103 |     // Buka menu input penjualan FIFO
  104 |     await page.goto('http://127.0.0.1:5050/?bypass_auth=true#/penjualan?bypass_auth=true');
  105 |     await page.waitForTimeout(5000);
  106 |     await expect(page.locator('text=Penjualan Baru').or(page.locator('text=Daftar Penjualan'))).toBeVisible();
  107 | 
  108 |     // Buka menu pelaporan kartu gudang
  109 |     await page.goto('http://127.0.0.1:5050/?bypass_auth=true#/reporting?bypass_auth=true');
  110 |     await page.waitForTimeout(5000);
  111 |     await expect(page.locator('text=Laporan Stok').or(page.locator('text=Laporan'))).toBeVisible();
  112 |   });
  113 | 
  114 |   test('4. Simulasi Alur Nasabah - Penarikan & Transparansi FIFO', async ({ page }) => {
  115 |     // Buka menu penarikan tabungan pegawai
  116 |     await page.goto('http://127.0.0.1:5050/?bypass_auth=true#/penarikan?bypass_auth=true');
  117 |     await page.waitForTimeout(5000);
  118 | 
  119 |     // Aktifkan aksesibilitas
  120 |     await enableAccessibility(page);
  121 | 
  122 |     await expect(page.locator('text=Ajukan Penarikan').or(page.locator('text=Daftar Penarikan'))).toBeVisible();
  123 | 
  124 |     // Buka menu transparansi audit FIFO selisih realisasi saldo
  125 |     await page.goto('http://127.0.0.1:5050/?bypass_auth=true#/selisih-realisasi?bypass_auth=true');
  126 |     await page.waitForTimeout(5000);
  127 |     await expect(page.locator('text=Riwayat Realisasi').or(page.locator('text=Transparansi FIFO').or(page.locator('text=Selisih')))).toBeVisible();
  128 |   });
  129 | });
  130 | 
```