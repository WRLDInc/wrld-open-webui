# Simple Open WebUI Secret Key Generator
# Run this script to generate a secure key for Coolify

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Open WebUI Secret Key for Coolify    " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Generate a secure random key
$bytes = New-Object byte[] 32
[System.Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($bytes)
$secretKey = [System.BitConverter]::ToString($bytes) -replace '-', ''

Write-Host "Your generated secret key:" -ForegroundColor Green
Write-Host ""
Write-Host $secretKey.ToLower() -ForegroundColor Yellow
Write-Host ""
Write-Host "Instructions:" -ForegroundColor Cyan
Write-Host "1. Copy the key above" -ForegroundColor White
Write-Host "2. Go to Coolify > Your App > Environment Variables" -ForegroundColor White
Write-Host "3. Add new variable:" -ForegroundColor White
Write-Host "   Name: WEBUI_SECRET_KEY" -ForegroundColor Yellow
Write-Host "   Value: [paste your key]" -ForegroundColor Yellow
Write-Host "   Secret: Yes (check the box)" -ForegroundColor Yellow
Write-Host "4. Save and redeploy your application" -ForegroundColor White
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
