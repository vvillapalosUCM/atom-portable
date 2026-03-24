@echo off
chcp 65001 >nul
cls
echo =============================================================
echo  AtoM Portable - DETENIENDO
echo =============================================================
echo.
SET D=%~dp0
SET D=%D:~0,-1%
cd /d "%D%"
docker compose down
echo Servicios detenidos. Puede apagar o desconectar el disco.
echo.
pause
