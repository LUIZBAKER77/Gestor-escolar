# Gestor Escolar - Passo a passo

## O que este app faz

- separa o uso de aluno e admin no tablet
- oculta apps nao permitidos no modo aluno
- protege o acesso administrativo com senha
- bloqueia a criacao de senha/PIN/padrao no modo aluno com:
  - `Device Owner`
  - politicas do `DevicePolicyManager`
  - um servico de acessibilidade que fecha telas de bloqueio de tela

## O que voce precisa antes

1. `adb.exe` funcionando no PC
2. APK compilado do app
3. tablet sem:
   - conta Google
   - outros usuarios
   - perfil de trabalho
   - senha / PIN / padrao

## Como compilar o APK

1. Abra o Android Studio
2. Abra a pasta do projeto
3. Vá em `Build > Build APK(s)`
4. Pegue o arquivo em:
   `app/build/outputs/apk/debug/app-debug.apk`
5. Copie para esta pasta e renomeie para:
   `GestorEscolar.apk`

## Como configurar o tablet

1. Ative a depuracao USB no tablet
2. Conecte o tablet no PC
3. Rode [configurar_tablets.bat](C:\Users\Luiz\Downloads\GestorEscolar_PRONTO\configurar_tablets.bat)
4. Escolha a opcao `1`
5. Aguarde o `Device Owner` ser aplicado

## Passo obrigatorio para a protecao de senha funcionar

Em Android 13+ o sistema bloqueia acessibilidade para apps instalados fora da Play Store ate voce liberar manualmente.

No tablet, faça isso:

1. `Configuracoes > Apps > Gestor Escolar`
2. Toque nos `3 pontinhos`
3. Toque em `Permitir configuracoes restritas`
4. Volte para:
   `Configuracoes > Acessibilidade > Servicos instalados > Protecao de senha`
5. Ative o servico

## Como confirmar no PC se a protecao foi ativada

Rode:

```powershell
.\adb.exe shell settings get secure enabled_accessibility_services
```

Tem que aparecer:

```text
com.escola.tabletmanager/com.escola.tabletmanager.PasswordGuardAccessibilityService
```

## Como usar no tablet

1. Abra o app `Gestor Escolar`
2. Crie a senha admin
3. Marque os apps que os alunos podem usar
4. Toque em `Salvar`
5. Toque em `Modo Aluno`

## Como testar se o bloqueio de senha funcionou

1. No modo aluno, tente abrir a tela de senha / PIN / padrao
2. O app deve fechar essa tela
3. Se quiser verificar por log:

```powershell
.\adb.exe logcat -c
```

Tente abrir a tela de senha no tablet e depois rode:

```powershell
.\adb.exe logcat -d | findstr /i "GestorEscolar PasswordGuard"
```

## Comandos uteis

Ver aparelho:

```powershell
.\adb.exe devices
```

Ver `Device Owner`:

```powershell
.\adb.exe shell dpm list-owners
```

Ver servico de acessibilidade:

```powershell
.\adb.exe shell settings get secure enabled_accessibility_services
```

## Arquivos principais

- [configurar_tablets.bat](C:\Users\Luiz\Downloads\GestorEscolar_PRONTO\configurar_tablets.bat)
- [COMANDOS_ADB_PRONTOS.txt](C:\Users\Luiz\Downloads\GestorEscolar_PRONTO\COMANDOS_ADB_PRONTOS.txt)
- [AppManager.kt](C:\Users\Luiz\Downloads\GestorEscolar_PRONTO\app\src\main\java\com\escola\tabletmanager\AppManager.kt)
- [PasswordGuardAccessibilityService.kt](C:\Users\Luiz\Downloads\GestorEscolar_PRONTO\app\src\main\java\com\escola\tabletmanager\PasswordGuardAccessibilityService.kt)
- [SchoolDeviceAdminReceiver.kt](C:\Users\Luiz\Downloads\GestorEscolar_PRONTO\app\src\main\java\com\escola\tabletmanager\SchoolDeviceAdminReceiver.kt)
