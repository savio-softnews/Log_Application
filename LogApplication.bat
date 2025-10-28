@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul

rem ============================================================
rem  Aplicador de Log - Versão .BAT (conversão do script PowerShell)
rem  Requer: 7-Zip e SQL Anywhere 17 instalados nos caminhos padrão
rem ============================================================

set "seteZipPath=C:\Program Files\7-Zip\7zG.exe"
set "dbengPath=C:\Program Files\SQL Anywhere 17\Bin64\dbeng17.exe"
set "diretorioAtual=%~dp0"
set "pastaM=%diretorioAtual%M"
set "pastaLogs=%diretorioAtual%Logs"

echo.
echo ===================================================================
echo                 Aplicador de Log - Versão 1.0
echo   Sávio Morais: github.com/savio-softnews/Log_Application
echo ===================================================================

set /p resposta=As senhas de descompactacao sao a senha padrao? (S/N): 

if /I "%resposta%"=="S" (
    set "senhaM=[senha padrão]"
    set "senhaC=[senha padrão]"
) else if /I "%resposta%"=="N" (
    set /p senhaM=Informe a senha do arquivo de Modificacao: 
    set /p senhaC=Informe a senha do arquivo Completo: 
) else (
    echo Opcao invalida. Execute novamente e informe S ou N.
    pause
    exit /b
)

echo.
echo Iniciando aplicador de log...
echo.

rem Criar pastas M e Logs
if not exist "%pastaM%" mkdir "%pastaM%"
if not exist "%pastaLogs%" mkdir "%pastaLogs%"

rem Mover arquivo M.dom para pasta M
for %%f in ("%diretorioAtual%*M.dom") do (
    if exist "%%f" move "%%f" "%pastaM%" >nul
)

rem Extrair arquivo M.dom
for %%f in ("%pastaM%\*.dom") do (
    echo Extraindo %%~nxf ...
    call :log_time "Inicio descompactação backup Modificação"
    "%seteZipPath%" x "%%f" -o"%pastaM%" -p%senhaM% -y >nul
    call :log_time "Fim descompactação backup Modificação"
    echo. >> tempos.txt
    echo Arquivo %%~nxf extraído na pasta M.
)

rem Renomear e mover logs da pasta M
for %%f in ("%pastaM%\*.log") do (
    set "nome=%%~nf"
    set "novoNome=!nome!1.log"
    ren "%%f" "!novoNome!" >nul
    move "%pastaM%\!novoNome!" "%pastaLogs%\!novoNome!" >nul
    echo %%~nxf renomeado e movido para Logs.
)

rem Extrair arquivo C.dom na pasta raiz
for %%f in ("%diretorioAtual%*C.dom") do (
    echo Extraindo %%~nxf ...
    call :log_time "Inicio descompactação backup Completo"
    "%seteZipPath%" x "%%f" -o"%diretorioAtual%" -p%senhaC% -y >nul
    call :log_time "Fim descompactação backup Completo"
    echo. >> tempos.txt
    echo Arquivo %%~nxf extraído na pasta raiz.
)

rem Mover logs da raiz para Logs
for %%f in ("%diretorioAtual%*.log") do (
    move "%%f" "%pastaLogs%\%%~nxf" >nul
    echo %%~nxf movido para Logs.
)

rem Aplicar log com dbeng17.exe
echo.
call :log_time "Inicio aplicação Log"
echo Iniciando aplicacao de log...
if exist "%dbengPath%" if exist "%diretorioAtual%contabil.db" (
    "%dbengPath%" contabil.db -ad logs -o LogInformations.txt
    call :log_time "Fim aplicação Log"
    echo Aplicacao de log concluida.
) else (
    echo dbeng17.exe ou contabil.db nao encontrados.
)

echo.
echo Processamento finalizado.
pause
exit /b
goto :eof

rem Função para registrar o tempo e a operação no arquivo de log
:log_time
set "operacao=%~1"
for /f "tokens=1,2 delims=:" %%a in ('time /t') do (
    set hora=%%a
    set minuto=%%b
)

rem Salvar tempo inicial e final em variáveis globais
if /i "%operacao:~0,6%"=="Inicio" (
    set "tempo_inicial=!hora!:!minuto!"
) else if /i "%operacao:~0,3%"=="Fim" (
    set "tempo_final=!hora!:!minuto!"
)

echo %operacao% %hora%:%minuto% >> tempos.txt
goto :eof

rem Calcular a difereça entre hora inicial e final
:calculate_range
setLocal enabledelayedexpansion

for /f "tokens=1,2 delims=:" %%a in ("%~1") do (
    set /a "hora_inicial=%%a", "minuto_inicial=%%b"
)
for /f "tokens=1,2 delims=:" %%a in ("%~2") do (
    set /a "hora_final=%%a", "minuto_final=%%b"
)

rem Converter tempo para minutos, facilitando os calculos
set /a "total_inicial = hora_inicial * 60 + minuto_inicial"
set /a "total_final = hora_final * 60 + minuto_final"

rem Tratativa para tempos que passem da meia noite
if !total_final! lss !total_inicial! set /a "total_final+=24*60"

rem Intervalo dos minutos
set /a "intervalo_total_minutos = total_final - total_inicial"

rem Caso o intervalo seja menor que 1 min, será setado o tempo minimo de 1 min
if !intervalo_total_minutos! lss 1 set /a "intervalo_total_minutos=1"

rem Retornando e formantando os minutos para ser exibido em HH:MM
set /a "intervalo_hora = intervalo_total_minutos/60"
set /a "intervalo_minuto = intervalo_total_minutos%%60"

if !intervalo_hora! lss 10 set "intervalo_hora=0!intervalo_hora!"
if !intervalo_minuto! lss 10 set "intervalo_minuto=0!intervalo_minuto!"

echo %~3 !intervalo_hora!h:!intervalo_minuto!min >> tempos.txt
goto :eof