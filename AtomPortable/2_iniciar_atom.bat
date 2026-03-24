@echo off
chcp 65001 >nul
cls
echo =============================================================
echo  AtoM Portable + Asistente IA - INICIANDO
echo =============================================================
echo.

docker info >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Docker Desktop no esta en ejecucion.
    pause & exit /b 1
)

SET D=%~dp0
SET D=%D:~0,-1%
cd /d "%D%"

docker image inspect atom-portable:2.10.0 >nul 2>&1
if %errorlevel% neq 0 (
    if not exist "images\atom.tar" (
        echo ERROR: Ejecute primero 1_preparar_atom.bat
        pause & exit /b 1
    )
    echo Cargando imagenes desde disco...
    docker load -i "images\atom.tar"
    docker load -i "images\atom-nginx.tar"
    docker load -i "images\asistente.tar"
    docker load -i "images\elasticsearch.tar" >nul 2>&1
    docker load -i "images\percona.tar"       >nul 2>&1
    docker load -i "images\memcached.tar"     >nul 2>&1
    docker load -i "images\gearmand.tar"      >nul 2>&1
    echo Imagenes cargadas.
    echo.
)

echo Iniciando servicios...
docker compose up -d

echo.
echo =============================================================
echo  Servicios iniciados
echo.
echo  AtoM:         http://localhost:8080  (admin / Admin2024!)
echo  Asistente IA: http://localhost:8081
echo.
echo  AtoM tarda 1-2 min en arrancar completamente.
echo  Para detener: 3_detener_atom.bat
echo =============================================================
echo.
pause
