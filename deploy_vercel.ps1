# Script untuk Build & Deploy Flutter Web ke Vercel secara Aman

Write-Host "1. Memulai build Flutter Web dengan aman..." -ForegroundColor Cyan
flutter build web --release --dart-define-from-file=.env

if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Build Flutter gagal! Pastikan Flutter SDK sudah terinstall dengan benar." -ForegroundColor Red
    exit 1
}

Write-Host "2. Membuat konfigurasi vercel.json untuk routing SPA..." -ForegroundColor Cyan
$VercelJsonContent = @"
{
  "cleanUrls": true,
  "rewrites": [
    { "source": "/(.*)", "destination": "/index.html" }
  ]
}
"@

# Pastikan folder build/web ada
if (!(Test-Path -Path "build/web")) {
    Write-Host "Error: Folder build/web tidak ditemukan!" -ForegroundColor Red
    exit 1
}

# Tulis file vercel.json ke build/web tanpa BOM
[System.IO.File]::WriteAllText("build/web/vercel.json", $VercelJsonContent)

Write-Host "3. Memulai deploy ke Vercel..." -ForegroundColor Cyan
# Masuk ke folder build/web dan jalankan vercel
Push-Location build/web
vercel --prod
Pop-Location

Write-Host "Selesai! Aplikasi Anda sudah berhasil di-deploy ke Vercel." -ForegroundColor Green
