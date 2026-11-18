$ErrorActionPreference = 'Stop'
$compiler = Join-Path $env:WINDIR 'Microsoft.NET/Framework64/v4.0.30319/csc.exe'
Push-Location -LiteralPath (Split-Path -Parent $PSScriptRoot)
try {
    & $compiler /nologo /codepage:65001 /target:winexe /out:stationBuilder-1.3.exe /reference:System.Windows.Forms.dll /reference:System.Drawing.dll /reference:System.Runtime.Serialization.dll (Join-Path (Split-Path -Parent $PSScriptRoot) 'tools/StationBuilder.cs')
    if ($LASTEXITCODE -ne 0) { throw "Falló la compilación de stationBuilder ($LASTEXITCODE)." }
}
finally {
    Pop-Location
}
