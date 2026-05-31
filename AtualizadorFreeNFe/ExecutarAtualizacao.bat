@echo off
chcp 1252 >nul
setlocal

:: Verifica se o usuario pediu o manual de ajuda (?, /?, -h, --help)
if "%~1"=="?" goto :AJUDA
if "%~1"=="/?" goto :AJUDA
if /i "%~1"=="-h" goto :AJUDA
if /i "%~1"=="--help" goto :AJUDA

:: Validação: Verifica se o primeiro parâmetro (Origem) foi informado
if "%~1"=="" (
    echo ====================================================
    echo ERRO: A pasta de origem e obrigatoria.
    echo.
    echo Digite %~nx0 ? para ler o manual de instrucoes.
    echo ====================================================
    goto :FIM
)

:: Configuração dos caminhos via parâmetros
set "PASTA_XML=%~1"

:: Verifica se o segundo parâmetro (Destino) foi informado
if "%~2"=="" (
    set "PASTA_DESTINO=%~1\processados"
) else (
    set "PASTA_DESTINO=%~2"
)

set "EXECUTAVEL=extraixmlnfe.exe"

echo ====================================================
echo    INICIANDO ATUALIZACAO EM MASSA DE XMLs DA NFe
echo ====================================================
echo Pasta de origem: %PASTA_XML%
echo Pasta de destino: %PASTA_DESTINO%
echo.

:: Verifica se a pasta de XMLs existe
if not exist "%PASTA_XML%" (
    echo ERRO: Pasta de XMLs "%PASTA_XML%" nao encontrada.
    goto :FIM
)

:: Cria a pasta de destino caso nao exista
if not exist "%PASTA_DESTINO%" (
    mkdir "%PASTA_DESTINO%"
)

:: Varre todos os arquivos .xml da pasta informada (ignora subpastas)
for %%F in ("%PASTA_XML%\*.xml") do (
    echo Processando: %%~nxF
    
    :: Executa o programa e decide a ação com base no sucesso
    "%EXECUTAVEL%" "%%~fF" && (
        echo [OK] Processado com sucesso. Movendo arquivo...
        move "%%~fF" "%PASTA_DESTINO%\" >nul
    ) || (
        :: Avalia os códigos de erro do maior para o menor
        if errorlevel 8 (
            echo [ERRO] Falha critica ou erro de leitura. Arquivo MANTIDO na origem.
        ) else if errorlevel 7 (
            echo [ERRO] NFe emitida em ambiente de homologacao. Arquivo MANTIDO na origem.
        ) else if errorlevel 6 (
            echo [AVISO] Nota nao localizada no banco. Arquivo MANTIDO na origem.
        ) else (
            echo [ERRO] Falha critica ou erro de leitura. Arquivo MANTIDO na origem.
        )
    )
    echo ----------------------------------------------------
)

echo.
echo Processo concluido com sucesso!
goto :FIM

:: =====================================================================
:: BLOCO DO MANUAL DE AJUDA
:: =====================================================================
:AJUDA
echo ===============================================================================
echo                       MANUAL DE USO DO PROCESSADOR DE XML
echo ===============================================================================
echo O QUE ESTE SCRIPT FAZ:
echo Processa arquivos XML em massa utilizando o programa "extraixmlnfe.exe".
echo Arquivos processados com sucesso sao movidos para uma pasta de destino.
echo.
echo EXCECOES (Arquivos nao movidos e mantidos na origem):
echo - XMLs que apresentam falha critica de leitura ou dados incompletos.
echo - XMLs cujas notas correspondentes nao existem no banco de dados.
echo - XMLs de notas emitidas em Ambiente de Homologacao.
echo.
echo SINTAXE E ORDEM DOS PARAMETROS:
echo .\%~nx0 "Caminho\da\Origem" ["Caminho\do\Destino"]
echo.
echo 1. Origem  (Obrigatorio) : Pasta onde estao os XMLs a serem processados.
echo 2. Destino (Opcional)    : Pasta para onde irao os XMLs concluidos.
echo                            Se omitido, sera criada a pasta "processados"
echo                            automaticamente dentro da pasta de origem.
echo.
echo USO DE ASPAS:
echo E altamente recomendado sempre envolver os caminhos com aspas duplas (" "),
echo especialmente se o caminho contiver espacos em branco.
echo.
echo EXEMPLOS DE USO NO POWERSHELL OU CMD:
echo Com origem e destino:
echo .\%~nx0 "D:\NFe\202605" "D:\NFe\Processados"
echo.
echo Somente com origem (destino automatico na mesma pasta):
echo .\%~nx0 "D:\NFe\202605"
echo ===============================================================================

:FIM
echo.
pause