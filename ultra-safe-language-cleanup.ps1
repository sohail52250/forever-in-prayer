$ErrorActionPreference = "Stop"

$path = Join-Path (Get-Location) "index.html"
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backup = "index.before-ultra-safe-language-cleanup-$stamp.html"

Write-Host "============================================================"
Write-Host "FOREVER IN PRAYER - ULTRA SAFE LANGUAGE CLEANUP"
Write-Host "============================================================"

if (!(Test-Path $path)) {
    Write-Host "ABORT: index.html not found"
    exit 1
}

Copy-Item $path $backup -Force
$html = [IO.File]::ReadAllText($path)

# ------------------------------------------------------------
# PROTECTED CONTENT - MUST SURVIVE EXACTLY
# ------------------------------------------------------------

$protected = @(
    "AlFatihah.mp3",
    "Dua.mp3",
    "brother1.jpeg",
    "brother2.jpeg",
    "26 August 2025",
    "26 July 2025",
    "startPrayer",
    "forever-global-language-controller",
    "SUPPORTED_LANGUAGES",
    "DEFAULT_LANGUAGE",
    "globalLanguageSelector"
)

Write-Host ""
Write-Host "--- BEFORE CHECK ---"

foreach ($item in $protected) {
    if (!$html.Contains($item)) {
        Write-Host "ABORT: protected item missing BEFORE cleanup: $item"
        exit 1
    }
}

Write-Host "All protected content present."

# ------------------------------------------------------------
# MASK ONLY THE THREE REAL LANGUAGE SECTIONS
# ------------------------------------------------------------

$sectionRegex = '(?is)<section\b[^>]*data-memorial-language="(?:ur|ar|en)"[^>]*>.*?</section>'
$matches = [regex]::Matches($html, $sectionRegex)

if ($matches.Count -ne 3) {
    Write-Host "ABORT: expected exactly 3 canonical language sections."
    Write-Host "Found:" $matches.Count
    exit 1
}

$sections = @()
foreach ($m in $matches) {
    $sections += $m.Value
}

$counter = 0

$masked = [regex]::Replace(
    $html,
    $sectionRegex,
    {
        param($m)

        $token = "__CANONICAL_LANGUAGE_SECTION_$script:counter`__"
        $script:counter++

        return $token
    },
    [Text.RegularExpressions.RegexOptions]::Singleline
)

# ------------------------------------------------------------
# REMOVE ONLY CLEAR LEGACY DUPLICATE BLOCKS OUTSIDE
# CANONICAL LANGUAGE SECTIONS
# ------------------------------------------------------------

$legacyHeadings = @(
    "Remembering Two Beloved Brothers",
    "Two Brothers, One Bond",
    "Our Beloved Brothers",
    "Final Prayer"
)

foreach ($heading in $legacyHeadings) {

    $escaped = [regex]::Escape($heading)

    $pattern = '(?is)<h[1-6][^>]*>\s*' +
               $escaped +
               '\s*</h[1-6]>.*?(?=<h[1-6]\b|<script\b|</body>)'

    $masked = [regex]::Replace($masked, $pattern, '')
}

# Remove ONLY exact standalone legacy counters/buttons.
# Do NOT remove memorial paragraphs containing dates.

$masked = [regex]::Replace(
    $masked,
    '(?is)<p[^>]*>\s*0\s+visitors\s+offered\s+a\s+dua\.?\s*</p>',
    ''
)

$masked = [regex]::Replace(
    $masked,
    '(?is)<p[^>]*>\s*I\s+Made\s+Dua\s+Today\s*</p>',
    ''
)

# ------------------------------------------------------------
# RESTORE THE THREE CANONICAL LANGUAGE SECTIONS
# ------------------------------------------------------------

for ($j = 0; $j -lt 3; $j++) {

    $token = "__CANONICAL_LANGUAGE_SECTION_$j`__"

    if (!$masked.Contains($token)) {
        Write-Host "ABORT: canonical section token missing: $j"
        Copy-Item $backup $path -Force
        exit 1
    }

    $masked = $masked.Replace($token, $sections[$j])
}

# ------------------------------------------------------------
# POST-CLEANUP PROTECTION CHECK
# ------------------------------------------------------------

foreach ($item in $protected) {

    if (!$masked.Contains($item)) {

        Write-Host ""
        Write-Host "ABORT: protected item would be lost: $item"
        Write-Host "Restoring backup..."

        Copy-Item $backup $path -Force

        Write-Host "Original file restored."
        exit 1
    }
}

# ------------------------------------------------------------
# STRUCTURE CHECK
# ------------------------------------------------------------

$urCount = [regex]::Matches(
    $masked,
    'data-memorial-language="ur"'
).Count

$arCount = [regex]::Matches(
    $masked,
    'data-memorial-language="ar"'
).Count

$enCount = [regex]::Matches(
    $masked,
    'data-memorial-language="en"'
).Count

if ($urCount -ne 1 -or $arCount -ne 1 -or $enCount -ne 1) {

    Write-Host "ABORT: language section structure changed."
    Copy-Item $backup $path -Force
    exit 1
}

# ------------------------------------------------------------
# WRITE UTF-8 WITHOUT BOM
# ------------------------------------------------------------

$utf8 = New-Object System.Text.UTF8Encoding($false)
[IO.File]::WriteAllText($path, $masked, $utf8)

# ------------------------------------------------------------
# FINAL VERIFICATION
# ------------------------------------------------------------

$final = [IO.File]::ReadAllText($path)

Write-Host ""
Write-Host "============================================================"
Write-Host "FINAL VERIFICATION"
Write-Host "============================================================"

Write-Host "Urdu sections    :" $urCount
Write-Host "Arabic sections  :" $arCount
Write-Host "English sections :" $enCount

foreach ($item in $protected) {
    Write-Host ("{0,-40}: {1}" -f $item, $final.Contains($item))
}

Write-Host ""
Write-Host "--- DUPLICATE MARKER COUNTS ---"

foreach ($text in @(
    "Remembering Two Beloved Brothers",
    "Two Brothers, One Bond",
    "Our Beloved Brothers",
    "Final Prayer"
)) {
    Write-Host ("{0,-40}: {1}" -f $text, ([regex]::Matches(
        $final,
        [regex]::Escape($text),
        [Text.RegularExpressions.RegexOptions]::IgnoreCase
    )).Count)
}

Write-Host ""
Write-Host "============================================================"
Write-Host "ULTRA SAFE LANGUAGE CLEANUP COMPLETE"
Write-Host "============================================================"
Write-Host "Backup: $backup"
Write-Host ""
Write-Host "IMPORTANT:"
Write-Host "The protected audio, pictures, dates, prayer function,"
Write-Host "language controller and selector were preserved."
Write-Host ""
Write-Host "Run:"
Write-Host "Start-Process .\index.html"
Write-Host "============================================================"
