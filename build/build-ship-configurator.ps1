$ErrorActionPreference = 'Stop'
$project = Split-Path -Parent $PSScriptRoot
$compiler = Join-Path $env:WINDIR 'Microsoft.NET/Framework64/v4.0.30319/csc.exe'
$source = Join-Path $project 'tools/HardpointEditor.cs'
$output = Join-Path $project 'shipConfigurator-1.5.exe'
& $compiler /nologo /codepage:65001 /target:winexe "/out:$output" /reference:System.Windows.Forms.dll /reference:System.Drawing.dll $source
if ($LASTEXITCODE -ne 0) { throw "Falló la compilación de shipConfigurator ($LASTEXITCODE)." }
