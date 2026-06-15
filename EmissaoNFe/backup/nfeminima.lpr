program nfeminima;

uses {$IFDEF UNIX}cthreads, {$ENDIF}
  Interfaces // <--- Obrigatorio para o ACBr instanciar os objetos visuais internos
  , SysUtils
  , CustApp
  , ActiveX
  , emissaonfe
  , ACBrDFe.Conversao
  , FileLoggerUnit
  ;

type
  TNotaApplication = class(TCustomApplication)
  protected
    procedure DoRun; override;
    procedure ExibirAjuda; // Nova rotina para centralizar o texto de ajuda
  end;

procedure TNotaApplication.ExibirAjuda;
begin
  Writeln('===================================================================');
  Writeln('                      EMISSOR DE NFe CONSOLE                       ');
  Writeln('===================================================================');
  Writeln('Uso: nfeminima.exe -e <ambiente> -n <numero_nfe>');
  Writeln('     nfeminima.exe --env=<ambiente> --num=<numero_nfe>');
  Writeln('');
  Writeln('Parametros disponiveis:');
  Writeln('  -e, --env   Define o ambiente de emissao.');
  Writeln('              Valores aceitos: "homologacao" ou "producao"');
  Writeln('  -n, --num   Define o numero sequencial da NFe (Apenas numeros).');
  Writeln('  -h, --help  Exibe esta tela de ajuda.');
  Writeln('');
  Writeln('Exemplos de uso:');
  Writeln('  nfeminima.exe -e homologacao -n 8558');
  Writeln('  nfeminima.exe --env=producao --num=10243');
  Writeln('===================================================================');
end;

procedure EmitirNFe(const AAmbiente: String; const ANumero: Integer);
begin
  Writeln('--------------------------------------------------');
  LogToFile('==================================================');
  Writeln('Executando EmitirNFe...');
  LogToFile('Executando EmitirNFe...');
  Writeln('Ambiente: ', AAmbiente);
  LogToFile('Ambiente: ' + AAmbiente);
  Writeln('Numero da NFe: ', ANumero);
  LogToFile('Numero da NFe: ' + IntToStr(ANumero));
  Writeln('--------------------------------------------------');
  // Lógica da Sefaz/ACBr aqui
  if AAmbiente = 'homologacao' then
    EmissaoNFe.EmitirNFe(taHomologacao, ANumero)
  else
    EmissaoNFe.EmitirNFe(taProducao, ANumero);
end;

procedure TNotaApplication.DoRun;
var
  StrAmbiente: String;
  StrNumero: String;
  IntNumero: Integer;
  ErrorMsg: String;
begin
  try
    // 1. Verifica se o usuário pediu ajuda por "?", "-h" ou "--help"
    if (ParamStr(1) = '?') or HasOption('h', 'help') then begin
      ExibirAjuda;
      Exit; // O try..finally no final garantirá o Terminate
    end;

    // 2. Valida as flags normais passadas no terminal
    ErrorMsg := CheckOptions('en', ['env:', 'num:']);
    if ErrorMsg <> '' then begin
      Writeln('Erro de parametros: ', ErrorMsg);
      Writeln('Digite "nfeminima.exe ?" para ver as instrucoes de uso.');
      Exit;
    end;

    // 3. Captura os valores como texto
    StrAmbiente := LowerCase(GetOptionValue('e', 'env'));
    StrNumero   := GetOptionValue('n', 'num');

    // 4. Validação: Verifica se os campos obrigatórios
    if (StrAmbiente = '') or (StrNumero = '') then begin
      Writeln('Erro: Os parametros --env e --num sao obrigatorios.');
      Exit;
    end;

    // 5. Validação do conteúdo do Ambiente
    if (StrAmbiente <> 'homologacao') and (StrAmbiente <> 'producao') then begin
      Writeln('Erro: Ambiente "', StrAmbiente, '" invalido.');
      Exit;
    end;

    // 6. Validação: Transforma o texto em número inteiro
    if not TryStrToInt(StrNumero, IntNumero) then begin
      Writeln('Erro: O parametro --num deve ser um numero inteiro valido.');
      Exit;
    end;

    if IntNumero <= 0 then begin
      Writeln('Erro: O numero da NFe deve ser maior que zero.');
      Exit;
    end;

    // 7. Executa a lógica de negócio se tudo estiver correto
    EmitirNFe(StrAmbiente, IntNumero);

  finally
    // INDEPENDENTE DE SUCESSO OU ERRO (RAISE), O PROGRAMA SEMPRE VAI ENCERRAR!
    LogToFile('==================================================');
    Terminate;
  end;
end;

var
  App: TNotaApplication;
begin
  CoInitialize(nil); // <--- INICIALIZA O SUBSISTEMA DE REDE/CRIPTOGRAFIA DO WINDOWS
    try
      App := TNotaApplication.Create(nil);
      App.Title := 'Emissor NFe';
      App.Run;
      App.Free;
    finally
      CoUninitialize; // <--- LIBERA A MEMÓRIA AO FECHAR
    end;
end.

