program clonenfe;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
    Classes
  , SysUtils
  , CustApp
  , FileLoggerUnit
  , PluginUtils
  , FreeNFeUtils
  ;

type

  { TCloneNFe }

  TCloneNFe = class(TCustomApplication)
  protected
    procedure DoRun; override;
    procedure ExibirAjuda; // Nova rotina para centralizar o texto de ajuda
    procedure ClonarNFe(const NumPedido: Integer);
    function EhDataValida(const Texto: string): Boolean;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    procedure WriteHelp; virtual;
  end;

{ TCloneNFe }

procedure TCloneNFe.DoRun;
var
  StrData: String;
  StrNumero: String;
  IntNumero: Integer;
  ErrorMsg: String;
  i: Integer = 0;
begin
  LogToFile('++++++++++++++++++++++++++++++++++++++++++++++++++');
  LogToFile('Iniciando o programa.');
  LogToFile('==================================================');
  try
    // 1. Verifica se o usuário pediu ajuda por "?", "-h" ou "--help"
    if (ParamStr(1) = '?') or HasOption('h', 'help') then begin
      ExibirAjuda;
      Exit;
    end;


    CaseSensitiveOptions := False; // Permite misturar maiúsculas/minúsculas

    // CORREÇÃO AQUI: 'd:n:' define as opções curtas -d e -n com parâmetros obrigatórios.
    // 'data:' e 'num:' definem as opções longas --data e --num com parâmetros obrigatórios.
    ErrorMsg := CheckOptions('d:n:', ['data:', 'num:'], True);
    if ErrorMsg <> '' then begin
      Writeln('Erro de parametros: ', ErrorMsg);
      Writeln('Digite "clonenfe.exe ?" para ver as instrucoes de uso.');
      Exit;
    end;

    // 3. Captura os valores como texto (Alinhado com as opções longas acima)
    StrData := LowerCase(GetOptionValue('d', 'data'));
    StrNumero := GetOptionValue('n', 'num');

    // 4. Validação: Verifica se os campos são obrigatórios
    if (StrData = '') or (StrNumero = '') then begin
      Writeln('Erro: Os parametros -d (--data) e -n (--num) sao obrigatorios.');
      Exit;
    end;

    // 5. Validação do conteúdo da Data (CORREÇÃO AQUI: adicionado o "not")
    if not EhDataValida(StrData) then begin
      Writeln('Erro: Data "', StrData, '" invalida.');
      Exit;
    end;

    // 6. Validação: Transforma o texto em número inteiro
    if not TryStrToInt(StrNumero, IntNumero) then begin
      Writeln('Erro: O parametro --num deve ser um numero inteiro valido.');
      Exit;
    end;
    if IntNumero <= 0 then begin
      Writeln('Erro: O numero do Pedido deve ser maior que zero.');
      Exit;
    end;

    // 7. Executa a lógica de negócio se tudo estiver correto
    ClonarNFe(IntNumero);
  finally
    LogToFile('Saindo do programa.');
    LogToFile('++++++++++++++++++++++++++++++++++++++++++++++++++');
    Terminate;
  end;
end;


procedure TCloneNFe.ExibirAjuda;
begin
  Writeln('===================================================================');
  Writeln('                        CLONAR NFe CONSOLE                         ');
  Writeln('===================================================================');
  Writeln('Uso: CloneNFe.exe -d <data_pedido> -n <numero_pedido>');
  Writeln('     CloneNFe.exe --data=<data_pedido> --num=<numero_pedido>');
  Writeln('');
  Writeln('Parametros disponiveis:');
  Writeln('  -d, --data  Define a data para selecao de pedidos.');
  Writeln('              Formato de data: "dd/mm/aaaa"');
  Writeln('  -n, --num   Define o numero sequencial do pedido (Apenas numeros).');
  Writeln('  -h, --help  Exibe esta tela de ajuda.');
  Writeln('');
  Writeln('Exemplos de uso:');
  Writeln('  CloneNFe.exe -d 25/05/2026');
  Writeln('  CloneNFe.exe --data=25/05/2026');
  Writeln('  CloneNFe.exe --n 10243');
  Writeln('  CloneNFe.exe --num=10243');
  Writeln('===================================================================');
end;

procedure TCloneNFe.ClonarNFe(const NumPedido: Integer);
var
  Pedido: TPedido;
  Nota: TNFe;
begin
  WriteLn('===================================================');
  Pedido := GetPedido(NumPedido);
  if Pedido.CodFreeNFe = '' then
  begin
    WriteLn('Cliente nao encontrado no FreeNFe.');
    WriteLn('Nao foi possivel clonar NFe.');
    WriteLn('Saindo do programa...');
    WriteLn('===================================================');
    Exit;
  end;
  Nota := GetNFe(StrToInt(Pedido.CodFreeNFe));
  WriteLn('O numero da ultima NFe do cliente e: ' + IntToStr(Nota.NumNFe));
  WriteLn('O nome do cliente e: ' + Nota.Nome);
  WriteLn('O valor da NFe e: ', FormatCurr('R$ #,##0.00', Nota.ValorNFe));
  WriteLn('===================================================');
end;

function TCloneNFe.EhDataValida(const Texto: string): Boolean;
var
  DataConvertida: TDateTime;
begin
  // TryStrToDate retorna True se for válida e False se não for
  Result := TryStrToDate(Texto, DataConvertida);
end;

constructor TCloneNFe.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  StopOnException:=True;
end;

destructor TCloneNFe.Destroy;
begin
  inherited Destroy;
end;

procedure TCloneNFe.WriteHelp;
begin
  { add your help code here }
  writeln('Usage: ', ExeName, ' -h');
  ExibirAjuda;
end;

var
  Application: TCloneNFe;
begin
  Application:=TCloneNFe.Create(nil);
  Application.Title:='Clone NFe';
  Application.Run;
  Application.Free;
end.

