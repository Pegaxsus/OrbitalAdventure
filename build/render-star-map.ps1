param(
    [ValidatePattern('^\d+\.\d+\.\d+$')]
    [string]$Version = '0.1.17'
)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$project=Split-Path -Parent $PSScriptRoot
$sectors=Import-Csv -LiteralPath (Join-Path $project 'data/sectors.txt')
$links=Import-Csv -LiteralPath (Join-Path $project 'data/sector-links.txt')
$types=Import-Csv -LiteralPath (Join-Path $project 'data/background-types.txt') -Encoding UTF8
$assignments=@{}
foreach($row in (Get-Content -LiteralPath (Join-Path $project 'data/sector-backgrounds.txt'))) {if($row.StartsWith('#') -or !$row){continue};$cells=$row.Split(',');$assignments[[int]$cells[0]]=$cells[1]}
$typeById=@{};foreach($type in $types){$typeById[$type.profile]=$type}
$output=Join-Path $project "lore/maps/mapa-estelar-$Version.png"
$image=[Drawing.Bitmap]::new(3540,2010)
$graphics=[Drawing.Graphics]::FromImage($image)
$graphics.SmoothingMode=[Drawing.Drawing2D.SmoothingMode]::AntiAlias
$graphics.TextRenderingHint=[Drawing.Text.TextRenderingHint]::AntiAliasGridFit
$font=[Drawing.Font]::new('Segoe UI',12)
$bold=[Drawing.Font]::new('Segoe UI',12,[Drawing.FontStyle]::Bold)
$title=[Drawing.Font]::new('Segoe UI',26,[Drawing.FontStyle]::Bold)
$subtitle=[Drawing.Font]::new('Segoe UI',13)
$line=[Drawing.Pen]::new([Drawing.ColorTranslator]::FromHtml('#8C97A1'),1.7)
$outline=[Drawing.Pen]::new([Drawing.ColorTranslator]::FromHtml('#3C4A59'),1.7)
$ice=[Drawing.Pen]::new([Drawing.ColorTranslator]::FromHtml('#198DFF'),2.5)
$red=[Drawing.Pen]::new([Drawing.Color]::Crimson,2.5)
$station=[Drawing.SolidBrush]::new([Drawing.ColorTranslator]::FromHtml('#FFF0CC'))
$ink=[Drawing.SolidBrush]::new([Drawing.ColorTranslator]::FromHtml('#182A3B'))
$muted=[Drawing.SolidBrush]::new([Drawing.ColorTranslator]::FromHtml('#526476'))
$gateway=[Drawing.SolidBrush]::new([Drawing.ColorTranslator]::FromHtml('#FFE2E5'))
$align=[Drawing.StringFormat]::new()
$align.Alignment=[Drawing.StringAlignment]::Center
$align.LineAlignment=[Drawing.StringAlignment]::Center
$crest=[Drawing.Bitmap]::new((Join-Path $project 'assets/factions/asterion-crest.png'))
function RoundPath([Drawing.RectangleF]$box) {
    $path=[Drawing.Drawing2D.GraphicsPath]::new()
    $diameter=24
    $path.AddArc($box.X,$box.Y,$diameter,$diameter,180,90)
    $path.AddArc($box.Right-$diameter,$box.Y,$diameter,$diameter,270,90)
    $path.AddArc($box.Right-$diameter,$box.Bottom-$diameter,$diameter,$diameter,0,90)
    $path.AddArc($box.X,$box.Bottom-$diameter,$diameter,$diameter,90,90)
    $path.CloseFigure()
    return $path
}
function MapPoint($sector) {
    return [Drawing.PointF]::new(55+1.08*[float]$sector.map_x,90+1.08*[float]$sector.map_y)
}
try {
    $graphics.Clear([Drawing.Color]::White)
    $graphics.DrawString("MAPA ESTELAR  $Version",$title,$ink,30,8)
    $graphics.DrawString('100 sectores · 116 conexiones · 16 estaciones · 17 sistemas de hielo · 8 ambientes · mapa completo de referencia',$subtitle,$muted,32,58)
    foreach($edge in $links) {
        $a=MapPoint $sectors[[int]$edge.from]
        $b=MapPoint $sectors[[int]$edge.to]
        $graphics.DrawLine($line,$a,$b)
    }
    foreach($sector in $sectors) {
        $at=MapPoint $sector
        $box=[Drawing.RectangleF]::new($at.X-56,$at.Y-21,112,42)
        $fill=if($sector.id -eq '3'){$gateway}elseif($sector.station -eq '1'){$station}else{[Drawing.Brushes]::White}
        $pen=if($sector.id -eq '3'){$red}else{$outline}
        if($sector.ice -eq '1') {
            $halo=[Drawing.RectangleF]::new($box.X-6,$box.Y-6,$box.Width+12,$box.Height+12)
            $path=RoundPath $halo
            $graphics.DrawPath($ice,$path)
            $path.Dispose()
        }
        if($sector.station -eq '1') {
            $graphics.FillRectangle($fill,$box)
            $graphics.DrawRectangle($pen,$box.X,$box.Y,$box.Width,$box.Height)
        } else {
            $path=RoundPath $box
            $graphics.FillPath($fill,$path)
            $graphics.DrawPath($pen,$path)
            $path.Dispose()
        }
        $type=$typeById[$assignments[4107+[int]$sector.id]]
        $ambienceBrush=[Drawing.SolidBrush]::new([Drawing.ColorTranslator]::FromHtml($type.color))
        $graphics.FillRectangle($ambienceBrush,$box.X+4,$box.Y+7,4,28);$ambienceBrush.Dispose()
        if($sector.faction -eq 'asterion') {
            $graphics.DrawImage($crest,$box.X-24,$box.Y+9,21,24)
        }
        $graphics.DrawString($sector.name,$(if($sector.id -eq '3'){$bold}else{$font}),$(if($sector.id -eq '3'){[Drawing.Brushes]::Crimson}else{$ink}),$box,$align)
    }
    $y=1784
    $graphics.FillRectangle($station,35,$y,52,30)
    $graphics.DrawRectangle($outline,35,$y,52,30)
    $graphics.DrawString('Sistema con estación',$subtitle,$ink,100,$y+2)
    $path=RoundPath ([Drawing.RectangleF]::new(440,$y,52,30))
    $graphics.DrawPath($outline,$path);$path.Dispose()
    $graphics.DrawString('Sin estación',$subtitle,$ink,505,$y+2)
    $path=RoundPath ([Drawing.RectangleF]::new(770,$y,52,30))
    $graphics.DrawPath($ice,$path);$path.Dispose()
    $graphics.DrawString('Hielo de agua y metano en el 80 % de los asteroides',$subtitle,$ink,835,$y+2)
    $graphics.DrawString('4110  acceso al clúster',$subtitle,[Drawing.Brushes]::Crimson,1650,$y+2)
    $graphics.DrawImage($crest,2070,$y,25,30)
    $graphics.DrawString('Imperio de Asterión',$subtitle,$ink,2105,$y+2)
    $graphics.DrawString('El clúster nuevo queda pendiente de afiliación. Todas las líneas son puertas equivalentes.',$subtitle,$muted,2550,$y-8)
    $graphics.DrawString('Banda de color interior: ambiente del sector (las formas siguen indicando estación/hielo).',$subtitle,$muted,35,1840)
    for($i=0;$i -lt 8;$i++) {
        $type=$types[$i];$x=35+($i%4)*875;$legendY=1880+[int][Math]::Floor($i/4)*50
        $brush=[Drawing.SolidBrush]::new([Drawing.ColorTranslator]::FromHtml($type.color))
        $graphics.FillRectangle($brush,$x,$legendY,35,24);$brush.Dispose()
        $graphics.DrawString($type.name,$subtitle,$ink,$x+48,$legendY)
    }
    $image.Save($output,[Drawing.Imaging.ImageFormat]::Png)
    $output
}
finally {
    $graphics.Dispose();$image.Dispose();$font.Dispose();$bold.Dispose();$title.Dispose();$subtitle.Dispose()
    $line.Dispose();$outline.Dispose();$ice.Dispose();$red.Dispose();$station.Dispose();$ink.Dispose();$muted.Dispose();$gateway.Dispose();$align.Dispose();$crest.Dispose()
}
