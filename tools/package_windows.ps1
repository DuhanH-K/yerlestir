$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$releaseRoot = Join-Path $projectRoot 'build/windows/x64/runner/Release'
$packageRoot = Join-Path $projectRoot 'output/Yerlestir-Windows'
$archivePath = Join-Path $projectRoot 'output/Yerlestir-Windows.zip'
if (!(Test-Path -LiteralPath (Join-Path $releaseRoot 'yerlestir.exe'))) {
    throw 'Run flutter build windows --release first.'
}
New-Item -ItemType Directory -Path $packageRoot -Force | Out-Null
Get-ChildItem -LiteralPath $releaseRoot | Where-Object Extension -ne '.pdb' |
    Copy-Item -Destination $packageRoot -Recurse -Force
$vswherePath = 'C:/Program Files (x86)/Microsoft Visual Studio/Installer/vswhere.exe'
$vsRoot = & $vswherePath -version '[17.0,18.0)' -latest -property installationPath
$crtRoot = Get-ChildItem -LiteralPath (Join-Path $vsRoot 'VC/Redist/MSVC') -Directory |
    Where-Object Name -Match '^14\.' | Sort-Object Name -Descending | Select-Object -First 1
$crtPath = Join-Path $crtRoot.FullName 'x64/Microsoft.VC143.CRT'
Get-ChildItem -LiteralPath $crtPath -Filter '*.dll' | Copy-Item -Destination $packageRoot -Force
@'
YERLESTIR! - Windows 10/11 (64 bit)

1. ZIP dosyasinin tamamini bir klasore cikart.
2. Klasordeki yerlestir.exe dosyasini ac.
3. Bloklari fareyle surukle veya once bloka, sonra tahtaya tikla.

EXE'yi tek basina tasima: DLL dosyalari ve data klasoru yaninda kalmali.
Kurulum, Flutter veya Visual Studio gerekmez. Oyun internetsiz oynanabilir.
Ilerlemen kendi bilgisayarinda saklanir. Bu PC test surumunde reklam yoktur.
'@ | Set-Content -LiteralPath (Join-Path $packageRoot 'BASLAT.txt') -Encoding utf8
Compress-Archive -Path $packageRoot -DestinationPath $archivePath -Force
Get-Item -LiteralPath $archivePath | Select-Object FullName, Length

