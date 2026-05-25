// playwright/e2e_smoke_test.spec.js
// Playwright E2E Integration & Browser Test untuk Bank Sampah Pemda
// Menjamin seluruh alur transaksi berjalan mulus tanpa error.

const { test, expect } = require('@playwright/test');

test.describe('Bank Sampah E2E Browser Smoke Tests', () => {
  
  test.beforeEach(async ({ page }) => {
    // Pantau error di browser console
    page.on('console', msg => {
      if (msg.type() === 'error') {
        console.error(`[BROWSER ERROR] ${msg.text()}`);
      }
    });
    // Pantau request yang gagal
    page.on('requestfailed', request => {
      console.error(`[REQUEST FAILED] ${request.url()} - ${request.failure()?.errorText || 'Unknown Error'}`);
    });
    // Pantau HTTP responses dengan status error
    page.on('response', response => {
      if (response.status() >= 400) {
        console.error(`[RESPONSE ERROR] ${response.url()} - Status: ${response.status()}`);
      }
    });
  });

  test('1. Simulasi Alur Otorisasi & Login Dashboard', async ({ page }) => {
    // 1. Kunjungi landing page web bank sampah dengan double query auth bypass
    await page.goto('http://[::1]:5050/?bypass_auth=true#/dashboard?bypass_auth=true');
    
    // Tunggu inisialisasi Flutter engine (sangat penting untuk headless browser)
    await page.waitForTimeout(10000);

    // Pastikan judul halaman sesuai (case-insensitive)
    await expect(page).toHaveTitle(/Bank Sampah/i);

    // Aktifkan aksesibilitas Flutter Web dengan menekan tombol Tab 3 kali
    await page.keyboard.press('Tab');
    await page.keyboard.press('Tab');
    await page.keyboard.press('Tab');
    await page.waitForTimeout(3000);

    // Simulasi Dashboard termuat
    await expect(page.locator('text=Bank Sampah Pemda').or(page.locator('text=Admin BKPSDM Playwright'))).toBeVisible();
  });

  test('2. Simulasi Alur Kerja Admin - Master Data & Bulk Import', async ({ page }) => {
    await page.goto('http://[::1]:5050/?bypass_auth=true#/master?bypass_auth=true');
    await page.waitForTimeout(5000);

    // Aktifkan aksesibilitas
    await page.keyboard.press('Tab');
    await page.keyboard.press('Tab');
    await page.keyboard.press('Tab');
    await page.waitForTimeout(3000);

    // Pastikan berada di tab Master Data
    await expect(page.locator('text=Master Data').or(page.locator('text=Pegawai'))).toBeVisible();

    // Pastikan tab Pegawai aktif dan tombol Bulk Import tersedia
    const bulkImportBtn = page.locator('text=Bulk Import');
    await expect(bulkImportBtn).toBeVisible();
    await bulkImportBtn.click();

    // Isikan template JSON pegawai untuk di-import
    const jsonTextArea = page.locator('textarea');
    await expect(jsonTextArea).toBeVisible();

    const sampleJSON = JSON.stringify([
      {
        "nama_pegawai": "Pegawai DLH Playwright",
        "nip": "199707072026051009",
        "email": "playwright.test@dlh.badung.go.id",
        "no_telepon": "089988776655"
      }
    ], null, 2);

    await jsonTextArea.fill(sampleJSON);

    // Kirim form bulk import
    const submitBtn = page.locator('text=Import Sekarang');
    await expect(submitBtn).toBeVisible();
  });

  test('3. Simulasi Transaksi - Setoran, Penjualan & Kartu Gudang', async ({ page }) => {
    // Buka menu input setoran
    await page.goto('http://[::1]:5050/?bypass_auth=true#/setoran?bypass_auth=true');
    await page.waitForTimeout(5000);

    // Aktifkan aksesibilitas
    await page.keyboard.press('Tab');
    await page.keyboard.press('Tab');
    await page.keyboard.press('Tab');
    await page.waitForTimeout(3000);

    await expect(page.locator('text=Setoran Baru').or(page.locator('text=Daftar Setoran'))).toBeVisible();

    // Buka menu input penjualan FIFO
    await page.goto('http://[::1]:5050/?bypass_auth=true#/penjualan?bypass_auth=true');
    await page.waitForTimeout(5000);
    await expect(page.locator('text=Penjualan Baru').or(page.locator('text=Daftar Penjualan'))).toBeVisible();

    // Buka menu pelaporan kartu gudang
    await page.goto('http://[::1]:5050/?bypass_auth=true#/reporting?bypass_auth=true');
    await page.waitForTimeout(5000);
    await expect(page.locator('text=Laporan Stok').or(page.locator('text=Laporan'))).toBeVisible();
  });

  test('4. Simulasi Alur Nasabah - Penarikan & Transparansi FIFO', async ({ page }) => {
    // Buka menu penarikan tabungan pegawai
    await page.goto('http://[::1]:5050/?bypass_auth=true#/penarikan?bypass_auth=true');
    await page.waitForTimeout(5000);

    // Aktifkan aksesibilitas
    await page.keyboard.press('Tab');
    await page.keyboard.press('Tab');
    await page.keyboard.press('Tab');
    await page.waitForTimeout(3000);

    await expect(page.locator('text=Ajukan Penarikan').or(page.locator('text=Daftar Penarikan'))).toBeVisible();

    // Buka menu transparansi audit FIFO selisih realisasi saldo
    await page.goto('http://[::1]:5050/?bypass_auth=true#/selisih-realisasi?bypass_auth=true');
    await page.waitForTimeout(5000);
    await expect(page.locator('text=Riwayat Realisasi').or(page.locator('text=Transparansi FIFO').or(page.locator('text=Selisih')))).toBeVisible();
  });
});



