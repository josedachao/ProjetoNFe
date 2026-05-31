unit PluginUtils;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils;

type

  TPedido = record
    NumPedido: Integer;
    Nome: string;
    CodFreeNFe: string;
  end;

function GetPedido(NumPedido: Integer): TPedido;

implementation

uses
  SQLDB
  , mysql57conn
  , SQLDBLib
  , FileLoggerUnit
  ;

const
  CInfoPadrao = 'Baixa automática de pedido';
  CPedidoJaLiquidadoERR = 'O pedido já está liquidado';

  { Ajustar conforme seu ambiente }
  DB_HOST     = '127.0.0.1';
  DB_NAME     = 'ps_plugingestor';
  DB_USER     = 'root';
  DB_PASSWORD = 'Visualizar';
  DB_PORT     = 3306;
  DB_CHARSET  = 'latin1';

function GetPedido(NumPedido: Integer): TPedido;
const
  cSQL = 'SELECT pvm.numero_pedido, pvm.cod_cliente, cli.id, cli.nome, cdp.id_cliente_freenfe FROM pedidovendam pvm LEFT JOIN clientes cli ON pvm.cod_cliente = cli.id LEFT JOIN clientes_de_para cdp ON cli.id = cdp.id_cliente_plugin WHERE pvm.numero_pedido = :NUMPEDIDO;';
var
  Conn   : TMySQL57Connection;
  Trans  : TSQLTransaction;
  Qry    : TSQLQuery;
  Pedido : TPedido;
begin
  LogToFile('Consultando Plugin.');
  Conn  := TMySQL57Connection.Create(nil);
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
    Qry.ParamByName('NUMPEDIDO').AsInteger := NumPedido;

    Conn.Open;
    Qry.Open; // <--- LINHA ADICIONADA: Executa a consulta de fato

    // Boa prática: Verificar se a consulta retornou algum registro antes de ler
    if not Qry.EOF then
    begin
      Pedido.NumPedido := Qry.FieldByName('numero_pedido').AsInteger;
      Pedido.Nome      := Qry.FieldByName('nome').AsString;
      Pedido.CodFreeNFe:= Qry.FieldByName('id_cliente_freenfe').AsString;
    end
    else
    begin
      // Opcional: Tratar caso a nota não seja encontrada (zerar a variável Cliente, etc)
      Pedido := Default(TPedido);
    end;

    Result := Pedido;
    LogToFile('Numero pedido: ', IntToStr(Pedido.NumPedido));
    LogToFile('Nome cliente: ', Pedido.Nome);
    LogToFile('Codigo cliente FreeNFe (cadastrado no Plugin): ', Pedido.CodFreeNFe);
  finally
    Qry.Active:=False;
    Qry.Free;
    Trans.Free;
    Conn.Close(False);
    Conn.Free;
  end;
end;

end.

