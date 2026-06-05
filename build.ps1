# Gold Rush 构建脚本
# 功能：更新版本号、导出Web版本

$ErrorActionPreference = "Stop"

# Godot 路径
$GODOT_PATH = "C:\Users\wxx11\OneDrive\桌面\工具\Godot\Godot_v4.6.3-stable_win64.exe"

# 版本号文件
$VERSION_FILE = "version.txt"

# 获取当前版本号
if (Test-Path $VERSION_FILE) {
    $version = Get-Content $VERSION_FILE -Raw
    $version = $version.Trim()
} else {
    $version = "v1.0"
}

# 解析版本号
$versionMatch = [regex]::Match($version, "v(\d+)\.(\d+)")
if ($versionMatch.Success) {
    $major = [int]$versionMatch.Groups[1].Value
    $minor = [int]$versionMatch.Groups[2].Value
} else {
    $major = 1
    $minor = 0
}

# 递增版本号
$minor++
if ($minor -ge 10) {
    $minor = 0
    $major++
}

$newVersion = "v$major.$minor"
Write-Host "更新版本号: $version -> $newVersion"

# 保存新版本号
Set-Content -Path $VERSION_FILE -Value $newVersion -NoNewline

# 更新场景文件中的版本号
$sceneFile = "scenes\StartScreen.tscn"
$sceneContent = Get-Content $sceneFile -Raw
$sceneContent = $sceneContent -replace 'text = "v\d+\.\d+"', "text = `"$newVersion`""
Set-Content -Path $sceneFile -Value $sceneContent -NoNewline

Write-Host "已更新场景文件中的版本号"

# 导出Web版本
Write-Host "开始导出Web版本..."
$exportDir = "export\web"
if (-not (Test-Path $exportDir)) {
    New-Item -ItemType Directory -Path $exportDir -Force | Out-Null
}

& $GODOT_PATH --headless --export-release "Web" "$exportDir\index.html"

if ($LASTEXITCODE -eq 0) {
    Write-Host "导出成功: $exportDir\index.html"
} else {
    Write-Host "导出失败，退出码: $LASTEXITCODE"
    exit 1
}

Write-Host "构建完成!"
