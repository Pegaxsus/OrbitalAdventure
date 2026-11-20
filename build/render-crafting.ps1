param([string]$Version='0.1.12')
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$project=Split-Path -Parent $PSScriptRoot
$materials=Import-Csv -LiteralPath (Join-Path $project 'data/materials.txt')
$recipes=Import-Csv -LiteralPath (Join-Path $project 'data/recipes.txt')
$output=Join-Path $project 'lore/industry'
New-Item -ItemType Directory -Path $output -Force | Out-Null
$rowsPerColumn=[int][Math]::Ceiling($recipes.Count/2.0)
$footerY=370+$rowsPerColumn*200+30
$art=[Drawing.Bitmap]::new(3000,($footerY+180))
$g=[Drawing.Graphics]::FromImage($art)
$g.Clear([Drawing.Color]::FromArgb(245,248,252))
$g.SmoothingMode=[Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.TextRenderingHint=[Drawing.Text.TextRenderingHint]::AntiAliasGridFit
$title=[Drawing.Font]::new('Segoe UI',44,[Drawing.FontStyle]::Bold)
$head=[Drawing.Font]::new('Segoe UI',23,[Drawing.FontStyle]::Bold)
$body=[Drawing.Font]::new('Segoe UI',20)
$small=[Drawing.Font]::new('Segoe UI',18)
$dark=[Drawing.SolidBrush]::new([Drawing.Color]::FromArgb(26,45,63))
$muted=[Drawing.SolidBrush]::new([Drawing.Color]::FromArgb(78,98,118))
$blue=[Drawing.SolidBrush]::new([Drawing.Color]::FromArgb(17,99,142))
$purple=[Drawing.SolidBrush]::new([Drawing.Color]::FromArgb(119,63,160))
$green=[Drawing.SolidBrush]::new([Drawing.Color]::FromArgb(19,116,85))
$edge=[Drawing.Pen]::new([Drawing.Color]::FromArgb(212,224,235),2)
function Caption([string]$text,[Drawing.Font]$font,[Drawing.Brush]$brush,[int]$x,[int]$y,[int]$w,[int]$h) {
 $g.DrawString($text,$font,$brush,[Drawing.RectangleF]::new($x,$y,$w,$h))
}
function Pairs([string]$value) {
 $names=foreach($entry in $value.Split('|')) {$pair=$entry.Split(':');$pair[1]+' × '+$materials[[int]$pair[0]].name}
 return ($names -join ' + ')
}
function ResultPairs($recipe,[decimal]$efficiency) {
 $recovery=if($recipe.stage -eq 'Refinado'){[decimal]0.95}else{[decimal]1}
 $names=foreach($entry in $recipe.outputs.Split('|')) {
  $pair=$entry.Split(':');$quantity=([decimal]$pair[1])*$recovery*$(if($recipe.stage -eq 'Refinado'){$efficiency}else{[decimal]1})
  $quantity.ToString('0.####',[Globalization.CultureInfo]::GetCultureInfo('es-ES'))+' × '+$materials[[int]$pair[0]].name
 }
 return ($names -join ' + ')
}
Caption ('INDUSTRIA ORBITAL / '+$Version) $title $dark 55 30 2890 76
Caption ('23 recursos brutos · '+$materials.Count+' materiales y productos · '+$recipes.Count+' recetas por lotes') $head $blue 60 115 2880 45
Caption 'COMBUSTIBLES: hielo de agua / metano / tritio / xenón. CONSTRUCCIÓN: 12 elementos. ESPECIALES: tierras raras y 6 minerales ficticios.' $body $dark 60 175 2880 40
Caption 'BASE → REFINADO → PROCESADO / FABRICACIÓN → COMPONENTES → futuro ensamblaje' $head $green 60 225 2880 45
Caption 'Cantidades ideales antes de eficiencia. Refinado: salida × 0,95 × eficiencia de estación. Procesado/fabricación/ensamblaje: 100 %, sin pérdidas. Refinería base: 80 %.' $small $muted 60 280 2860 56
for($i=0;$i -lt $recipes.Count;$i++) {
 $recipe=$recipes[$i]
 $column=[int][Math]::Floor($i/$rowsPerColumn)
 $row=$i%$rowsPerColumn
 $x=55+$column*1495
 $y=370+$row*200
 $g.FillRectangle([Drawing.Brushes]::White,$x,$y,1440,190)
 $g.DrawRectangle($edge,$x,$y,1440,190)
 $accent=if($recipe.stage -eq 'Refinado') {$blue} elseif($recipe.stage -eq 'Procesamiento') {$green} else {$purple}
 Caption (('{0:00}' -f ($i+1))+'  '+$recipe.name+'  / '+$recipe.stage) $head $accent ($x+15) ($y+6) 1400 34
 Caption ('ENTRA: '+(Pairs $recipe.inputs)) $body $dark ($x+15) ($y+42) 1400 78
 Caption ('TEÓRICO: '+(ResultPairs $recipe 1)) $body $muted ($x+15) ($y+120) 1400 33
 Caption ('ACTUAL: '+(ResultPairs $recipe 0.8)) $body $green ($x+15) ($y+154) 1400 33
}
Caption 'Especiales ocultos: Veltrita · Naurita · Oraxita · Silexio · Terina · Cuarión, además de tierras raras.' $head $purple 60 $footerY 2880 45
Caption 'Se renuevan al iniciar/cargar en 3–7 asteroides vivos por sector, con 1–3 U por asteroide. Salvaging conserva cobre / hierro / titanio / aluminio: 3, 5 o 7 U.' $small $muted 60 ($footerY+60) 2880 65
$path=Join-Path $output ('crafting-'+$Version+'.png')
$art.Save($path,[Drawing.Imaging.ImageFormat]::Png)
$g.Dispose();$art.Dispose()
foreach($item in @($title,$head,$body,$small,$dark,$muted,$blue,$purple,$green,$edge)) {$item.Dispose()}
Write-Output $path
