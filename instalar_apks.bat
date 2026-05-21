@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Instalador de APKs - Colegio Santa Catarina

set "ADB_CMD="
set "PASTA_APKS=%~dp0apks_extraidos"

call :LOCALIZAR_ADB
if errorlevel 1 goto FIM

:MENU
cls
echo ==========================================
echo   INSTALADOR DE APKs
echo   Colegio Santa Catarina
echo ==========================================
echo.
echo  ADB: %ADB_CMD%
echo  Pasta: %PASTA_APKS%
echo.

set /a NPASTAS=0
set /a NAPKS=0
for /d %%D in ("%PASTA_APKS%\*") do set /a NPASTAS+=1
for %%F in ("%PASTA_APKS%\*.apk") do set /a NAPKS+=1

echo  Apps (pastas split): %NPASTAS%
echo  APKs soltos:         %NAPKS%
echo.
echo  [1] Instalar em UM tablet
echo  [2] Instalar em VARIOS tablets em sequencia
echo  [3] Verificar tablet conectado
echo  [4] Sair
echo.
set /p OPCAO="Digite a opcao: "
if "%OPCAO%"=="1" goto UM
if "%OPCAO%"=="2" goto VARIOS
if "%OPCAO%"=="3" goto VERIFICAR
if "%OPCAO%"=="4" goto FIM
goto MENU

:VERIFICAR
cls
call :ADB devices
echo.
call :ADB shell getprop ro.product.model
call :ADB shell getprop ro.build.version.release
pause
goto MENU

:UM
cls
echo === INSTALAR EM UM TABLET ===
echo.
call :ADB shell echo ok >nul 2>&1
if %errorlevel% neq 0 (
    echo Nenhum tablet detectado.
    echo Verifique o cabo e aceite o popup de autorizacao USB.
    pause
    goto MENU
)
call :INSTALAR
pause
goto MENU

:VARIOS
cls
echo === INSTALAR EM VARIOS TABLETS ===
echo.
set /p TOTAL="Quantos tablets? "
set /a CONT=0
set /a SUC=0
set /a FAL=0

:LOOP
set /a REST=%TOTAL%-%CONT%
if %REST% leq 0 goto FIM_LOOP
echo.
echo Progresso: %CONT%/%TOTAL%  Sucesso: %SUC%  Falha: %FAL%
echo Conecte o proximo tablet e pressione ENTER (ou F para finalizar):
set /p P=">> "
if /i "%P%"=="F" goto FIM_LOOP
call :ADB wait-for-device
timeout /t 2 /nobreak >nul
call :INSTALAR
if !errorlevel!==0 (set /a SUC+=1) else (set /a FAL+=1)
set /a CONT+=1
goto LOOP

:FIM_LOOP
echo.
echo  Sucesso: %SUC%  Falha: %FAL%
pause
goto MENU

:INSTALAR
echo.
set /a INST_OK=0
set /a JA_INST=0
set /a INST_FAIL=0

echo  Modelo do tablet:
call :ADB shell getprop ro.product.model
echo.

rem ── Pastas (Split APKs) ──────────────────────────────────────────
for /d %%D in ("%PASTA_APKS%\*") do (
    set "PKG=%%~nD"
    call :ADB shell pm path !PKG! >nul 2>&1
    if !errorlevel!==0 (
        echo  [JA INST] !PKG!
        set /a JA_INST+=1
    ) else (
        set "LISTA="
        for %%A in ("%%D\*.apk") do set "LISTA=!LISTA! "%%A""
        if defined LISTA (
            call :ADB install-multiple -r !LISTA! >nul 2>&1
            if !errorlevel!==0 (
                echo  [OK] !PKG!
                set /a INST_OK+=1
            ) else (
                call :ADB install-multiple -r --no-streaming !LISTA! >nul 2>&1
                if !errorlevel!==0 (
                    echo  [OK] !PKG!
                    set /a INST_OK+=1
                ) else (
                    echo  [FALHA] !PKG!
                    set /a INST_FAIL+=1
                )
            )
        )
    )
)

rem ── APKs soltos ──────────────────────────────────────────────────
for %%F in ("%PASTA_APKS%\*.apk") do (
    set "PKG=%%~nF"
    call :ADB shell pm path !PKG! >nul 2>&1
    if !errorlevel!==0 (
        echo  [JA INST] !PKG!
        set /a JA_INST+=1
    ) else (
        call :ADB install -r "%%F" >nul 2>&1
        if !errorlevel!==0 (
            echo  [OK] !PKG!
            set /a INST_OK+=1
        ) else (
            call :ADB install -r --no-streaming "%%F" >nul 2>&1
            if !errorlevel!==0 (
                echo  [FALHA] !PKG!
                set /a INST_FAIL+=1
            ) else (
                echo  [OK] !PKG!
                set /a INST_OK+=1
            )
        )
    )
)

echo.
echo  ==========================================
echo   Instalados: %INST_OK%  Ja existiam: %JA_INST%  Falhas: %INST_FAIL%
echo  ==========================================
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
