# run_edge.ps1
Stop-Process -Name msedge -ErrorAction SilentlyContinue

$testProfileDir = "C:\Users\Msi_\AppData\Local\Microsoft\Edge\UserDataTest"
if (-not (Test-Path $testProfileDir)) {
    New-Item -ItemType Directory -Force -Path $testProfileDir | Out-Null
}

$edgePath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"

Write-Host "Menjalankan Edge Headless Terisolasi..."
Start-Process $edgePath -ArgumentList "--remote-debugging-port=9222", "--user-data-dir=C:\Users\Msi_\AppData\Local\Microsoft\Edge\UserDataTest", "--no-first-run", "--no-default-browser-check", "--headless=new", "--disable-gpu"

Start-Sleep -Seconds 5

$sourceFile = Join-Path $testProfileDir "DevToolsActivePort"
$targetFile = "C:\Users\Msi_\AppData\Local\Google\Chrome\User Data\DevToolsActivePort"

if (Test-Path $sourceFile) {
    $targetDir = "C:\Users\Msi_\AppData\Local\Google\Chrome\User Data"
    if (-not (Test-Path $targetDir)) {
        New-Item -ItemType Directory -Force -Path $targetDir | Out-Null
    }
    Copy-Item -Path $sourceFile -Destination $targetFile -Force
    Write-Host "Berhasil menyalin DevToolsActivePort dari Edge ke $targetFile!"
} else {
    Write-Error "File DevToolsActivePort tidak ditemukan di profil Edge $sourceFile!"
}
