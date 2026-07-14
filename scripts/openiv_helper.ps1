# Helper script for OpenIV YTD optimization workflow
# Step 1: Launch OpenIV with GTA V mode
Write-Host "=== OpenIV YTD Texture Optimizer ===" -ForegroundColor Cyan
Write-Host "`nThis will help you batch-resize oversized YTD textures (4K->2K)"
Write-Host "`nWorkflow:"
Write-Host "  1. OpenIV will open - select GTA V (FiveM / Five)"
Write-Host "  2. Navigate to Tools > Package Installer"
Write-Host "  3. Use it to open each YTD and export textures"
Write-Host "`nAfter exporting, run: python scripts/resize_pngs.py"
Write-Host "Then import back into OpenIV"
Write-Host "`nLaunching OpenIV..." -ForegroundColor Yellow

# Launch OpenIV with GTA V mode
Start-Process -FilePath "$env:LOCALAPPDATA\New Technology Studio\Apps\OpenIV\OpenIV.exe" -ArgumentList "-core.game:V -core.game.select:false"
