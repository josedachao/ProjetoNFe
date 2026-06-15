program nfeminima_eventos;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils, CustApp;

type
  { TNFeEventosApp }
  TNFeEventosApp = class(TCustomApplication)
  protected
    procedure DoRun; override;
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
  Writeln('--------------------------------------------------');
  Writeln('Executando EventoNFe...');
  Writeln('Ambiente: ', Ambiente);
  Writeln('Evento: ', TipoEvento);
  Writeln('Numero da NFe: ', NumeroNFe);
  if TipoEvento = 'cce' then
    Writeln('Sequencial CCe: ', Sequencial);
  Writeln('Motivo: ', Motivo);
  Writeln('--------------------------------------------------');
  Writeln('Conectado ao Banco de Dados');

  // TODO: Buscar os dados da NF-e no banco usando o 'NumeroNFe'
  // para resgatar a Chave de Acesso e o Protocolo de Autorização.

  // TODO: Instanciar e configurar o ACBrNFe1
  // TODO: Chamar ACBrNFe1.EnviarEvento(1)

  Writeln('Cogumelos da Chão'); // Mock do nome do emitente vindo do BD
  Writeln('SUCESSO! Evento Vinculado.');
  Writeln('Código Status: 135');
  Writeln('Motivo: Evento registrado e vinculado a NF-e');
  Writeln('');

  Terminate;
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
  Application := TNFeEventosApp.Create(nil);
  Application.Title := 'NFe Eventos CLI';
  Application.Run;
  Application.Free;
end.
