param(
    [string]$PythonExe = "py",
    [string]$GodotExe = "D:\programas\Godot_v4.7.2-stable_win64.exe"
)

$ErrorActionPreference = "Stop"
$Root = $PSScriptRoot
$DistDir = Join-Path $Root "dist\ElCuatroLlanero"
$ZipPath = Join-Path $Root "dist\ElCuatroLlanero-Windows.zip"
$BuildTmp = Join-Path $Root "build\pyinstaller"

Write-Host "==> 1. Limpiando carpeta de salida..."
New-Item -ItemType Directory -Path $DistDir -Force | Out-Null
Get-ChildItem $DistDir -Force | Remove-Item -Recurse -Force
if (Test-Path $ZipPath) { Remove-Item $ZipPath -Force }

Write-Host "==> 2. Compilando backend Python (ANTLR4 + Turing) con PyInstaller..."
& $PythonExe -m PyInstaller --noconfirm --onedir --console `
    --name backend_server `
    --paths $Root `
    --distpath $DistDir `
    --workpath (Join-Path $BuildTmp "work") `
    --specpath $BuildTmp `
    (Join-Path $Root "backend\main.py")
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "==> 3. Exportando cliente Godot 4.7.2 (Windows Desktop)..."
$GodotProj = Join-Path $Root "cliente_Godot"
$OutExe = Join-Path $DistDir "ElCuatroLlanero.exe"
& $GodotExe --headless --path $GodotProj --export-release "Windows Desktop" $OutExe | Out-Host
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "==> 4. Creando archivo README de ejecucion y ZIP portable..."
@"
EL CUATRO LLANERO - Guia rapida
================================
1. Descomprime toda esta carpeta en cualquier ubicacion.
2. Haz doble clic en ElCuatroLlanero.exe (el servidor Python se inicia y cierra solo).

Controles:
- WASD o Flechas: Mover al Llanero (8 direcciones)
- J (Re / T), K (Sol / S), L (La7 / D), I (Sim / M): Acordes del Cuatro
- Espacio: Frenao (lanza el golpe o defensa)
- Backspace: Borrar acordes antes de enviar

Golpes validos:
- Golpe de Pajarillo (30 dano): I K L I + Espacio
- Contrapunteo Libre (25 dano): J L (K L J)+ + Espacio
- Golpe de Gaban (15 dano): J L L J + Espacio
- Seis por Derecho (Parry): J K L J + Espacio
- Zumbe y Zumbe (Esquive): K L K L + Espacio
- Tonada de Sabana (Furia -1): J I K J + Espacio
"@ | Set-Content -Path (Join-Path $DistDir "LEEME.txt") -Encoding UTF8

Compress-Archive -Path "$DistDir\*" -DestinationPath $ZipPath -CompressionLevel Optimal
Write-Host "==> Build completo:"
Write-Host "    Carpeta: $DistDir"
Write-Host "    ZIP:     $ZipPath"
