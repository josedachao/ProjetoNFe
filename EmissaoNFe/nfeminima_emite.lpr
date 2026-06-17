program nfeminima_emite;

{$mode ObjFPC}{$H+}
{$codepage utf8}

uses {$IFDEF UNIX}cthreads, cwstring, BlindagemFPU,{$ENDIF}
  SysUtils
  , CustApp
  {$IFDEF MSWINDOWS}
  , ActiveX
  {$ENDIF}
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
  Writeln('Uso: nfeminima_emite.exe -e <ambiente> -n <numero_nfe>');
  Writeln('     nfeminima_emite.exe -e <ambiente> -r <inicio..fim>');
  Writeln('');
  Writeln('Parametros disponiveis:');
  Writeln('  -e, --env    Define o ambiente de emissao.');
  Writeln('               Valores aceitos: "homologacao" ou "producao"');
  Writeln('  -n, --num    Define o numero sequencial de uma unica NFe.');
  Writeln('  -r, --range  Define uma faixa de NFes para emissao (Ex: 8100..8130).');
  Writeln('  -h, --help   Exibe esta tela de ajuda.');
  Writeln('');
  Writeln('Exemplos de uso:');
  Writeln('  nfeminima_emite.exe -e homologacao -n 8558');
  Writeln('  nfeminima_emite.exe --env=producao --num=10243');
  Writeln('  nfeminima_emite.exe -e producao -r 8100..8130');
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
  StrRange: String;
  IntNumero: Integer;
  ErrorMsg: String;

  // Variáveis para manipulação do Range
  PosPontoPonto: Integer;
  NumInicial, NumFinal, I: Integer;
begin
  try
    // 1. Verifica se o usuário pediu ajuda por "?", "-h" ou "--help"
    if (ParamStr(1) = '?') or HasOption('h', 'help') then begin
      ExibirAjuda;
      Exit;
    end;

    // 2. Valida as flags normais passadas no terminal (adicionado 'r' e 'range:')
    ErrorMsg := CheckOptions('enr', ['env:', 'num:', 'range:']);
    if ErrorMsg <> '' then begin
      Writeln('Erro de parametros: ', ErrorMsg);
      Writeln('Digite "nfeminima_emite.exe ?" para ver as instrucoes de uso.');
      Exit;
    end;

    // 3. Captura os valores como texto
    StrAmbiente := LowerCase(GetOptionValue('e', 'env'));
    StrNumero   := GetOptionValue('n', 'num');
    StrRange    := GetOptionValue('r', 'range');

    // 4. Validação: Verifica se Ambiente foi informado e se há Número OU Range
    if (StrAmbiente = '') then begin
      Writeln('Erro: O parametro --env e obrigatorio.');
      Exit;
    end;

    if (StrNumero = '') and (StrRange = '') then begin
      Writeln('Erro: Informe o parametro --num ou --range para emitir a(s) NFe(s).');
      Exit;
    end;

    if (StrNumero <> '') and (StrRange <> '') then begin
      Writeln('Erro: Utilize apenas --num OU --range, nao os dois simultaneamente.');
      Exit;
    end;

    // 5. Validação do conteúdo do Ambiente
    if (StrAmbiente <> 'homologacao') and (StrAmbiente <> 'producao') then begin
      Writeln('Erro: Ambiente "', StrAmbiente, '" invalido.');
      Exit;
    end;

    // 6. Lógica de Emissão
    if StrRange <> '' then
    begin
      // --- EMISSÃO EM RANGE ---
      // Localiza o separador '..'
      PosPontoPonto := Pos('..', StrRange);

      if PosPontoPonto = 0 then begin
        Writeln('Erro: Formato de range invalido. Use Inicio..Fim (Ex: 8100..8130).');
        Exit;
      end;

      // Extrai os limites inferior e superior e converte para inteiro
      if not TryStrToInt(Copy(StrRange, 1, PosPontoPonto - 1), NumInicial) or
         not TryStrToInt(Copy(StrRange, PosPontoPonto + 2, Length(StrRange)), NumFinal) then
      begin
        Writeln('Erro: Os limites do range devem ser numeros inteiros validos.');
        Exit;
      end;

      // Validação semântica do range
      if (NumInicial <= 0) or (NumFinal < NumInicial) then begin
        Writeln('Erro: Range invalido. Certifique-se de que o inicio e > 0 e o fim e >= inicio.');
        Exit;
      end;

      Writeln('Iniciando emissao em lote: NFe ', NumInicial, ' ate ', NumFinal);
      // Loop de emissão
      for I := NumInicial to NumFinal do
      begin
        EmitirNFe(StrAmbiente, I);
      end;

    end
    else
    begin
      // --- EMISSÃO ÚNICA (Comportamento original) ---
      if not TryStrToInt(StrNumero, IntNumero) then begin
        Writeln('Erro: O parametro --num deve ser um numero inteiro valido.');
        Exit;
      end;

      if IntNumero <= 0 then begin
        Writeln('Erro: O numero da NFe deve ser maior que zero.');
        Exit;
      end;

      EmitirNFe(StrAmbiente, IntNumero);
    end;

  finally
    // INDEPENDENTE DE SUCESSO OU ERRO (RAISE), O PROGRAMA SEMPRE VAI ENCERRAR!
    LogToFile('==================================================');
    Terminate;
  end;
end;

var
  App: TNotaApplication;
begin
  {$IFDEF MSWINDOWS}
  CoInitialize(nil); // <--- INICIALIZA O SUBSISTEMA DE REDE/CRIPTOGRAFIA DO WINDOWS
  {$ENDIF}
  try
    App := TNotaApplication.Create(nil);
    App.Title := 'Emissor NFe';
    App.Run;
    App.Free;
  finally
    {$IFDEF MSWINDOWS}
    CoUninitialize; // <--- LIBERA A MEMÓRIA AO FECHAR
    {$ENDIF}
  end;
end.
























{program nfeminima;

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
  Writeln('Uso: nfeminima_emite.exe -e <ambiente> -n <numero_nfe>');
  Writeln('     nfeminima_emite.exe --env=<ambiente> --num=<numero_nfe>');
  Writeln('');
  Writeln('Parametros disponiveis:');
  Writeln('  -e, --env   Define o ambiente de emissao.');
  Writeln('              Valores aceitos: "homologacao" ou "producao"');
  Writeln('  -n, --num   Define o numero sequencial da NFe (Apenas numeros).');
  Writeln('  -h, --help  Exibe esta tela de ajuda.');
  Writeln('');
  Writeln('Exemplos de uso:');
  Writeln('  nfeminima_emite.exe -e homologacao -n 8558');
  Writeln('  nfeminima_emite.exe --env=producao --num=10243');
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
      Writeln('Digite "nfeminima_emite.exe ?" para ver as instrucoes de uso.');
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
}
