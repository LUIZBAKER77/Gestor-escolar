@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Extrator de APKs - Colegio Santa Catarina

set "ADB_CMD="
set "PASTA_SAIDA=%~dp0apks_extraidos"

call :LOCALIZAR_ADB
if errorlevel 1 goto FIM

:MENU
cls
echo ==========================================
echo   EXTRATOR DE APKs - TABLET MODELO
echo   Colegio Santa Catarina
echo ==========================================
echo.
echo  ADB: %ADB_CMD%
echo  Saida: %PASTA_SAIDA%
echo.
echo  [1] Extrair TODOS os apps instalados pelo usuario
echo  [2] Extrair UM app especifico (pelo nome do pacote)
echo  [3] Verificar tablet conectado
echo  [4] Sair
echo.
set /p OPCAO="Digite a opcao: "
if "%OPCAO%"=="1" goto EXTRAIR_TUDO
if "%OPCAO%"=="2" goto EXTRAIR_UM
if "%OPCAO%"=="3" goto VERIFICAR
if "%OPCAO%"=="4" goto FIM
goto MENU

:VERIFICAR
cls
echo Dispositivos conectados:
call :ADB devices
echo.
echo Modelo:
call :ADB shell getprop ro.product.model
echo Android:
call :ADB shell getprop ro.build.version.release
pause
goto MENU

:EXTRAIR_TUDO
cls
echo === EXTRAIR TODOS OS APPS DO USUARIO ===
echo.
call :ADB shell echo ok >nul 2>&1
if %errorlevel% neq 0 (
    echo Nenhum tablet detectado.
    echo Verifique o cabo e aceite o popup de autorizacao USB no tablet.
    pause
    goto MENU
)
if not exist "%PASTA_SAIDA%" mkdir "%PASTA_SAIDA%"

echo Listando apps instalados pelo usuario...
call :ADB shell pm list packages -3 > "%TEMP%\pkgs.txt" 2>nul

set /a TOTAL=0
set /a OK=0
set /a FAIL=0

for /f "tokens=2 delims=:" %%P in (%TEMP%\pkgs.txt) do (
    set /a TOTAL+=1
    set "PKG=%%P"
    call :EXTRAIR_PACOTE "!PKG!"
    if !errorlevel!==0 (set /a OK+=1) else (set /a FAIL+=1)
)

echo.
echo ==========================================
echo  EXTRACAO CONCLUIDA
echo  Total: %TOTAL%  Sucesso: %OK%  Falha: %FAIL%
echo  Pasta: %PASTA_SAIDA%
echo ==========================================
pause
goto MENU

:EXTRAIR_UM
cls
echo === EXTRAIR UM APP ESPECIFICO ===
echo.
set /p PKG="Digite o nome do pacote (ex: com.google.android.youtube): "
if "%PKG%"=="" goto MENU
call :EXTRAIR_PACOTE "%PKG%"
pause
goto MENU

:EXTRAIR_PACOTE
set "PKG=%~1"
if "%PKG%"=="" exit /b 1

:: Pegar TODOS os caminhos de APK do pacote (base + splits)
call :ADB shell pm path "%PKG%" > "%TEMP%\paths_%PKG%.txt" 2>nul

:: Contar quantos APKs tem
set /a NAPKS_PKG=0
for /f "tokens=2 delims=:" %%L in (%TEMP%\paths_%PKG%.txt) do (
    set /a NAPKS_PKG+=1
)

if %NAPKS_PKG%==0 (
    echo  [NAO ENCONTRADO] %PKG%
    exit /b 1
)

:: Criar pasta para o pacote
set "DEST=%PASTA_SAIDA%\%PKG%"
if not exist "%DEST%" mkdir "%DEST%"

:: Baixar cada APK
set /a APK_IDX=0
for /f "tokens=2 delims=:" %%L in (%TEMP%\paths_%PKG%.txt) do (
    set "APK_PATH=%%L"
    :: Remover espacos e \r no inicio/fim
    set "APK_PATH=!APK_PATH: =!"

    :: Nome do arquivo
    for %%N in ("!APK_PATH!") do set "APK_NOME=%%~nxN"

    call :ADB pull "!APK_PATH!" "%DEST%\!APK_NOME!" >nul 2>&1
    if !errorlevel!==0 (
        set /a APK_IDX+=1
    )
)

if %APK_IDX%==0 (
    echo  [FALHA] %PKG%
    rmdir "%DEST%" >nul 2>&1
    exit /b 1
)

echo  [OK] %PKG% (%APK_IDX% arquivo(s))
exit /b 0

:LOCALIZAR_ADB
if exist "%~dp0adb.exe" (
    set "ADB_CMD=%~dp0adb.exe"
    goto :EOF
)
where adb >nul 2>&1
if %errorlevel%==0 (
    set "ADB_CMD=adb"
    goto :EOF
)
echo ERRO: ADB nao encontrado.
echo Coloque o adb.exe na mesma pasta ou adicione ao PATH.
pause
exit /b 1

:ADB
"%ADB_CMD%" %*
exit /b %errorlevel%

:FIM
endlocal
exit /b 0
