@echo off
setlocal

set PACKAGE=com.escola.tabletmanager
set ADMIN=%PACKAGE%/.SchoolDeviceAdminReceiver
set ACCESSIBILITY=%PACKAGE%/%PACKAGE%.PasswordGuardAccessibilityService

echo.
echo GESTOR ESCOLAR - CONFIGURACAO DO TABLET
echo.
echo Coloque o GestorEscolar.apk nesta mesma pasta antes de continuar.
echo O tablet precisa estar sem conta Google, sem senha/PIN/padrao e com USB autorizado.
echo.

adb devices
echo.
pause

echo.
echo Instalando APK...
adb install -r GestorEscolar.apk
if errorlevel 1 goto erro

echo.
echo Concedendo permissao para ativar a acessibilidade automaticamente...
adb shell pm grant %PACKAGE% android.permission.WRITE_SECURE_SETTINGS
adb shell appops set %PACKAGE% android:access_restricted_settings allow

echo.
echo Aplicando Device Owner...
adb shell dpm set-device-owner %ADMIN%
if errorlevel 1 goto erro

echo.
echo Ativando Protecao de senha na acessibilidade...
adb shell appops set %PACKAGE% android:access_restricted_settings allow
adb shell settings put secure enabled_accessibility_services %ACCESSIBILITY%
adb shell settings put secure accessibility_enabled 1

echo.
echo Reiniciando navegadores para recarregar politicas gerenciadas...
adb shell am force-stop com.android.chrome
adb shell am force-stop com.chrome.beta
adb shell am force-stop com.chrome.dev
adb shell am force-stop com.sec.android.app.sbrowser
adb shell am force-stop com.microsoft.emmx

echo.
echo Abrindo o app Gestor Escolar...
adb shell monkey -p %PACKAGE% -c android.intent.category.LAUNCHER 1

echo.
echo Configuracao concluida.
echo.
echo Verifique se aparece:
adb shell dpm list-owners
adb shell settings get secure enabled_accessibility_services
echo.
pause
exit /b 0

:erro
echo.
echo Ocorreu um erro. Confira se:
echo - o arquivo GestorEscolar.apk esta nesta pasta
echo - o tablet autorizou a depuracao USB
echo - o tablet esta sem conta Google e sem senha/PIN/padrao
echo - o app ainda nao e Device Owner antigo
echo.
pause
exit /b 1
