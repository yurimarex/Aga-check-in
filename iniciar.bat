@echo off
cd /d "%~dp0"
title Recepcao - Servidor local

echo Iniciando o sistema da recepcao...
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0servidor.ps1"
