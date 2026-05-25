# run_chrome_gui.ps1
Stop-Process -Name chrome -ErrorAction SilentlyContinue

$testProfileDir = "C:\Users\Msi_\AppData\Local\Google\Chrome\UserDataTest"
if (-not (Test-Path $testProfileDir)) {
    New-Item -ItemType Directory -Force -Path $testProfileDir | Out-Null
}

$chromePath = "C:\Program Files\Google\Chrome\Application\chrome.exe"

Write-Host "Menjalankan Chrome Headless dengan Bypassed Sandbox..."
Start-Process $chromePath -ArgumentList "--remote-debugging-port=9222", "--user-data-dir=C:\Users\Msi_\AppData\Local\Google\Chrome\UserDataTest", "--no-first-run", "--no-default-browser-check", "--headless=new", "--disable-gpu", "--no-sandbox", "--disable-setuid-sandbox"

Start-Sleep -Seconds 5

$sourceFile = Join-Path $testProfileDir "DevToolsActivePort"
$targetFile = "C:\Users\Msi_\AppData\Local\Google\Chrome\User Data\DevToolsActivePort"

if (Test-Path $sourceFile) {
    $targetDir = "C:\Users\Msi_\AppData\Local\Google\Chrome\User Data"
    if (-not (Test-Path $targetDir)) {
        New-Item -ItemType Directory -Force -Path $targetDir | Out-Null
    }
    Copy-Item -Path $sourceFile -Destination $targetFile -Force
    Write-Host "Berhasil menyalin DevToolsActivePort ke $targetFile!"
} else {
    Write-Error "File DevToolsActivePort tidak ditemukan di $sourceFile!"
}
