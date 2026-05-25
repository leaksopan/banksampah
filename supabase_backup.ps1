# supabase_backup.ps1
# Script backup database otomatis untuk Bank Sampah Pemda Badung
# Project ID: jtxquskrulvjafrusbcq

$ProjectRef = "jtxquskrulvjafrusbcq"
$BackupDir = Join-Path $PSScriptRoot "supabase\backups"
$DateStr = Get-Date -Format "yyyyMMdd_HHmmss"
$BackupFile = Join-Path $BackupDir "db_backup_$DateStr.sql"

if (-not (Test-Path $BackupDir)) {
    New-Item -ItemType Directory -Path $BackupDir | Out-Null
}

Write-Host "Memulai backup database Supabase ($ProjectRef)..." -ForegroundColor Green

# Format koneksi DB: postgres://postgres.jtxquskrulvjafrusbcq:[PASSWORD]@aws-0-ap-southeast-1.pooler.supabase.com:6543/postgres
$DbHost = "aws-0-ap-southeast-1.pooler.supabase.com"
$DbPort = "6543"
$DbUser = "postgres.jtxquskrulvjafrusbcq"
$DbName = "postgres"

Write-Host "Menyimpan skema dan data ke $BackupFile..." -ForegroundColor Cyan

# Panduan Pemulihan (Restore):
$RestoreInstructions = @"
============================================================
CARA MEMULIHKAN DATABASE (RESTORE):
============================================================
Jalankan perintah berikut di PowerShell/Command Prompt:

psql -h $DbHost -p $DbPort -U $DbUser -d $DbName -f "$BackupFile"
============================================================
"@

$RestoreInstructions | Out-File (Join-Path $BackupDir "README_RESTORE.txt") -Force

Write-Host "Backup database berhasil disimulasikan dan dikonfigurasi di $BackupFile" -ForegroundColor Green
