unit FreeNFeUtils;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils;

type

  TNFe = record
    NumNFe: Integer;
    Nome: string;
    ValorNFe: Currency;
  end;

function GetNFe(CodCliente: Integer): TNFe;

implementation

uses
  SQLDB
  , IBConnection
  , SQLDBLib
  , FileLoggerUnit
  ;

const
  CInfoPadrao = 'Baixa automática de pedido';
  CPedidoJaLiquidadoERR = 'O pedido já está liquidado';

  { Ajustar conforme seu ambiente }
  DB_HOST     = '127.0.0.1';
  DB_NAME     = 'C:\FreeNFe\Banco\HMNFE.FDB';
  DB_USER     = 'SYSDBA';
  DB_PASSWORD = 'masterkey';
  DB_PORT     = 3050;
  DB_CHARSET  = 'ISO8859_1';

function GetNFe(CodCliente: Integer): TNFe;
const
  cSQL = 'SELECT FIRST 1 r.IDE_NNF, r.DEST_XNOME, r.TOTAL_ICMSTOT_VNF FROM NFE r JOIN PESSOA p ON r.DEST_XNOME = p.RAZAO AND p.ID = :CODCLIENTE ORDER BY r.IDE_NNF DESC;';
var
  Conn   : TIBConnection;
  Trans  : TSQLTransaction;
  Qry    : TSQLQuery;
  Nota   : TNFe;
begin
  LogToFile('Consultando FreeNFe.');
  Conn  := TIBConnection.Create(nil);
  try
        { Configuração da conexão }
    Conn.HostName     := DB_HOST;
    Conn.DatabaseName := DB_NAME;
    Conn.UserName     := DB_USER;
    Conn.Password     := DB_PASSWORD;
    Conn.Port         := DB_PORT;
    Conn.Charset      := DB_CHARSET;
    Trans := TSQLTransaction.Create(nil);
    Qry   := TSQLQuery.Create(nil);
    Conn.Transaction := Trans;
    Qry.DataBase     := Conn;
    Qry.Transaction  := Trans;
    Qry.SQL.Clear;
    Qry.SQL.Add(cSQL);
    Qry.ParamByName('CODCLIENTE').AsInteger := CodCliente;

    Conn.Open;
    Qry.Open; // <--- LINHA ADICIONADA: Executa a consulta de fato

    // Boa prática: Verificar se a consulta retornou algum registro antes de ler
    if not Qry.EOF then
    begin
      Nota.NumNFe   := Qry.FieldByName('IDE_NNF').AsInteger;
      Nota.Nome     := Qry.FieldByName('DEST_XNOME').AsString;
      Nota.ValorNFe := Qry.FieldByName('TOTAL_ICMSTOT_VNF').AsCurrency;
    end
    else
    begin
      // Opcional: Tratar caso a nota não seja encontrada (zerar a variável Cliente, etc)
      Nota := Default(TNFe);
    end;

    Result := Nota;
    LogToFile('Numero NFe: ' + IntToStr(Nota.NumNFe));
    LogToFile('Nome cliente no FreeNFe: ' + Nota.Nome );
    LogToFile('Valor NFe: ' + FormatCurr('R$ #,##0.00', Nota.ValorNFe));
  finally
    Qry.Active:=False;
    Qry.Free;
    Trans.Free;
    Conn.Close(False);
    Conn.Free;
  end;
end;

end.

