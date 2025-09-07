
# settings.psd1 から設定を読み込む
$settingsFile = "settings.psd1"
if (-not (Test-Path $settingsFile)) {
    Write-Host "settings.psd1 が見つかりません。"
    exit 1
}
$settings = Import-PowerShellDataFile -Path $settingsFile
$url = $settings.URL
$targetDirName = $settings.DIRNAME
$html = Invoke-WebRequest -Uri $url -UseBasicParsing


# ===============================
#  WOLF RPGエディター 自動DLスクリプト
# ===============================
Write-Host ""
Write-Host "==============================="
Write-Host "  WOLF RPGエディター 自動DLスクリプト"
Write-Host "==============================="
Write-Host ""

# 2. zipのダウンロードURL抽出（HTML内容を直接パース）
$content = $html.Content

# フルパッケージURL
$fullPattern = 'href="(https://www\.silversecond\.com/WolfRPGEditor/Data/WolfRPGEditor_[\d.]+\.zip)".*?フルパッケージ'
$fullMatch = [regex]::Match($content, $fullPattern)
$fullUrl = if ($fullMatch.Success) { $fullMatch.Groups[1].Value } else { $null }

# プログラムのみURL
$progPattern = 'href="(https://www\.silversecond\.com/WolfRPGEditor/Data/WolfRPGEditor_[\d.]+mini\.zip)".*?プログラムのみ'
$progMatch = [regex]::Match($content, $progPattern)
$progUrl = if ($progMatch.Success) { $progMatch.Groups[1].Value } else { $null }

if (-not $fullUrl -or -not $progUrl) {
    Write-Host "ダウンロードリンクが見つかりません。"
    exit 1
}

Write-Host "【ダウンロード種別を選択してください】"
Write-Host ""
Write-Host "  1: フルパッケージ"
Write-Host "     $fullUrl"
Write-Host ""
Write-Host "  2: プログラムのみ"
Write-Host "     $progUrl"
Write-Host ""
$choice = Read-Host "番号を入力してください (1/2)"

if ($choice -eq "1") {
    $dlUrl = $fullUrl
    $dlType = "フルパッケージ"
} elseif ($choice -eq "2") {
    $dlUrl = $progUrl
    $dlType = "プログラムのみ"
} else {
    Write-Host "無効な選択です。"
    exit 1
}

Write-Host ""
Write-Host "【保存ファイル名の指定】"
Write-Host ""
$saveName = Read-Host "保存するファイル名（.zip拡張子含む、空欄で元ファイル名）を入力してください"
if ([string]::IsNullOrWhiteSpace($saveName)) {
    $saveName = [System.IO.Path]::GetFileName($dlUrl)
    Write-Host "→ ファイル名が未入力のため、$saveName で保存します。"
}
if (-not $saveName.EndsWith(".zip")) {
    $saveName += ".zip"
}
Write-Host ""

Write-Host "【ダウンロード開始】"
Write-Host "  $dlUrl"
Write-Host ""
Invoke-WebRequest -Uri $dlUrl -OutFile $saveName

# 5. zip展開＆ディレクトリ名リネーム
$extractDir = [System.IO.Path]::GetFileNameWithoutExtension($saveName)

# 7z.exeのパスを探す
$sevenZipCandidates = @(
    "C:\\Program Files\\7-Zip\\7z.exe",
    "C:\\Program Files (x86)\\7-Zip\\7z.exe",
    "7z.exe"
)
$sevenZip = $sevenZipCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1

Write-Host "【展開処理】"
if ($sevenZip) {
    Write-Host "  7z.exe を使用して展開します（日本語ファイル名対応）"
    & "$sevenZip" x "$saveName" "-o$extractDir" -y | Out-Null
} else {
    Write-Host "  7z.exe が見つかりません。PowerShell標準のExpand-Archiveで展開します。"
    Write-Host "  ※日本語ファイル名が文字化けする可能性があります。"
    Expand-Archive -Path $saveName -DestinationPath $extractDir -Force
}
Write-Host ""

# 6. Editor.ini生成先ディレクトリを自動判別
$subDir = Join-Path $extractDir $targetDirName
if (Test-Path $subDir) {
    $iniTarget = $subDir
    Write-Host "WOLF_RPG_Editor3 ディレクトリが見つかりました。Editor.iniをその中に生成します。"
} else {
    $iniTarget = $extractDir
    Write-Host "WOLF_RPG_Editor3 ディレクトリが見つかりません。Editor.iniを展開直下に生成します。"
}
$iniPath = Join-Path $iniTarget "Editor.ini"
Write-Host ""
Write-Host "【Editor.ini生成】"
Write-Host "  $iniPath"
Write-Host ""
@"
[ProgramData]
AutoTxtOutput_Folder=Data_AutoTXT
AutoTxtOutput=11111
"@ | Set-Content -Encoding UTF8 $iniPath

Write-Host "==============================="
Write-Host "  完了しました！"
Write-Host "==============================="
Write-Host ""

# --- .gitignoreコピーとgit init ---
$gitignoreSrc = Join-Path $PSScriptRoot ".gitignore"
if (Test-Path $gitignoreSrc) {
    $gitignoreDst = Join-Path $iniTarget ".gitignore"
    Copy-Item $gitignoreSrc $gitignoreDst -Force
    Write-Host ".gitignore を $iniTarget にコピーしました。"
    # git init（エラー時も続行）
    try {
        Push-Location $iniTarget
        git init | Out-Null
        Pop-Location
        Write-Host "git init を $iniTarget で実行しました。"
    } catch {
        Write-Host "git init 実行時にエラーが発生しました。gitがインストールされているかご確認ください。"
    }
} else {
    Write-Host ".gitignore がスクリプトと同じ場所に見つかりません。コピーとgit initはスキップします。"
}

Read-Host "続行するにはEnterを押してください"
