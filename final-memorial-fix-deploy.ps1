#requires -version 5.1
Set-StrictMode -Version 2
$ErrorActionPreference = 'Stop'

Set-Location $PSScriptRoot
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "FOREVER IN PRAYER - FINAL SAFE MULTILINGUAL + MEMORIAL EFFECTS" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

$index = Join-Path $PWD 'index.html'
if (!(Test-Path -LiteralPath $index)) { throw "index.html not found in $PWD" }

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$backup = Join-Path $PWD "index.before-final-multilingual-effects-$stamp.html"
Copy-Item -LiteralPath $index -Destination $backup -Force

# Prefer the verified 16/16 known-good backup if the active file is clearly damaged/default.
$known = Join-Path $PWD 'index.before-final-multilingual-recovery-20260828-055342.html'
$activeText = [IO.File]::ReadAllText($index)
$useKnown = $false
if ($activeText -match 'Firebase Hosting Setup Complete' -or
    $activeText -notmatch 'Forever In Prayer' -or
    $activeText -notmatch 'globalLanguageSelector' -or
    $activeText -notmatch 'Imran Nazir' -or
    $activeText -notmatch 'AlFatihah\.mp3') {
    if (Test-Path -LiteralPath $known) {
        Copy-Item -LiteralPath $known -Destination $index -Force
        $activeText = [IO.File]::ReadAllText($index)
        $useKnown = $true
    }
}

if ($activeText -notmatch 'Forever In Prayer') { throw "Known-good memorial HTML could not be established." }

# Locate audio assets without changing/removing any existing media.
$audioCandidates = @(Get-ChildItem -Path $PWD -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Extension -match '^\.(mp3|m4a|ogg|wav|webm)$' })

$yasin = $audioCandidates | Where-Object {
    $_.Name -match '(?i)yasin|yaseen|surah[-_ ]?y[aā]sin'
} | Select-Object -First 1

$quran = $audioCandidates | Where-Object {
    $_.Name -match '(?i)quran|quraan|recitation|tilawat'
} | Select-Object -First 1

$dua = $audioCandidates | Where-Object { $_.Name -match '(?i)^dua\.mp3$|dua' } | Select-Object -First 1

# Build relative web paths.
function Get-WebPath([string]$full) {
    $baseUri = New-Object System.Uri(($PWD.Path.TrimEnd('\\') + '\\'))
    $fullUri = New-Object System.Uri($full)
    $rel = $baseUri.MakeRelativeUri($fullUri).ToString()
    return ($rel -replace '\\','/')
}
$yasinSrc = if ($yasin) { Get-WebPath $yasin.FullName } elseif ($quran) { Get-WebPath $quran.FullName } else { '' }
$duaSrc = if ($dua) { Get-WebPath $dua.FullName } else { 'Dua.mp3' }

$controller = @'
<style id="final-memorial-language-authority">
html[dir="rtl"] body { direction: rtl; }
html[dir="ltr"] body { direction: ltr; }

[data-memorial-language] {
  display: none !important;
  visibility: hidden !important;
}
[data-memorial-language].memorial-language-active {
  display: block !important;
  visibility: visible !important;
}
[data-memorial-language="ur"].memorial-language-active,
[data-memorial-language="ar"].memorial-language-active {
  direction: rtl !important;
  text-align: right !important;
}
[data-memorial-language="en"].memorial-language-active {
  direction: ltr !important;
  text-align: left !important;
}

#memorial-rose-petals {
  position: fixed;
  inset: 0;
  pointer-events: none;
  overflow: hidden;
  z-index: 99999;
}
.memorial-rose-petal {
  position: absolute;
  top: -12vh;
  width: 14px;
  height: 10px;
  border-radius: 80% 20% 80% 20%;
  background: linear-gradient(135deg,#d11 0%,#f45 55%,#ffd 100%);
  opacity: .85;
  transform: rotate(25deg);
  animation: memorialRoseFall linear forwards;
}
@keyframes memorialRoseFall {
  0% { transform: translate3d(0,-10vh,0) rotate(0deg); opacity: 0; }
  8% { opacity: .9; }
  100% { transform: translate3d(var(--drift),115vh,0) rotate(var(--spin)); opacity: .15; }
}
#memorial-yasin-status {
  position: fixed;
  left: 50%;
  bottom: 18px;
  transform: translateX(-50%);
  z-index: 100000;
  display: none;
  padding: 9px 14px;
  border-radius: 999px;
  background: rgba(20,20,20,.88);
  color: #fff;
  font: 14px/1.3 system-ui,sans-serif;
}
#memorial-yasin-status button {
  margin-left: 8px;
  border: 0;
  border-radius: 999px;
  padding: 6px 11px;
  cursor: pointer;
}
'@

$js = @"
<script id="final-memorial-language-controller">
(function () {
  'use strict';

  var SUPPORTED = ['ur','ar','en'];
  var DEFAULT = 'ur';
  var KEY = 'foreverInPrayerLanguage';
  var selector = null;

  function normalize(v) {
    return SUPPORTED.indexOf(v) >= 0 ? v : DEFAULT;
  }

  function getLanguage() {
    var v = null;
    try { v = localStorage.getItem(KEY); } catch (_) {}
    return normalize(v);
  }

  function apply(language) {
    language = normalize(language);
    var nodes = document.querySelectorAll('[data-memorial-language]');
    for (var i = 0; i < nodes.length; i++) {
      var node = nodes[i];
      var active = node.getAttribute('data-memorial-language') === language;
      node.classList.toggle('memorial-language-active', active);
      node.setAttribute('aria-hidden', active ? 'false' : 'true');
    }

    if (selector) selector.value = language;
    document.documentElement.lang = language;
    document.documentElement.dir = (language === 'ur' || language === 'ar') ? 'rtl' : 'ltr';

    try { localStorage.setItem(KEY, language); } catch (_) {}
    window.foreverInPrayerLanguage = language;
  }

  function init() {
    selector = document.getElementById('globalLanguageSelector');
    apply(getLanguage());

    if (selector && !selector.__finalMemorialBound) {
      selector.__finalMemorialBound = true;
      selector.addEventListener('change', function () {
        apply(this.value);
        window.setTimeout(function () { apply(selector.value); }, 0);
        window.setTimeout(function () { apply(selector.value); }, 100);
      }, false);
    }

    window.setInterval(function () {
      var current = selector ? normalize(selector.value) : getLanguage();
      apply(current);
    }, 1500);
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
}());
</script>
"@

$effects = @"
<script id="final-memorial-effects">
(function () {
  'use strict';

  var YASIN_SRC = '$yasinSrc';
  var DUA_SRC = '$duaSrc';

  function makePetal() {
    var layer = document.getElementById('memorial-rose-petals');
    if (!layer) {
      layer = document.createElement('div');
      layer.id = 'memorial-rose-petals';
      layer.setAttribute('aria-hidden','true');
      document.body.appendChild(layer);
    }
    var p = document.createElement('span');
    p.className = 'memorial-rose-petal';
    p.style.left = (Math.random() * 100) + 'vw';
    p.style.animationDuration = (7 + Math.random() * 8) + 's';
    p.style.setProperty('--drift', ((Math.random() - .5) * 30) + 'vw');
    p.style.setProperty('--spin', ((Math.random() * 900) - 450) + 'deg');
    p.style.width = (9 + Math.random() * 10) + 'px';
    p.style.height = (7 + Math.random() * 8) + 'px';
    layer.appendChild(p);
    window.setTimeout(function () { if (p.parentNode) p.parentNode.removeChild(p); }, 16000);
  }

  function startPetals() {
    if (window.__memorialPetalsStarted) return;
    window.__memorialPetalsStarted = true;
    for (var i=0;i<18;i++) window.setTimeout(makePetal, i*90);
    window.setInterval(function () {
      for (var i=0;i<3;i++) makePetal();
    }, 700);
  }

  function findAudioBySrcPart(part) {
    if (!part) return null;
    var all = document.querySelectorAll('audio');
    for (var i=0;i<all.length;i++) {
      var src = all[i].getAttribute('src') || '';
      if (src.toLowerCase().indexOf(part.toLowerCase()) >= 0) return all[i];
    }
    return null;
  }

  function addYasinAudio() {
    if (!YASIN_SRC) return null;
    var existing = findAudioBySrcPart(YASIN_SRC);
    if (existing) return existing;

    var a = document.createElement('audio');
    a.id = 'surah-yasin-after-dua';
    a.preload = 'auto';
    a.src = YASIN_SRC;
    a.setAttribute('aria-label','Surah Yasin / Quran recitation');
    a.style.display = 'none';
    document.body.appendChild(a);
    return a;
  }

  function setupAudio() {
    var duaAudio = findAudioBySrcPart('Dua.mp3') || findAudioBySrcPart('dua');
    if (!duaAudio && DUA_SRC) duaAudio = findAudioBySrcPart(DUA_SRC);
    var yasinAudio = addYasinAudio();

    if (!duaAudio || !yasinAudio || duaAudio.__yasinAfterDuaBound) return;
    duaAudio.__yasinAfterDuaBound = true;

    duaAudio.addEventListener('ended', function () {
      startPetals();
      yasinAudio.currentTime = 0;
      var playPromise = yasinAudio.play();
      if (playPromise && typeof playPromise.catch === 'function') {
        playPromise.catch(function () {
          var status = document.getElementById('memorial-yasin-status');
          if (status) {
            status.style.display = 'block';
            var button = status.querySelector('button');
            if (button) button.onclick = function () {
              yasinAudio.play().then(function () { status.style.display='none'; }).catch(function(){});
            };
          }
        });
      }
    }, false);
  }

  function init() {
    var status = document.createElement('div');
    status.id = 'memorial-yasin-status';
    status.innerHTML = 'Quran recitation is ready <button type="button">Play</button>';
    document.body.appendChild(status);
    setupAudio();
    var observer = new MutationObserver(setupAudio);
    observer.observe(document.body, {childList:true, subtree:true});
  }

  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', init);
  else init();
}());
</script>
"@

# Add a CSS/JS authority at the end. No destructive language cleanup.
$h = [IO.File]::ReadAllText($index)
if ($h -notmatch 'id="final-memorial-language-authority"') {
    $h = $h -replace '(?i)</head>', ($controller + "`r`n</head>")
}
if ($h -notmatch 'id="final-memorial-language-controller"') {
    $bodyReplacement = $js + "`r`n" + $effects + "`r`n</body>"
    $h = $h -replace '(?i)</body>', $bodyReplacement
}
[IO.File]::WriteAllText($index, $h, (New-Object System.Text.UTF8Encoding($false)))

# Final local verification.
$final = [IO.File]::ReadAllText($index)
$checks = [ordered]@{
    'UTF-8 Urdu' = ($final -match 'زبان|اردو|عمران نذیر|محسن نذیر')
    'English memorial' = ($final -match 'Forever In Prayer|Imran Nazir|Mohsan Nazir')
    'Arabic' = ($final -match 'اللهم|إِنَّا')
    'Language selector' = ($final -match 'globalLanguageSelector')
    'Language authority' = ($final -match 'final-memorial-language-authority')
    'Language controller' = ($final -match 'final-memorial-language-controller')
    'Rose petals' = ($final -match 'memorial-rose-petals|memorialRoseFall')
    'Dua preserved' = ($final -match 'Dua\.mp3')
    'AlFatihah preserved' = ($final -match 'AlFatihah\.mp3')
    'Brother 1 picture' = ($final -match 'brother1\.jpeg')
    'Brother 2 picture' = ($final -match 'brother2\.jpeg')
    'Imran date' = ($final -match '26 August 2025|26 August 2025')
    'Mohsan date' = ($final -match '26 July 2025|26 July 2025')
}
Write-Host ""
Write-Host "BACKUP: $backup"
Write-Host "Known-good source used: $useKnown"
Write-Host "Yasin/Quran audio found: $([bool]$yasinSrc) -> $yasinSrc"
Write-Host ""
$checks.GetEnumerator() | ForEach-Object {
    Write-Host ("{0,-25}: {1}" -f $_.Key, $_.Value) -ForegroundColor ($(if($_.Value){'Green'}else{'Red'}))
}
if (!$checks.Values -contains $false) {
    Write-Host ""
    Write-Host "LOCAL FINALIZATION PASSED." -ForegroundColor Green
    Write-Host "Now deploy with: firebase deploy --only hosting" -ForegroundColor Yellow
} else {
    throw "Verification failed. DO NOT DEPLOY."
}



