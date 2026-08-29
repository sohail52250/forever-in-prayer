Set-Location $PSScriptRoot
$path=(Resolve-Path ".\index.html").Path
$stamp=Get-Date -Format "yyyyMMdd-HHmmss"
$backup="index.before-safe-language-clean-$stamp.html"

Write-Host "============================================================"
Write-Host "FOREVER IN PRAYER - SAFE LANGUAGE CLEANUP"
Write-Host "============================================================"

$html=[IO.File]::ReadAllText($path)

# Protect the three canonical language sections.
$rx='(?is)<section\b[^>]*data-memorial-language="(?:ur|ar|en)"[^>]*>.*?</section>'
$sections=[regex]::Matches($html,$rx)

if($sections.Count -ne 3){
    Write-Host "ABORT: expected 3 language sections; found $($sections.Count)"
    exit 1
}

$protected=@(
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

foreach($item in $protected){
    if(-not $html.Contains($item)){
        Write-Host "ABORT: protected item missing: $item"
        exit 1
    }
}

# Mask canonical sections so cleanup can never modify them.
$keep=@()
$n=0

$work=[regex]::Replace(
    $html,
    $rx,
    {
        param($match)
        $token="___CANONICAL_LANGUAGE_$n___"
        $keep += $match.Value
        $n++
        return $token
    }
)

# Remove ONLY known duplicate memorial headings/content outside
# the canonical language sections.
$headings=@(
    "Remembering Two Beloved Brothers",
    "Two Brothers, One Bond",
    "Our Beloved Brothers",
    "Final Prayer"
)

foreach($heading in $headings){

    $escaped=[regex]::Escape($heading)

    $pattern="(?is)<h[1-6][^>]*>\s*$escaped\s*</h[1-6]>.*?(?=<h[1-6]\b|<script\b|</body>)"

    $work=[regex]::Replace($work,$pattern,"")
}

# Remove only the stray counter/message.
$work=[regex]::Replace(
    $work,
    '(?is)<p[^>]*>\s*0\s+visitors\s+offered\s+a\s+dua\.?\s*</p>',
    ""
)

# Restore canonical language sections exactly.
for($i=0;$i -lt $keep.Count;$i++){
    $work=$work.Replace(
        "___CANONICAL_LANGUAGE_$i___",
        $keep[$i]
    )
}

# Final safety verification BEFORE writing.
foreach($item in $protected){
    if(-not $work.Contains($item)){
        Write-Host "ABORT: protected item would be lost: $item"
        exit 1
    }
}

if(([regex]::Matches($work,'data-memorial-language="ur"').Count) -ne 1){
    Write-Host "ABORT: Urdu section verification failed"
    exit 1
}

if(([regex]::Matches($work,'data-memorial-language="ar"').Count) -ne 1){
    Write-Host "ABORT: Arabic section verification failed"
    exit 1
}

if(([regex]::Matches($work,'data-memorial-language="en"').Count) -ne 1){
    Write-Host "ABORT: English section verification failed"
    exit 1
}

# Backup only after all safety checks pass.
Copy-Item $path $backup -Force

try{
    [IO.File]::WriteAllText(
        $path,
        $work,
        (New-Object Text.UTF8Encoding($false))
    )

    $verify=[IO.File]::ReadAllText($path)

    foreach($item in $protected){
        if(-not $verify.Contains($item)){
            throw "Post-write verification failed: $item"
        }
    }

    if(([regex]::Matches($verify,'data-memorial-language="ur"').Count) -ne 1){
        throw "Post-write Urdu verification failed"
    }

    if(([regex]::Matches($verify,'data-memorial-language="ar"').Count) -ne 1){
        throw "Post-write Arabic verification failed"
    }

    if(([regex]::Matches($verify,'data-memorial-language="en"').Count) -ne 1){
        throw "Post-write English verification failed"
    }

    Write-Host ""
    Write-Host "============================================================"
    Write-Host "SAFE CLEANUP COMPLETE"
    Write-Host "============================================================"
    Write-Host "Backup: $backup"
    Write-Host "Urdu sections   :" ([regex]::Matches($verify,'data-memorial-language="ur"').Count)
    Write-Host "Arabic sections :" ([regex]::Matches($verify,'data-memorial-language="ar"').Count)
    Write-Host "English sections:" ([regex]::Matches($verify,'data-memorial-language="en"').Count)
    Write-Host "Audio           : OK"
    Write-Host "Pictures        : OK"
    Write-Host "Dates           : OK"
    Write-Host "Prayer          : OK"
    Write-Host "Language engine : OK"
    Write-Host "Selector        : OK"
    Write-Host "============================================================"
}
catch{
    Write-Host ""
    Write-Host "ERROR - RESTORING BACKUP"
    Copy-Item $backup $path -Force
    Write-Host "Original file restored."
    Write-Host $_.Exception.Message
    exit 1
}
