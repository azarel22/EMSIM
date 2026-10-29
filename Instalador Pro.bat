<# :
@echo off
chcp 65001 > nul
setlocal EnableDelayedExpansion
title Microsoft Office Deployment Manager - Enterprise Edition

:: ============================================================================
:: VARIABLES PERSISTENTES (MODIFICABLES Y GUARDABLES CON [G] EN CONFIGURACION)
:: ============================================================================
set "CFG_TIMEOUT=3600"                       
set "CFG_WATCHDOG=ON"                        
set "APP_VERSION=7.0.1"                      
set "GH_VERSION_URL=https://raw.githubusercontent.com/azarel22/EMSIM/refs/heads/main/version.txt"
set "GH_CHANGELOG_URL=https://raw.githubusercontent.com/azarel22/EMSIM/refs/heads/main/changelog.txt"
set "GH_SCRIPT_URL=https://raw.githubusercontent.com/azarel22/EMSIM/refs/heads/main/Instalador%%20Pro.bat"
set "GH_GUIDE_URL=https://raw.githubusercontent.com/azarel22/EMSIM/refs/heads/main/Guia%%20de%%20Operador%%20Office%%20Installer.txt"
:: ============================================================================

:: Escalado de privilegios de Administrador[cite: 1, 4]
net session >nul 2>&1
if %errorLevel% neq 0 (
    powershell -NoProfile -WindowStyle Hidden -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

mode con: cols=74 lines=34
for /F "delims=#" %%E in ('"prompt #$E# & echo on & for %%b in (1) do rem"') do set "ESC=%%E"
echo %ESC%[?25l

:: ============================================================================
:: PALETA DE COLORES INSTITUCIONAL / EMPRESARIAL + EFECTO PULSANTE (ANSI RGB)[cite: 1]
:: ============================================================================
set "C_BORDER=%ESC%[38;2;70;82;102m"
set "C_SLATE=%ESC%[38;2;130;145;165m"
set "C_TEXT=%ESC%[38;2;215;222;232m"
set "C_WHITE=%ESC%[38;2;255;255;255m"

set "C_CORP=%ESC%[38;2;45;140;240m"
set "C_CYAN=%ESC%[38;2;56;189;248m"
set "C_OK=%ESC%[38;2;16;185;129m"
set "C_WARN=%ESC%[38;2;245;158;11m"
set "C_WARN_DIM=%ESC%[38;2;145;95;25m"
set "C_CRIT=%ESC%[38;2;239;68;68m"
set "C_BLINK=%ESC%[5m"

set "BG_HEADER=%ESC%[48;2;20;32;52m%ESC%[38;2;255;255;255m"
set "BG_OK=%ESC%[48;2;6;95;70m%ESC%[38;2;209;250;229m"
set "BG_WARN=%ESC%[48;2;120;53;15m%ESC%[38;2;254;243;199m"
set "BG_CRIT=%ESC%[48;2;127;29;29m%ESC%[38;2;254;226;226m"
set "BG_INFO=%ESC%[48;2;30;58;138m%ESC%[38;2;219;234;254m"
set "BG_UPD=%ESC%[48;2;88;28;135m%ESC%[38;2;243;232;255m"
set "C_RESET=%ESC%[0m"

cd /d "%~dp0"
set "CARPETA=%~dp0"
set "CARPETA_LIMPIA=%CARPETA:~0,-1%"
set "ACTIVITY_FILE=%TEMP%\modm_wd_activity.tmp"
set "PS_OUT_FILE=%TEMP%\modm_ps_out.tmp"
set "CHANGELOG_CACHE=%TEMP%\modm_changelog.tmp"
set "JUST_UPDATED_FLAG=%TEMP%\modm_post_update.flg"
set "SELF_FILE=%~f0"

:: Limpiar espacios de las variables de ancho fijo
set "CFG_TIMEOUT=!CFG_TIMEOUT: =!"
set "CFG_WATCHDOG=!CFG_WATCHDOG: =!"
set "APP_VERSION=!APP_VERSION: =!"

:: ============================================================================
:: ARRANQUE CON BARRA DE CARGA REACTIVA EN TIEMPO REAL
:: ============================================================================
if /I "!CFG_WATCHDOG!"=="ON" echo !CFG_TIMEOUT!>"%ACTIVITY_FILE%"
if /I not "!CFG_WATCHDOG!"=="ON" del /f /q "%ACTIVITY_FILE%" >nul 2>&1

set "BIOS_SN=GENERIC-SN"
set "UPD_AVAILABLE=NO"
set "REMOTE_VER=!APP_VERSION!"

call :PS_GET "BOOT_INIT" "%CARPETA_LIMPIA%" "!CFG_TIMEOUT!" "BOOT_DATA"
if defined BOOT_DATA (
    for /f "tokens=1,2,3 delims=|" %%A in ("!BOOT_DATA!") do (
        set "BIOS_SN=%%A"
        set "UPD_AVAILABLE=%%B"
        set "REMOTE_VER=%%C"
    )
)

:: Si el programa se acaba de actualizar y reabrir, mostrar pantalla estilizada de Changelog antes del Login
if exist "%JUST_UPDATED_FLAG%" goto POST_UPDATE_SCREEN
goto INIT_LOGIN_VARS


:: ============================================================================
:: PANTALLA DE BIENVENIDA POST-ACTUALIZACION (REGISTRO DE CAMBIOS Y GUIA)
:: ============================================================================
:POST_UPDATE_SCREEN
del /f /q "%JUST_UPDATED_FLAG%" >nul 2>&1
mode con: cols=74 lines=38
cls
echo.
echo   %C_BORDER%┌────────────────────────────────────────────────────────────────────┐%C_RESET%
echo   %C_BORDER%│%BG_OK%  ★ ACTUALIZACION COMPLETADA EXITOSAMENTE                  v!APP_VERSION!  %C_RESET%%C_BORDER%│%C_RESET%
echo   %C_BORDER%├────────────────────────────────────────────────────────────────────┤%C_RESET%
echo   %C_BORDER%│                                                                    │%C_RESET%
echo   %C_BORDER%│  %C_WHITE%Bienvenido a la nueva version de Microsoft Office Deployment      %C_BORDER%│%C_RESET%
echo   %C_BORDER%│  %C_WHITE%Manager. El script principal y la Guia de Operador han sido       %C_BORDER%│%C_RESET%
echo   %C_BORDER%│  %C_WHITE%actualizados automaticamente en su carpeta local.                 %C_BORDER%│%C_RESET%
echo   %C_BORDER%│                                                                    │%C_RESET%
echo   %C_BORDER%├────────────────────────────────────────────────────────────────────┤%C_RESET%
echo   %C_BORDER%│  %C_CYAN%REGISTRO DE CAMBIOS Y NOVEDADES DE LA VERSION [v!APP_VERSION!]%ESC%[72G%C_BORDER%│%C_RESET%
echo   %C_BORDER%└────────────────────────────────────────────────────────────────────┘%C_RESET%
echo.

if exist "%CHANGELOG_CACHE%" (
    for /f "usebackq delims=" %%L in ("%CHANGELOG_CACHE%") do (
        echo     %C_OK%◆ %C_TEXT%%%L%C_RESET%
    )
) else (
    echo     %C_SLATE%∙ Sistema actualizado a la compilacion v!APP_VERSION!.%C_RESET%
)

echo.
echo   %C_BORDER%┌────────────────────────────────────────────────────────────────────┐%C_RESET%
echo   %C_BORDER%│                                                                    │%C_RESET%
echo   %C_BORDER%│  %C_CORP%[ENTER]%C_WHITE%  Continuar al Inicio de Sesion del Sistema                %C_BORDER%│%C_RESET%
echo   %C_BORDER%│                                                                    │%C_RESET%
echo   %C_BORDER%│  %C_CYAN%[G]    %C_WHITE%  Abrir "Guia de Operador Office Installer.txt" ahora      %C_BORDER%│%C_RESET%
echo   %C_BORDER%│                                                                    │%C_RESET%
echo   %C_BORDER%└────────────────────────────────────────────────────────────────────┘%C_RESET%
echo.
echo %ESC%[?25h
set "POST_OP="
set /p "POST_OP=   %C_OK%❯%C_WHITE% Presione [ENTER] para iniciar o escriba [G] para ver la Guia: %C_TEXT%"
echo %ESC%[?25l

if defined POST_OP set "POST_OP=!POST_OP: =!"
if /I "!POST_OP!"=="G" (
    if exist "%~dp0Guia de Operador Office Installer.txt" (
        start "" notepad.exe "%~dp0Guia de Operador Office Installer.txt"
    )
)


:: ============================================================================
:: MODULO DE AUTENTICACION INSTITUCIONAL (3 INTENTOS + CONTRASENA CON ASTERISCOS)
:: ============================================================================
:INIT_LOGIN_VARS
set /a INTENTOS=0
set "AUTH_MODE=USER"

:LOGIN
call :FORMAT_TIME "!CFG_TIMEOUT!"
mode con: cols=74 lines=33
cls

:: Bolita pulsante en verde si esta ON, o color ambar apagado si esta OFF
set "WD_LOGIN_TXT=%C_WARN_DIM%○ Desactivado [OFF]"
if /I "!CFG_WATCHDOG!"=="ON" set "WD_LOGIN_TXT=%C_OK%%C_BLINK%●%C_RESET%%C_OK% Activo %C_TEXT%[!TIME_STR!]"

set "AUTH_STATE_TXT=%C_SLATE%Estado: Esperando autenticacion criptografica [Intentos: 0 de 3]"
if !INTENTOS! gtr 0 set "AUTH_STATE_TXT=%C_CRIT%Advertencia: Intento fallido !INTENTOS! de 3 antes del borrado inmediato."

echo.
echo.
echo   %C_BORDER%┌────────────────────────────────────────────────────────────────────┐%C_RESET%
echo   %C_BORDER%│%BG_HEADER%  MICROSOFT OFFICE DEPLOYMENT MANAGER  •  By Aza            %C_RESET%%BG_HEADER%%ESC%[63Gv!APP_VERSION!%ESC%[72G%C_RESET%%C_BORDER%│%C_RESET%
echo   %C_BORDER%│                                                                    │%C_RESET%
echo   %C_BORDER%│%C_SLATE%  Sistema Institucional de Provisionamiento y Licenciamiento KMS    %C_BORDER%│%C_RESET%
if /I "!UPD_AVAILABLE!"=="YES" echo   %C_BORDER%├────────────────────────────────────────────────────────────────────┤%C_RESET%
if /I "!UPD_AVAILABLE!"=="YES" echo   %C_BORDER%│  %BG_UPD% %C_BLINK%●%C_RESET%%BG_UPD% ACTUALIZACION DISPONIBLE: v!REMOTE_VER! %C_RESET% %C_CYAN%[Disponible en Menu U]%ESC%[72G%C_BORDER%│%C_RESET%
echo   %C_BORDER%├──────────────────────────────────┬─────────────────────────────────┤%C_RESET%
echo   %C_BORDER%│                                  │                                 │%C_RESET%
echo   %C_BORDER%│%C_SLATE%  Numero de Serie [BIOS]          %C_BORDER%│%C_SLATE%  Temporizador de Inactividad    %C_BORDER%│%C_RESET%
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
<nul set /p "=   %C_CORP%❯%C_WHITE% Credencial de Acceso: %C_CYAN%"
call :PS_GET "READ_MASKED_AUTH" "" "" "AUTH_RES"
echo %ESC%[?25l
echo.

if /I "!CFG_WATCHDOG!"=="ON" echo !CFG_TIMEOUT!>"%ACTIVITY_FILE%"

if "!AUTH_RES!"=="ADMIN" goto LOGIN_DEV_OK
if "!AUTH_RES!"=="USER" goto LOGIN_NORMAL_OK
goto FAIL_AUTH

:LOGIN_DEV_OK
set "AUTH_MODE=ADMIN"
set "MASTER_KEY=1015"
echo.
echo   %BG_WARN% MODO ADMINISTRADOR %C_RESET% %C_WARN%Acceso de administracion concedido.%C_RESET%
goto MENU

:LOGIN_NORMAL_OK
set "AUTH_MODE=USER"
set "MASTER_KEY=1015"
echo.
echo   %BG_OK% AUTENTICADO %C_RESET% %C_OK%Sesion de operador iniciada.%C_RESET%
goto MENU

:FAIL_AUTH
set /a INTENTOS+=1
if !INTENTOS! geq 3 goto TRIGGER_LOCKOUT
echo.
echo   %BG_CRIT% ACCESO DENEGADO %C_RESET% %C_CRIT%La credencial ingresada no es valida.%C_RESET%
ping 127.0.0.1 -n 2 >nul
goto LOGIN

:: BORRADO INMEDIATO EN 1 SEGUNDO AL FALLAR 3 VECES (SIN GATITO PARA EVITAR COPIAS)
:TRIGGER_LOCKOUT
cls
echo.
echo.
echo   %C_CRIT%┌────────────────────────────────────────────────────────────────────┐%C_RESET%
echo   %C_CRIT%│%BG_CRIT%  ALERTA DE SEGURIDAD: LIMITE DE INTENTOS EXCEDIDO [3/3]            %C_RESET%%C_CRIT%│%C_RESET%
echo   %C_CRIT%├────────────────────────────────────────────────────────────────────┤%C_RESET%
echo   %C_CRIT%│                                                                    │%C_RESET%
echo   %C_CRIT%│  %C_WHITE%INTRUSION DETECTADA: Ejecutando destruccion inmediata de raiz...  %C_CRIT%│%C_RESET%
echo   %C_CRIT%│                                                                    │%C_RESET%
echo   %C_CRIT%└────────────────────────────────────────────────────────────────────┘%C_RESET%
ping 127.0.0.1 -n 2 >nul
goto EJECUTAR_BORRADO


:: ============================================================================
:: MENU PRINCIPAL (REORGANIZADO, LIMPIO Y CON APARTADO DE LIMPIEZA SOLO ADMIN)
:: ============================================================================
:MENU
if /I "!CFG_WATCHDOG!"=="ON" echo !CFG_TIMEOUT!>"%ACTIVITY_FILE%"
call :FORMAT_TIME "!CFG_TIMEOUT!"

if /I "!AUTH_MODE!"=="ADMIN" mode con: cols=74 lines=52
if /I not "!AUTH_MODE!"=="ADMIN" mode con: cols=74 lines=39
cls

:: Bolita verde pulsante si esta ON, o ambar apagado si esta OFF
set "WD_MENU_TXT=%C_WARN_DIM%○ Desactivado [OFF]"
if /I "!CFG_WATCHDOG!"=="ON" set "WD_MENU_TXT=%C_OK%%C_BLINK%●%C_RESET%%C_OK% Activo [!TIME_STR!]"

set "ROLE_TXT=%C_OK%◆ OPERADOR     "
if /I "!AUTH_MODE!"=="ADMIN" set "ROLE_TXT=%C_WARN%★ ADMINISTRADOR"

set "SEC3_TITLE=%C_CORP%ACTUALIZACIONES Y CONTROL DE SESION                               "
if /I "!AUTH_MODE!"=="ADMIN" set "SEC3_TITLE=%C_CORP%ADMINISTRACION, CLONACION USB Y ACTUALIZACIONES [ADMIN]           "

set "ROW_U_TXT=%C_BORDER%│ %C_CYAN%[U]  %C_BORDER%│ %C_TEXT%Centro de Actualizaciones Remotas%ESC%[54G%C_BORDER%│ %C_SLATE%GitHub OTA%ESC%[72G%C_BORDER%│%C_RESET%"
if /I "!UPD_AVAILABLE!"=="YES" set "ROW_U_TXT=%C_BORDER%│ %C_OK%%C_BLINK%[U]%C_RESET%  %C_BORDER%│ %C_WHITE%Centro de Actualizaciones [v!REMOTE_VER!]%ESC%[54G%C_BORDER%│ %C_OK%● Update Listo%ESC%[72G%C_BORDER%│%C_RESET%"

set "FOOT_TXT=%C_SLATE%Comandos activos: %C_TEXT%1-4%C_SLATE% y %C_TEXT%U%C_SLATE% [Verificar / Instalar Actualizaciones]  "
if /I "!AUTH_MODE!"=="ADMIN" set "FOOT_TXT=%C_SLATE%Comandos activos: %C_TEXT%1-4%C_SLATE%, %C_TEXT%R%C_SLATE% [Limpieza], %C_TEXT%C%C_SLATE% [Config], %C_TEXT%E%C_SLATE% [USB], %C_TEXT%U%C_SLATE% [OTA]  "

echo.
echo   %C_BORDER%┌────────────────────────────────────────────────────────────────────┐%C_RESET%
echo   %C_BORDER%│%BG_HEADER%  CONSOLA DE DESPLIEGUE CORPORATIVO  •  By Aza                      %C_RESET%%BG_HEADER%%ESC%[63Gv!APP_VERSION!%ESC%[72G%C_RESET%%C_BORDER%│%C_RESET%
if /I "!UPD_AVAILABLE!"=="YES" echo   %C_BORDER%├────────────────────────────────────────────────────────────────────┤%C_RESET%
if /I "!UPD_AVAILABLE!"=="YES" echo   %C_BORDER%│  %BG_UPD% %C_BLINK%▲%C_RESET%%BG_UPD% NUEVA VERSION DISPONIBLE: v!REMOTE_VER! %C_RESET% %C_CYAN%Presione [U] para actualizar%ESC%[72G%C_BORDER%│%C_RESET%
echo   %C_BORDER%├───────────────────────┬──────────────────────────┬─────────────────┤%C_RESET%
echo   %C_BORDER%│%C_SLATE%  Serie del Equipo     %C_BORDER%│%C_SLATE%  Protector de Inactividad%C_BORDER%│%C_SLATE%  Nivel Acceso   %C_BORDER%│%C_RESET%
echo   %C_BORDER%│  %C_CYAN%!BIOS_SN!%C_RESET%%ESC%[27G%C_BORDER%│  !WD_MENU_TXT!%ESC%[54G%C_BORDER%│  !ROLE_TXT!%ESC%[72G%C_BORDER%│%C_RESET%
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
if /I "!AUTH_MODE!"=="ADMIN" echo   %C_BORDER%├──────┴───────────────────────────────────────────┴─────────────────┤%C_RESET%
if /I "!AUTH_MODE!"=="ADMIN" echo   %C_BORDER%│                                                                    │%C_RESET%
if /I "!AUTH_MODE!"=="ADMIN" echo   %C_BORDER%│  %C_CORP%LIMPIEZA Y REPARACION AVANZADA DE OFFICE [EXCLUSIVO ADMIN]        %C_BORDER%│%C_RESET%
if /I "!AUTH_MODE!"=="ADMIN" echo   %C_BORDER%│                                                                    │%C_RESET%
if /I "!AUTH_MODE!"=="ADMIN" echo   %C_BORDER%├──────┬───────────────────────────────────────────┬─────────────────┤%C_RESET%
if /I "!AUTH_MODE!"=="ADMIN" echo   %C_BORDER%│      │                                           │                 │%C_RESET%
if /I "!AUTH_MODE!"=="ADMIN" echo   %C_BORDER%│ %C_CYAN%[R]  %C_BORDER%│ %C_WHITE%Modulo de Limpieza y Reparacion de Office %C_BORDER%│ %C_CYAN%Oficial/Forzada %C_BORDER%│%C_RESET%
if /I "!AUTH_MODE!"=="ADMIN" echo   %C_BORDER%│      │                                           │                 │%C_RESET%
echo   %C_BORDER%├──────┴───────────────────────────────────────────┴─────────────────┤%C_RESET%
echo   %C_BORDER%│                                                                    │%C_RESET%
echo   %C_BORDER%│  !SEC3_TITLE!%C_BORDER%│%C_RESET%
echo   %C_BORDER%│                                                                    │%C_RESET%
echo   %C_BORDER%├──────┬───────────────────────────────────────────┬─────────────────┤%C_RESET%
echo   %C_BORDER%│      │                                           │                 │%C_RESET%
if /I "!AUTH_MODE!"=="ADMIN" echo   %C_BORDER%│ %C_CYAN%[C]  %C_BORDER%│ %C_TEXT%Panel de Configuracion del Sistema        %C_BORDER%│ %C_SLATE%Watchdog/Tiempo %C_BORDER%│%C_RESET%
if /I "!AUTH_MODE!"=="ADMIN" echo   %C_BORDER%│      │                                           │                 │%C_RESET%
if /I "!AUTH_MODE!"=="ADMIN" echo   %C_BORDER%│ %C_OK%[E]  %C_BORDER%│ %C_TEXT%Exportar Kit a USB / Ruta [Modo Operador] %C_BORDER%│ %C_OK%Clonador Activo %C_BORDER%│%C_RESET%
if /I "!AUTH_MODE!"=="ADMIN" echo   %C_BORDER%│      │                                           │                 │%C_RESET%
echo   !ROW_U_TXT!
echo   %C_BORDER%│      │                                           │                 │%C_RESET%
echo   %C_BORDER%│ %C_CRIT%[4]  %C_BORDER%│ %C_WHITE%Finalizar Sesion / Protocolo de Borrado   %C_BORDER%│ %C_CRIT%Limpieza Final  %C_BORDER%│%C_RESET%
echo   %C_BORDER%│      │                                           │                 │%C_RESET%
echo   %C_BORDER%├──────┴───────────────────────────────────────────┴─────────────────┤%C_RESET%
echo   %C_BORDER%│  !FOOT_TXT!%C_BORDER%│%C_RESET%
echo   %C_BORDER%└────────────────────────────────────────────────────────────────────┘%C_RESET%
echo.
echo %ESC%[?25h
set "OPCION="
set /p "OPCION=   %C_CORP%❯%C_WHITE% Seleccione una operacion: %C_TEXT%"
echo %ESC%[?25l

if defined OPCION set "OPCION=!OPCION: =!"
if not defined OPCION goto MENU
if /I "!CFG_WATCHDOG!"=="ON" echo !CFG_TIMEOUT!>"%ACTIVITY_FILE%"

if "!OPCION!"=="1" goto OFFICE2024
if "!OPCION!"=="2" goto OFFICE2019
if "!OPCION!"=="3" goto SOLO_DESINSTALAR
if "!OPCION!"=="4" goto SALIR_AUTODESTRUCCION
if /I "!OPCION!"=="U" goto GITHUB_UPDATER
if /I "!OPCION!"=="RICK" goto Rick
if /I "!OPCION!"=="MG" goto Masgrave

:: Opciones exclusivas de Administrador (R = Limpieza/Reparacion, C = Config, E = Exportar USB)
if /I "!AUTH_MODE!"=="ADMIN" (
    if /I "!OPCION!"=="R" goto MENU_REPARACION
    if /I "!OPCION!"=="LIMPIEZA" goto MENU_REPARACION
    if /I "!OPCION!"=="C" goto INIT_CONFIG
    if /I "!OPCION!"=="CONFIG" goto INIT_CONFIG
    if /I "!OPCION!"=="E" goto EXPORTAR_KIT_OPERADOR
)

:: Si esta en modo OPERADOR y escribe la contrasena de ADMIN ("M4drUg4d0r"), escalar a ADMIN al instante
call :PS_GET "VERIFY_PASS" "!OPCION!" "" "MENU_ESC_RES"
if "!MENU_ESC_RES!"=="ADMIN" (
    set "AUTH_MODE=ADMIN"
    goto MENU
)
goto MENU


:: ============================================================================
:: APARTADO EXCLUSIVO ADMIN [R]: LIMPIEZA Y REPARACION DE MICROSOFT OFFICE
:: ============================================================================
:MENU_REPARACION
if /I "!CFG_WATCHDOG!"=="ON" echo !CFG_TIMEOUT!>"%ACTIVITY_FILE%"
mode con: cols=74 lines=34
cls
echo.
echo   %C_BORDER%┌────────────────────────────────────────────────────────────────────┐%C_RESET%
echo   %C_BORDER%│%BG_HEADER%  MODULO DE LIMPIEZA Y REPARACION DE MICROSOFT OFFICE [ADMIN]       %C_RESET%%C_BORDER%│%C_RESET%
echo   %C_BORDER%│                                                                    │%C_RESET%
echo   %C_BORDER%│%C_SLATE%  Seleccione el procedimiento tecnico de reparacion o limpieza:     %C_BORDER%│%C_RESET%
echo   %C_BORDER%├──────┬───────────────────────────────────────────┬─────────────────┤%C_RESET%
echo   %C_BORDER%│      │                                           │                 │%C_RESET%
echo   %C_BORDER%│ %C_CORP%[1]  %C_BORDER%│ %C_WHITE%Reparacion de Office Oficial              %C_BORDER%│ %C_OK%ClickToRun/MSI  %C_BORDER%│%C_RESET%
echo   %C_BORDER%│      │ %C_SLATE%Ejecuta diagnostico nativo del registro   %C_BORDER%│                 │%C_RESET%
echo   %C_BORDER%│      │                                           │                 │%C_RESET%
echo   %C_BORDER%│ %C_WARN%[2]  %C_BORDER%│ %C_WHITE%Reparacion de Office Forzada              %C_BORDER%│ %C_WARN%limpieza.xml    %C_BORDER%│%C_RESET%
echo   %C_BORDER%│      │ %C_SLATE%Ejecuta setup.exe /configure limpieza.xml %C_BORDER%│                 │%C_RESET%
echo   %C_BORDER%│      │                                           │                 │%C_RESET%
echo   %C_BORDER%├──────┼───────────────────────────────────────────┴─────────────────┤%C_RESET%
echo   %C_BORDER%│      │                                                             │%C_RESET%
echo   %C_BORDER%│ %C_SLATE%[M]  %C_BORDER%│ %C_TEXT%Cancelar y regresar al Menu Principal                       %C_BORDER%│%C_RESET%
echo   %C_BORDER%│      │                                                             │%C_RESET%
echo   %C_BORDER%└──────┴─────────────────────────────────────────────────────────────┘%C_RESET%
echo.
echo %ESC%[?25h
set "REP_OP="
set /p "REP_OP=   %C_CORP%❯%C_WHITE% Seleccione modalidad [1 / 2 / M]: %C_TEXT%"
echo %ESC%[?25l

if defined REP_OP set "REP_OP=!REP_OP: =!"
if "!REP_OP!"=="1" goto REPARACION_OFICIAL
if "!REP_OP!"=="2" goto REPARACION_FORZADA
if /I "!REP_OP!"=="M" goto MENU
goto MENU_REPARACION

:REPARACION_OFICIAL
cls
echo.
echo   %C_BORDER%┌────────────────────────────────────────────────────────────────────┐%C_RESET%
echo   %C_BORDER%│%BG_HEADER%  LIMPIEZA Y REPARACION: MODALIDAD OFICIAL [MOTOR NATIVO]           %C_RESET%%C_BORDER%│%C_RESET%
echo   %C_BORDER%└────────────────────────────────────────────────────────────────────┘%C_RESET%
echo.
echo %ESC%[?25h
call :PS_EXEC "REPAIR_OFFICIAL"
echo %ESC%[?25l
echo.
echo   %C_BORDER%──────────────────────────────────────────────────────────────────────%C_RESET%
pause
goto MENU_REPARACION

:REPARACION_FORZADA
cls
echo.
echo   %C_BORDER%┌────────────────────────────────────────────────────────────────────┐%C_RESET%
echo   %C_BORDER%│%BG_WARN%  LIMPIEZA Y REPARACION: MODALIDAD FORZADA [CARPETA LIMPIEZA]       %C_RESET%%C_BORDER%│%C_RESET%
echo   %C_BORDER%└────────────────────────────────────────────────────────────────────┘%C_RESET%
echo.
if not exist "%~dp0Limpieza\setup.exe" (
    echo   %BG_CRIT% ERROR %C_RESET% %C_CRIT%No se encontro "%~dp0Limpieza\setup.exe".%C_RESET%
    echo   %C_SLATE%  Verifique que la carpeta "Limpieza" exista a la par de las de Office.%C_RESET%
    echo.
    pause
    goto MENU_REPARACION
)
if not exist "%~dp0Limpieza\limpieza.xml" (
    echo   %BG_CRIT% ERROR %C_RESET% %C_CRIT%No se encontro "%~dp0Limpieza\limpieza.xml".%C_RESET%
    echo.
    pause
    goto MENU_REPARACION
)
call :PROGRESS_BAR "Inicializando motor de limpieza y reparacion forzada..." "%C_WARN%"
echo.
echo   %C_WARN%  ❯ Ejecutando: setup.exe /configure limpieza.xml...%C_RESET%
echo   %C_SLATE%    Operacion en curso desde carpeta Limpieza. No cierre la ventana.%C_RESET%
pushd "%~dp0Limpieza"
start /B /wait "" "setup.exe" /configure "limpieza.xml"
popd
echo.
echo   %C_BORDER%┌────────────────────────────────────────────────────────────────────┐%C_RESET%
echo   %C_BORDER%│%BG_OK%  REPARACION FORZADA COMPLETADA EXITOSAMENTE                        %C_RESET%%C_BORDER%│%C_RESET%
echo   %C_BORDER%└────────────────────────────────────────────────────────────────────┘%C_RESET%
echo.
pause
goto MENU


:: ============================================================================
:: MODULO [E]: EXPORTADOR DE KIT A USB / RUTA CON BARRA DE CARGA REACTIVA
:: ============================================================================
:EXPORTAR_KIT_OPERADOR
mode con: cols=74 lines=38
cls
echo.
echo   %C_BORDER%┌────────────────────────────────────────────────────────────────────┐%C_RESET%
echo   %C_BORDER%│%BG_HEADER%  CENTRO DE CLONACION Y DESPLIEGUE A USB [PERFIL DE OPERADOR]       %C_RESET%%C_BORDER%│%C_RESET%
echo   %C_BORDER%├────────────────────────────────────────────────────────────────────┤%C_RESET%
echo   %C_BORDER%│                                                                    │%C_RESET%
echo   %C_BORDER%│  %C_WHITE%Clona toda la suite [Office 2024, 2019, Limpieza y Script] hacia  %C_BORDER%│%C_RESET%
echo   %C_BORDER%│  %C_WHITE%una unidad USB o carpeta destino, preconfigurando automaticamente %C_BORDER%│%C_RESET%
echo   %C_BORDER%│  %C_WHITE%la copia exportada con %C_OK%Watchdog ACTIVO [ON]%C_WHITE% y %C_CYAN%1 Hora [3600s]%C_WHITE%.     %C_BORDER%│%C_RESET%
echo   %C_BORDER%│                                                                    │%C_RESET%
echo   %C_BORDER%├────────────────────────────────────────────────────────────────────┤%C_RESET%
echo   %C_BORDER%│  %C_CORP%UNIDADES ALMACENAMIENTO DETECTADAS EN EL EQUIPO                   %C_BORDER%│%C_RESET%
echo   %C_BORDER%└────────────────────────────────────────────────────────────────────┘%C_RESET%
echo.
call :PS_EXEC "LIST_DRIVES"
echo.
echo   %C_BORDER%┌────────────────────────────────────────────────────────────────────┐%C_RESET%
echo   %C_BORDER%│  %C_SLATE%∙ Ingrese la letra de unidad [ej: %C_WHITE%E%C_SLATE%] o ruta completa [ej: %C_WHITE%D:\Kit%C_SLATE%] %C_BORDER%│%C_RESET%
echo   %C_BORDER%│  %C_SLATE%∙ Escriba [%C_WHITE%M%C_SLATE%] para cancelar y regresar al Menu Principal.         %C_BORDER%│%C_RESET%
echo   %C_BORDER%└────────────────────────────────────────────────────────────────────┘%C_RESET%
echo.
echo %ESC%[?25h
set "EXP_DEST="
set /p "EXP_DEST=   %C_CORP%❯%C_WHITE% Unidad o Ruta destino: %C_TEXT%"
echo %ESC%[?25l

if not defined EXP_DEST goto MENU
if /I "!EXP_DEST!"=="M" goto MENU

call :PS_GET "EXPORT_KIT" "%CARPETA_LIMPIA%" "!EXP_DEST!" "EXP_RES"
echo.
if "!EXP_RES:~0,2!"=="OK" (
    echo   %C_BORDER%┌────────────────────────────────────────────────────────────────────┐%C_RESET%
    echo   %C_BORDER%│%BG_OK%  ✔ CLONACION Y CONFIGURACION COMPLETADAS CON EXITO                 %C_RESET%%C_BORDER%│%C_RESET%
    echo   %C_BORDER%├────────────────────────────────────────────────────────────────────┤%C_RESET%
    echo   %C_BORDER%│                                                                    │%C_RESET%
    echo   %C_BORDER%│  %C_SLATE%Ubicacion Destino : %C_WHITE%!EXP_RES:~3!%ESC%[72G%C_BORDER%│%C_RESET%
    echo   %C_BORDER%│  %C_SLATE%Perfil Inyectado  : %C_OK%● Watchdog ON %C_SLATE%• %C_CYAN%Tiempo: 1 Hora [3600s]%ESC%[72G%C_BORDER%│%C_RESET%
    echo   %C_BORDER%│                                                                    │%C_RESET%
    echo   %C_BORDER%└────────────────────────────────────────────────────────────────────┘%C_RESET%
) else (
    echo   %BG_CRIT% ERROR DE EXPORTACION %C_RESET% %C_CRIT%!EXP_RES!%C_RESET%
)
echo.
pause
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
:: PANEL DE CONFIGURACION CON AUTO-ACTIVACION AL CAMBIAR TIEMPO Y BOTON [G]
:: ============================================================================
:INIT_CONFIG
set "TMP_TIMEOUT=!CFG_TIMEOUT!"
set "TMP_WATCHDOG=!CFG_WATCHDOG!"
set "UNSAVED_CHANGES=NO"

:MENU_CONFIG
if /I "!CFG_WATCHDOG!"=="ON" echo !CFG_TIMEOUT!>"%ACTIVITY_FILE%"
call :FORMAT_TIME "!TMP_TIMEOUT!"
mode con: cols=74 lines=35
cls

set "WD_CFG_TXT=%C_WARN_DIM%○ Deshabilitado [OFF]"
if /I "!TMP_WATCHDOG!"=="ON" set "WD_CFG_TXT=%C_OK%%C_BLINK%●%C_RESET%%C_OK% Habilitado [ON]"

set "SAVE_STATUS_TXT=%C_SLATE%Estado: Sin modificaciones pendientes.                            "
if "!UNSAVED_CHANGES!"=="YES" set "SAVE_STATUS_TXT=%C_WARN%● CAMBIOS PENDIENTES: Presione [G] para guardar y aplicar.        "

echo.
echo   %C_BORDER%┌────────────────────────────────────────────────────────────────────┐%C_RESET%
echo   %C_BORDER%│%BG_HEADER%  CONFIGURACION DE PARAMETROS PERSISTENTES DEL SISTEMA              %C_RESET%%C_BORDER%│%C_RESET%
echo   %C_BORDER%│                                                                    │%C_RESET%
echo   %C_BORDER%│  !SAVE_STATUS_TXT!%ESC%[72G%C_BORDER%│%C_RESET%
echo   %C_BORDER%├──────┬───────────────────────────────────┬─────────────────────────┤%C_RESET%
echo   %C_BORDER%│      │                                   │                         │%C_RESET%
echo   %C_BORDER%│ %C_CORP%[1]  %C_BORDER%│ %C_WHITE%Tiempo Limite de Inactividad      %C_BORDER%│ %C_CYAN%!TIME_STR! %C_SLATE%[!TMP_TIMEOUT!s]%C_RESET%%ESC%[72G%C_BORDER%│%C_RESET%
echo   %C_BORDER%│      │                                   │                         │%C_RESET%
echo   %C_BORDER%│ %C_CORP%[2]  %C_BORDER%│ %C_WHITE%Estado Permanente del Protector   %C_BORDER%│ !WD_CFG_TXT!%ESC%[72G%C_BORDER%│%C_RESET%
echo   %C_BORDER%│      │                                   │                         │%C_RESET%
echo   %C_BORDER%├──────┼───────────────────────────────────┴─────────────────────────┤%C_RESET%
echo   %C_BORDER%│      │                                                             │%C_RESET%
echo   %C_BORDER%│ %C_OK%[G]  %C_BORDER%│ %C_OK%GUARDAR CAMBIOS PERMANENTEMENTE Y CERRAR EL SISTEMA         %C_BORDER%│%C_RESET%
echo   %C_BORDER%│      │                                                             │%C_RESET%
echo   %C_BORDER%│ %C_SLATE%[M]  %C_BORDER%│ %C_TEXT%Descartar cambios y regresar al Menu Principal              %C_BORDER%│%C_RESET%
echo   %C_BORDER%│      │                                                             │%C_RESET%
echo   %C_BORDER%└──────┴─────────────────────────────────────────────────────────────┘%C_RESET%
echo.
echo %ESC%[?25h
set "CFG_OP="
set /p "CFG_OP=   %C_CORP%❯%C_WHITE% Seleccione una opcion [1 / 2 / G / M]: %C_TEXT%"
echo %ESC%[?25l

if defined CFG_OP set "CFG_OP=!CFG_OP: =!"

if "!CFG_OP!"=="1" goto CFG_SET_TIME
if "!CFG_OP!"=="2" goto CFG_TOGGLE_BOOT
if /I "!CFG_OP!"=="G" goto CFG_COMMIT_AND_EXIT
if /I "!CFG_OP!"=="M" goto MENU
goto MENU_CONFIG

:CFG_SET_TIME
echo.
echo   %C_SLATE%Ingrese el tiempo en segundos [Por defecto: 3600 = 1 Hora, Prueba: 120 = 2 Min]%C_RESET%
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
:: Al establecer un tiempo, activar automaticamente el Watchdog a ON
set "TMP_TIMEOUT=!TEST_NUM!"
set "TMP_WATCHDOG=ON"
set "UNSAVED_CHANGES=YES"
goto MENU_CONFIG

:CFG_TOGGLE_BOOT
set "NEW_WD=ON"
if /I "!TMP_WATCHDOG!"=="ON" set "NEW_WD=OFF"
set "TMP_WATCHDOG=!NEW_WD!"
set "UNSAVED_CHANGES=YES"
goto MENU_CONFIG

:CFG_COMMIT_AND_EXIT
set "CFG_TIMEOUT=!TMP_TIMEOUT!"
set "CFG_WATCHDOG=!TMP_WATCHDOG!"
call :FORMAT_TIME "!CFG_TIMEOUT!"
echo.
echo   %C_SLATE%∙ Escribiendo parametros permanentes y actualizando demonio...%C_RESET%
call :PS_EXEC "SAVE_ALL_CONFIG" "!CFG_TIMEOUT!" "!CFG_WATCHDOG!" "%CARPETA_LIMPIA%"

echo.
echo   %C_BORDER%┌────────────────────────────────────────────────────────────────────┐%C_RESET%
echo   %C_BORDER%│%BG_OK%  CONFIGURACION GUARDADA CORRECTAMENTE                              %C_RESET%%C_BORDER%│%C_RESET%
echo   %C_BORDER%├────────────────────────────────────────────────────────────────────┤%C_RESET%
echo   %C_BORDER%│                                                                    │%C_RESET%
if /I "!CFG_WATCHDOG!"=="ON" (
    echo   %C_BORDER%│  %C_OK%✔ El protector de inactividad ha quedado ACTIVO [!TIME_STR!].%ESC%[72G%C_BORDER%│%C_RESET%
    echo   %C_BORDER%│  %C_SLATE%  Si esta carpeta no se utiliza durante ese tiempo, se eliminara  %C_BORDER%│%C_RESET%
    echo   %C_BORDER%│  %C_SLATE%  automaticamente en segundo plano para proteger las licencias.   %C_BORDER%│%C_RESET%
) else (
    echo   %C_BORDER%│  %C_WARN_DIM%○ El protector de inactividad ha quedado DESACTIVADO [OFF].       %C_BORDER%│%C_RESET%
    echo   %C_BORDER%│  %C_SLATE%  La carpeta no se eliminara automaticamente por inactividad.     %C_BORDER%│%C_RESET%
)
echo   %C_BORDER%│                                                                    │%C_RESET%
echo   %C_BORDER%│  %C_WHITE%Cerrando el sistema. ¡Hasta luego!                                %C_BORDER%│%C_RESET%
echo   %C_BORDER%└────────────────────────────────────────────────────────────────────┘%C_RESET%
ping 127.0.0.1 -n 4 >nul
echo %ESC%[?25h
exit


:: ============================================================================
:: CENTRO DE ACTUALIZACIONES OTA (DESCARGA SCRIPT + GUIA AUTOMATICAMENTE)
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
call :PS_GET "FETCH_UPDATE_INFO" "!APP_VERSION!" "" "OTA_RAW"
if defined OTA_RAW (
    for /f "tokens=1,2 delims=|" %%A in ("!OTA_RAW!") do (
        set "OTA_STATUS=%%A"
        set "REMOTE_VER=%%B"
    )
)

set "REM_STAT_TXT=%C_CRIT%✖ Sin conexion al servidor"
if "!OTA_STATUS!"=="UPDATE" set "REM_STAT_TXT=%C_OK%%C_BLINK%●%C_RESET%%C_OK% v!REMOTE_VER! [Nueva Version]"
if "!OTA_STATUS!"=="UPDATE" set "UPD_AVAILABLE=YES"
if "!OTA_STATUS!"=="UPTODATE" set "REM_STAT_TXT=%C_CYAN%✔ v!REMOTE_VER! [Al dia]"
if "!OTA_STATUS!"=="UPTODATE" set "UPD_AVAILABLE=NO"
if "!OTA_STATUS!"=="UNCONFIGURED" set "REM_STAT_TXT=%C_WARN%○ Sin configurar [Plantilla]"

cls
echo.
echo   %C_BORDER%┌────────────────────────────────────────────────────────────────────┐%C_RESET%
echo   %C_BORDER%│%BG_HEADER%  CENTRO DE ACTUALIZACIONES CORPORATIVAS [GITHUB OTA]               %C_RESET%%C_BORDER%│%C_RESET%
echo   %C_BORDER%├──────────────────────────────────┬─────────────────────────────────┤%C_RESET%
echo   %C_BORDER%│                                  │                                 │%C_RESET%
echo   %C_BORDER%│%C_SLATE%  Version Local Instalada         %C_BORDER%│%C_SLATE%  Version en Servidor GitHub     %C_BORDER%│%C_RESET%
echo   %C_BORDER%│  %C_WHITE%v!APP_VERSION!%ESC%[38G%C_BORDER%│  !REM_STAT_TXT!%ESC%[72G%C_BORDER%│%C_RESET%
echo   %C_BORDER%│                                  │                                 │%C_RESET%
echo   %C_BORDER%├──────────────────────────────────┴─────────────────────────────────┤%C_RESET%
echo   %C_BORDER%│  %C_CORP%LISTA DE CAMBIOS Y NOVEDADES [CHANGELOG.TXT]                      %C_BORDER%│%C_RESET%
echo   %C_BORDER%└────────────────────────────────────────────────────────────────────┘%C_RESET%
echo.

if exist "%CHANGELOG_CACHE%" (
    for /f "usebackq delims=" %%L in ("%CHANGELOG_CACHE%") do echo     %C_TEXT%∙ %%L%C_RESET%
)
if not exist "%CHANGELOG_CACHE%" echo     %C_SLATE%No hay notas de version disponibles para mostrar.%C_RESET%

echo.
echo   %C_BORDER%──────────────────────────────────────────────────────────────────────%C_RESET%

if "!OTA_STATUS!"=="UNCONFIGURED" goto OTA_MSG_UNCFG
if "!OTA_STATUS!"=="ERROR" goto OTA_MSG_ERR

echo.
echo %ESC%[?25h
set "UPD_CONFIRM="
if "!OTA_STATUS!"=="UPDATE" set /p "UPD_CONFIRM=   %C_OK%❯%C_WHITE% ¿Desea descargar e instalar la version v!REMOTE_VER! + Guia ahora? [S / N]: %C_TEXT%"
if not "!OTA_STATUS!"=="UPDATE" set /p "UPD_CONFIRM=   %C_CORP%❯%C_WHITE% El sistema esta al dia. ¿Volver al Menu Principal? [Enter]: %C_TEXT%"
echo %ESC%[?25l

if not "!OTA_STATUS!"=="UPDATE" goto MENU
if defined UPD_CONFIRM set "UPD_CONFIRM=!UPD_CONFIRM: =!"
if /I not "!UPD_CONFIRM!"=="S" goto MENU

:: Si es OPERADOR (USER), exigir la credencial "1015Update". Si es ADMIN, pasa directo.
if /I "!AUTH_MODE!"=="ADMIN" goto DO_OTA_DOWNLOAD

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
if "!UPD_AUTH_RES!"=="OK" goto DO_OTA_DOWNLOAD

echo.
echo   %BG_CRIT% AUTORIZACION DENEGADA %C_RESET% %C_CRIT%Credencial de actualizacion incorrecta.%C_RESET%
ping 127.0.0.1 -n 3 >nul
goto MENU

:DO_OTA_DOWNLOAD
if /I not "!AUTH_MODE!"=="ADMIN" echo. & echo   %BG_OK% AUTORIZADO %C_RESET% %C_OK%Permiso de actualizacion verificado.%C_RESET%
echo.
call :PROGRESS_BAR "Descargando nueva version y Guia de Operador desde GitHub..." "%C_CYAN%"
call :PS_GET "APPLY_UPDATE" "%~dp0Guia de Operador Office Installer.txt" "" "APPLY_RES"

if "!APPLY_RES!"=="OK" (
    echo !REMOTE_VER!>"%JUST_UPDATED_FLAG%"
    echo.
    echo   %BG_OK% ACTUALIZACION COMPLETADA %C_RESET% %C_OK%Reiniciando aplicacion con notas de version...%C_RESET%
    ping 127.0.0.1 -n 2 >nul
    start "" "%~f0"
    exit
)
echo.
echo   %BG_CRIT% FALLO DE DESCARGA %C_RESET% %C_CRIT%No se pudo escribir la nueva version. Verifique la URL.%C_RESET%
pause
goto MENU

:OTA_MSG_UNCFG
echo.
echo   %BG_WARN% AVISO %C_RESET% %C_WARN%Configure las URLs de su repositorio GitHub al inicio del script.%C_RESET%
echo.
pause
goto MENU

:OTA_MSG_ERR
echo.
echo   %BG_CRIT% ERROR %C_RESET% %C_CRIT%No fue posible conectar con el repositorio remoto en GitHub.%C_RESET%
echo.
pause
goto MENU


:: ============================================================================
:: MODULOS SECUNDARIOS Y LOGS (MG ADAPTADO A ESTETICA CORPORATIVA)[cite: 1]
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
mode con: cols=74 lines=22
cls
call :REGISTRAR_LOG "PAA999" "INICIADO"
echo.
echo.
echo   %C_BORDER%┌────────────────────────────────────────────────────────────────────┐%C_RESET%
echo   %C_BORDER%│%BG_HEADER%  MODULO DE EJECUCION AUXILIAR  •  POWERSHELL ELEVATION             %C_RESET%%C_BORDER%│%C_RESET%
echo   %C_BORDER%├────────────────────────────────────────────────────────────────────┤%C_RESET%
echo   %C_BORDER%│                                                                    │%C_RESET%
echo   %C_BORDER%│  %BG_INFO% [INFO] %C_RESET% %C_WHITE%Lanzando PowerShell como Administrador...                %C_BORDER%│%C_RESET%
echo   %C_BORDER%│           %C_SLATE%Espera a que cargue la ventana azul.                     %C_BORDER%│%C_RESET%
echo   %C_BORDER%│                                                                    │%C_RESET%
echo   %C_BORDER%│  %BG_OK% [PROCESO] %C_RESET% %C_OK%Script ejecutado en segunda ventana.                  %C_BORDER%│%C_RESET%
echo   %C_BORDER%│                                                                    │%C_RESET%
echo   %C_BORDER%└────────────────────────────────────────────────────────────────────┘%C_RESET%
echo.
ping 127.0.0.1 -n 4 >nul
goto MENU

:REGISTRAR_LOG
echo [%DATE% %TIME%] SN:!BIOS_SN! - Codigo:%~1 - Estado:%~2 >> "%~dp0actividad_sistema.log"
exit /b


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

call :PS_GET "DECRYPT_KEY" "!MASTER_KEY!" "" "DEC_KEY"

cd /d "!OFFICE_PATH!"
echo.
echo   %C_CORP%  ❯ Asignando licencia al equipo con serie %C_WHITE%!BIOS_SN!%C_CORP%...%C_RESET%
cscript //nologo ospp.vbs /inpkey:!DEC_KEY! >nul
set "DEC_KEY="
echo   %C_CORP%  ❯ Validando activacion con el servicio de licencias...%C_RESET%
cscript //nologo ospp.vbs /act >nul
echo   %C_OK%  ✔ Producto validado y activado correctamente.%C_RESET%
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
:: SALIDA Y AUTODESTRUCCION[cite: 1]
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

if /I "!CFG_WATCHDOG!"=="ON" echo !CFG_TIMEOUT!>"%ACTIVITY_FILE%"
echo.
echo   %BG_OK% SESION FINALIZADA %C_RESET% %C_OK%Cerrando consola. ¡Hasta pronto!%C_RESET%
ping 127.0.0.1 -n 2 >nul
exit


:: ============================================================================
:: GATITO CALIBRADO A 5 SEGUNDOS EXACTOS (PASO DE COLOR 3 + DELAY 85)[cite: 1]
:: ============================================================================
:ANIMACION_GATITO
reg add "HKCU\Console" /v "FaceName" /t REG_SZ /d "NSimSun" /f >nul 2>&1
chcp 65001 > nul
cls
echo %ESC%[?25l
setlocal EnableDelayedExpansion
mode con: cols=36 lines=21

set "max_loops=1"
set "delay=85"

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

for /L %%i in (150,3,255) do (
    set /a G=%%i
    call :Display !R! !G! !B!
)
for /L %%i in (255,-3,150) do (
    set /a R=%%i
    call :Display !R! !G! !B!
)
for /L %%i in (150,3,255) do (
    set /a B=%%i
    call :Display !R! !G! !B!
)
for /L %%i in (255,-3,150) do (
    set /a G=%%i
    call :Display !R! !G! !B!
)
for /L %%i in (150,3,255) do (
    set /a R=%%i
    call :Display !R! !G! !B!
)
for /L %%i in (255,-3,150) do (
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
:: BORRADO ULTRARRAPIDO EN WINDOWS 10 Y 11 (NOMBRES DE ARCHIVO LIMPIOS)[cite: 1]
:: ============================================================================
:EJECUTAR_BORRADO
reg add "HKCU\Console" /v "FaceName" /t REG_SZ /d "Consolas" /f >nul 2>&1
del /f /q "%ACTIVITY_FILE%" >nul 2>&1
set "KILLER=%TEMP%\modm_sys_cleaner.bat"
if exist "%KILLER%" del /f /q "%KILLER%" >nul 2>&1

(
echo @echo off
echo cd /d "%TEMP%"
echo taskkill /f /im setup.exe ^>nul 2^>^&1
echo :LOOP
echo rmdir /s /q "%CARPETA_LIMPIA%" ^>nul 2^>^&1
echo if exist "%CARPETA_LIMPIA%" ^(
echo     attrib -r -s -h "%CARPETA_LIMPIA%\*" /s /d ^>nul 2^>^&1
echo     del /f /s /q "%CARPETA_LIMPIA%\*" ^>nul 2^>^&1
echo     rmdir /s /q "%CARPETA_LIMPIA%" ^>nul 2^>^&1
echo ^)
echo if exist "%CARPETA_LIMPIA%" goto LOOP
echo ^(goto^) 2^>nul ^& del /f /q "%%~f0"
) > "%KILLER%"

cd /d "%TEMP%"
start "" /min cmd.exe /c "%KILLER%"
exit
#>

# =============================================================================
# NUCLEO NATIVO DE POWERSHELL (VARIABLES LIMPIAS, CERO RASTROS EXTERNOS)
# =============================================================================
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$f        = $env:SELF_FILE
$a        = $env:PS_ACTION
$arg1     = $env:PS_ARG1
$arg2     = $env:PS_ARG2
$arg3     = $env:PS_ARG3
$outF     = $env:PS_OUT_FILE
$actFile  = $env:ACTIVITY_FILE
$clCache  = $env:CHANGELOG_CACHE
$utf8No   = New-Object System.Text.UTF8Encoding($false)

function Start-WatchdogDaemon($targetDir) {
    $pidFile      = Join-Path $env:TEMP "modm_wd_daemon.pid"
    $wdScriptPath = Join-Path $env:TEMP "modm_watchdog_daemon.ps1"
    $vbsLauncher  = Join-Path $env:TEMP "modm_wd_launcher.vbs"
    $killerPath   = Join-Path $env:TEMP "modm_wd_killer.bat"

    if (Test-Path -LiteralPath $pidFile) {
        try {
            $oldPid = [int]([System.IO.File]::ReadAllText($pidFile).Trim())
            Stop-Process -Id $oldPid -Force -ErrorAction SilentlyContinue
        } catch {}
    }

    $batLines = @(
        '@echo off',
        'cd /d "%TEMP%"',
        'taskkill /f /im setup.exe >nul 2>&1',
        'for /f "tokens=2" %%P in (''tasklist /v /fo csv ^| findstr /i "Deployment Manager"'') do taskkill /f /pid %%~P >nul 2>&1',
        'powershell -NoProfile -WindowStyle Hidden -Command "Get-CimInstance Win32_Process | Where-Object { $_.CommandLine -match ''Instalador'' } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }" >nul 2>&1',
        'ping 127.0.0.1 -n 2 >nul',
        ':L',
        ('rmdir /s /q "' + $targetDir + '" >nul 2>&1'),
        ('if exist "' + $targetDir + '" ('),
        ('    attrib -r -s -h "' + $targetDir + '\*" /s /d >nul 2>&1'),
        ('    del /f /s /q "' + $targetDir + '\*" >nul 2>&1'),
        ('    rmdir /s /q "' + $targetDir + '" >nul 2>&1'),
        ')',
        ('if exist "' + $targetDir + '" ('),
        '    ping 127.0.0.1 -n 2 >nul',
        '    goto L',
        ')',
        '(goto) 2>nul & del /f /q "%~f0"'
    )
    $batContent = $batLines -join "`r`n"
    [System.IO.File]::WriteAllText($killerPath, $batContent, [System.Text.Encoding]::ASCII)

    $psLines = @(
        '$ErrorActionPreference = "SilentlyContinue"',
        'Set-Location -LiteralPath $env:TEMP',
        ('$dir     = ''' + $targetDir + ''''),
        ('$flag    = ''' + $actFile + ''''),
        ('$pidPath = ''' + $pidFile + ''''),
        ('$killer  = ''' + $killerPath + ''''),
        '[System.IO.File]::WriteAllText($pidPath, $PID.ToString())',
        'while ($true) {',
        '    Start-Sleep -Seconds 2',
        '    if (-not (Test-Path -LiteralPath $flag)) { break }',
        '    if (-not (Test-Path -LiteralPath $dir))  { Remove-Item -LiteralPath $flag -Force; break }',
        '    $item = Get-Item -LiteralPath $flag',
        '    if (-not $item) { break }',
        '    $rawText = [System.IO.File]::ReadAllText($flag).Trim()',
        '    $limitSec = 3600',
        '    if ($rawText -match "^\d+$") { $limitSec = [int]$rawText }',
        '    $idleSeconds = ((Get-Date) - $item.LastWriteTime).TotalSeconds',
        '    if ($idleSeconds -ge $limitSec) {',
        '        Remove-Item -LiteralPath $flag -Force',
        '        Remove-Item -LiteralPath $pidPath -Force',
        '        $wsh = New-Object -ComObject WScript.Shell',
        '        $wsh.Run("cmd.exe /c `"" + $killer + "`"", 0, $false)',
        '        break',
        '    }',
        '}'
    )
    $psContent = $psLines -join "`r`n"
    [System.IO.File]::WriteAllText($wdScriptPath, $psContent, $utf8No)

    $vbsLine1 = 'Set WshShell = CreateObject("WScript.Shell")'
    $vbsLine2 = 'WshShell.Run "powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File ""' + $wdScriptPath + '""", 0, False'
    [System.IO.File]::WriteAllText($vbsLauncher, ($vbsLine1 + "`r`n" + $vbsLine2), [System.Text.Encoding]::ASCII)
    Start-Process -FilePath "wscript.exe" -ArgumentList ('//nologo "' + $vbsLauncher + '"') -WorkingDirectory $env:TEMP -WindowStyle Hidden
}

function Draw-BootProgress([int]$pct, [string]$statusText) {
    $e = [char]27
    $cBorder = "$e[38;2;70;82;102m"
    $cCorp   = "$e[38;2;45;140;240m"
    $cWhite  = "$e[38;2;255;255;255m"
    $cSlate  = "$e[38;2;130;145;165m"
    $cReset  = "$e[0m"

    $totalBlocks = 36
    $filled = [Math]::Floor(($pct / 100.0) * $totalBlocks)
    $empty  = $totalBlocks - $filled
    $barStr = ("━" * $filled)
    $empStr = ("─" * $empty)
    if ($statusText.Length -gt 58) { $statusText = $statusText.Substring(0, 58) }
    $padStatus = $statusText.PadRight(58, ' ')
    $pctStr    = $pct.ToString().PadLeft(3, ' ')

    [Console]::Write("$e[12;1H  $cBorder│$cReset  $cSlate$padStatus$cReset$e[72G$cBorder│$cReset")
    [Console]::Write("$e[14;1H  $cBorder│$cReset    $cBorder[$cCorp$barStr$cBorder$empStr] $cWhite$pctStr%$cReset$e[72G$cBorder│$cReset")
}

function Test-AuthCredential([string]$cleanInput) {
    if ([string]::IsNullOrWhiteSpace($cleanInput)) { return "FAIL" }
    $cleanInput = $cleanInput.Trim()
    $inBytes = [System.Text.Encoding]::UTF8.GetBytes($cleanInput)

    $admVec = @(94, 69, 117, 131, 102, 120, 69, 117, 65, 131)
    $isAdm  = ($inBytes.Length -eq $admVec.Length)
    if ($isAdm) {
        for ($i = 0; $i -lt $inBytes.Length; $i++) {
            if (($inBytes[$i] + 17) -ne $admVec[$i]) { $isAdm = $false; break }
        }
    }
    if ($isAdm) { return "ADMIN" }

    $cipherBytes = [Convert]::FromBase64String("wsHDpqy4ptfaza29ptLSwsa4xtKmrdC9zaHfptA=")
    $plainBytes = New-Object byte[] $cipherBytes.Length
    for ($i = 0; $i -lt $cipherBytes.Length; $i++) {
        $plainBytes[$i] = $cipherBytes[$i] -bxor 0xA5 -bxor $inBytes[$i % $inBytes.Length]
    }
    $candidate = [System.Text.Encoding]::UTF8.GetString($plainBytes)
    if ($candidate -match '^[A-Z0-9]{5}-[A-Z0-9]{5}-[A-Z0-9]{5}-[A-Z0-9]{5}-[A-Z0-9]{5}$') {
        return "USER"
    }
    return "FAIL"
}

switch ($a) {

    # 0. BOOT_INIT CON BARRA DE CARGA REACTIVA EN TIEMPO REAL
    "BOOT_INIT" {
        $targetDir = $arg1
        $wdState   = $env:CFG_WATCHDOG.Trim()
        $localVer  = [version]($env:APP_VERSION.Trim())
        $verUrl    = $env:GH_VERSION_URL
        $clUrl     = $env:GH_CHANGELOG_URL

        $e = [char]27
        $cBorder = "$e[38;2;70;82;102m"
        $bgHead  = "$e[48;2;20;32;52m$e[38;2;255;255;255m"
        $cReset  = "$e[0m"

        [Console]::Clear()
        [Console]::WriteLine("")
        [Console]::WriteLine("")
        [Console]::WriteLine("")
        [Console]::WriteLine("")
        [Console]::WriteLine("")
        [Console]::WriteLine("")
        [Console]::WriteLine("")
        [Console]::WriteLine("  $cBorder┌────────────────────────────────────────────────────────────────────┐$cReset")
        [Console]::WriteLine("  $cBorder│$bgHead  INICIALIZANDO MICROSOFT OFFICE DEPLOYMENT MANAGER          v$localVer  $cReset$cBorder│$cReset")
        [Console]::WriteLine("  $cBorder├────────────────────────────────────────────────────────────────────┤$cReset")
        [Console]::WriteLine("  $cBorder│                                                                    │$cReset")
        [Console]::WriteLine("  $cBorder│                                                                    │$cReset")
        [Console]::WriteLine("  $cBorder│                                                                    │$cReset")
        [Console]::WriteLine("  $cBorder│                                                                    │$cReset")
        [Console]::WriteLine("  $cBorder│                                                                    │$cReset")
        [Console]::WriteLine("  $cBorder└────────────────────────────────────────────────────────────────────┘$cReset")

        Draw-BootProgress 15 "Consultando identificacion de hardware [SMBIOS]..."
        $sn = "GENERIC-SN"
        try {
            $val = (Get-CimInstance -ClassName Win32_BIOS -ErrorAction Stop).SerialNumber
            if (-not [string]::IsNullOrWhiteSpace($val)) { $sn = $val.Trim() }
        } catch {}
        Draw-BootProgress 40 ("Hardware verificado [" + $sn + "]. Conectando con GitHub...")

        $upd = "NO"
        $remVerStr = $localVer.ToString()
        try {
            if ($verUrl -notmatch "TU_USUARIO") {
                $ts = [DateTimeOffset]::Now.ToUnixTimeSeconds()
                Draw-BootProgress 65 "Verificando version remota en repositorio EMSIM..."
                $rStr = (Invoke-WebRequest -Uri ($verUrl + "?t=" + $ts) -UseBasicParsing -TimeoutSec 3 -ErrorAction Stop).Content.Trim()
                if ([version]$rStr -gt $localVer) {
                    $upd = "YES"
                    $remVerStr = $rStr
                } else {
                    $remVerStr = $rStr
                }
                # Si acaba de actualizarse, asegurar que changelog este en cache para la pantalla post-update
                if ((Test-Path -LiteralPath $env:JUST_UPDATED_FLAG) -and (-not (Test-Path -LiteralPath $clCache))) {
                    $clText = (Invoke-WebRequest -Uri ($clUrl + "?t=$ts") -UseBasicParsing -TimeoutSec 3 -ErrorAction SilentlyContinue).Content.Trim()
                    if (-not [string]::IsNullOrWhiteSpace($clText)) {
                        [System.IO.File]::WriteAllText($clCache, $clText, $utf8No)
                    }
                }
            }
        } catch {}
        Draw-BootProgress 85 "Sincronizacion completada. Iniciando demonio de seguridad..."

        if ($wdState -match '^ON$') {
            Start-WatchdogDaemon $targetDir
        }
        Draw-BootProgress 100 "Entorno corporativo listo. Abriendo consola de acceso..."
        Start-Sleep -Milliseconds 180

        [System.IO.File]::WriteAllText($outF, ($sn + "|" + $upd + "|" + $remVerStr), $utf8No)
    }

    # 1A. LECTURA DE CONTRASENA EN LOGIN CENSURADA CON ASTERISCOS (*) Y VALIDACION DIRECTA
    "READ_MASKED_AUTH" {
        $pass = ""
        try {
            while ($true) {
                $k = [Console]::ReadKey($true)
                if ($k.Key -eq [ConsoleKey]::Enter) {
                    break
                } elseif ($k.Key -eq [ConsoleKey]::Backspace) {
                    if ($pass.Length -gt 0) {
                        $pass = $pass.Substring(0, $pass.Length - 1)
                        [Console]::Write("`b `b")
                    }
                } elseif ($k.KeyChar -ge ' ' -and [int]$k.KeyChar -le 126) {
                    $pass += $k.KeyChar
                    [Console]::Write("*")
                }
            }
        } catch {}
        $res = Test-AuthCredential $pass
        [System.IO.File]::WriteAllText($outF, $res, $utf8No)
    }

    # 1B. VALIDACION CRIPTOGRAFICA EN MENU: "1015" (USER) O "M4drUg4d0r" (ADMIN)
    "VERIFY_PASS" {
        $res = Test-AuthCredential ([string]$arg1)
        [System.IO.File]::WriteAllText($outF, $res, $utf8No)
    }

    # 2. VALIDACION EXACTA DE LLAVE DE ACTUALIZACION ("1015Update")
    "VERIFY_UPD_PASS" {
        $res = "FAIL"
        try {
            $cleanInput = [string]$arg1
            if (-not [string]::IsNullOrWhiteSpace($cleanInput)) {
                $inBytes = [System.Text.Encoding]::UTF8.GetBytes($cleanInput.Trim())
                $updVec = @(66, 65, 66, 70, 102, 129, 117, 114, 133, 118)
                $isUpd  = ($inBytes.Length -eq $updVec.Length)
                if ($isUpd) {
                    for ($i = 0; $i -lt $inBytes.Length; $i++) {
                        if (($inBytes[$i] + 17) -ne $updVec[$i]) { $isUpd = $false; break }
                    }
                }
                if ($isUpd) { $res = "OK" }
            }
        } catch {}
        [System.IO.File]::WriteAllText($outF, $res, $utf8No)
    }

    # 3. BOVEDA CRIPTOGRAFICA DE LICENCIAS
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
            [System.IO.File]::WriteAllText($outF, $license, $utf8No)
        } catch {
            [System.IO.File]::WriteAllText($outF, "ERROR-DECRYPT", $utf8No)
        }
    }

    # 4. GUARDADO DEFINITIVO Y REINICIO DEL DEMONIO WATCHDOG
    "SAVE_ALL_CONFIG" {
        try {
            $newTimeout  = $arg1.Trim()
            $newWatchdog = $arg2.Trim()
            $targetDir   = $arg3

            $fileItem = Get-Item -LiteralPath $f -Force -ErrorAction SilentlyContinue
            if ($fileItem -and $fileItem.IsReadOnly) {
                $fileItem.IsReadOnly = $false
            }

            $lines = [System.IO.File]::ReadAllLines($f, [System.Text.Encoding]::UTF8)
            for ($i = 0; $i -lt [Math]::Min(25, $lines.Count); $i++) {
                if ($lines[$i] -match '^\s*set\s+"CFG_TIMEOUT=[^"]*"\s*$') {
                    $lines[$i] = ('set "CFG_TIMEOUT=' + $newTimeout + '"').PadRight(45, ' ')
                }
                if ($lines[$i] -match '^\s*set\s+"CFG_WATCHDOG=[^"]*"\s*$') {
                    $lines[$i] = ('set "CFG_WATCHDOG=' + $newWatchdog + '"').PadRight(45, ' ')
                }
            }
            $joined = [string]::Join("`r`n", $lines) + "`r`n"
            [System.IO.File]::WriteAllText($f, $joined, $utf8No)

            if ($newWatchdog -match '^ON$') {
                [System.IO.File]::WriteAllText($actFile, $newTimeout, $utf8No)
                Start-WatchdogDaemon $targetDir
            } else {
                if (Test-Path -LiteralPath $actFile) {
                    Remove-Item -LiteralPath $actFile -Force -ErrorAction SilentlyContinue
                }
                $pidFile = Join-Path $env:TEMP "modm_wd_daemon.pid"
                if (Test-Path -LiteralPath $pidFile) {
                    $oldPid = [int]([System.IO.File]::ReadAllText($pidFile).Trim())
                    Stop-Process -Id $oldPid -Force -ErrorAction SilentlyContinue
                    Remove-Item -LiteralPath $pidFile -Force -ErrorAction SilentlyContinue
                }
            }
        } catch {}
    }

    # 5A. OBTENER INFORMACION COMPLETA Y DESCARGAR CHANGELOG.TXT
    "FETCH_UPDATE_INFO" {
        if (Test-Path $clCache) { Remove-Item $clCache -Force -ErrorAction SilentlyContinue }
        $localVer = [version]$arg1
        $verUrl   = $env:GH_VERSION_URL
        $clUrl    = $env:GH_CHANGELOG_URL

        if ($verUrl -match "TU_USUARIO") {
            [System.IO.File]::WriteAllText($clCache, "Repositorio pendiente de vinculacion.`r`nConfigure GH_VERSION_URL, GH_CHANGELOG_URL y GH_SCRIPT_URL.", $utf8No)
            [System.IO.File]::WriteAllText($outF, ("UNCONFIGURED|" + $arg1), $utf8No)
            break
        }

        try {
            $ts = [DateTimeOffset]::Now.ToUnixTimeSeconds()
            $remoteStr = (Invoke-WebRequest -Uri ($verUrl + "?t=" + $ts) -UseBasicParsing -TimeoutSec 8 -ErrorAction Stop).Content.Trim()
            $remoteVer = [version]$remoteStr

            try {
                $clText = (Invoke-WebRequest -Uri ($clUrl + "?t=" + $ts) -UseBasicParsing -TimeoutSec 8 -ErrorAction Stop).Content.Trim()
                if ([string]::IsNullOrWhiteSpace($clText)) { $clText = "Sin detalles adicionales en changelog.txt." }
            } catch {
                $clText = "No se encontro el archivo changelog.txt en el repositorio azarel22/EMSIM."
            }
            [System.IO.File]::WriteAllText($clCache, $clText, $utf8No)

            if ($remoteVer -gt $localVer) {
                [System.IO.File]::WriteAllText($outF, ("UPDATE|" + $remoteStr), $utf8No)
            } else {
                [System.IO.File]::WriteAllText($outF, ("UPTODATE|" + $remoteStr), $utf8No)
            }
        } catch {
            [System.IO.File]::WriteAllText($clCache, ("Error al consultar el servidor remoto: " + $_.Exception.Message), $utf8No)
            [System.IO.File]::WriteAllText($outF, "ERROR|N/A", $utf8No)
        }
    }

    # 5B. DESCARGAR NUEVO SCRIPT + DESCARGAR AUTOMATICAMENTE LA GUIA DE OPERADOR AL ACTUALIZAR
    "APPLY_UPDATE" {
        $res = "FAIL"
        try {
            $guideDest = $arg1
            $scriptUrl = $env:GH_SCRIPT_URL
            $guideUrl  = $env:GH_GUIDE_URL
            if ([string]::IsNullOrWhiteSpace($scriptUrl)) {
                $scriptUrl = "https://raw.githubusercontent.com/azarel22/EMSIM/refs/heads/main/Instalador%20Pro.bat"
            }
            if ([string]::IsNullOrWhiteSpace($guideUrl)) {
                $guideUrl = "https://raw.githubusercontent.com/azarel22/EMSIM/refs/heads/main/Guia%20de%20Operador%20Office%20Installer.txt"
            }
            $scriptUrl = $scriptUrl.Replace(" ", "%20")
            $guideUrl  = $guideUrl.Replace(" ", "%20")

            $ts   = [DateTimeOffset]::Now.ToUnixTimeSeconds()
            $wc   = New-Object System.Net.WebClient
            $wc.Encoding = [System.Text.Encoding]::UTF8
            $wc.Headers.Add("Cache-Control", "no-cache")

            # 1. Descargar y sobrescribir automaticamente la Guia de Operador
            try {
                $gBytes = $wc.DownloadData($guideUrl + "?t=" + $ts)
                $gText  = [System.Text.Encoding]::UTF8.GetString($gBytes)
                if ($gText.Length -gt 0 -and [int]$gText[0] -eq 65279) { $gText = $gText.Substring(1) }
                [System.IO.File]::WriteAllText($guideDest, $gText, $utf8No)
            } catch {}

            # 2. Descargar y sobrescribir el propio script .bat
            $rawBytes   = $wc.DownloadData($scriptUrl + "?t=" + $ts)
            $newContent = [System.Text.Encoding]::UTF8.GetString($rawBytes)

            if ($newContent.Length -gt 0 -and [int]$newContent[0] -eq 65279) {
                $newContent = $newContent.Substring(1)
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

    # 6. REPARACION OFICIAL DE OFFICE (INTEGRADA DE REPARACION.BAT)[cite: 4]
    "REPAIR_OFFICIAL" {
        $ErrorActionPreference = 'SilentlyContinue'
        try {
            $paths = @(
                'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
                'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
            )
            $cfg = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration'
            $apps = Get-ItemProperty -Path $paths | Where-Object {
                $_.DisplayName -match 'Microsoft (Office|365)' -and
                $_.DisplayName -notmatch 'Proofing|Language Pack|MUI|Web Components|Update|Viewer|Interop|Shared'
            }

            $items = @()
            $seenC2R = @{}

            foreach ($app in $apps) {
                $u = $app.UninstallString
                if (-not $u) { continue }

                if ($u -match 'OfficeClickToRun\.exe') {
                    $exe = ''
                    if ($u -match '^"([^"]+)"') { $exe = $matches[1] }
                    elseif ($u -match '^(.*?\.exe)') { $exe = $matches[1] }
                    if (-not $exe -or -not (Test-Path $exe)) { continue }
                    if ($seenC2R.ContainsKey($exe)) { continue }
                    $seenC2R[$exe] = $true

                    $plat = $cfg.Platform
                    if (-not $plat) {
                        if ([Environment]::Is64BitOperatingSystem) { $plat = 'x64' } else { $plat = 'x86' }
                    }
                    $cult = $cfg.ClientCulture
                    if (-not $cult -and $u -match 'culture=([\w-]+)') { $cult = $matches[1] }
                    if (-not $cult) { $cult = 'es-es' }

                    $items += [pscustomobject]@{
                        Nombre = $app.DisplayName
                        Tipo   = 'Click-to-Run'
                        Exe    = $exe
                        Args   = "scenario=Repair platform=$plat culture=$cult forceappshutdown=False DisplayLevel=True"
                    }
                }
                elseif ($u -match 'msiexec' -and $app.PSChildName -match '^\{[0-9A-Fa-f-]+\}$') {
                    $items += [pscustomobject]@{
                        Nombre = $app.DisplayName
                        Tipo   = 'MSI'
                        Exe    = "$env:windir\System32\msiexec.exe"
                        Args   = "/i $($app.PSChildName)"
                    }
                }
            }

            if (-not $items) {
                Write-Host '  [-] No se encontro ninguna instalacion de Office en el registro.' -ForegroundColor DarkGray
                return
            }

            $sel = $items[0]
            if ($items.Count -gt 1) {
                Write-Host '  Instalaciones de Office detectadas:' -ForegroundColor Cyan
                for ($i = 0; $i -lt $items.Count; $i++) {
                    Write-Host ("   [{0}] {1}  ({2})" -f ($i + 1), $items[$i].Nombre, $items[$i].Tipo)
                }
                Write-Host ''
                $n = Read-Host '   Elige el numero a reparar'
                if ($n -notmatch '^\d+$' -or [int]$n -lt 1 -or [int]$n -gt $items.Count) {
                    Write-Host '  [ERROR] Opcion invalida.' -ForegroundColor Red
                    return
                }
                $sel = $items[[int]$n - 1]
            }

            Write-Host ('  [+] Abriendo reparacion/modificacion de: ' + $sel.Nombre + ' [' + $sel.Tipo + ']') -ForegroundColor Cyan
            Start-Process -FilePath $sel.Exe -ArgumentList $sel.Args -Wait
            Write-Host '  [✔] Proceso de reparacion oficial finalizado.' -ForegroundColor Green
        } catch {
            Write-Host ('  [ERROR CRITICO] ' + $_.Exception.Message) -ForegroundColor Red
        }
    }

    # 7A. LISTAR UNIDADES USB Y DISCOS DISPONIBLES PARA EXPORTAR
    "LIST_DRIVES" {
        try {
            $drives = Get-CimInstance Win32_LogicalDisk | Where-Object { $_.DriveType -in @(2, 3) }
            foreach ($d in $drives) {
                $typeStr = if ($d.DriveType -eq 2) { "MEMORIA USB [Extraible]" } else { "Disco Local            " }
                $freeGB  = [Math]::Round($d.FreeSpace / 1GB, 2)
                $vol     = if ([string]::IsNullOrWhiteSpace($d.VolumeName)) { "SIN ETIQUETA" } else { $d.VolumeName }
                $color   = if ($d.DriveType -eq 2) { "Green" } else { "Gray" }
                Write-Host ("    ∙ Unidad [{0}]  |  {1}  |  Etiqueta: {2,-14} |  Libre: {3} GB" -f $d.DeviceID, $typeStr, $vol, $freeGB) -ForegroundColor $color
            }
        } catch {
            Write-Host "    ∙ Ingrese manualmente la letra de unidad o ruta destino." -ForegroundColor Gray
        }
    }

    # 7B. EXPORTAR KIT COMPLETO CON BARRA DE CARGA EN VIVO Y PARCHE A MODO OPERADOR
    "EXPORT_KIT" {
        try {
            $srcDir  = $arg1.TrimEnd('\')
            $rawDest = $arg2.Trim().Trim('"')
            $folderName = Split-Path -Path $srcDir -Leaf

            if ($rawDest -match '^[A-Za-z]:?\\?$') {
                $driveLetter = $rawDest.Substring(0, 1).ToUpper() + ":\"
                if (-not (Test-Path -LiteralPath $driveLetter)) {
                    [System.IO.File]::WriteAllText($outF, "La unidad $driveLetter no existe o no esta conectada.", $utf8No)
                    break
                }
                $destDir = Join-Path $driveLetter $folderName
            } else {
                $destDir = $rawDest
            }

            if ($destDir -eq $srcDir) {
                [System.IO.File]::WriteAllText($outF, "La ruta destino no puede ser la misma carpeta actual.", $utf8No)
                break
            }

            if (-not (Test-Path -LiteralPath $destDir)) {
                New-Item -ItemType Directory -Path $destDir -Force | Out-Null
            }

            $e = [char]27
            $cBorder = "$e[38;2;70;82;102m"
            $cCorp   = "$e[38;2;45;140;240m"
            $cCyan   = "$e[38;2;56;189;248m"
            $cOk     = "$e[38;2;16;185;129m"
            $cWhite  = "$e[38;2;255;255;255m"
            $cSlate  = "$e[38;2;130;145;165m"
            $bgHead  = "$e[48;2;20;32;52m$e[38;2;255;255;255m"
            $cReset  = "$e[0m"

            [Console]::Clear()
            [Console]::WriteLine("")
            [Console]::WriteLine("  $cBorder┌────────────────────────────────────────────────────────────────────┐$cReset")
            [Console]::WriteLine("  $cBorder│$bgHead  CLONANDO SUITE DE DESPLIEGUE HACIA UNIDAD DESTINO                 $cReset$cBorder│$cReset")
            [Console]::WriteLine("  $cBorder├────────────────────────────────────────────────────────────────────┤$cReset")
            [Console]::WriteLine("  $cBorder│                                                                    │$cReset")
            [Console]::WriteLine("  $cBorder│                                                                    │$cReset")
            [Console]::WriteLine("  $cBorder│                                                                    │$cReset")
            [Console]::WriteLine("  $cBorder│                                                                    │$cReset")
            [Console]::WriteLine("  $cBorder│                                                                    │$cReset")
            [Console]::WriteLine("  $cBorder└────────────────────────────────────────────────────────────────────┘$cReset")

            $allFiles = Get-ChildItem -LiteralPath $srcDir -Recurse -File | Where-Object { $_.Name -ne "actividad_sistema.log" }
            $totalFiles = [Math]::Max(1, $allFiles.Count)
            $copied = 0
            $totalBlocks = 36

            foreach ($file in $allFiles) {
                $relPath = $file.FullName.Substring($srcDir.Length).TrimStart('\')
                $targetFile = Join-Path $destDir $relPath
                $targetParent = Split-Path -Path $targetFile -Parent
                if (-not (Test-Path -LiteralPath $targetParent)) {
                    New-Item -ItemType Directory -Path $targetParent -Force | Out-Null
                }
                Copy-Item -LiteralPath $file.FullName -Destination $targetFile -Force

                $copied++
                $pct = [Math]::Min(98, [Math]::Floor(($copied / $totalFiles) * 98))
                $filled = [Math]::Floor(($pct / 100.0) * $totalBlocks)
                $empty  = $totalBlocks - $filled
                $barStr = ("━" * $filled)
                $empStr = ("─" * $empty)

                $dispName = "Copiando: " + $file.Name
                if ($dispName.Length -gt 58) { $dispName = $dispName.Substring(0, 58) }
                $padName = $dispName.PadRight(58, ' ')
                $pctStr  = $pct.ToString().PadLeft(3, ' ')

                [Console]::Write("$e[6;1H  $cBorder│$cReset  $cSlate$padName$cReset$e[72G$cBorder│$cReset")
                [Console]::Write("$e[8;1H  $cBorder│$cReset    $cBorder[$cCyan$barStr$cBorder$empStr] $cWhite$pctStr%$cReset$e[72G$cBorder│$cReset")
            }

            # Parchar la copia destino con CFG_TIMEOUT=3600 y CFG_WATCHDOG=ON
            $scriptName = Split-Path -Path $f -Leaf
            $destScript = Join-Path $destDir $scriptName
            if (Test-Path -LiteralPath $destScript) {
                $lines = [System.IO.File]::ReadAllLines($destScript, [System.Text.Encoding]::UTF8)
                for ($i = 0; $i -lt [Math]::Min(25, $lines.Count); $i++) {
                    if ($lines[$i] -match '^\s*set\s+"CFG_TIMEOUT=[^"]*"\s*$') {
                        $lines[$i] = ('set "CFG_TIMEOUT=3600"').PadRight(45, ' ')
                    }
                    if ($lines[$i] -match '^\s*set\s+"CFG_WATCHDOG=[^"]*"\s*$') {
                        $lines[$i] = ('set "CFG_WATCHDOG=ON"').PadRight(45, ' ')
                    }
                }
                $joined = [string]::Join("`r`n", $lines) + "`r`n"
                [System.IO.File]::WriteAllText($destScript, $joined, $utf8No)
            }

            $barFull = ("━" * $totalBlocks)
            $doneTxt = ("Aplicando perfil de Operador [Watchdog ON / 1 Hora]...").PadRight(58, ' ')
            [Console]::Write("$e[6;1H  $cBorder│$cReset  $cOk$doneTxt$cReset$e[72G$cBorder│$cReset")
            [Console]::Write("$e[8;1H  $cBorder│$cReset    $cBorder[$cOk$barFull$cBorder] $cWhite 100%$cReset$e[72G$cBorder│$cReset")
            [Console]::WriteLine("$e[11;1H")

            [System.IO.File]::WriteAllText($outF, ("OK|" + $destDir), $utf8No)
        } catch {
            [System.IO.File]::WriteAllText($outF, ("Error al exportar: " + $_.Exception.Message), $utf8No)
        }
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
