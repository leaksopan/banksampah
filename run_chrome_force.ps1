# run_chrome_force.ps1
Write-Host "Menghentikan semua proses Chrome secara paksa..."
Stop-Process -Name chrome -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

Write-Host "Meluncurkan Chrome Debugging Port 9222 dengan Sandbox Bypass..."
$chromePath = "C:\Program Files\Google\Chrome\Application\chrome.exe"
Start-Process $chromePath -ArgumentList "--remote-debugging-port=9222", "--headless=new", "--disable-gpu", "--no-sandbox", "--disable-setuid-sandbox", "--no-first-run", "--no-default-browser-check"
Start-Sleep -Seconds 5

$targetFile = "C:\Users\Msi_\AppData\Local\Google\Chrome\User Data\DevToolsActivePort"
if (Test-Path $targetFile) {
    Write-Host "SUKSES: DevToolsActivePort ditemukan di $targetFile!"
    Get-Content $targetFile | Out-String | Write-Host
} else {
    Write-Error "DevToolsActivePort TETAP tidak ditemukan di $targetFile!"
    Write-Host "Mencari file DevToolsActivePort secara rekursif di User Data..."
    Get-ChildItem -Path "C:\Users\Msi_\AppData\Local\Google\Chrome\User Data" -Filter "DevToolsActivePort" -Recurse -ErrorAction SilentlyContinue | Out-String | Write-Host
}
