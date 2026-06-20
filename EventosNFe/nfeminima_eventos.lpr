program nfeminima_eventos;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes
  , SysUtils
  , CustApp
  , CancelamentoNFe
  , TypInfo
  , ACBrDFe.Conversao
  , FileLoggerUnit
  ;

type
  { TNFeEventosApp }
  TNFeEventosApp = class(TCustomApplication)
  protected
    procedure DoRun; override;
    procedure CancelarNotaFiscal(const NumeroNFe, Motivo, Ambiente: string);
    procedure SaidaRetornoTela(Cancelamento: TCancelamento);
    procedure LogRetornoToFile(Cancelamento: TCancelamento);
  public
    constructor Create(TheOwner: TComponent); override;
    procedure WriteHelp; virtual;
  end;

{ TNFeEventosApp }

procedure TNFeEventosApp.DoRun;
var
  ErrorMsg: String;
  Ambiente, TipoEvento, NumeroNFe, Motivo: String;
  Sequencial: Integer;
begin
  try
  // Intercepta pedidos de ajuda (incluindo o "?" sem hífen)
  if HasOption('h', 'help') or (ParamCount = 0) or (ParamStr(1) = '?') then begin
    WriteHelp;
    Terminate;
    Exit;
  end;

  // Validação rápida de parâmetros obrigatórios
  ErrorMsg := CheckOptions('he:t:n:m:s:', 'help env: tipo: num: motivo: seq:');
  if ErrorMsg <> '' then begin
    Writeln('Erro na passagem de parametros: ', ErrorMsg);
    Writeln('Digite "nfeminima_eventos -h" para ajuda.');
    Terminate;
    Exit;
  end;

  // Coleta dos valores informados
  Ambiente   := LowerCase(GetOptionValue('e', 'env'));
  TipoEvento := LowerCase(GetOptionValue('t', 'tipo'));
  NumeroNFe  := GetOptionValue('n', 'num');
  Motivo     := GetOptionValue('m', 'motivo');

  // Tratamento do sequencial (se não for informado, assume 1)
  if HasOption('s', 'seq') then
    Sequencial := StrToIntDef(GetOptionValue('s', 'seq'), 1)
  else
    Sequencial := 1;

  // Validações de Regra de Negócio Básica da CLI
  if (Ambiente <> 'homologacao') and (Ambiente <> 'producao') then begin
    Writeln('Erro: Ambiente invalido. Use "homologacao" ou "producao".');
    Terminate;
    Exit;
  end;

  if (TipoEvento <> 'cancelamento') and (TipoEvento <> 'cce') then begin
    Writeln('Erro: Tipo de evento invalido. Use "cancelamento" ou "cce".');
    Terminate;
    Exit;
  end;

  if Trim(Motivo) = '' then begin
    Writeln('Erro: O motivo/justificativa e obrigatorio (-m "texto").');
    Terminate;
    Exit;
  end;

  // --------------------------------------------------
  // INÍCIO DA EXECUÇÃO VISUAL NO CONSOLE
  // --------------------------------------------------
  LogToFile('--------------------------------------------------');
  LogToFile('Executando EventoNFe...');
  LogToFile('Ambiente: ' + Ambiente);
  LogToFile('Evento: ' + TipoEvento);
  LogToFile('Numero da NFe: ' + NumeroNFe);
  if TipoEvento = 'cce' then
    LogToFile('Sequencial CCe: ' + IntToStr(Sequencial));
  LogToFile('Motivo: ' + Motivo);
  LogToFile('--------------------------------------------------');


  Writeln('--------------------------------------------------');
  Writeln('Executando EventoNFe...');
  Writeln('Ambiente: ', Ambiente);
  Writeln('Evento: ', TipoEvento);
  Writeln('Numero da NFe: ', NumeroNFe);
  if TipoEvento = 'cce' then
    Writeln('Sequencial CCe: ', Sequencial);
  Writeln('Motivo: ', Motivo);
  Writeln('--------------------------------------------------');
  //Writeln('Conectado ao Banco de Dados');

  // TODO: Buscar os dados da NF-e no banco usando o 'NumeroNFe'
  // para resgatar a Chave de Acesso e o Protocolo de Autorização.

  // TODO: Instanciar e configurar o ACBrNFe1
  // TODO: Chamar ACBrNFe1.EnviarEvento(1)

  if TipoEvento = 'cancelamento' then
    CancelarNotaFiscal(NumeroNFe, Motivo, Ambiente);

  //*****INSERIR RETORNO DOS SERVIDORES DA SEFAZ*****

{  Writeln('Cogumelos da Chão'); // Mock do nome do emitente vindo do BD
  Writeln('SUCESSO! Evento Vinculado.');
  Writeln('Código Status: 135');
  Writeln('Motivo: Evento registrado e vinculado a NF-e');
  Writeln('');        }
  finally
    //ReadLn();
    Terminate;
  end;
end;

procedure TNFeEventosApp.CancelarNotaFiscal(const NumeroNFe, Motivo, Ambiente: string);
var
  NumNFe: Integer;
  Cancelamento: TCancelamento;
  Ambi: TACBrTipoAmbiente;
begin
  if Ambiente = 'homologacao' then
    Ambi := taHomologacao;
  if Ambiente = 'producao' then
    Ambi := taProducao;
  if TryStrToInt(NumeroNFe, NumNFe) then
    CancelarNFe(NumNFe, Motivo, Ambi, Cancelamento);
  SaidaRetornoTela(Cancelamento);
  LogRetornoToFile(Cancelamento);
end;

procedure TNFeEventosApp.SaidaRetornoTela(Cancelamento: TCancelamento);
begin
  WriteLn('--------------------------------------------------');
  WriteLn('RetWS:');
  WriteLn(Cancelamento.RetWS);
  WriteLn('--------------------------------------------------');
  WriteLn('RetornoWS:');
  WriteLn(Cancelamento.RetornoWS);
  WriteLn('--------------------------------------------------');
  WriteLn('Chave de envio da NFe: ' + Cancelamento.Chave);
  WriteLn('Protocolo de envio da NFe: ' + Cancelamento.ProtocoloEnvio);
  WriteLn('Data emissao da NFe: ' + DateTimeToStr(Cancelamento.DataEmissao));
  WriteLn('--------------------------------------------------');
  WriteLn('Chave NFe: ' + Cancelamento.chNFe);
  WriteLn('Protocolo de retorno da NFe: ' + Cancelamento.ProtocoloRetorno);
  WriteLn('Status: ' + IntToStr(Cancelamento.cStat));
  WriteLn('Motivo: ' + Cancelamento.xMotivo);
  WriteLn('Tipo de evento: ' + GetEnumName(TypeInfo(TACBrTipoEvento), Ord(Cancelamento.tpEvento)));
  WriteLn('Evento: ' + Cancelamento.xEvento);
  WriteLn('Num. Seq. Evento: ' + IntToStr(Cancelamento.nSeqEvento));
  WriteLn('--------------------------------------------------');
  WriteLn('Id: ' + Cancelamento.Id);
  WriteLn('Tipo ambiente: ' + GetEnumName(TypeInfo(TACBrTipoAmbiente), Ord(Cancelamento.tpAmb)));
  WriteLn('Ver aplic: ' + Cancelamento.verAplic);
  WriteLn('Cód. Órgão: ' + IntToStr(Cancelamento.cOrgao));
  WriteLn('--------------------------------------------------');
  WriteLn('CNPJ Dest.: ' + Cancelamento.CNPJDest);
  WriteLn('E-mail Dest.: ' + Cancelamento.emailDest);
  WriteLn('Data/Hora Registro Evento: ' + DateTimeToStr (Cancelamento.dhRegEvento));
  WriteLn('--------------------------------------------------');
end;

procedure TNFeEventosApp.LogRetornoToFile(Cancelamento: TCancelamento);
begin
  LogToFile('--------------------------------------------------');
  LogToFile('RetWS:');
  LogToFile(Cancelamento.RetWS);
  LogToFile('--------------------------------------------------');
  LogToFile('RetornoWS:');
  LogToFile(Cancelamento.RetornoWS);
  LogToFile('--------------------------------------------------');
  LogToFile('Chave de envio da NFe: ' + Cancelamento.Chave);
  LogToFile('Protocolo de envio da NFe: ' + Cancelamento.ProtocoloEnvio);
  LogToFile('Data emissao da NFe: ' + DateTimeToStr(Cancelamento.DataEmissao));
  LogToFile('--------------------------------------------------');
  LogToFile('Chave NFe: ' + Cancelamento.chNFe);
  LogToFile('Protocolo de retorno da NFe: ' + Cancelamento.ProtocoloRetorno);
  LogToFile('Status: ' + IntToStr(Cancelamento.cStat));
  LogToFile('Motivo: ' + Cancelamento.xMotivo);
  LogToFile('Tipo de evento: ' + GetEnumName(TypeInfo(TACBrTipoEvento), Ord(Cancelamento.tpEvento)));
  LogToFile('Evento: ' + Cancelamento.xEvento);
  LogToFile('Num. Seq. Evento: ' + IntToStr(Cancelamento.nSeqEvento));
  LogToFile('--------------------------------------------------');
  LogToFile('Id: ' + Cancelamento.Id);
  LogToFile('Tipo ambiente: ' + GetEnumName(TypeInfo(TACBrTipoAmbiente), Ord(Cancelamento.tpAmb)));
  LogToFile('Ver aplic: ' + Cancelamento.verAplic);
  LogToFile('Cód. Órgão: ' + IntToStr(Cancelamento.cOrgao));
  LogToFile('--------------------------------------------------');
  LogToFile('CNPJ Dest.: ' + Cancelamento.CNPJDest);
  LogToFile('E-mail Dest.: ' + Cancelamento.emailDest);
  LogToFile('Data/Hora Registro Evento: ' + DateTimeToStr (Cancelamento.dhRegEvento));
  LogToFile('--------------------------------------------------');
end;

constructor TNFeEventosApp.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  StopOnException := True;
end;

procedure TNFeEventosApp.WriteHelp;
begin
  Writeln('===================================================================');
  Writeln('                      GERENCIADOR DE EVENTOS NFe');
  Writeln('===================================================================');
  Writeln('Uso: nfeminima_eventos.exe -e <ambiente> -t <tipo> -n <numero> -m <motivo>');
  Writeln('');
  Writeln('Parametros disponiveis:');
  Writeln('  -e, --env    Define o ambiente. Valores: "homologacao" ou "producao"');
  Writeln('  -t, --tipo   Define o evento. Valores: "cancelamento" ou "cce"');
  Writeln('  -n, --num    Define o numero sequencial da NFe alvo do evento.');
  Writeln('  -m, --motivo Texto da justificativa ou correcao (min 15 caracteres).');
  Writeln('  -s, --seq    (Opcional) Sequencial do evento (para CCe). Padrao: 1');
  Writeln('  -h, --help   Exibe esta tela de ajuda.');
  Writeln('');
  Writeln('Exemplos de uso:');
  Writeln('  nfeminima_eventos.exe -e homologacao -t cancelamento -n 8690 -m "Cliente desistiu da compra"');
  Writeln('  nfeminima_eventos.exe --env=producao --tipo=cce --num=10243 --seq=2 -m "Correcao do peso bruto para 150kg"');
  Writeln('===================================================================');
end;

var
  Application: TNFeEventosApp;
begin
  LogToFile('==================================================');
  Application := TNFeEventosApp.Create(nil);
  Application.Title := 'NFe Eventos CLI';
  Application.Run;
  Application.Free;
  LogToFile('==================================================');
end.
