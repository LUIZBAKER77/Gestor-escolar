@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Gestor Escolar - Configurador ADB

set "APP_ID=com.escola.tabletmanager"
set "ADMIN_COMPONENT=com.escola.tabletmanager/.SchoolDeviceAdminReceiver"
set "ADB_CMD="
set "APK_PATH="

call :LOCALIZAR_ADB
if errorlevel 1 goto FIM
call :FIND_APK

:MENU
cls
echo ==========================================
echo   GESTOR ESCOLAR - COLEGIO SANTA CATARINA
echo   Configurador ADB
echo ==========================================
echo.
echo  ADB: %ADB_CMD%
if defined APK_PATH (
    echo  APK: %APK_PATH%
) else (
    echo  APK: nao encontrado na pasta
)
echo.
echo  [1] Configurar UM tablet agora
echo  [2] Configurar varios tablets em sequencia
echo  [3] Verificar status do tablet
echo  [4] Ver usuarios/perfis do tablet
echo  [5] Validar bloqueio e logs
echo  [6] FAIL-SAFE / Restaurar componentes
echo  [7] Limpar contas invisíveis (resolve erro "accounts on device")
echo  [8] Sair
echo.
set /p OPCAO="Digite a opcao (1-8): "

if "%OPCAO%"=="1" goto UM
if "%OPCAO%"=="2" goto VARIOS
if "%OPCAO%"=="3" goto STATUS
if "%OPCAO%"=="4" goto USUARIOS
if "%OPCAO%"=="5" goto VALIDAR
if "%OPCAO%"=="6" goto FAILSAFE
if "%OPCAO%"=="7" goto LIMPAR_CONTAS
if "%OPCAO%"=="8" goto FIM
goto MENU

:UM
cls
echo === CONFIGURAR UM TABLET ===
echo.
echo Checklist antes de continuar:
echo  1. Tablet conectado no USB
echo  2. Depuracao USB ativada no tablet
echo  3. Conta Google removida do tablet
echo  4. Tablet sem senha/PIN/padrao configurado
echo  5. Aceite o popup de autorizacao USB no tablet
echo.
if not defined APK_PATH (
    echo AVISO: nenhum APK encontrado nesta pasta.
    echo Coloque GestorEscolar.apk ou app-debug.apk aqui se quiser instalacao automatica.
    echo.
)
pause
call :LISTAR_DEVICES
echo.
set /p OK="O tablet aparece como 'device'? S ou N: "
if /i not "%OK%"=="S" (
    echo Verifique o cabo e aceite o popup de autorizacao no tablet.
    pause
    goto MENU
)
call :EXECUTAR
goto MENU

:VARIOS
cls
echo === CONFIGURAR VARIOS TABLETS ===
echo.
set /p TOTAL="Quantos tablets configurar agora? "
set /a CONT=0
set /a SUC=0
set /a FAL=0

:LOOP
set /a REST=%TOTAL%-%CONT%
if %REST% leq 0 goto FIM_LOOP
echo.
echo Feito: %CONT%/%TOTAL%  Sucesso: %SUC%  Falha: %FAL%
echo Conecte o proximo tablet e pressione ENTER (ou F para finalizar):
set /p P=">> "
if /i "%P%"=="F" goto FIM_LOOP
echo Aguardando tablet...
call :ADB wait-for-device
timeout /t 3 /nobreak >nul
call :EXECUTAR
if %errorlevel%==0 (
    set /a SUC=%SUC%+1
) else (
    set /a FAL=%FAL%+1
)
set /a CONT=%CONT%+1
goto LOOP

:FIM_LOOP
echo.
echo === RESULTADO: Sucesso=%SUC%  Falha=%FAL% ===
pause
goto MENU

:EXECUTAR
echo.
call :ADB get-state >nul 2>&1
if %errorlevel% neq 0 (
    echo ERRO: Tablet nao detectado. Verifique o cabo USB.
    pause
    exit /b 1
)

call :INSTALAR_APK
if errorlevel 1 exit /b 1

echo.
echo Configurando Device Owner...
call :ADB shell dpm set-device-owner %ADMIN_COMPONENT% > "%TEMP%\gestor_owner_result.txt" 2>&1
findstr /i "success" "%TEMP%\gestor_owner_result.txt" >nul
if %errorlevel%==0 (
    echo.
    echo SUCESSO! Device Owner aplicado.
    call :STATUS_RAPIDO
    echo.
    echo Proximo passo no tablet:
    echo  1. Abra o Gestor Escolar
    echo  2. Crie a senha admin
    echo  3. Escolha os apps permitidos
    echo  4. Ative o Modo Aluno
    echo.
    pause
    exit /b 0
)

echo.
echo Falhou. Verificando motivo...
echo.
type "%TEMP%\gestor_owner_result.txt"
echo.

findstr /i "already several users" "%TEMP%\gestor_owner_result.txt" >nul
if %errorlevel%==0 (
    echo [PROBLEMA] Ha mais de um usuario/perfil no tablet.
    echo Use a opcao 4 para listar e a opcao 7 para tentar limpar.
    echo.
)

findstr /i "some accounts on the device" "%TEMP%\gestor_owner_result.txt" >nul
if %errorlevel%==0 (
    echo [PROBLEMA DETECTADO] Ha contas cadastradas no tablet ^(podem ser invisíveis^).
    echo.
    echo Isso e muito comum no Samsung Tab A8 e outros modelos Samsung.
    echo O sistema Samsung cria contas automaticamente mesmo sem voce fazer login.
    echo.
    echo SOLUCAO RAPIDA: Use a opcao 7 do menu para limpar contas invisiveis via ADB.
    echo.
    echo Se preferir fazer manualmente no tablet:
    echo   Configuracoes ^> Contas e backup ^> Gerenciar contas ^> Remova tudo
    echo   Configuracoes ^> Biometria e seguranca ^> Pasta Segura ^> desative
    echo   Configuracoes ^> Usuarios ^> remova Convidado se existir
    echo.
)

findstr /i "already set" "%TEMP%\gestor_owner_result.txt" >nul
if %errorlevel%==0 (
    echo [PROBLEMA] Ja existe um Device Owner configurado.
    echo Use a opcao 6 ^> A para remover e tente novamente.
    echo.
)

findstr /i "not installed" "%TEMP%\gestor_owner_result.txt" >nul
if %errorlevel%==0 (
    echo [PROBLEMA] App nao instalado. Coloque o APK na pasta e tente novamente.
    echo.
)

pause
exit /b 1

:LIMPAR_CONTAS
cls
echo ==========================================
echo   LIMPAR CONTAS INVISIVEIS
echo   ^(resolve "accounts on device"^)
echo ==========================================
echo.
call :ADB get-state >nul 2>&1
if %errorlevel% neq 0 (
    echo Nenhum tablet detectado. Conecte o tablet e tente novamente.
    pause
    goto MENU
)

echo Limpando dados do Samsung Account ^(conta invisivel mais comum^)...
call :ADB shell pm clear com.osp.app.signin >nul 2>&1
call :ADB shell pm clear com.samsung.android.mobileservice >nul 2>&1
echo OK

echo Limpando cache do Google Account...
call :ADB shell pm clear com.google.android.gsf >nul 2>&1
call :ADB shell pm clear com.google.android.gms >nul 2>&1
echo OK

echo Removendo Pasta Segura se existir...
call :ADB shell pm disable-user --user 0 com.samsung.knox.securefolder >nul 2>&1
echo OK

echo Aguardando sistema processar...
timeout /t 4 /nobreak >nul

echo.
echo Testando Device Owner agora...
call :ADB shell dpm set-device-owner %ADMIN_COMPONENT% > "%TEMP%\gestor_test.txt" 2>&1
findstr /i "success" "%TEMP%\gestor_test.txt" >nul
if %errorlevel%==0 (
    echo.
    echo ================================================
    echo  SUCESSO! Device Owner configurado apos limpeza!
    echo ================================================
    call :STATUS_RAPIDO
    pause
    goto MENU
)

echo.
type "%TEMP%\gestor_test.txt"
echo.
echo Limpeza automatica nao foi suficiente.
echo Siga as instrucoes manuais abaixo.
echo.
goto LIMPAR_MANUAL

:LIMPAR_MANUAL
echo ==========================================
echo   INSTRUCOES MANUAIS PARA SAMSUNG TAB A8
echo ==========================================
echo.
echo Faca EXATAMENTE nesta ordem no tablet:
echo.
echo PASSO 1 - Remover contas visiveis:
echo   Configuracoes ^> Contas e backup ^> Gerenciar contas
echo   Remova TODAS as contas ^(Google, Samsung, Microsoft, etc^)
echo.
echo PASSO 2 - Desativar Pasta Segura ^(se existir^):
echo   Configuracoes ^> Biometria e seguranca ^> Pasta Segura
echo   Desativar e escolher "Excluir"
echo.
echo PASSO 3 - Remover Convidado ^(se existir^):
echo   Configuracoes ^> Gerenciamento geral ^> Usuarios
echo   Remova o usuario Convidado
echo.
echo PASSO 4 - Limpar conta Samsung Account do sistema:
echo   Configuracoes ^> Aplicativos ^> ver todos ^> Samsung Account
echo   Toque em "Armazenamento" ^> "Limpar dados"
echo   ATENCAO: isso desvincula a conta Samsung, nao apaga o Google
echo.
echo PASSO 5 - Reiniciar o tablet completamente
echo   Aguarde o tablet iniciar totalmente antes de continuar
echo.
echo PASSO 6 - Volte aqui e use a opcao 1 para configurar
echo.
echo ALTERNATIVA: Se ainda nao funcionar, faca reset de fabrica
echo   Configuracoes ^> Gerenciamento geral ^> Redefinir ^> Redefinir dados de fabrica
echo   Depois refaca o setup sem entrar com nenhuma conta Google/Samsung
echo   Conecte o USB logo apos o setup inicial e rode a opcao 1
echo.
pause
goto MENU

:STATUS
cls
echo === STATUS DO TABLET ===
echo.
call :ADB get-state >nul 2>&1
if %errorlevel% neq 0 (
    echo Nenhum tablet detectado.
    pause
    goto MENU
)
call :STATUS_RAPIDO
echo.
pause
goto MENU

:USUARIOS
cls
echo === USUARIOS / PERFIS DO TABLET ===
echo.
call :ADB get-state >nul 2>&1
if %errorlevel% neq 0 (
    echo Nenhum tablet detectado.
    pause
    goto MENU
)
echo Lista de usuarios retornada pelo Android:
call :ADB shell pm list users
echo.
echo Lista detalhada:
call :ADB shell cmd user list
echo.
echo Se aparecer algo alem do usuario 0, o Device Owner via ADB pode falhar.
echo Remova no proprio tablet itens como:
echo   - Convidado
echo   - Outros usuarios
echo   - Perfil de trabalho
echo   - Pasta Segura
echo   - Modo manutencao
echo.
echo Se souber o ID de um usuario extra e quiser remover via ADB:
echo   adb shell pm remove-user ID
echo ou
echo   adb shell cmd user remove ID
echo.
echo Nunca remova o usuario 0.
pause
goto MENU

:STATUS_RAPIDO
call :ADB shell dpm list-owners 2>nul | findstr /i "tabletmanager" >nul
if %errorlevel%==0 (
    echo [OK] Gestor Escolar configurado como Device Owner
) else (
    echo [X] Device Owner NAO configurado
)
echo.
echo Pacote instalado:
call :ADB shell pm path %APP_ID%
echo.
echo Modelo:
call :ADB shell getprop ro.product.model
echo Android:
call :ADB shell getprop ro.build.version.release
echo.
echo Usuario atual:
call :ADB shell am get-current-user
exit /b 0

:VALIDAR
cls
echo === VALIDAR BLOQUEIO E LOGS ===
echo.
call :ADB get-state >nul 2>&1
if %errorlevel% neq 0 (
    echo Nenhum tablet detectado.
    pause
    goto MENU
)
echo Device Owner:
call :ADB shell dpm list-owners
echo.
echo Restricoes relacionadas a credenciais:
call :ADB shell dumpsys device_policy | findstr /i "no_config_credentials password keyguard"
echo.
echo Accessibility habilitada:
call :ADB shell settings get secure enabled_accessibility_services
echo.
echo Tarefas/componentes de senha possivelmente desativados:
call :ADB shell pm list packages -d | findstr /i "settings"
echo.
echo Ultimos logs do app:
call :ADB logcat -d | findstr /i "GestorEscolar Token de reset Keyguard senha"
echo.
echo Se aparecer "Token de reset ativo: true", o app conseguiu preparar a limpeza automatica da senha.
pause
goto MENU

:FAILSAFE
cls
echo ==========================================
echo   FAIL-SAFE / RESTAURACAO
echo ==========================================
echo.
echo [A] Remover Device Owner completamente
echo [B] Verificar se o app ainda esta instalado
echo [C] Voltar ao menu
echo.
set /p FS="Opcao: "
if /i "%FS%"=="A" goto FS_OWNER
if /i "%FS%"=="B" goto FS_PACOTE
if /i "%FS%"=="C" goto MENU
goto FAILSAFE

:FS_PACOTE
echo.
call :ADB shell pm path %APP_ID%
pause
goto MENU

:FS_OWNER
echo.
echo ATENCAO: Remove o Device Owner completamente.
set /p CONF="Digite CONFIRMAR para continuar: "
if not "%CONF%"=="CONFIRMAR" (
    echo Cancelado.
    pause
    goto MENU
)
echo.
call :ADB shell dpm remove-active-admin --user 0 %ADMIN_COMPONENT%
echo.
echo Se nao funcionou, abra o app Gestor Escolar no tablet,
echo entre no modo Admin e use o botao "Remover" dentro do app.
pause
goto MENU

:INSTALAR_APK
if not defined APK_PATH exit /b 0

echo.
echo Instalando/atualizando APK...
call :ADB install -r "%APK_PATH%" >nul
if %errorlevel% neq 0 (
    echo Falha ao instalar o APK.
    echo Verifique se o arquivo nao esta corrompido.
    pause
    exit /b 1
)
echo APK instalado com sucesso.
exit /b 0

:LISTAR_DEVICES
call :ADB devices
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

echo Nao encontrei o ADB.
echo.
echo Opcoes:
echo  1. Copie este arquivo para a pasta do platform-tools
echo  2. Ou coloque o adb.exe na mesma pasta deste .bat
echo  3. Ou adicione o ADB ao PATH do Windows
echo.
pause
exit /b 1

:ADB
"%ADB_CMD%" %*
exit /b %errorlevel%

:FIND_APK
set "APK_PATH="
if exist "%~dp0GestorEscolar.apk" set "APK_PATH=%~dp0GestorEscolar.apk"
if not defined APK_PATH if exist "%~dp0app-debug.apk" set "APK_PATH=%~dp0app-debug.apk"
if not defined APK_PATH if exist "%~dp0app\build\outputs\apk\debug\app-debug.apk" set "APK_PATH=%~dp0app\build\outputs\apk\debug\app-debug.apk"
exit /b 0

:FIM
endlocal
exit /b 0
