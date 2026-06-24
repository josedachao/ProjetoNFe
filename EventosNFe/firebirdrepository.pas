unit FirebirdRepository;

{$mode ObjFPC}{$H+}

interface

uses
  Classes
  , SysUtils
  , SQLDB
  , SQLDBLib
  , IBConnection
  , DTOs
  ;

procedure GetDadosNFe(const NumNFe: Integer; var Cancelamento: TCancelamento);
function SetSummaryData(const NumNFe: Integer): Boolean;
function SetCancelada(const NumNFe: Integer; const NFeXML: string): Boolean;

implementation

const
  CInfoPadrao = 'Baixa automática de pedido';
  CPedidoJaLiquidadoERR = 'O pedido já está liquidado';

  { Ajustar conforme seu ambiente }
  DB_HOST     = '127.0.0.1';
  {$IFDEF WINDOWS}
  DB_NAME     = 'C:\FreeNFe\Banco\HMNFE.FDB';
  {$ELSE}
  {$IFDEF Linux}
  DB_NAME     = '/opt/firebird/data/HMNFE.FDB';
  {$ENDIF}
  {$ENDIF}
  DB_USER     = 'SYSDBA';
  {$IFDEF WINDOWS}
  DB_PASSWORD = 'masterkey';
  {$ELSE}
  {$IFDEF Linux}
  DB_PASSWORD = 'Outr453nh4!';
  {$ENDIF}
  {$ENDIF}
  {$IFDEF WINDOWS}
  DB_PORT     = 3050;
  {$ELSE}
  {$IFDEF Linux}
  DB_PORT     = 3050;
  {$ENDIF}
  {$ENDIF}
  DB_CHARSET  = 'ISO8859_1';

procedure GetDadosNFe(const NumNFe: Integer; var Cancelamento: TCancelamento);
const
  cSQL = 'SELECT a.ID, a.IDE_NNF, a.IDE_DEMI, a.NFE_CHAVE, a.NFE_PROTOCOLO FROM NFE a WHERE a.IDE_NNF = :NUMNNF;';
  //cSQL = 'SELECT a.IDE_NNF, a.IDE_DEMI, a.NFE_CHAVE, a.NFE_PROTOCOLO FROM NFE_DBG a WHERE a.IDE_NNF = :NUMNNF;';
var
  Conn   : TIBConnection;
  Trans  : TSQLTransaction;
  Qry    : TSQLQuery;
  ChaveNFe: string;
begin
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
    Qry.ParamByName('NUMNNF').AsInteger := NumNFe;

    Conn.Open;
    WriteLn('Conectado ao banco de dados...');
    Qry.Open; // <--- LINHA ADICIONADA: Executa a consulta de fato

    // Boa prática: Verificar se a consulta retornou algum registro antes de ler
    if not Qry.EOF then
    begin
      Cancelamento.Chave := Qry.FieldByName('NFE_CHAVE').AsString;
      Cancelamento.ProtocoloEnvio := Qry.FieldByName('NFE_PROTOCOLO').AsString;
      Cancelamento.DataEmissao := Qry.FieldByName('IDE_DEMI').AsDateTime;
    end
    else
    begin
      // Opcional: Tratar caso a nota não seja encontrada (retornar registro vazio)
      Cancelamento := Default(TCancelamento);
    end;
    WriteLn('Chave registrada no banco: ' + Cancelamento.Chave);
  finally
    Qry.Active:=False;
    Qry.Free;
    Trans.Free;
    Conn.Close(False);
    Conn.Free;
  end;
end;

function SetSummaryData(const NumNFe: Integer): Boolean;
const
  cSQL = 'UPDATE NFE_DBG SET CANCELADA = ''S'' WHERE IDE_NNF = :NUMNFE;';
var
  Conn  : TIBConnection;
  Trans : TSQLTransaction;
  Qry   : TSQLQuery;
begin
  Result := False;

  // Instancia os objetos antes do try principal para evitar Access Violations no finally
  Conn  := TIBConnection.Create(nil);
  Trans := TSQLTransaction.Create(nil);
  Qry   := TSQLQuery.Create(nil);

  try
    { Configuração da conexão }
    Conn.HostName     := DB_HOST;
    Conn.DatabaseName := DB_NAME; // ATENÇÃO: Garanta que seja um caminho absoluto!
    Conn.UserName     := DB_USER;
    Conn.Password     := DB_PASSWORD;
    Conn.Port         := DB_PORT;
    Conn.Charset      := DB_CHARSET;

    // Vinculações
    Conn.Transaction := Trans;
    Qry.DataBase     := Conn;
    Qry.Transaction  := Trans;
    Qry.SQL.Clear;

    // Use .Text ao invés de .Add() para garantir que a query está limpa
    Qry.SQL.Text := cSQL;

    try
      Conn.Open;

      // Garante que a transação está rodando
      if not Trans.Active then
        Trans.StartTransaction;

      // PREPARE: O pulo do gato. Envia o SQL pro banco interpretar os parâmetros
      // antes de injetarmos os valores.
      Qry.Prepare;

      Qry.ParamByName('NUMNFE').AsInteger  := NumNFe;

      Qry.ExecSQL;

      // O Commit é o que efetiva a gravação física (Write-Ahead Logging do Firebird)
      Trans.Commit;

      Result := True;
    except
      on E: Exception do
      begin
        Result := False;

        // Trava de Segurança: Só tenta fazer Rollback se a transação chegou a ser aberta
        if Trans.Active then
          Trans.Rollback;

        // Imprime o erro REAL devolvido pelo Firebird
        WriteLn('Erro UPDATE BD [SetSummaryData]: ', E.Message);

        // Em CLI, repassar o 'raise' pode quebrar a execução em lote.
        // Como a função já retorna False, o chamador pode tratar graciosamente.
        // raise;
      end;
    end;
  finally
    // A limpeza deve ser feita na ordem inversa da criação (Filho -> Pai)
    // OBS: Retirado o "Qry.Active := False" pois é incorreto para ExecSQL.
    Qry.Free;
    Trans.Free;
    Conn.Close; // No Lazarus padrão, Close() não leva o parâmetro 'False'
    Conn.Free;
  end;
end;

function SetCancelada(const NumNFe: Integer; const NFeXML: string): Boolean;
const
  cSQLNFE_DBG = 'UPDATE NFE_DBG SET CANCELADA = ''S'', NFE_SITUACAO = ''4'', NFE_XML = :NFEXML WHERE IDE_NNF = :NUMNFE;';
  cSQLNFE = 'UPDATE NFE SET NFE_SITUACAO = ''4'', NFE_XML = :NFEXML WHERE IDE_NNF = :NUMNFE;';
var
  Conn  : TIBConnection;
  Trans : TSQLTransaction;
  QryNFE: TSQLQuery;
  QryNFE_DBG   : TSQLQuery;
begin
  Result := False;

  // Instancia os objetos antes do try principal para evitar Access Violations no finally
  Conn  := TIBConnection.Create(nil);
  Trans := TSQLTransaction.Create(nil);
  QryNFE:= TSQLQuery.Create(nil);
  QryNFE_DBG   := TSQLQuery.Create(nil);

  try
    { Configuração da conexão }
    Conn.HostName     := DB_HOST;
    Conn.DatabaseName := DB_NAME; // ATENÇÃO: Garanta que seja um caminho absoluto!
    Conn.UserName     := DB_USER;
    Conn.Password     := DB_PASSWORD;
    Conn.Port         := DB_PORT;
    Conn.Charset      := DB_CHARSET;

    // Vinculações
    Conn.Transaction := Trans;

    QryNFE.DataBase     := Conn;
    QryNFE.Transaction  := Trans;
    QryNFE.SQL.Clear;

    QryNFE_DBG.DataBase     := Conn;
    QryNFE_DBG.Transaction  := Trans;
    QryNFE_DBG.SQL.Clear;

    // Use .Text ao invés de .Add() para garantir que a query está limpa
    QryNFE.SQL.Text := cSQLNFE;
    QryNFE_DBG.SQL.Text := cSQLNFE_DBG;

    try
      Conn.Open;

      // Garante que a transação está rodando
      if not Trans.Active then
        Trans.StartTransaction;

      // PREPARE: O pulo do gato. Envia o SQL pro banco interpretar os parâmetros
      // antes de injetarmos os valores.
      QryNFE.Prepare;
      QryNFE_DBG.Prepare;

      QryNFE.ParamByName('NUMNFE').AsInteger  := NumNFe;
      QryNFE.ParamByName('NFEXML').AsString := NFeXML;

      QryNFE_DBG.ParamByName('NUMNFE').AsInteger  := NumNFe;
      QryNFE_DBG.ParamByName('NFEXML').AsString := NFeXML;

      QryNFE.ExecSQL;
      QryNFE_DBG.ExecSQL;

      // O Commit é o que efetiva a gravação física (Write-Ahead Logging do Firebird)
      Trans.Commit;

      Result := True;
    except
      on E: Exception do
      begin
        Result := False;

        // Trava de Segurança: Só tenta fazer Rollback se a transação chegou a ser aberta
        if Trans.Active then
          Trans.Rollback;

        // Imprime o erro REAL devolvido pelo Firebird
        WriteLn('Erro UPDATE BD [SetSummaryData]: ', E.Message);

        // Em CLI, repassar o 'raise' pode quebrar a execução em lote.
        // Como a função já retorna False, o chamador pode tratar graciosamente.
        // raise;
      end;
    end;
  finally
    // A limpeza deve ser feita na ordem inversa da criação (Filho -> Pai)
    // OBS: Retirado o "Qry.Active := False" pois é incorreto para ExecSQL.
    QryNFE.Free;
    QryNFE_DBG.Free;
    Trans.Free;
    Conn.Close; // No Lazarus padrão, Close() não leva o parâmetro 'False'
    Conn.Free;
  end;
end;

end.

