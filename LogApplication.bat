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

goto :eof
rem Função para registrar o tempo e a operação no arquivo de log
:log_time
set "operation=%~1"
for /f "tokens=1,2 delims=:" %%a in ('time /t') do (
    set hour=%%a
    set minute=%%b
)
echo %operation% %hour%:%minute% >> tempos.txt
goto :eof

echo.
echo Processamento finalizado.
pause
exit /b