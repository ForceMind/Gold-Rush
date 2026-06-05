@echo off
setlocal

REM Godot 路径
set GODOT_PATH="C:\Users\wxx11\OneDrive\桌面\工具\Godot\Godot_v4.6.3-stable_win64.exe"

echo ========================================
echo Gold Rush 重新导入资源并导出
echo ========================================

REM 步骤1: 重新导入所有资源
echo [1/3] 重新导入资源...
%GODOT_PATH% --headless --import
if %ERRORLEVEL% neq 0 (
    echo 错误: 资源重新导入失败
    pause
    exit /b 1
)

REM 步骤2: 清理导入缓存
echo [2/3] 清理导入缓存...
if exist ".godot\imported" (
    echo 删除旧的导入缓存...
)

REM 步骤3: 导出Web版本
echo [3/3] 导出Web版本...
if not exist "export\web" mkdir "export\web"
%GODOT_PATH% --headless --export-release "Web" "export\web\index.html"
if %ERRORLEVEL% neq 0 (
    echo 错误: 导出失败
    pause
    exit /b 1
)

echo ========================================
echo 构建完成!
echo 输出目录: export\web\index.html
echo ========================================

pause
