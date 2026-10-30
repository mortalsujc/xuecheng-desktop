# Generate multi-size icon.ico (16/32/48/64/128/256, BMP frames, NSIS-compatible)
# ASCII-only script so it is safe under any PowerShell code-page.
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$outDir = Split-Path -Parent $PSScriptRoot
$icoPath = Join-Path $outDir 'icon.ico'
$sizes = @(16, 32, 48, 64, 128, 256)

function New-DrawnBitmap {
    param([int]$Size)
    $bmp = New-Object System.Drawing.Bitmap($Size, $Size)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
    $rect = New-Object System.Drawing.Rectangle(0, 0, $Size, $Size)

    # Rounded-rect background with blue gradient
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $d = [int]($Size * 0.22)
    $path.AddArc(0, 0, $d, $d, 180, 90)
    $path.AddArc($Size - $d, 0, $d, $d, 270, 90)
    $path.AddArc($Size - $d, $Size - $d, $d, $d, 0, 90)
    $path.AddArc(0, $Size - $d, $d, $d, 90, 90)
    $path.CloseFigure()
    $brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush($rect, [System.Drawing.Color]::FromArgb(255, 76, 143, 255), [System.Drawing.Color]::FromArgb(255, 24, 66, 178), 45)
    $g.FillPath($brush, $path)

    # White "Xue" char (U+5B66), skipped for tiny sizes
    if ($Size -ge 32) {
        $charXue = [char]0x5B66
        $fontSize = [int]($Size * 0.54)
        $font = New-Object System.Drawing.Font('Microsoft YaHei', $fontSize, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
        $sf = New-Object System.Drawing.StringFormat
        $sf.Alignment = [System.Drawing.StringAlignment]::Center
        $sf.LineAlignment = [System.Drawing.StringAlignment]::Center
        $textRect = New-Object System.Drawing.RectangleF(0, -[float]($Size * 0.04), $Size, $Size)
        $g.DrawString($charXue, $font, [System.Drawing.Brushes]::White, $textRect, $sf)
    }
    $g.Dispose()
    return $bmp
}

function ConvertTo-BgraRows {
    param($Bitmap)
    $w = $Bitmap.Width
    $h = $Bitmap.Height
    $rect = New-Object System.Drawing.Rectangle(0, 0, $w, $h)
    $data = $Bitmap.LockBits($rect, [System.Drawing.Imaging.ImageLockMode]::ReadOnly, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $stride = $data.Stride
    $raw = New-Object byte[] ($stride * $h)
    [System.Runtime.InteropServices.Marshal]::Copy($data.Scan0, $raw, 0, $raw.Length)
    $Bitmap.UnlockBits($data)
    # ICO stores BMP rows bottom-up; LockBits rows are top-down, so reverse
    $out = New-Object byte[] ($stride * $h)
    for ($y = 0; $y -lt $h; $y++) {
        [Array]::Copy($raw, $y * $stride, $out, ($h - 1 - $y) * $stride, $stride)
    }
    return $out
}

$frames = @()
$frameSizes = @()
foreach ($s in $sizes) {
    $bmp = New-DrawnBitmap $s
    $pixels = ConvertTo-BgraRows $bmp
    $bmp.Dispose()
    $stride = $s * 4
    # BITMAPINFOHEADER (40 bytes) + BGRA pixels
    $hdr = New-Object byte[] 40
    $hdr[0] = 40                                       # biSize
    $hdr[4] = [byte]($s -band 0xFF)                    # biWidth (s<256)
    $hdr[8] = [byte]((2 * $s) -band 0xFF)              # biHeight (XOR + AND)
    $hdr[9] = [byte]((2 * $s) -shr 8 -band 0xFF)
    $hdr[12] = 1                                       # biPlanes
    $hdr[14] = 32                                      # biBitCount
    $imgSize = $stride * $s
    $hdr[20] = [byte]($imgSize -band 0xFF)             # biSizeImage
    $hdr[21] = [byte](($imgSize -shr 8) -band 0xFF)
    $hdr[22] = [byte](($imgSize -shr 16) -band 0xFF)
    $hdr[23] = [byte](($imgSize -shr 24) -band 0xFF)
    $frame = $hdr + $pixels
    $frames += , $frame
    $frameSizes += $s
}

$count = $frames.Count
$headerLen = 6 + 16 * $count
$total = $headerLen
foreach ($f in $frames) { $total += $f.Length }

$ico = New-Object byte[] $total
$ico[2] = 1                      # type: icon
$ico[4] = [byte]$count           # image count

$offset = $headerLen
for ($i = 0; $i -lt $count; $i++) {
    $s = $frameSizes[$i]
    $len = $frames[$i].Length
    $p = 6 + 16 * $i
    $ico[$p] = if ($s -ge 256) { 0 } else { [byte]$s }       # width (0 = 256)
    $ico[$p + 1] = if ($s -ge 256) { 0 } else { [byte]$s }   # height (0 = 256)
    $ico[$p + 4] = 1                                         # planes
    $ico[$p + 6] = 32                                        # bit count
    $ico[$p + 8] = [byte]($len -band 0xFF)
    $ico[$p + 9] = [byte](($len -shr 8) -band 0xFF)
    $ico[$p + 10] = [byte](($len -shr 16) -band 0xFF)
    $ico[$p + 11] = [byte](($len -shr 24) -band 0xFF)
    $ico[$p + 12] = [byte]($offset -band 0xFF)
    $ico[$p + 13] = [byte](($offset -shr 8) -band 0xFF)
    $ico[$p + 14] = [byte](($offset -shr 16) -band 0xFF)
    $ico[$p + 15] = [byte](($offset -shr 24) -band 0xFF)
    [Array]::Copy($frames[$i], 0, $ico, $offset, $len)
    $offset += $len
}

[System.IO.File]::WriteAllBytes($icoPath, $ico)
Write-Output "icon created: $icoPath ($((Get-Item -LiteralPath $icoPath).Length) bytes, $count sizes)"
