@echo off
chcp 65001 >nul
cls
echo =============================================================
echo  AtoM Portable - PASO 1: PREPARACION
echo  Ejecutar solo UNA VEZ. Necesita internet (~30 min).
echo =============================================================
echo.

docker info >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Docker Desktop no esta en ejecucion.
    echo Abralo y espere a que el icono de la ballena este quieto.
    pause & exit /b 1
)

SET D=%~dp0
SET D=%D:~0,-1%
cd /d "%D%"

REM === Crear directorios necesarios si no existen ===
if not exist "images"  mkdir images
if not exist "uploads" mkdir uploads

REM === Verificar que .env existe y tiene contrasenas configuradas ===
if not exist ".env" (
    echo ERROR: No se encontro el fichero .env
    echo.
    echo Debe copiar .env.example como .env y configurar las contrasenas
    echo antes de ejecutar este script.
    echo.
    echo   copy .env.example .env
    echo   notepad .env
    echo.
    pause & exit /b 1
)

REM Leer contrasenas desde .env
SET ATOM_MYSQL_PASSWORD=
SET MYSQL_ROOT_PASSWORD=
SET ATOM_ADMIN_PASSWORD=
SET ATOM_ADMIN_EMAIL=
for /f "usebackq tokens=1,* delims==" %%a in (".env") do (
    if "%%a"=="ATOM_MYSQL_PASSWORD"  set "ATOM_MYSQL_PASSWORD=%%b"
    if "%%a"=="MYSQL_ROOT_PASSWORD"  set "MYSQL_ROOT_PASSWORD=%%b"
    if "%%a"=="ATOM_ADMIN_PASSWORD"  set "ATOM_ADMIN_PASSWORD=%%b"
    if "%%a"=="ATOM_ADMIN_EMAIL"     set "ATOM_ADMIN_EMAIL=%%b"
)

REM Verificar que las contrasenas se han cambiado
echo %ATOM_MYSQL_PASSWORD% | findstr /C:"CAMBIAR" >nul
if %errorlevel% equ 0 (
    echo ERROR: Las contrasenas en .env no se han configurado.
    echo Abra .env con un editor y cambie todos los valores que dicen CAMBIAR_ESTO.
    echo.
    echo   notepad .env
    echo.
    pause & exit /b 1
)
echo %MYSQL_ROOT_PASSWORD% | findstr /C:"CAMBIAR" >nul
if %errorlevel% equ 0 (
    echo ERROR: MYSQL_ROOT_PASSWORD no se ha configurado en .env
    pause & exit /b 1
)
echo %ATOM_ADMIN_PASSWORD% | findstr /C:"CAMBIAR" >nul
if %errorlevel% equ 0 (
    echo ERROR: ATOM_ADMIN_PASSWORD no se ha configurado en .env
    pause & exit /b 1
)

if "%ATOM_ADMIN_EMAIL%"=="" set "ATOM_ADMIN_EMAIL=admin@atom.local"

echo Contrasenas leidas correctamente desde .env
echo.

echo === FASE 1: DESCARGAR Y CONSTRUIR IMAGENES ===
echo.

echo [1/6] Descargando imagenes de servicios (Docker Hub)...
docker pull nginx:1.25-alpine
docker pull docker.elastic.co/elasticsearch/elasticsearch-oss:7.10.2
docker pull percona:8.0
docker pull memcached:1.6-alpine
docker pull artefactual/gearmand:1.1.22
echo  Imagenes de servicios descargadas.
echo.

echo [2/6] Descargando codigo fuente de AtoM 2.10.0...
if exist "atom-src\index.php" (
    echo  Ya descargado.
) else (
    curl -L -o atom-src.zip "https://github.com/artefactual/atom/archive/refs/tags/v2.10.0.zip"
    if %errorlevel% neq 0 (
        echo ERROR: Fallo la descarga. Verifique su conexion.
        pause & exit /b 1
    )
    echo  Extrayendo...
    powershell -Command "Expand-Archive -Force -Path 'atom-src.zip' -DestinationPath '.'"
    if exist "atom-2.10.0" rename "atom-2.10.0" "atom-src"
    del atom-src.zip
    echo  Codigo fuente listo.
)
echo.

echo [3/6] Construyendo imagen de AtoM (10-20 min)...
docker build -t atom-portable:2.10.0 "atom-src"
if %errorlevel% neq 0 (
    echo ERROR: Fallo la construccion de AtoM.
    pause & exit /b 1
)
echo  Imagen AtoM construida.
echo.

echo [4/6] Construyendo imagen de Nginx...
docker build -t atom-nginx:1.0 "config"
if %errorlevel% neq 0 (
    echo ERROR: Fallo la construccion de Nginx.
    pause & exit /b 1
)
echo  Imagen Nginx construida.
echo.

echo [5/6] Construyendo imagen del Asistente IA...
docker build -t asistente-ia:1.0 "asistente-ia"
if %errorlevel% neq 0 (
    echo ERROR: Fallo la construccion del Asistente IA.
    pause & exit /b 1
)
echo  Imagen Asistente IA lista.
echo.

REM Rutas relativas en docker save: evita problemas de traduccion de rutas
REM en Docker Desktop con WSL2 al usar rutas absolutas de Windows.
echo [6/6] Guardando imagenes para uso offline...
docker save -o "images\atom.tar"          atom-portable:2.10.0
docker save -o "images\atom-nginx.tar"    atom-nginx:1.0
docker save -o "images\asistente.tar"     asistente-ia:1.0
docker save -o "images\nginx.tar"         nginx:1.25-alpine
docker save -o "images\elasticsearch.tar" docker.elastic.co/elasticsearch/elasticsearch-oss:7.10.2
docker save -o "images\percona.tar"       percona:8.0
docker save -o "images\memcached.tar"     memcached:1.6-alpine
docker save -o "images\gearmand.tar"      artefactual/gearmand:1.1.22
echo  Imagenes guardadas.
echo.

echo === FASE 2: INICIALIZAR BASE DE DATOS ===
echo.
echo Iniciando MySQL y Elasticsearch...
docker compose up -d percona elasticsearch memcached gearmand
echo.

echo Esperando a que MySQL este listo...
:check_mysql
timeout /t 8 /nobreak >nul
docker inspect --format "{{.State.Health.Status}}" atom-percona 2>nul | findstr /C:"healthy" >nul
if %errorlevel% neq 0 ( echo  MySQL iniciando... & goto check_mysql )
echo  MySQL listo.

echo Esperando a que Elasticsearch este listo...
:check_es
timeout /t 10 /nobreak >nul
docker inspect --format "{{.State.Health.Status}}" atom-elasticsearch 2>nul | findstr /C:"healthy" >nul
if %errorlevel% neq 0 ( echo  Elasticsearch iniciando... & goto check_es )
echo  Elasticsearch listo.
echo.

echo Iniciando AtoM...
docker compose up -d atom atom_worker
echo Esperando 25 segundos...
timeout /t 25 /nobreak >nul

echo Inicializando base de datos...
FOR /F "tokens=*" %%i IN ('docker compose ps -q atom') DO SET ATOM_ID=%%i
docker exec %ATOM_ID% php -d memory_limit=1G symfony tools:install ^
  --no-confirmation ^
  --database-host=percona ^
  --database-port=3306 ^
  --database-name=atom ^
  --database-user=atom ^
  --database-password=%ATOM_MYSQL_PASSWORD% ^
  --search-host=elasticsearch ^
  --search-port=9200 ^
  --search-index=atom ^
  --admin-email=%ATOM_ADMIN_EMAIL% ^
  --admin-username=admin ^
  --admin-password=%ATOM_ADMIN_PASSWORD%

if %errorlevel% neq 0 (
    echo  Reintentando en 30 segundos...
    timeout /t 30 /nobreak >nul
    docker exec %ATOM_ID% php -d memory_limit=1G symfony tools:install ^
      --no-confirmation ^
      --database-host=percona ^
      --database-port=3306 ^
      --database-name=atom ^
      --database-user=atom ^
      --database-password=%ATOM_MYSQL_PASSWORD% ^
      --search-host=elasticsearch ^
      --search-port=9200 ^
      --search-index=atom ^
      --admin-email=%ATOM_ADMIN_EMAIL% ^
      --admin-username=admin ^
      --admin-password=%ATOM_ADMIN_PASSWORD%
)

docker compose down
echo.
echo =============================================================
echo  PREPARACION COMPLETADA
echo.
echo  Ahora ejecute: 2_iniciar_atom.bat
echo  AtoM:         http://localhost:8080
echo  Asistente IA: http://localhost:8081
echo.
echo  Usuario: admin  /  Contrasena: la que configuro en .env
echo  CAMBIE LA CONTRASENA tras el primer acceso.
echo =============================================================
echo.
pause
