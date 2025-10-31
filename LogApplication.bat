@echo off
title Aplicador de Log
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
echo                 Aplicador de Log - Versão 2.0
echo   Sávio Morais: github.com/savio-softnews/Log_Application
echo ===================================================================
echo.
echo Informe se o seu backup é de origem Web (DW/backup em nuvem) ou Local
echo 1 - Web
echo 2 - Local
set /p tipo_base=Informe a sua resposta: 

if /I "!tipo_base!"=="1" (
	echo.
	call :base_web
) else if /I "!tipo_base!"=="2" (
    echo.
	call :base_local
) else (
	echo Opcao invalida. Execute novamente e informe 1 ou 2.
)

echo Processamento finalizado.
pause
exit /b

:: ============================================================
:: Função 'base web', realiza a descompactação e aplicação de log em bases DW ou backup em Nuvem
:: ============================================================
:base_web
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
    call :calculate_range "!tempo_inicial!" "!tempo_final!" "Tempo total descompactação backup Modificação: " 
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
    call :calculate_range "!tempo_inicial!" "!tempo_final!" "Tempo total descompactação backup Completo: " 
    echo. >> tempos.txt
    echo Arquivo %%~nxf extraído na pasta raiz.
)

rem Mover logs da raiz para Logs
for %%f in ("%diretorioAtual%*.log") do (
    move "%%f" "%pastaLogs%\%%~nxf" >nul
    echo %%~nxf movido para Logs.
)

call :log_application
goto :eof

:: ============================================================
:: Função 'base local', realiza a descompactação e aplicação de log em bases DW ou backup em Nuvem
:: ============================================================
:base_local
echo.
echo Iniciando aplicador de log...
echo.

if not exist "%pastaM%" mkdir "%pastaM%"
if not exist "%pastaLogs%" mkdir "%pastaLogs%"

rem Extração arquivo M.dom
for %%f in ("%diretorioAtual%*M.dom") do (
    if exist "%%f" move "%%f" "%pastaM%" >nul
)

for %%f in ("%pastaM%\*.dom") do (
    echo --------------------------------------------------
    echo Extraindo %%~nxf ...
    call :log_time "Inicio descompactação backup Modificação"
    "%seteZipPath%" x "%%f" -o"%pastaM%" -p%senhaM% -y >nul
    call :log_time "Fim descompactação backup Modificação"
    call :calculate_range "!tempo_inicial!" "!tempo_final!" "Tempo total descompactação backup Modificação: " 
    echo. >> tempos.txt
    echo Arquivo %%~nxf extraído na pasta M.

    rem --- Busca recursiva apenas por .log ---
    set "log_encontrado=false"
    call :procurar_arquivo "%pastaM%" "log" "false"
	
	call :limpar_pastas "%pastaM%%"
)

rem Extração arquivo C.dom
for %%f in ("%diretorioAtual%*C.dom") do (
    echo --------------------------------------------------
    echo Extraindo %%~nxf ...
    call :log_time "Inicio descompactação backup Completo"
    "%seteZipPath%" x "%%f" -o"%diretorioAtual%" -p%senhaC% -y >nul
    call :log_time "Fim descompactação backup Completo"
    call :calculate_range "!tempo_inicial!" "!tempo_final!" "Tempo total descompactação backup Completo: "
    echo. >> tempos.txt
    echo Arquivo %%~nxf extraído na pasta raiz.
	
	rem --- Determinar pasta base da extração (geralmente contém Backup) ---
    for /d %%D in ("%diretorioAtual%") do (
		call :debug_log "Diretorio D: %%D"
        if exist "%%~fD" (
            set "pastaExtraida=%%~fD"
			call :debug_log "pasta extraida: !pastaExtraida!"
            goto :found_folder
        )
    )
	:found_folder
    rem --- Busca recursiva por .log e .db ---
    set "log_encontrado=false"
    set "db_encontrado=false"
    call :procurar_arquivo "%diretorioAtual%" "log,db" "true"
	
	call :limpar_pastas "!pastaExtraida!"
)

call :log_application
goto :eof

:: ============================================================
:: Função 'Log Application', realiza aplicação de log e chama função para informar o tempo total do processo
:: ============================================================
:log_application
echo.
call :log_time "Inicio aplicação Log"
echo Iniciando aplicacao de log...
if exist "%dbengPath%" if exist "%diretorioAtual%contabil.db" (
    "%dbengPath%" contabil.db -ad logs -o LogInformations.txt
    call :log_time "Fim aplicação Log"
    call :calculate_range "!tempo_inicial!" "!tempo_final!" "Tempo total aplicação de Log: " 
    echo Aplicacao de log concluida.
) else (
    echo dbeng17.exe ou contabil.db nao encontrados.
)

echo.
echo Calculando tempo total do processo...
call :sum_times
echo.
goto :eof

:: ============================================================
:: Função 'Log time', que registra o tempo e operação no arquivo de log
:: ============================================================
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

echo %operacao% !hora!:!minuto! >> tempos.txt
goto :eof

:: ============================================================
:: Função 'Calculate range', calcula a diferença entre hora inicial e final
:: ============================================================
:calculate_range
setLocal enabledelayedexpansion

for /f "tokens=1,2 delims=:" %%a in ("%~1") do (
    set "hora_inicial=%%a"
    set "minuto_inicial=%%b"
)
for /f "tokens=1,2 delims=:" %%a in ("%~2") do (
    set "hora_final=%%a"
    set "minuto_final=%%b"
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

:: ============================================================
:: Função 'Sum times', soma e informa o tempo total do processo
:: ============================================================
:sum_times
setlocal enabledelayedexpansion
set /a total_min=0

for /f "tokens=2,3 delims=:" %%a in ('findstr /r "[0-9][0-9]h:[0-9][0-9]min" tempos.txt') do (
    for /f "tokens=1 delims=h" %%H in ("%%a") do set "H=%%H"
    for /f "tokens=1 delims=m" %%M in ("%%b") do set "M=%%M"

    set /a total_minutos+=H*60+M
)

set /a total_hora = total_minutos/60
set /a total_min = total_minutos%%60

if %total_hora% lss 10 set "total_hora=0%total_hora%"
if %total_min% lss 10 set "total_min=0%total_min%"

(
    echo.
    echo =====================================
    echo Tempo total do processo: %total_hora%h:%total_min%min
    echo =====================================
) >> tempos.txt
endlocal
goto :eof

:: ============================================================
:: Função 'Procurar arquivo', procurar arquivos .log e .db nas subpastas extraidas
:: ============================================================
:procurar_arquivo
setlocal enabledelayedexpansion
set "pasta=%~1"
set "tipos=%~2"
set "modoCompleto=%~3"

for %%A in ("%pasta%\*") do (
    if exist "%%~A" (
        for %%T in (!tipos!) do (
            if /i "%%~xA"==".%%T" (
                if "%%T"=="log" (
                    if "!log_encontrado!"=="false" (
                        echo Encontrado LOG: %%~nxA
                        if "!modoCompleto!"=="true" (
                            move /Y "%%~fA" "%pastaLogs%\%%~nxA" >nul
                        ) else (
                            set "novoNome=%%~nA1.log"
                            move /Y "%%~fA" "%pastaLogs%\!novoNome!" >nul
                        )
                        if %errorlevel%==0 (
                            echo %%~nxA movido para Logs.
                            endlocal & set "log_encontrado=true"
                        )
                    )
                )
                if "%%T"=="db" (
                    if "!db_encontrado!"=="false" (
                        echo Encontrado DB: %%~nxA
                        move /Y "%%~fA" "%diretorioAtual%\%%~nxA" >nul
                        if %errorlevel%==0 (
                            echo %%~nxA movido para pasta raiz.
                            endlocal & set "db_encontrado=true"
                        )
                    )
                )
            )
        )
    )
)

rem --- Verificar condição de parada ---
if "!modoCompleto!"=="true" (
    if "!log_encontrado!"=="true" if "!db_encontrado!"=="true" exit /b
) else (
    if "!log_encontrado!"=="true" exit /b
)

for /d %%D in ("%pasta%\*") do (
    call :procurar_arquivo "%%~fD" "%tipos%" "%modoCompleto%"
)
exit /b

:: ============================================================
:: Função 'Limpar pastas', remove subpastas residuais após a extração
:: ============================================================
:limpar_pastas
set "base=%~1"
for /d %%D in ("%base%\*") do (
    if exist "%%~fD" (
		if /I NOT "%%~nxD"=="M" if /I NOT "%%~nxD"=="Logs" (
			echo Removendo pasta %%~nxD ...
			rmdir /S /Q "%%~fD"
		) 
    )
)
goto :eof