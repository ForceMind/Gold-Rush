@echo off
chcp 65001 >nul
cd /d "%~dp0"
start "" "https://localhost:8060/Gold%20Rush.html"
python serve.py
