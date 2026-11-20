param([string]$Version='0.1.13')
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$project=Split-Path -Parent $PSScriptRoot
$types=@(Import-Csv -LiteralPath (Join-Path $project 'data/background-types.txt') -Encoding UTF8 | Where-Object {$_.profile -eq $_.family})
$profiles=@{}
foreach($line in (Get-Content -LiteralPath (Join-Path $project 'data/background-profiles.txt'))) {
 if(!$line -or $line.StartsWith('#')){continue}
 $cells=$line.Split(',');$profiles[$cells[0]]=$cells
}
$bitmap=[Drawing.Bitmap]::new(2000,850)
$g=[Drawing.Graphics]::FromImage($bitmap)
$g.Clear([Drawing.Color]::FromArgb(6,12,24))
$g.TextRenderingHint=[Drawing.Text.TextRenderingHint]::AntiAliasGridFit
$g.InterpolationMode=[Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$title=[Drawing.Font]::new('Segoe UI',25,[Drawing.FontStyle]::Bold)
$caption=[Drawing.Font]::new('Segoe UI',17,[Drawing.FontStyle]::Bold)
$small=[Drawing.Font]::new('Segoe UI',12)
$stars=[Drawing.Bitmap]::new((Join-Path $project 'assets/backgrounds/stars.png'))
$g.DrawString('HANGAR ORBITAL / OCHO AMBIENTES',$title,[Drawing.Brushes]::Turquoise,20,15)
$g.DrawString('Cuatro perfiles originales + cuatro nuevos. Capas transparentes sobre el campo estelar.',$small,[Drawing.Brushes]::LightSlateGray,23,62)
for($i=0;$i -lt $types.Count;$i++) {
 $type=$types[$i];$profile=$profiles[$type.profile]
 $x=15+($i%4)*500;$y=105+[int][Math]::Floor($i/4)*350
 $area=[Drawing.Rectangle]::new($x,$y,470,265)
 $g.DrawImage($stars,$area)
 $art=[Drawing.Bitmap]::new((Join-Path $project ('assets/backgrounds/'+$profile[1])))
 $attributes=[Drawing.Imaging.ImageAttributes]::new()
 $matrix=[Drawing.Imaging.ColorMatrix]::new()
 $matrix.Matrix33=if($profile.Count -gt 7){[float]::Parse($profile[7],[Globalization.CultureInfo]::InvariantCulture)}else{1}
 $attributes.SetColorMatrix($matrix)
 $g.DrawImage($art,$area,0,0,$art.Width,$art.Height,[Drawing.GraphicsUnit]::Pixel,$attributes)
 $pen=[Drawing.Pen]::new([Drawing.ColorTranslator]::FromHtml($type.color),2)
 $g.DrawRectangle($pen,$area);$pen.Dispose()
 $g.DrawString($type.name,$caption,[Drawing.Brushes]::White,$x,$y+274)
 $g.DrawString($(if($i -ge 4){'NUEVO'}else{'EXISTENTE'}),$small,[Drawing.Brushes]::LightSlateGray,$x,$y+306)
 $art.Dispose();$attributes.Dispose()
}
$g.DrawString('Nácar y Vesper conservan sus variantes históricas. Cada uno de los 100 sectores tiene un ambiente.',$small,[Drawing.Brushes]::LightSlateGray,23,810)
$path=Join-Path $project ('lore/maps/bocetos-ambientes-'+$Version+'.png')
$bitmap.Save($path,[Drawing.Imaging.ImageFormat]::Png)
$g.Dispose();$bitmap.Dispose();$title.Dispose();$caption.Dispose();$small.Dispose();$stars.Dispose()
Write-Output $path
