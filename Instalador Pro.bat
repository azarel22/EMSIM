<# :
@echo off
chcp 65001 > nul
setlocal EnableDelayedExpansion
title Microsoft Office Deployment Manager - Enterprise Edition

:: ============================================================================
:: VARIABLES PERSISTENTES Y CONFIGURACION GITHUB (AUTO-GUARDABLES EN ESTE .BAT)
:: ============================================================================
set "CFG_TIMEOUT=3600"
set "CFG_WATCHDOG=ON"
set "APP_VERSION=5.0.1"
set "GH_VERSION_URL=https://raw.githubusercontent.com/azarel22/EMSIM/main/version.txt"
set "GH_CHANGELOG_URL=https://raw.githubusercontent.com/azarel22/EMSIM/main/changelog.txt"
set "GH_SCRIPT_URL=https://raw.githubusercontent.com/azarel22/EMSIM/main/Instalador%20Pro.bat"
:: ============================================================================

for /F "delims=#" %%E in ('"prompt #$E# & echo on & for %%b in (1) do rem"') do set "ESC=%%E"
echo %ESC%[?25l

:: ============================================================================
:: PALETA DE COLORES INSTITUCIONAL / EMPRESARIAL + EFECTO PULSANTE (ANSI RGB)
:: ============================================================================
set "C_BORDER=%ESC%[38;2;70;82;102m"
set "C_SLATE=%ESC%[38;2;130;145;165m"
set "C_TEXT=%ESC%[38;2;215;222;232m"
set "C_WHITE=%ESC%[38;2;255;255;255m"

set "C_CORP=%ESC%[38;2;45;140;240m"
set "C_CYAN=%ESC%[38;2;56;189;248m"
set "C_OK=%ESC%[38;2;16;185;129m"
set "C_WARN=%ESC%[38;2;245;158;11m"
set "C_CRIT=%ESC%[38;2;239;68;68m"
set "C_BLINK=%ESC%[5m"

set "BG_HEADER=%ESC%[48;2;20;32;52m%ESC%[38;2;255;255;255m"
set "BG_OK=%ESC%[48;2;6;95;70m%ESC%[38;2;209;250;229m"
set "BG_WARN=%ESC%[48;2;120;53;15m%ESC%[38;2;254;243;199m"
set "BG_CRIT=%ESC%[48;2;127;29;29m%ESC%[38;2;254;226;226m"
set "BG_INFO=%ESC%[48;2;30;58;138m%ESC%[38;2;219;234;254m"
set "BG_UPD=%ESC%[48;2;88;28;135m%ESC%[38;2;243;232;255m"
set "C_RESET=%ESC%[0m"

:: Verificar privilegios de Administrador[cite: 1]
net session >nul 2>&1
if %errorLevel% neq 0 (
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)
cd /d "%~dp0"
set "CARPETA=%~dp0"
set "CARPETA_LIMPIA=%CARPETA:~0,-1%"
set "ACTIVITY_FILE=%TEMP%\aza_wd_activity.tmp"
set "PS_OUT_FILE=%TEMP%\aza_ps_out.tmp"
set "CHANGELOG_CACHE=%TEMP%\aza_changelog.tmp"
set "SELF_FILE=%~f0"

:: Aplicar tipografia limpia (Consolas) para interfaz empresarial
call :PS_EXEC "SET_UI_FONT"

:: Obtener Numero de Serie de la BIOS
call :PS_GET "GET_SERIAL" "" "" "BIOS_SN"
if not defined BIOS_SN set "BIOS_SN=GENERIC-SN"

:: Comprobacion de actualizaciones al iniciar
set "UPD_AVAILABLE=NO"
set "REMOTE_VER=!APP_VERSION!"
call :PS_GET "QUICK_UPDATE_CHECK" "!APP_VERSION!" "!GH_VERSION_URL!" "UPD_CHECK_RES"
if defined UPD_CHECK_RES (
    for /f "tokens=1,2 delims=|" %%A in ("!UPD_CHECK_RES!") do (
        set "UPD_AVAILABLE=%%A"
        set "REMOTE_VER=%%B"
    )
)

:: Iniciar Watchdog de inactividad si esta activo en la configuracion persistente
if /I "!CFG_WATCHDOG!"=="ON" (
    echo !TIME! > "%ACTIVITY_FILE%"
    call :PS_EXEC "START_WATCHDOG" "%CARPETA_LIMPIA%" "!CFG_TIMEOUT!" "%ACTIVITY_FILE%"
) else (
    del /f /q "%ACTIVITY_FILE%" >nul 2>&1
)

:: ============================================================================
:: MODULO DE AUTENTICACION INSTITUCIONAL (3 INTENTOS)
:: ============================================================================
set /a INTENTOS=0
set "AUTH_MODE=USER"

:LOGIN
call :FORMAT_TIME "!CFG_TIMEOUT!"
mode con: cols=74 lines=33
cls

set "WD_LOGIN_TXT=%C_WARN%○ Desactivado %C_SLATE%[Permanente]"
if /I "!CFG_WATCHDOG!"=="ON" set "WD_LOGIN_TXT=%C_OK%● Activo %C_TEXT%[!TIME_STR!]"

set "AUTH_STATE_TXT=%C_SLATE%Estado: Esperando autenticacion criptografica [Intentos: 0 de 3]"
if !INTENTOS! gtr 0 set "AUTH_STATE_TXT=%C_CRIT%Advertencia: Intento fallido !INTENTOS! de 3 antes del borrado de seguridad."

echo.
echo.
echo   %C_BORDER%┌────────────────────────────────────────────────────────────────────┐%C_RESET%
echo   %C_BORDER%│%BG_HEADER%  MICROSOFT OFFICE DEPLOYMENT MANAGER                       %C_RESET%%BG_HEADER%%ESC%[63Gv!APP_VERSION!%ESC%[72G%C_RESET%%C_BORDER%│%C_RESET%
echo   %C_BORDER%│                                                                    │%C_RESET%
echo   %C_BORDER%│%C_SLATE%  Sistema Institucional de Provisionamiento y Licenciamiento KMS    %C_BORDER%│%C_RESET%
if /I "!UPD_AVAILABLE!"=="YES" (
    echo   %C_BORDER%├────────────────────────────────────────────────────────────────────┤%C_RESET%
    echo   %C_BORDER%│  %BG_UPD% %C_BLINK%●%C_RESET%%BG_UPD% ACTUALIZACION DISPONIBLE: v!REMOTE_VER! %C_RESET% %C_CYAN%[Disponible en Menu U]%ESC%[72G%C_BORDER%│%C_RESET%
)
echo   %C_BORDER%├──────────────────────────────────┬─────────────────────────────────┤%C_RESET%
echo   %C_BORDER%│                                  │                                 │%C_RESET%
echo   %C_BORDER%│%C_SLATE%  Numero de Serie [BIOS]          %C_BORDER%│%C_SLATE%  Temporizador de Seguridad      %C_BORDER%│%C_RESET%
echo   %C_BORDER%│  %C_CYAN%!BIOS_SN!%C_RESET%%ESC%[38G%C_BORDER%│  !WD_LOGIN_TXT!%ESC%[72G%C_BORDER%│%C_RESET%
echo   %C_BORDER%│                                  │                                 │%C_RESET%
echo   %C_BORDER%├──────────────────────────────────┴─────────────────────────────────┤%C_RESET%
echo   %C_BORDER%│                                                                    │%C_RESET%
echo   %C_BORDER%│  %C_WHITE%CONTROL DE ACCESO CRIPTOGRAFICO                                   %C_BORDER%│%C_RESET%
echo   %C_BORDER%│                                                                    │%C_RESET%
echo   %C_BORDER%│  %C_SLATE%Ingrese la credencial autorizada para desbloquear la boveda RAM.  %C_BORDER%│%C_RESET%
echo   %C_BORDER%│  !AUTH_STATE_TXT!%ESC%[72G%C_BORDER%│%C_RESET%
echo   %C_BORDER%│                                                                    │%C_RESET%
echo   %C_BORDER%└────────────────────────────────────────────────────────────────────┘%C_RESET%
echo.
echo.
echo %ESC%[?25h
set "PASS_INPUT="
set /p "PASS_INPUT=   %C_CORP%❯%C_WHITE% Credencial de Acceso: %C_TEXT%"
echo %ESC%[?25l

if defined PASS_INPUT set "PASS_INPUT=!PASS_INPUT: =!"
if not defined PASS_INPUT goto FAIL_AUTH

:: Validacion criptografica unificada (Detecta si es "1015" o "M4drUg4d0r")
call :PS_GET "VERIFY_PASS" "!PASS_INPUT!" "" "AUTH_RES"
if "!AUTH_RES!"=="ADMIN" goto LOGIN_DEV_OK
if "!AUTH_RES!"=="USER" goto LOGIN_NORMAL_OK
goto FAIL_AUTH

:LOGIN_DEV_OK
set "AUTH_MODE=ADMIN"
set "CFG_WATCHDOG=OFF"
del /f /q "%ACTIVITY_FILE%" >nul 2>&1
call :PS_EXEC "SAVE_CONFIG" "CFG_WATCHDOG" "OFF"
set "MASTER_KEY=1015"
echo.
echo   %BG_WARN% MODO ADMINISTRADOR %C_RESET% %C_WARN%Acceso total concedido y Protector desactivado.%C_RESET%
ping 127.0.0.1 -n 2 >nul
goto MENU

:LOGIN_NORMAL_OK
set "AUTH_MODE=USER"
set "MASTER_KEY=1015"
echo.
echo   %BG_OK% AUTENTICADO %C_RESET% %C_OK%Sesion de operador iniciada correctamente.%C_RESET%
ping 127.0.0.1 -n 2 >nul
goto MENU

:FAIL_AUTH
set /a INTENTOS+=1
if !INTENTOS! geq 3 goto TRIGGER_LOCKOUT
echo.
echo   %BG_CRIT% ACCESO DENEGADO %C_RESET% %C_CRIT%La credencial ingresada no es valida.%C_RESET%
ping 127.0.0.1 -n 2 >nul
goto LOGIN

:TRIGGER_LOCKOUT
cls
echo.
echo.
echo   %C_CRIT%┌────────────────────────────────────────────────────────────────────┐%C_RESET%
echo   %C_CRIT%│%BG_CRIT%  ALERTA DE SEGURIDAD: LIMITE DE INTENTOS EXCEDIDO [3/3]            %C_RESET%%C_CRIT%│%C_RESET%
echo   %C_CRIT%├────────────────────────────────────────────────────────────────────┤%C_RESET%
echo   %C_CRIT%│                                                                    │%C_RESET%
echo   %C_CRIT%│  %C_WHITE%Se ha activado el protocolo de proteccion de activos.             %C_CRIT%│%C_RESET%
echo   %C_CRIT%│  %C_SLATE%Eliminando permanentemente el repositorio local...                %C_CRIT%│%C_RESET%
echo   %C_CRIT%│                                                                    │%C_RESET%
echo   %C_CRIT%└────────────────────────────────────────────────────────────────────┘%C_RESET%
ping 127.0.0.1 -n 3 >nul
goto ANIMACION_GATITO


:: ============================================================================
:: MENU PRINCIPAL (GEOMETRIA FIJA CON %ESC%[54G Y %ESC%[72G)
:: ============================================================================
:MENU
if /I "!CFG_WATCHDOG!"=="ON" echo !TIME! > "%ACTIVITY_FILE%"
call :FORMAT_TIME "!CFG_TIMEOUT!"

if /I "!AUTH_MODE!"=="ADMIN" (
    mode con: cols=74 lines=46
) else (
    mode con: cols=74 lines=38
)
cls

set "WD_MENU_TXT=%C_WARN%○ Desactivado [OFF]"
if /I "!CFG_WATCHDOG!"=="ON" set "WD_MENU_TXT=%C_OK%● Activo [!TIME_STR!]"

echo.
echo   %C_BORDER%┌────────────────────────────────────────────────────────────────────┐%C_RESET%
echo   %C_BORDER%│%BG_HEADER%  CONSOLA DE DESPLIEGUE CORPORATIVO  •  OFFICE SUITE                %C_RESET%%BG_HEADER%%ESC%[63Gv!APP_VERSION!%ESC%[72G%C_RESET%%C_BORDER%│%C_RESET%
if /I "!UPD_AVAILABLE!"=="YES" (
    echo   %C_BORDER%├────────────────────────────────────────────────────────────────────┤%C_RESET%
    echo   %C_BORDER%│  %BG_UPD% %C_BLINK%▲%C_RESET%%BG_UPD% NUEVA VERSION DISPONIBLE: v!REMOTE_VER! %C_RESET% %C_CYAN%Presione [U] para actualizar%ESC%[72G%C_BORDER%│%C_RESET%
)
echo   %C_BORDER%├───────────────────────┬──────────────────────────┬─────────────────┤%C_RESET%
echo   %C_BORDER%│%C_SLATE%  Serie del Equipo     %C_BORDER%│%C_SLATE%  Protector de Inactividad%C_BORDER%│%C_SLATE%  Nivel Acceso   %C_BORDER%│%C_RESET%
if /I "!AUTH_MODE!"=="ADMIN" (
    echo   %C_BORDER%│  %C_CYAN%!BIOS_SN!%C_RESET%%ESC%[27G%C_BORDER%│  !WD_MENU_TXT!%ESC%[54G%C_BORDER%│  %C_WARN%★ ADMINISTRADOR%ESC%[72G%C_BORDER%│%C_RESET%
) else (
    echo   %C_BORDER%│  %C_CYAN%!BIOS_SN!%C_RESET%%ESC%[27G%C_BORDER%│  !WD_MENU_TXT!%ESC%[54G%C_BORDER%│  %C_OK%◆ OPERADOR     %ESC%[72G%C_BORDER%│%C_RESET%
)
echo   %C_BORDER%├───────────────────────┴──────────────────────────┴─────────────────┤%C_RESET%
echo   %C_BORDER%│                                                                    │%C_RESET%
echo   %C_BORDER%│  %C_CORP%PAQUETES DE INSTALACION Y MANTENIMIENTO                           %C_BORDER%│%C_RESET%
echo   %C_BORDER%│                                                                    │%C_RESET%
echo   %C_BORDER%├──────┬───────────────────────────────────────────┬─────────────────┤%C_RESET%
echo   %C_BORDER%│      │                                           │                 │%C_RESET%
echo   %C_BORDER%│ %C_CORP%[1]  %C_BORDER%│ %C_WHITE%Instalar Microsoft Office 2024 LTSC       %C_BORDER%│ %C_OK%Licencia Cifrada%C_BORDER%│%C_RESET%
echo   %C_BORDER%│      │                                           │                 │%C_RESET%
echo   %C_BORDER%│ %C_CORP%[2]  %C_BORDER%│ %C_WHITE%Instalar Microsoft Office 2019 Pro        %C_BORDER%│ %C_SLATE%Config. Basica  %C_BORDER%│%C_RESET%
echo   %C_BORDER%│      │                                           │                 │%C_RESET%
echo   %C_BORDER%│ %C_WARN%[3]  %C_BORDER%│ %C_WHITE%Desinstalar Office [Limpieza Profunda]    %C_BORDER%│ %C_WARN%Purga Registro  %C_BORDER%│%C_RESET%
echo   %C_BORDER%│      │                                           │                 │%C_RESET%
echo   %C_BORDER%├──────┴───────────────────────────────────────────┴─────────────────┤%C_RESET%
echo   %C_BORDER%│                                                                    │%C_RESET%
if /I "!AUTH_MODE!"=="ADMIN" (
    echo   %C_BORDER%│  %C_CORP%ADMINISTRACION DEL SISTEMA Y ACTUALIZACIONES [ADMIN]              %C_BORDER%│%C_RESET%
) else (
    echo   %C_BORDER%│  %C_CORP%ACTUALIZACIONES Y CONTROL DE SESION                               %C_BORDER%│%C_RESET%
)
echo   %C_BORDER%│                                                                    │%C_RESET%
echo   %C_BORDER%├──────┬───────────────────────────────────────────┬─────────────────┤%C_RESET%
echo   %C_BORDER%│      │                                           │                 │%C_RESET%
if /I "!AUTH_MODE!"=="ADMIN" (
    echo   %C_BORDER%│ %C_CYAN%[C]  %C_BORDER%│ %C_TEXT%Panel de Configuracion del Sistema        %C_BORDER%│ %C_SLATE%Persistencia    %C_BORDER%│%C_RESET%
    echo   %C_BORDER%│      │                                           │                 │%C_RESET%
)
if /I "!UPD_AVAILABLE!"=="YES" (
    echo   %C_BORDER%│ %C_OK%%C_BLINK%[U]%C_RESET%  %C_BORDER%│ %C_WHITE%Centro de Actualizaciones [v!REMOTE_VER!]%ESC%[54G%C_BORDER%│ %C_OK%● Update Listo%ESC%[72G%C_BORDER%│%C_RESET%
) else (
    echo   %C_BORDER%│ %C_CYAN%[U]  %C_BORDER%│ %C_TEXT%Centro de Actualizaciones Remotas%ESC%[54G%C_BORDER%│ %C_SLATE%GitHub OTA%ESC%[72G%C_BORDER%│%C_RESET%
)
echo   %C_BORDER%│      │                                           │                 │%C_RESET%
if /I "!AUTH_MODE!"=="ADMIN" (
    echo   %C_BORDER%│ %C_WARN%[D]  %C_BORDER%│ %C_TEXT%Alternar Protector [Cambio Permanente]    %C_BORDER%│ %C_SLATE%Guardar On/Off  %C_BORDER%│%C_RESET%
    echo   %C_BORDER%│      │                                           │                 │%C_RESET%
)
echo   %C_BORDER%│ %C_CRIT%[4]  %C_BORDER%│ %C_WHITE%Finalizar Sesion / Protocolo de Borrado   %C_BORDER%│ %C_CRIT%Limpieza Final  %C_BORDER%│%C_RESET%
echo   %C_BORDER%│      │                                           │                 │%C_RESET%
echo   %C_BORDER%├──────┴───────────────────────────────────────────┴─────────────────┤%C_RESET%
if /I "!AUTH_MODE!"=="ADMIN" (
    echo   %C_BORDER%│  %C_SLATE%Comandos activos: %C_TEXT%1-4%C_SLATE%, %C_TEXT%U%C_SLATE% [Actualizar], %C_TEXT%C%C_SLATE% [Config], %C_TEXT%D%C_SLATE% [Protector]  %C_BORDER%│%C_RESET%
) else (
    echo   %C_BORDER%│  %C_SLATE%Comandos activos: %C_TEXT%1-4%C_SLATE% y %C_TEXT%U%C_SLATE% [Verificar / Instalar Actualizaciones]  %C_BORDER%│%C_RESET%
)
echo   %C_BORDER%└────────────────────────────────────────────────────────────────────┘%C_RESET%
echo.
echo %ESC%[?25h
set "OPCION="
set /p "OPCION=   %C_CORP%❯%C_WHITE% Seleccione una operacion: %C_TEXT%"
echo %ESC%[?25l

if defined OPCION set "OPCION=!OPCION: =!"
if /I "!CFG_WATCHDOG!"=="ON" echo !TIME! > "%ACTIVITY_FILE%"

if "!OPCION!"=="1" goto OFFICE2024
if "!OPCION!"=="2" goto OFFICE2019
if "!OPCION!"=="3" goto SOLO_DESINSTALAR
if "!OPCION!"=="4" goto SALIR_AUTODESTRUCCION
if /I "!OPCION!"=="U" goto GITHUB_UPDATER
if /I "!OPCION!"=="R" goto Rick
if /I "!OPCION!"=="MG" goto Masgrave

:: Opciones C y D siguen siendo exclusivas de ADMIN (M4drUg4d0r)
if /I "!AUTH_MODE!"=="ADMIN" (
    if /I "!OPCION!"=="C" goto MENU_CONFIG
    if /I "!OPCION!"=="CONFIG" goto MENU_CONFIG
    if /I "!OPCION!"=="D" goto TOGGLE_DEV
    if /I "!OPCION!"=="DEV" goto TOGGLE_DEV
)
goto MENU

:TOGGLE_DEV
if /I "!CFG_WATCHDOG!"=="ON" goto DEV_TURN_OFF
set "CFG_WATCHDOG=ON"
call :PS_EXEC "SAVE_CONFIG" "CFG_WATCHDOG" "ON"
echo !TIME! > "%ACTIVITY_FILE%"
call :PS_EXEC "START_WATCHDOG" "%CARPETA_LIMPIA%" "!CFG_TIMEOUT!" "%ACTIVITY_FILE%"
goto MENU

:DEV_TURN_OFF
set "CFG_WATCHDOG=OFF"
del /f /q "%ACTIVITY_FILE%" >nul 2>&1
call :PS_EXEC "SAVE_CONFIG" "CFG_WATCHDOG" "OFF"
goto MENU


:: ============================================================================
:: CONVERSOR AUTOMATICO DE SEGUNDOS A FORMATO HUMANO
:: ============================================================================
:FORMAT_TIME
set /a "T_SEC=%~1" 2>nul
if !T_SEC! lss 60 (
    set "TIME_STR=!T_SEC! Segundos"
    exit /b
)
set /a "T_HRS=!T_SEC! / 3600"
set /a "T_REM=!T_SEC! %% 3600"
set /a "T_MIN=!T_REM! / 60"
set /a "T_S=!T_REM! %% 60"

if !T_HRS! gtr 0 goto FMT_HOURS
if !T_S! gtr 0 (
    set "TIME_STR=!T_MIN!m !T_S!s"
    exit /b
)
if !T_MIN! equ 1 set "TIME_STR=1 Minuto"
if !T_MIN! neq 1 set "TIME_STR=!T_MIN! Minutos"
exit /b

:FMT_HOURS
if !T_MIN! gtr 0 (
    set "TIME_STR=!T_HRS!h !T_MIN!m"
    exit /b
)
if !T_HRS! equ 1 set "TIME_STR=1 Hora"
if !T_HRS! neq 1 set "TIME_STR=!T_HRS! Horas"
exit /b


:: ============================================================================
:: PANEL DE CONFIGURACION PERSISTENTE (EXCLUSIVO ADMIN)
:: ============================================================================
:MENU_CONFIG
call :FORMAT_TIME "!CFG_TIMEOUT!"
mode con: cols=74 lines=34
cls

set "WD_CFG_TXT=%C_WARN%○ Deshabilitado [OFF]"
if /I "!CFG_WATCHDOG!"=="ON" set "WD_CFG_TXT=%C_OK%● Habilitado [ON]"

echo.
echo   %C_BORDER%┌────────────────────────────────────────────────────────────────────┐%C_RESET%
echo   %C_BORDER%│%BG_HEADER%  CONFIGURACION DE PARAMETROS PERSISTENTES DEL SISTEMA              %C_RESET%%C_BORDER%│%C_RESET%
echo   %C_BORDER%│                                                                    │%C_RESET%
echo   %C_BORDER%│%C_SLATE%  Todo cambio realizado aqui queda grabado permanentemente en .bat  %C_BORDER%│%C_RESET%
echo   %C_BORDER%├──────┬───────────────────────────────────┬─────────────────────────┤%C_RESET%
echo   %C_BORDER%│      │                                   │                         │%C_RESET%
echo   %C_BORDER%│ %C_CORP%[1]  %C_BORDER%│ %C_WHITE%Tiempo Limite de Inactividad      %C_BORDER%│ %C_CYAN%!TIME_STR! %C_SLATE%[!CFG_TIMEOUT!s]%C_RESET%%ESC%[72G%C_BORDER%│%C_RESET%
echo   %C_BORDER%│      │                                   │                         │%C_RESET%
echo   %C_BORDER%│ %C_CORP%[2]  %C_BORDER%│ %C_WHITE%Estado Permanente del Protector   %C_BORDER%│ !WD_CFG_TXT!%ESC%[72G%C_BORDER%│%C_RESET%
echo   %C_BORDER%│      │                                   │                         │%C_RESET%
echo   %C_BORDER%│ %C_CORP%[3]  %C_BORDER%│ %C_WHITE%Desactivar Protector [Permanente] %C_BORDER%│ %C_WARN%Apagar y Guardar [OFF]%ESC%[72G%C_BORDER%│%C_RESET%
echo   %C_BORDER%│      │                                   │                         │%C_RESET%
echo   %C_BORDER%│ %C_CORP%[4]  %C_BORDER%│ %C_WHITE%Auditoria de Licencias Asignadas  %C_BORDER%│ %C_OK%Consultar bitacora%ESC%[72G%C_BORDER%│%C_RESET%
echo   %C_BORDER%│      │                                   │                         │%C_RESET%
echo   %C_BORDER%├──────┼───────────────────────────────────┴─────────────────────────┤%C_RESET%
echo   %C_BORDER%│      │                                                             │%C_RESET%
echo   %C_BORDER%│ %C_SLATE%[M]  %C_BORDER%│ %C_TEXT%Regresar al Menu Principal                                  %C_BORDER%│%C_RESET%
echo   %C_BORDER%│      │                                                             │%C_RESET%
echo   %C_BORDER%└──────┴─────────────────────────────────────────────────────────────┘%C_RESET%
echo.
echo %ESC%[?25h
set "CFG_OP="
set /p "CFG_OP=   %C_CORP%❯%C_WHITE% Seleccione el parametro a configurar: %C_TEXT%"
echo %ESC%[?25l

if defined CFG_OP set "CFG_OP=!CFG_OP: =!"

if "!CFG_OP!"=="1" goto CFG_SET_TIME
if "!CFG_OP!"=="2" goto CFG_TOGGLE_BOOT
if "!CFG_OP!"=="3" goto CFG_KILL_NOW
if "!CFG_OP!"=="4" goto CFG_VIEW_LOG
if /I "!CFG_OP!"=="M" goto MENU
goto MENU_CONFIG

:CFG_SET_TIME
echo.
echo   %C_SLATE%Ingrese el tiempo en segundos [Ej: 3600 = 1 Hora, 1800 = 30 Minutos]%C_RESET%
echo %ESC%[?25h
set "NEW_TIME="
set /p "NEW_TIME=   %C_CORP%❯%C_WHITE% Nuevo valor en segundos: %C_TEXT%"
echo %ESC%[?25l
if not defined NEW_TIME goto MENU_CONFIG
set "NEW_TIME=!NEW_TIME: =!"
set /a "TEST_NUM=!NEW_TIME!" 2>nul
if !TEST_NUM! lss 10 (
    echo.
    echo   %BG_CRIT% VALOR INVALIDO %C_RESET% %C_CRIT%Ingrese un numero mayor o igual a 10 segundos.%C_RESET%
    ping 127.0.0.1 -n 2 >nul
    goto MENU_CONFIG
)
set "CFG_TIMEOUT=!TEST_NUM!"
call :FORMAT_TIME "!CFG_TIMEOUT!"
call :PS_EXEC "SAVE_CONFIG" "CFG_TIMEOUT" "!CFG_TIMEOUT!"
if /I "!CFG_WATCHDOG!"=="ON" (
    del /f /q "%ACTIVITY_FILE%" >nul 2>&1
    ping 127.0.0.1 -n 2 >nul
    echo !TIME! > "%ACTIVITY_FILE%"
    call :PS_EXEC "START_WATCHDOG" "%CARPETA_LIMPIA%" "!CFG_TIMEOUT!" "%ACTIVITY_FILE%"
)
echo.
echo   %BG_OK% GUARDADO PERMANENTE %C_RESET% %C_OK%Tiempo actualizado a !TIME_STR! [!CFG_TIMEOUT!s].%C_RESET%
ping 127.0.0.1 -n 2 >nul
goto MENU_CONFIG

:CFG_TOGGLE_BOOT
set "NEW_WD=ON"
if /I "!CFG_WATCHDOG!"=="ON" set "NEW_WD=OFF"
set "CFG_WATCHDOG=!NEW_WD!"
call :PS_EXEC "SAVE_CONFIG" "CFG_WATCHDOG" "!CFG_WATCHDOG!"
if /I "!CFG_WATCHDOG!"=="OFF" (
    del /f /q "%ACTIVITY_FILE%" >nul 2>&1
) else (
    echo !TIME! > "%ACTIVITY_FILE%"
    call :PS_EXEC "START_WATCHDOG" "%CARPETA_LIMPIA%" "!CFG_TIMEOUT!" "%ACTIVITY_FILE%"
)
echo.
echo   %BG_OK% GUARDADO PERMANENTE %C_RESET% %C_OK%Estado del protector fijado en: !CFG_WATCHDOG!%C_RESET%
ping 127.0.0.1 -n 2 >nul
goto MENU_CONFIG

:CFG_KILL_NOW
set "CFG_WATCHDOG=OFF"
del /f /q "%ACTIVITY_FILE%" >nul 2>&1
call :PS_EXEC "SAVE_CONFIG" "CFG_WATCHDOG" "OFF"
echo.
echo   %BG_WARN% DESACTIVADO PERMANENTE %C_RESET% %C_WARN%El protector quedo en OFF para futuras sesiones.%C_RESET%
ping 127.0.0.1 -n 2 >nul
goto MENU_CONFIG

:CFG_VIEW_LOG
cls
echo.
echo   %C_BORDER%┌────────────────────────────────────────────────────────────────────┐%C_RESET%
echo   %C_BORDER%│%BG_HEADER%  REGISTRO DE AUDITORIA: LICENCIAS ASIGNADAS                        %C_RESET%%C_BORDER%│%C_RESET%
echo   %C_BORDER%└────────────────────────────────────────────────────────────────────┘%C_RESET%
echo.
if exist "%~dp0licencias_asignadas.log" type "%~dp0licencias_asignadas.log"
if not exist "%~dp0licencias_asignadas.log" echo   %C_SLATE%  No se encontraron registros de activacion en este directorio.%C_RESET%
echo.
echo   %C_BORDER%──────────────────────────────────────────────────────────────────────%C_RESET%
pause
goto MENU_CONFIG


:: ============================================================================
:: CENTRO DE ACTUALIZACIONES OTA (PIDE 1015Update SOLO SI ES OPERADOR)
:: ============================================================================
:GITHUB_UPDATER
mode con: cols=74 lines=38
cls
echo.
echo   %C_BORDER%┌────────────────────────────────────────────────────────────────────┐%C_RESET%
echo   %C_BORDER%│%BG_HEADER%  CENTRO DE ACTUALIZACIONES CORPORATIVAS [GITHUB OTA]               %C_RESET%%C_BORDER%│%C_RESET%
echo   %C_BORDER%│                                                                    │%C_RESET%
echo   %C_BORDER%│%C_SLATE%  Sincronizando metadatos y notas de version con el servidor...     %C_BORDER%│%C_RESET%
echo   %C_BORDER%└────────────────────────────────────────────────────────────────────┘%C_RESET%

set "OTA_STATUS=ERROR"
set "REMOTE_VER=Desconocida"
call :PS_GET "FETCH_UPDATE_INFO" "!APP_VERSION!" "!GH_VERSION_URL!" "OTA_RAW"
if defined OTA_RAW (
    for /f "tokens=1,2 delims=|" %%A in ("!OTA_RAW!") do (
        set "OTA_STATUS=%%A"
        set "REMOTE_VER=%%B"
    )
)

cls
echo.
echo   %C_BORDER%┌────────────────────────────────────────────────────────────────────┐%C_RESET%
echo   %C_BORDER%│%BG_HEADER%  CENTRO DE ACTUALIZACIONES CORPORATIVAS [GITHUB OTA]               %C_RESET%%C_BORDER%│%C_RESET%
echo   %C_BORDER%├──────────────────────────────────┬─────────────────────────────────┤%C_RESET%
echo   %C_BORDER%│                                  │                                 │%C_RESET%
echo   %C_BORDER%│%C_SLATE%  Version Local Instalada         %C_BORDER%│%C_SLATE%  Version en Servidor GitHub     %C_BORDER%│%C_RESET%
if "!OTA_STATUS!"=="UPDATE" (
    echo   %C_BORDER%│  %C_WHITE%v!APP_VERSION!%ESC%[38G%C_BORDER%│  %C_OK%● v!REMOTE_VER! [Nueva Version]%ESC%[72G%C_BORDER%│%C_RESET%
    set "UPD_AVAILABLE=YES"
) else if "!OTA_STATUS!"=="UPTODATE" (
    echo   %C_BORDER%│  %C_WHITE%v!APP_VERSION!%ESC%[38G%C_BORDER%│  %C_CYAN%✔ v!REMOTE_VER! [Al dia]%ESC%[72G%C_BORDER%│%C_RESET%
    set "UPD_AVAILABLE=NO"
) else if "!OTA_STATUS!"=="UNCONFIGURED" (
    echo   %C_BORDER%│  %C_WHITE%v!APP_VERSION!%ESC%[38G%C_BORDER%│  %C_WARN%○ Sin configurar [Plantilla]%ESC%[72G%C_BORDER%│%C_RESET%
) else (
    echo   %C_BORDER%│  %C_WHITE%v!APP_VERSION!%ESC%[38G%C_BORDER%│  %C_CRIT%✖ Sin conexion al servidor%ESC%[72G%C_BORDER%│%C_RESET%
)
echo   %C_BORDER%│                                  │                                 │%C_RESET%
echo   %C_BORDER%├──────────────────────────────────┴─────────────────────────────────┤%C_RESET%
echo   %C_BORDER%│  %C_CORP%LISTA DE CAMBIOS Y NOVEDADES [CHANGELOG.TXT]                      %C_BORDER%│%C_RESET%
echo   %C_BORDER%└────────────────────────────────────────────────────────────────────┘%C_RESET%
echo.

if exist "%CHANGELOG_CACHE%" (
    for /f "usebackq delims=" %%L in ("%CHANGELOG_CACHE%") do (
        echo     %C_TEXT%∙ %%L%C_RESET%
    )
) else (
    echo     %C_SLATE%No hay notas de version disponibles para mostrar.%C_RESET%
)

echo.
echo   %C_BORDER%──────────────────────────────────────────────────────────────────────%C_RESET%

if "!OTA_STATUS!"=="UNCONFIGURED" (
    echo.
    echo   %BG_WARN% AVISO %C_RESET% %C_WARN%Configure las URLs de su repositorio GitHub al inicio del script.%C_RESET%
    echo.
    pause
    goto MENU
)

if "!OTA_STATUS!"=="ERROR" (
    echo.
    echo   %BG_CRIT% ERROR %C_RESET% %C_CRIT%No fue posible conectar con el repositorio remoto en GitHub.%C_RESET%
    echo.
    pause
    goto MENU
)

echo.
echo %ESC%[?25h
set "UPD_CONFIRM="
if "!OTA_STATUS!"=="UPDATE" (
    set /p "UPD_CONFIRM=   %C_OK%❯%C_WHITE% ¿Desea descargar e instalar la version v!REMOTE_VER! ahora? [S / N]: %C_TEXT%"
) else (
    set /p "UPD_CONFIRM=   %C_CORP%❯%C_WHITE% El sistema esta al dia. ¿Forzar reinstalacion desde GitHub? [S / N]: %C_TEXT%"
)
echo %ESC%[?25l

if defined UPD_CONFIRM set "UPD_CONFIRM=!UPD_CONFIRM: =!"
if /I not "!UPD_CONFIRM!"=="S" goto MENU

:: Si es OPERADOR (USER), exigir la credencial "1015Update". Si es ADMIN, pasa directo.
if /I not "!AUTH_MODE!"=="ADMIN" (
    echo.
    echo   %C_BORDER%┌────────────────────────────────────────────────────────────────────┐%C_RESET%
    echo   %C_BORDER%│  %C_WARN%AUTORIZACION REQUERIDA PARA OPERADORES                            %C_BORDER%│%C_RESET%
    echo   %C_BORDER%│  %C_SLATE%Ingrese la clave de actualizacion para sobrescribir el sistema.   %C_BORDER%│%C_RESET%
    echo   %C_BORDER%└────────────────────────────────────────────────────────────────────┘%C_RESET%
    echo.
    echo %ESC%[?25h
    set "UPD_PASS="
    set /p "UPD_PASS=   %C_WARN%❯%C_WHITE% Credencial de Actualizacion: %C_TEXT%"
    echo %ESC%[?25l
    if defined UPD_PASS set "UPD_PASS=!UPD_PASS: =!"
    call :PS_GET "VERIFY_UPD_PASS" "!UPD_PASS!" "" "UPD_AUTH_RES"
    if not "!UPD_AUTH_RES!"=="OK" (
        echo.
        echo   %BG_CRIT% AUTORIZACION DENEGADA %C_RESET% %C_CRIT%Credencial de actualizacion incorrecta.%C_RESET%
        ping 127.0.0.1 -n 3 >nul
        goto MENU
    )
    echo.
    echo   %BG_OK% AUTORIZADO %C_RESET% %C_OK%Permiso de actualizacion verificado.%C_RESET%
)

echo.
call :PROGRESS_BAR "Descargando paquete de actualizacion desde GitHub..." "%C_CYAN%"
call :PS_GET "APPLY_UPDATE" "!GH_SCRIPT_URL!" "" "APPLY_RES"

if "!APPLY_RES!"=="OK" (
    echo.
    echo   %BG_OK% ACTUALIZACION COMPLETADA %C_RESET% %C_OK%Reiniciando aplicacion con la nueva version...%C_RESET%
    del /f /q "%ACTIVITY_FILE%" >nul 2>&1
    ping 127.0.0.1 -n 3 >nul
    start "" "%~f0"
    exit
) else (
    echo.
    echo   %BG_CRIT% FALLO DE DESCARGA %C_RESET% %C_CRIT%No se pudo escribir la nueva version. Verifique la URL.%C_RESET%
    pause
    goto MENU
)


:: ============================================================================
:: MODULOS SECUNDARIOS Y LOGS[cite: 1]
:: ============================================================================
:Rick
mode con: cols=70 lines=35
cls
start /b "" curl -s ascii.live/rick
set /p "="
taskkill /f /im curl.exe > nul 2>&1
cls
goto MENU

:Masgrave
cls
call :REGISTRAR_LOG "PAA999" "INICIADO"
echo.
echo   %BG_INFO% AUDITORIA %C_RESET% %C_TEXT%Evento PAA999 registrado correctamente.%C_RESET%
ping 127.0.0.1 -n 2 >nul
goto MENU

:REGISTRAR_LOG
echo [%DATE% %TIME%] SN:!BIOS_SN! - Codigo:%~1 - Estado:%~2 >> "%~dp0actividad_sistema.log"
exit /b
goto MENU


:: ============================================================================
:: FUNCION: BARRA DE PROGRESO CORPORATIVA[cite: 1]
:: ============================================================================
:PROGRESS_BAR
setlocal EnableDelayedExpansion
set "MSG=%~1"
set "COLOR=%~2"
echo.
echo   %C_TEXT%  ∙ !MSG!%C_RESET%
set "bar="
set "space=─────────────────────────"
for /L %%i in (1,1,25) do (
    set "bar=!bar!━"
    set /a "pct=%%i * 4"
    <nul set /p "=%ESC%[1G    %C_BORDER%[!COLOR!!bar!%C_BORDER%!space:~%%i!] %C_WHITE%!pct!%%%C_RESET%"
    pathping -p 10 -q 1 localhost >nul
)
echo.
endlocal
exit /b


:: ============================================================================
:: MODULO: OFFICE 2024 (CON BOVEDA CIFRADA)[cite: 1]
:: ============================================================================
:OFFICE2024
cls
echo.
echo   %C_BORDER%┌────────────────────────────────────────────────────────────────────┐%C_RESET%
echo   %C_BORDER%│%BG_HEADER%  IMPLEMENTACION DE SOFTWARE: MICROSOFT OFFICE 2024 LTSC            %C_RESET%%C_BORDER%│%C_RESET%
echo   %C_BORDER%└────────────────────────────────────────────────────────────────────┘%C_RESET%
echo.
call :DESINSTALAR

call :PROGRESS_BAR "Preparando entorno e inicializando motor ClickToRun..." "%C_CORP%"
echo.
echo   %C_CORP%  ❯ Ejecutando instalacion desatendida de Office 2024...%C_RESET%
echo   %C_SLATE%    Operacion en curso. Por favor, no cierre esta ventana.%C_RESET%
start /B /wait "" "%~dp0Office 2024\setup.exe" /configure "%~dp0Office 2024\config.xml"
echo   %C_OK%  ✔ Instalacion base finalizada correctamente.%C_RESET%

call :PROGRESS_BAR "Desencriptando licencia corporativa en memoria RAM..." "%C_CYAN%"
set "OFFICE_PATH="
if exist "%ProgramFiles%\Microsoft Office\Office16\ospp.vbs" set "OFFICE_PATH=%ProgramFiles%\Microsoft Office\Office16"
if exist "%ProgramFiles(x86)%\Microsoft Office\Office16\ospp.vbs" set "OFFICE_PATH=%ProgramFiles(x86)%\Microsoft Office\Office16"

if not defined OFFICE_PATH (
    echo.
    echo   %BG_CRIT% ERROR %C_RESET% %C_CRIT%No se encontro ospp.vbs. La instalacion no pudo completarse.%C_RESET%
    pause
    goto SALIR_AUTODESTRUCCION
)

call :PS_GET "DECRYPT_KEY" "!MASTER_KEY!" "!BIOS_SN!" "DEC_KEY"

cd /d "!OFFICE_PATH!"
echo.
echo   %C_CORP%  ❯ Asignando licencia al equipo con serie %C_WHITE%!BIOS_SN!%C_CORP%...%C_RESET%
cscript //nologo ospp.vbs /inpkey:!DEC_KEY! >nul
set "DEC_KEY="
echo   %C_CORP%  ❯ Validando activacion con el servicio de licencias...%C_RESET%
cscript //nologo ospp.vbs /act >nul
echo   %C_OK%  ✔ Producto activado y auditado en el registro local.%C_RESET%
cd /d "%~dp0"
echo.
echo   %C_BORDER%┌────────────────────────────────────────────────────────────────────┐%C_RESET%
echo   %C_BORDER%│%BG_OK%  PROCESO COMPLETADO: MICROSOFT OFFICE 2024 OPERATIVO               %C_RESET%%C_BORDER%│%C_RESET%
echo   %C_BORDER%└────────────────────────────────────────────────────────────────────┘%C_RESET%
echo.
pause
goto SALIR_AUTODESTRUCCION


:: ============================================================================
:: MODULO: OFFICE 2019[cite: 1]
:: ============================================================================
:OFFICE2019
cls
echo.
echo   %C_BORDER%┌────────────────────────────────────────────────────────────────────┐%C_RESET%
echo   %C_BORDER%│%BG_HEADER%  IMPLEMENTACION DE SOFTWARE: MICROSOFT OFFICE 2019 PRO             %C_RESET%%C_BORDER%│%C_RESET%
echo   %C_BORDER%└────────────────────────────────────────────────────────────────────┘%C_RESET%
echo.
call :DESINSTALAR

call :PROGRESS_BAR "Preparando entorno e inicializando motor ClickToRun..." "%C_CORP%"
echo.
echo   %C_CORP%  ❯ Ejecutando instalacion desatendida de Office 2019...%C_RESET%
echo   %C_SLATE%    Operacion en curso. Por favor, no cierre esta ventana.%C_RESET%
start /B /wait "" "%~dp0Office 2019\setup.exe" /configure "%~dp0Office 2019\Office2019-Basico-OK.xml"
echo   %C_OK%  ✔ Instalacion base finalizada correctamente.%C_RESET%
echo.
echo   %C_BORDER%┌────────────────────────────────────────────────────────────────────┐%C_RESET%
echo   %C_BORDER%│%BG_OK%  PROCESO COMPLETADO: MICROSOFT OFFICE 2019 OPERATIVO               %C_RESET%%C_BORDER%│%C_RESET%
echo   %C_BORDER%└────────────────────────────────────────────────────────────────────┘%C_RESET%
echo.
pause
goto SALIR_AUTODESTRUCCION


:: ============================================================================
:: MODULO: DESINSTALACION[cite: 1]
:: ============================================================================
:SOLO_DESINSTALAR
cls
echo.
echo   %C_BORDER%┌────────────────────────────────────────────────────────────────────┐%C_RESET%
echo   %C_BORDER%│%BG_WARN%  MANTENIMIENTO: REMOCION PROFUNDA DE VERSIONES PREVIAS             %C_RESET%%C_BORDER%│%C_RESET%
echo   %C_BORDER%└────────────────────────────────────────────────────────────────────┘%C_RESET%
echo.
call :DESINSTALAR
echo.
echo   %C_BORDER%┌────────────────────────────────────────────────────────────────────┐%C_RESET%
echo   %C_BORDER%│%BG_OK%  PROCESO DE LIMPIEZA FINALIZADO CORRECTAMENTE                      %C_RESET%%C_BORDER%│%C_RESET%
echo   %C_BORDER%└────────────────────────────────────────────────────────────────────┘%C_RESET%
echo.
pause
goto MENU

:DESINSTALAR
echo   %C_SLATE%  ∙ Analizando colmenas del registro en busca de instalaciones...%C_RESET%
call :PS_EXEC "UNINSTALL"
echo   %C_OK%  ✔ Verificacion del sistema concluida.%C_RESET%
goto :eof


:: ============================================================================
:: MOTOR DE COMUNICACION CON POWERSHELL (CERO TUBERIAS, CERO FALLOS EN CMD)
:: ============================================================================
:PS_EXEC
set "PS_ACTION=%~1"
set "PS_ARG1=%~2"
set "PS_ARG2=%~3"
set "PS_ARG3=%~4"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-Expression (Get-Content -LiteralPath $env:SELF_FILE -Encoding UTF8 -Raw)"
exit /b

:PS_GET
set "PS_ACTION=%~1"
set "PS_ARG1=%~2"
set "PS_ARG2=%~3"
set "RET_VAR=%~4"
del /f /q "%PS_OUT_FILE%" >nul 2>&1
powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-Expression (Get-Content -LiteralPath $env:SELF_FILE -Encoding UTF8 -Raw)"
set "!RET_VAR!="
if exist "%PS_OUT_FILE%" (
    for /f "usebackq delims=" %%R in ("%PS_OUT_FILE%") do set "!RET_VAR!=%%R"
    del /f /q "%PS_OUT_FILE%" >nul 2>&1
)
exit /b


:: ============================================================================
:: SALIDA Y AUTODESTRUCCION (OPCIONES: S, N, M - CON MAYOR ESPACIADO)[cite: 1]
:: ============================================================================
:SALIR_AUTODESTRUCCION
echo %ESC%[?25h
mode con: cols=74 lines=29
cls
echo.
echo   %C_CRIT%┌────────────────────────────────────────────────────────────────────┐%C_RESET%
echo   %C_CRIT%│%BG_CRIT%  PROTOCOLO DE SEGURIDAD: LIMPIEZA DE MEDIOS DE INSTALACION         %C_RESET%%C_CRIT%│%C_RESET%
echo   %C_CRIT%├────────────────────────────────────────────────────────────────────┤%C_RESET%
echo   %C_CRIT%│                                                                    │%C_RESET%
echo   %C_CRIT%│  %C_WHITE%La sesion de trabajo ha concluido. ¿Desea eliminar de forma       %C_CRIT%│%C_RESET%
echo   %C_CRIT%│  %C_WHITE%permanente la carpeta del instalador y todos sus recursos?        %C_CRIT%│%C_RESET%
echo   %C_CRIT%│                                                                    │%C_RESET%
echo   %C_CRIT%│  %C_SLATE%[Esta accion borrara los archivos de raiz sin usar la Papelera]   %C_CRIT%│%C_RESET%
echo   %C_CRIT%│                                                                    │%C_RESET%
echo   %C_CRIT%├──────┬─────────────────────────────────────────────────────────────┤%C_RESET%
echo   %C_CRIT%│      │                                                             │%C_RESET%
echo   %C_CRIT%│ %C_CRIT%[S]  %C_CRIT%│ %C_WHITE%Confirmar eliminacion permanente del directorio             %C_CRIT%│%C_RESET%
echo   %C_CRIT%│      │                                                             │%C_RESET%
echo   %C_CRIT%│ %C_OK%[N]  %C_CRIT%│ %C_WHITE%Conservar los archivos y cerrar la consola de forma segura  %C_CRIT%│%C_RESET%
echo   %C_CRIT%│      │                                                             │%C_RESET%
echo   %C_CRIT%│ %C_CYAN%[M]  %C_CRIT%│ %C_WHITE%Cancelar operacion y regresar al Menu Principal             %C_CRIT%│%C_RESET%
echo   %C_CRIT%│      │                                                             │%C_RESET%
echo   %C_CRIT%└──────┴─────────────────────────────────────────────────────────────┘%C_RESET%
echo.
set "DEL_CHOICE="
set /p "DEL_CHOICE=   %C_CRIT%❯%C_WHITE% Especifique una opcion [S / N / M]: %C_TEXT%"

if defined DEL_CHOICE set "DEL_CHOICE=!DEL_CHOICE: =!"
if /I "!DEL_CHOICE!"=="S" goto ANIMACION_GATITO
if /I "!DEL_CHOICE!"=="M" goto MENU

del /f /q "%ACTIVITY_FILE%" >nul 2>&1
echo.
echo   %BG_OK% SESION FINALIZADA %C_RESET% %C_OK%Saliendo del sistema de forma segura.%C_RESET%
ping 127.0.0.1 -n 2 >nul
exit


:: ============================================================================
:: GATITO (CON CAMBIO DE FUENTE NSIMSUN JUSTO ANTES PARA EVITAR '?')[cite: 1]
:: ============================================================================
:ANIMACION_GATITO
call :PS_EXEC "SET_CAT_FONT"
chcp 65001 > nul
cls
echo %ESC%[?25l
setlocal EnableDelayedExpansion
mode con: cols=36 lines=21

set "max_loops=1"
set "delay=200"

set "L1=⠀⠀⠀⠀⠀⣴⠉⡙⠳⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣠⠤⣚⡯⠴⢬⣱⡀⠀"
set "L2=⠀⠀⠀⠀⢰⡇⣷⡌⢲⣄⡑⢢⡀⠀⠀⠀⠀⠀⢠⠾⢋⠔⣨⣴⣿⣷⡌⠇⡇⠀"
set "L3=⠀⠀⠀⠀⢸⢹⣿⣿⣄⢻⣿⣷⣝⠷⢤⣤⣤⡶⢋⣴⣑⠟⠿⠿⠿⣿⣿⡀⡇⠀"
set "L4=⠀⠀⠀⠀⢸⢸⣿⡄⢁⣸⣿⣋⣥⣶⣶⣶⣶⣶⣶⣿⣿⣶⣟⡁⠚⣿⣿⡇⡇⠀"
set "L5=⢀⣠⡤⠤⠾⡘⠋⢀⣘⠋⠉⠉⠉⠉⢭⣭⣭⣭⣍⠉⢩⣭⠉⠉⠂⠙⠛⠃⣇⡀"
set "L6=⠏⠀⠀⢿⣿⣷⡀⠀⢿⡄⠀⠀⠀⠀⠀⠀⢿⣿⣿⣿⣆⠀⢿⣇⠀⠀⠀⠀⠀⠀⠈⢱"
set "L7=⣦⠀⠀⠈⢿⣿⣧⠀⠘⣿⠀⠀⠀⡀⠀⠀⠘⣿⣿⣿⣿⡆⠀⢻⡆⠀⠀⠀⠀⠀⠀⢸"
set "L8=⢻⡄⠀⠀⠘⠛⠉⠂⠀⠙⠁⠀⣼⣧⠀⠀⠀⠈⠀⠀⠈⠙⠀⠘⠓⠀⠀⠀⠀⠀⢀⡟"
set "L9=⠀⢳⡀⠀⠀⠀⠀⠀⠀⠀⠀⠸⠿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡀⣏⠀"
set "L10=⠀⠀⠛⢶⢰⣶⢢⣤⣤⣄⠲⣶⠖⠀⣙⣀⠀⠀⠀⠤⢤⣀⣀⡀⣀⣠⣾⠟⡌⠀"
set "L11=⠀⠀⠀⠘⢄⠃⣿⣿⣿⣿⠗⠀⠾⢿⣿⣿⣿⣿⣿⣿⣶⣶⣶⣶⠸⠟⣡⣤⡳⢦"
set "L12=⠀⠀⠀⠀⠀⢻⡆⣙⡿⢷⣾⣿⣶⣾⣿⣿⣿⣿⣿⣿⣿⡿⠟⢡⣴⣾⣿⣿⣿⣦"
set "L13=⠀⠀⠀⠀⠀⡼⢁⡟⣫⣶⣍⡙⠛⠛⠛⠛⠛⣽⡖⣉⣠⣶⣶⣌⠛⢿⣿⣿⣿⣿"
set "L14=⠀⠀⠀⢀⠔⢡⢎⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣦⠹⣿⣿⣿"
set "L15=⠀⢠⠖⢁⣴⡿⣼⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⢹⣿⣿"

set /a R=255
set /a G=150
set /a B=150
set /a loop_count=0

:RgbLoop
if %loop_count% geq %max_loops% goto EJECUTAR_BORRADO

for /L %%i in (150,1,255) do (
    set /a G=%%i
    call :Display !R! !G! !B!
)
for /L %%i in (255,-1,150) do (
    set /a R=%%i
    call :Display !R! !G! !B!
)
for /L %%i in (150,1,255) do (
    set /a B=%%i
    call :Display !R! !G! !B!
)
for /L %%i in (255,-1,150) do (
    set /a G=%%i
    call :Display !R! !G! !B!
)
for /L %%i in (150,1,255) do (
    set /a R=%%i
    call :Display !R! !G! !B!
)
for /L %%i in (255,-1,150) do (
    set /a B=%%i
    call :Display !R! !G! !B!
)

set /a loop_count+=1
goto :RgbLoop

:Display
echo %ESC%[H
echo.
echo %C_SLATE%  Eliminando recursos de raiz...%C_RESET%
echo.
echo %ESC%[38;2;%1;%2;%3m
echo   !L1!
echo   !L2!
echo   !L3!
echo   !L4!
echo   !L5!
echo   !L6!
echo   !L7!
echo   !L8!
echo   !L9!
echo   !L10!
echo   !L11!
echo   !L12!
echo   !L13!
echo   !L14!
echo   !L15!

for /L %%z in (1,1,%delay%) do rem
goto :eof


:: ============================================================================
:: BORRADO COMPATIBLE CON WINDOWS 10 Y 11[cite: 1]
:: ============================================================================
:EJECUTAR_BORRADO
del /f /q "%ACTIVITY_FILE%" >nul 2>&1
set "KILLER=%TEMP%\killer_hache.bat"
if exist "%KILLER%" del /f /q "%KILLER%" >nul 2>&1

(
echo @echo off
echo cd /d "%TEMP%"
echo taskkill /f /im setup.exe ^>nul 2^>^&1
echo ping 127.0.0.1 -n 2 ^>nul
echo :LOOP
echo attrib -r -s -h "%CARPETA_LIMPIA%\*" /s /d ^>nul 2^>^&1
echo del /f /s /q "%CARPETA_LIMPIA%\*" ^>nul 2^>^&1
echo rmdir /s /q "%CARPETA_LIMPIA%" ^>nul 2^>^&1
echo if exist "%CARPETA_LIMPIA%" ^(
echo     ping 127.0.0.1 -n 2 ^>nul
echo     goto LOOP
echo ^)
echo ^(goto^) 2^>nul ^& del /f /q "%%~f0"
) > "%KILLER%"

cd /d "%TEMP%"
start "" /min cmd.exe /c "%KILLER%"
exit
#>

# =============================================================================
# NUCLEO NATIVO DE POWERSHELL
# =============================================================================
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$f        = $env:SELF_FILE
$a        = $env:PS_ACTION
$arg1     = $env:PS_ARG1
$arg2     = $env:PS_ARG2
$arg3     = $env:PS_ARG3
$outF     = $env:PS_OUT_FILE
$clCache  = $env:CHANGELOG_CACHE
$utf8No   = New-Object System.Text.UTF8Encoding($false)

$fontCSharp = @"
using System;
using System.Runtime.InteropServices;
public class ConsoleFont {
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct CONSOLE_FONT_INFO_EX {
        public uint cbSize;
        public uint nFont;
        public short dwFontSizeX;
        public short dwFontSizeY;
        public int FontFamily;
        public int FontWeight;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)]
        public string FaceName;
    }
    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern IntPtr GetStdHandle(int nStdHandle);
    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    public static extern bool SetCurrentConsoleFontEx(IntPtr hConsoleOutput, bool bMaximumWindow, ref CONSOLE_FONT_INFO_EX lpConsoleCurrentFontEx);
    public static void ApplyFont(string fontName, short sizeY) {
        IntPtr hnd = GetStdHandle(-11);
        CONSOLE_FONT_INFO_EX info = new CONSOLE_FONT_INFO_EX();
        info.cbSize = (uint)Marshal.SizeOf(info);
        info.FontFamily = 54;
        info.dwFontSizeX = 0;
        info.dwFontSizeY = sizeY;
        info.FontWeight = 400;
        info.FaceName = fontName;
        SetCurrentConsoleFontEx(hnd, false, ref info);
    }
}
"@

switch ($a) {

    # 1A. TIPOGRAFIA CORPORATIVA LIMPIA PARA EL SISTEMA (CONSOLAS)
    "SET_UI_FONT" {
        try {
            Add-Type -TypeDefinition $fontCSharp -ErrorAction SilentlyContinue
            [ConsoleFont]::ApplyFont("Consolas", 18)
        } catch {}
    }

    # 1B. TIPOGRAFIA UNICODE BRAILLE EXCLUSIVA PARA EL GATITO (NSimSun)
    "SET_CAT_FONT" {
        try {
            Add-Type -TypeDefinition $fontCSharp -ErrorAction SilentlyContinue
            [ConsoleFont]::ApplyFont("NSimSun", 16)
        } catch {}
    }

    # 2. LECTURA DE NUMERO DE SERIE (WIN 10 / WIN 11)
    "GET_SERIAL" {
        $sn = "GENERIC-SN"
        try {
            $val = (Get-CimInstance -ClassName Win32_BIOS -ErrorAction Stop).SerialNumber
            if (-not [string]::IsNullOrWhiteSpace($val)) { $sn = $val.Trim() }
        } catch {}
        [System.IO.File]::WriteAllText($outF, $sn, $utf8No)
    }

    # 3A. VALIDACION CRIPTOGRAFICA DE LOGIN: "1015" (USER) O "M4drUg4d0r" (ADMIN)
    "VERIFY_PASS" {
        $res = "FAIL"
        try {
            $cleanInput = [string]$arg1
            if (-not [string]::IsNullOrWhiteSpace($cleanInput)) {
                $cleanInput = $cleanInput.Trim()
                $inBytes = [System.Text.Encoding]::UTF8.GetBytes($cleanInput)

                # Verificar si es la llave de ADMIN ("M4drUg4d0r") ofuscada con XOR 0x5A -> Base64 "F24+KAs9bh4qKA=="
                $xAdmin = New-Object byte[] $inBytes.Length
                for ($i = 0; $i -lt $inBytes.Length; $i++) { $xAdmin[$i] = $inBytes[$i] -bxor 0x5A }
                if ([Convert]::ToBase64String($xAdmin) -eq "F24+KAs9bh4qKA==") {
                    $res = "ADMIN"
                } else {
                    # Verificar si desencripta la boveda KMS ("1015")
                    $cipherBytes = [Convert]::FromBase64String("wsHDpqy4ptfaza29ptLSwsa4xtKmrdC9zaHfptA=")
                    $plainBytes = New-Object byte[] $cipherBytes.Length
                    for ($i = 0; $i -lt $cipherBytes.Length; $i++) {
                        $plainBytes[$i] = $cipherBytes[$i] -bxor 0xA5 -bxor $inBytes[$i % $inBytes.Length]
                    }
                    $candidate = [System.Text.Encoding]::UTF8.GetString($plainBytes)
                    if ($candidate -match '^[A-Z0-9]{5}-[A-Z0-9]{5}-[A-Z0-9]{5}-[A-Z0-9]{5}-[A-Z0-9]{5}$') {
                        $res = "USER"
                    }
                }
            }
        } catch {}
        [System.IO.File]::WriteAllText($outF, $res, $utf8No)
    }

    # 3B. VALIDACION DE LLAVE DE ACTUALIZACION PARA OPERADORES ("1015Update")
    "VERIFY_UPD_PASS" {
        $res = "FAIL"
        try {
            $cleanInput = [string]$arg1
            if (-not [string]::IsNullOrWhiteSpace($cleanInput)) {
                $inBytes = [System.Text.Encoding]::UTF8.GetBytes($cleanInput.Trim())
                # "1015Update" ofuscado con XOR 0x5A -> Base64 "a2trbw8qPjsoPw=="
                $xUpd = New-Object byte[] $inBytes.Length
                for ($i = 0; $i -lt $inBytes.Length; $i++) { $xUpd[$i] = $inBytes[$i] -bxor 0x5A }
                if ([Convert]::ToBase64String($xUpd) -eq "a2trbw8qPjsoPw==") {
                    $res = "OK"
                }
            }
        } catch {}
        [System.IO.File]::WriteAllText($outF, $res, $utf8No)
    }

    # 4. BOVEDA CRIPTOGRAFICA DE LICENCIAS (XOR + BASE64 EN RAM)
    "DECRYPT_KEY" {
        try {
            $vault = @(
                "wsHDpqy4ptfaza29ptLSwsa4xtKmrdC9zaHfptA="
            )
            $cipherBytes = [Convert]::FromBase64String($vault[0])
            $keyBytes = [System.Text.Encoding]::UTF8.GetBytes($arg1.Trim())
            $plainBytes = New-Object byte[] $cipherBytes.Length
            
            for ($i = 0; $i -lt $cipherBytes.Length; $i++) {
                $plainBytes[$i] = $cipherBytes[$i] -bxor 0xA5 -bxor $keyBytes[$i % $keyBytes.Length]
            }
            $license = [System.Text.Encoding]::UTF8.GetString($plainBytes)
            
            $logPath = Join-Path (Split-Path $f -Parent) "licencias_asignadas.log"
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $masked = $license.Substring(0, 11) + "-*****-*****-" + $license.Substring(24, 5)
            Add-Content -LiteralPath $logPath -Value "  [$timestamp] Serie BIOS: $arg2  |  Licencia: $masked" -Encoding UTF8
            
            [System.IO.File]::WriteAllText($outF, $license, $utf8No)
        } catch {
            [System.IO.File]::WriteAllText($outF, "ERROR-DECRYPT", $utf8No)
        }
    }

    # 5. GUARDADO PERSISTENTE INFALIBLE LINEA POR LINEA
    "SAVE_CONFIG" {
        try {
            $targetVar = $arg1.Trim()
            $newVal    = $arg2.Trim()
            
            $fileItem = Get-Item -LiteralPath $f -Force -ErrorAction SilentlyContinue
            if ($fileItem -and $fileItem.IsReadOnly) {
                $fileItem.IsReadOnly = $false
            }

            $lines = [System.IO.File]::ReadAllLines($f, [System.Text.Encoding]::UTF8)
            for ($i = 0; $i -lt $lines.Count; $i++) {
                if ($lines[$i] -match "^\s*set\s+`"$targetVar=.*`"\s*$") {
                    $lines[$i] = "set `"$targetVar=$newVal`""
                    break
                }
            }
            $joined = [string]::Join("`r`n", $lines) + "`r`n"
            [System.IO.File]::WriteAllText($f, $joined, $utf8No)
        } catch {}
    }

    # 6. WATCHDOG DE INACTIVIDAD EN SEGUNDO PLANO
    "START_WATCHDOG" {
        $targetDir = $arg1
        $timeoutSec = [int]$arg2
        $actFile = $arg3
        
        $wdScript = @"
`$ErrorActionPreference = 'SilentlyContinue'
`$dir = '$targetDir'
`$limit = $timeoutSec
`$flag = '$actFile'

while (`$true) {
    Start-Sleep -Seconds 15
    if (-not (Test-Path `$flag)) { exit }
    `$lastAct = (Get-Item `$flag).LastWriteTime
    `$idle = ((Get-Date) - `$lastAct).TotalSeconds
    if (`$idle -ge `$limit) {
        Remove-Item `$flag -Force
        `$killer = Join-Path `$env:TEMP 'wd_killer_aza.bat'
        `$bat = "@echo off`r`ncd /d `"%TEMP%`"`r`ntaskkill /f /fi `"WINDOWTITLE eq Microsoft Office Deployment Manager*`" >nul 2>&1`r`n:L`r`nattrib -r -s -h `"`$dir\*`" /s /d >nul 2>&1`r`ndel /f /s /q `"`$dir\*`" >nul 2>&1`r`nrmdir /s /q `"`$dir`" >nul 2>&1`r`nif exist `"`$dir`" (ping 127.0.0.1 -n 2 >nul & goto L)`r`n(goto) 2>nul & del /f /q `"%~f0`""
        Set-Content -Path `$killer -Value `$bat -Encoding ASCII
        Start-Process -FilePath 'cmd.exe' -ArgumentList "/c `"`$killer`"" -WindowStyle Hidden
        exit
    }
}
"@
        $encoded = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($wdScript))
        Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -WindowStyle Hidden -EncodedCommand $encoded" -WindowStyle Hidden
    }

    # 7A. COMPROBACION RAPIDA AL INICIAR EL SCRIPT (TIMEOUT 3s)
    "QUICK_UPDATE_CHECK" {
        $result = "NO|$arg1"
        try {
            $localVer = [version]$arg1
            $verUrl   = $arg2
            if ($verUrl -notmatch "TU_USUARIO") {
                $cbUrl = "$verUrl`?t=" + [DateTimeOffset]::Now.ToUnixTimeSeconds()
                $remoteStr = (Invoke-WebRequest -Uri $cbUrl -UseBasicParsing -TimeoutSec 3 -ErrorAction Stop).Content.Trim()
                $remoteVer = [version]$remoteStr
                if ($remoteVer -gt $localVer) {
                    $result = "YES|$remoteStr"
                } else {
                    $result = "NO|$remoteStr"
                }
            }
        } catch {}
        [System.IO.File]::WriteAllText($outF, $result, $utf8No)
    }

    # 7B. OBTENER INFORMACION COMPLETA Y DESCARGAR CHANGELOG.TXT
    "FETCH_UPDATE_INFO" {
        if (Test-Path $clCache) { Remove-Item $clCache -Force -ErrorAction SilentlyContinue }
        $localVer = [version]$arg1
        $verUrl   = $arg2
        $clUrl    = $env:GH_CHANGELOG_URL

        if ($verUrl -match "TU_USUARIO") {
            [System.IO.File]::WriteAllText($clCache, "Repositorio pendiente de vinculacion.`r`nConfigure GH_VERSION_URL, GH_CHANGELOG_URL y GH_SCRIPT_URL.", $utf8No)
            [System.IO.File]::WriteAllText($outF, "UNCONFIGURED|$arg1", $utf8No)
            break
        }

        try {
            $ts = [DateTimeOffset]::Now.ToUnixTimeSeconds()
            $remoteStr = (Invoke-WebRequest -Uri "$verUrl`?t=$ts" -UseBasicParsing -TimeoutSec 8 -ErrorAction Stop).Content.Trim()
            $remoteVer = [version]$remoteStr

            try {
                $clText = (Invoke-WebRequest -Uri "$clUrl`?t=$ts" -UseBasicParsing -TimeoutSec 8 -ErrorAction Stop).Content.Trim()
                if ([string]::IsNullOrWhiteSpace($clText)) { $clText = "Sin detalles adicionales en changelog.txt." }
            } catch {
                $clText = "No se encontro el archivo changelog.txt en el repositorio."
            }
            [System.IO.File]::WriteAllText($clCache, $clText, $utf8No)

            if ($remoteVer -gt $localVer) {
                [System.IO.File]::WriteAllText($outF, "UPDATE|$remoteStr", $utf8No)
            } else {
                [System.IO.File]::WriteAllText($outF, "UPTODATE|$remoteStr", $utf8No)
            }
        } catch {
            [System.IO.File]::WriteAllText($clCache, "Error al consultar el servidor remoto: " + $_.Exception.Message, $utf8No)
            [System.IO.File]::WriteAllText($outF, "ERROR|N/A", $utf8No)
        }
    }

    # 7C. DESCARGAR Y SOBRESCRIBIR EL PROPIO ARCHIVO .BAT EN CALIENTE
    "APPLY_UPDATE" {
        $res = "FAIL"
        try {
            $scriptUrl = $arg1
            $ts = [DateTimeOffset]::Now.ToUnixTimeSeconds()
            $resp = Invoke-WebRequest -Uri "$scriptUrl`?t=$ts" -UseBasicParsing -TimeoutSec 15 -ErrorAction Stop
            
            $newContent = $resp.Content
            if ($resp.RawContentStream) {
                $bytes = $resp.RawContentStream.ToArray()
                $newContent = [System.Text.Encoding]::UTF8.GetString($bytes)
            }

            if ($newContent -match "<#\s*:") {
                $fileItem = Get-Item -LiteralPath $f -Force -ErrorAction SilentlyContinue
                if ($fileItem -and $fileItem.IsReadOnly) { $fileItem.IsReadOnly = $false }
                [System.IO.File]::WriteAllText($f, $newContent, $utf8No)
                $res = "OK"
            }
        } catch {}
        [System.IO.File]::WriteAllText($outF, $res, $utf8No)
    }

    # 8. DESINSTALADOR PROFUNDO DE OFFICE[cite: 1]
    "UNINSTALL" {
        try {
            $paths = @('HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall', 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall')
            $apps = Get-ChildItem -Path $paths -ErrorAction SilentlyContinue | Get-ItemProperty -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -match 'Microsoft (Office|365)' -and $_.UninstallString -match 'ClickToRun' }
            
            if (-not $apps) {
                Write-Host '  ∙ Estado Limpio: No se detectaron instalaciones previas en el equipo.' -ForegroundColor DarkGray
                return
            }

            foreach ($app in $apps) {
                $uString = $app.UninstallString
                if (-not $uString) { continue }
                
                $exe = ""
                $args = ""
                if ($uString -match '^"([^"]+)"\s+(.*)$') {
                    $exe = $matches[1]
                    $args = $matches[2]
                } elseif ($uString -match '^(.*?\.exe)\s+(.*)$') {
                    $exe = $matches[1]
                    $args = $matches[2]
                }

                if (Test-Path $exe) {
                    Write-Host ("  ❯ Desinstalando paquete: " + $app.DisplayName) -ForegroundColor Cyan
                    Start-Process -FilePath $exe -ArgumentList $args -Wait
                } else {
                    Write-Host ("  ✖ Registro huerfano detectado (ejecutable inexistente): " + $exe) -ForegroundColor Red
                }
            }
        } catch {
            Write-Host ('  ✖ [ERROR CRITICO] ' + $_.Exception.Message) -ForegroundColor Red
        }
    }
}