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
  ;

type

  { TCloneNFe }

  TCloneNFe = class(TCustomApplication)
  protected
    procedure DoRun; override;
    procedure ExibirAjuda; // Nova rotina para centralizar o texto de ajuda
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    procedure WriteHelp; virtual;
  end;

{ TCloneNFe }

procedure TCloneNFe.DoRun;
var
  ErrorMsg: String;
begin
  // quick check parameters

  ErrorMsg:=CheckOptions('?', 'h', 'help');
  if ErrorMsg<>'' then begin
    ShowException(Exception.Create(ErrorMsg));
    Terminate;
    Exit;
  end;

  // parse parameters
  if HasOption('h', 'help') then begin
    WriteHelp;
    Terminate;
    Exit;
  end;

  { add your program here }

  // stop program loop
  Terminate;
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
  Writeln('  CloneNFe.exe --num=10243');
  Writeln('===================================================================');
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

