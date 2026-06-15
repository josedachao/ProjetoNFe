unit uDBService;

{$mode ObjFPC}{$H+}

interface

type

  TEnderecoEntrega = record
    CNPJCPF: string;
    xLgr: string;
    nro: string;
    xCpl: string;
    xBairro: string;
    cMun: Integer;
    xMun: string;
    UF: string;
  end;

  TClienteResultado = record
    idNFE   : Integer;
    CNPJCPF : string;
    IE      : string;
    indIEDest : Integer;
    //ISUF  : string;//SUFRAMA NÃO NECESSÁRIO
    xNome   : string;
    Fone    : string;
    CEP     : Integer;
    xLgr    : string;
    nro     : string;
    xCpl    : string;
    xBairro : string;
    cMun    : Integer;
    xMun    : string;
    UF      : string;
    cPais   : Integer;
    xPais   : string;
    Entrega : Boolean;
    EnderecoEntrega: TEnderecoEntrega;
  end;

  TProdutoResultado = record
    cProd: string;
    xProd: string;
    CFOP: string;
    qCom: Currency;
    vUnCom: Currency;
    vProd: Currency;
    qTrib: Currency;
    vUnTrib: Currency;
    vItem: Currency;
  end;

  TDadosGeraisNFe = record
    ID                         : string;
    Ide_natOp                  : string;
    UF_OPER                    : string;
    InfAdic_infCpl             : string;
    InfAdic_infAdFisco         : string;
    Total_ICMSTot_vProd        : Currency;
    Total_ICMSTot_vNF          : Currency;
    Transp_modFrete            : Integer;
    Transp_Transporta_CNPJCPF  : string;
    Transp_Transporta_xNome    : string;
    Transp_Transporta_IE       : string;
    Transp_Transporta_xEnder   : string;
    Transp_Transporta_xMun     : string;
    Transp_Transporta_UF       : string;
    Volume_qVol                : Integer;
    Volume_esp                 : string;
    Volume_marca               : string;
    Volume_nVol                : string;
    Volume_pesoL               : Currency;
    Volume_pesoB               : Currency;
    Duplicata_nDup             : string;
    Duplicata_dVenc            : TDateTime;
    Duplicata_vDup             : Currency;
  end;


function GetClient(NumNFe: Integer): TClienteResultado;
function ConnectNFE: Boolean;
function GetNumItens(IDNFe: Integer): Integer;
function GetItem(const IDNFe: Integer; const NumItem: Integer): TProdutoResultado;
function GetDadosGeraisNFe(const NumNFe: Integer): TDadosGeraisNFe;


implementation

uses
  SysUtils
  , SQLDB
  , mysql57conn
  , SQLDBLib
  , IBConnection
  ;




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
  DB_PORT     = 3050;
  DB_CHARSET  = 'ISO8859_1';

function CEPToInteger(const ACEP: string): Integer;
var
   i: Integer;
   ApenasDigitos: string;
begin
   ApenasDigitos := '';

   for i := 1 to Length(ACEP) do
   begin
     if ACEP[i] in ['0'..'9'] then
       ApenasDigitos := ApenasDigitos + ACEP[i];
   end;

   // Validação opcional
   if Length(ApenasDigitos) <> 8 then
     raise Exception.Create('CEP inválido.');

   Result := StrToInt(ApenasDigitos);
end;

function GetClient(NumNFe: Integer): TClienteResultado;
const
  cSQL = 'SELECT r.ID,r.IDE_NNF,r.IDE_DEMI,r.DEST_CNPJCPF,r.DEST_IE,r.DEST_ISUF,r.DEST_XNOME,r.DEST_ENDERDEST_FONE,r.DEST_ENDERDEST_CEP,r.DEST_ENDERDEST_XLGR,r.DEST_ENDERDEST_NRO,r.DEST_ENDERDEST_XCPL,r.DEST_ENDERDEST_XBAIRRO,r.DEST_ENDERDEST_CMUN,r.DEST_ENDERDEST_XMUN,r.DEST_ENDERDEST_UF,r.DEST_ENDERDEST_CPAIS,r.DEST_ENDERDEST_XPAIS, r.ENTREGA_CNPJCPF, r.ENTREGA_XLGR, r.ENTREGA_NRO, r.ENTREGA_XCPL, r.ENTREGA_XBAIRRO, r.ENTREGA_CMUN, r.ENTREGA_XMUN, r.ENTREGA_UF FROM NFE r WHERE IDE_NNF = :NUMNFE;';
var
  Conn   : TIBConnection;
  Trans  : TSQLTransaction;
  Qry    : TSQLQuery;
  Cliente: TClienteResultado;
begin
  Cliente.Entrega := False;
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
    Qry.ParamByName('NUMNFE').AsInteger := NumNFe;

    Conn.Open;
    Qry.Open; // <--- LINHA ADICIONADA: Executa a consulta de fato

    // Boa prática: Verificar se a consulta retornou algum registro antes de ler
    if not Qry.EOF then
    begin
      Cliente.idNFE   := Qry.FieldByName('ID').AsInteger;
      Cliente.CNPJCPF := Qry.FieldByName('DEST_CNPJCPF').AsString;
      Cliente.xNome   := Qry.FieldByName('DEST_XNOME').AsString;
      Cliente.IE      := Qry.FieldByName('DEST_IE').AsString;
      Cliente.Fone    := Qry.FieldByName('DEST_ENDERDEST_FONE').AsString;
      Cliente.xBairro := Qry.FieldByName('DEST_ENDERDEST_XBAIRRO').AsString;
      Cliente.xLgr    := Qry.FieldByName('DEST_ENDERDEST_XLGR').AsString;
      Cliente.xCpl    := Qry.FieldByName('DEST_ENDERDEST_XCPL').AsString;
      Cliente.xMun    := Qry.FieldByName('DEST_ENDERDEST_XMUN').AsString;
      Cliente.UF      := Qry.FieldByName('DEST_ENDERDEST_UF').AsString;
      Cliente.xPais   := Qry.FieldByName('DEST_ENDERDEST_XPAIS').AsString;
      Cliente.nro     := Qry.FieldByName('DEST_ENDERDEST_NRO').AsString;
      Cliente.CEP     := CEPToInteger(Qry.FieldByName('DEST_ENDERDEST_CEP').AsString);
      Cliente.cMun    := Qry.FieldByName('DEST_ENDERDEST_CMUN').AsInteger;
      Cliente.cPais   := Qry.FieldByName('DEST_ENDERDEST_CPAIS').AsInteger;
      if Qry.FieldByName('ENTREGA_XLGR').AsString <> '' then
      begin
        Cliente.Entrega := True;
        Cliente.EnderecoEntrega.cMun    := Qry.FieldByName('ENTREGA_CMUN').AsInteger;
        Cliente.EnderecoEntrega.xMun    := Qry.FieldByName('ENTREGA_XMUN').AsString;
        Cliente.EnderecoEntrega.UF      := Qry.FieldByName('ENTREGA_UF').AsString;
        Cliente.EnderecoEntrega.xBairro := Qry.FieldByName('ENTREGA_XBAIRRO').AsString;
        Cliente.EnderecoEntrega.xCpl    := Qry.FieldByName('ENTREGA_XCPL').AsString;
        Cliente.EnderecoEntrega.nro     := Qry.FieldByName('ENTREGA_NRO').AsString;
        Cliente.EnderecoEntrega.xLgr    := Qry.FieldByName('ENTREGA_XLGR').AsString;
        if Qry.FieldByName('ENTREGA_CNPJCPF').AsString = '' then
          Cliente.EnderecoEntrega.CNPJCPF := Cliente.CNPJCPF
        else
          Cliente.EnderecoEntrega.CNPJCPF := Qry.FieldByName('ENTREGA_CNPJCPF').AsString;
      end;
    end
    else
    begin
      // Opcional: Tratar caso a nota não seja encontrada (zerar a variável Cliente, etc)
      Cliente := Default(TClienteResultado);
    end;

    Result := Cliente;
  finally
    Qry.Active:=False;
    Qry.Free;
    Trans.Free;
    Conn.Close(False);
    Conn.Free;
  end;
end;

function ConnectNFE: Boolean;
var
  Conn   : TIBConnection;
  Trans  : TSQLTransaction;
  Qry    : TSQLQuery;
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
    //Qry.SQL.Add(;
    Conn.Open;
    if conn.Connected then Result := true;
  finally
    Qry.Free;
    Trans.Free;
    Conn.Free;
  end;
end;

function GetNumItens(IDNFe: Integer): Integer;
const
  cSQL = 'SELECT COUNT(a.NITEM) FROM NFE_ITENS a WHERE a.ID_NFE = :NUMNFE;';
var
  Conn   : TIBConnection;
  Trans  : TSQLTransaction;
  Qry    : TSQLQuery;
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
    Qry.ParamByName('NUMNFE').AsInteger := IDNFe;

    Conn.Open;
    Qry.Open; // <--- LINHA ADICIONADA: Executa a consulta de fato

    // Boa prática: Verificar se a consulta retornou algum registro antes de ler
    if not Qry.EOF then
    begin
      Result := Qry.FieldByName('COUNT').AsInteger;
    end
    else
    begin
      // Opcional: Tratar caso a nota não seja encontrada (zerar a variável Cliente, etc)
      Result := 0;
    end;
  finally
    Qry.Active := False;
    Qry.Free;
    Trans.Free;
    Conn.Close(False);
    Conn.Free;
  end;
end;

function GetItem(const IDNFe: Integer; const NumItem: Integer): TProdutoResultado;
const
  cSQL = 'SELECT i.ID, i.ID_NFE, i.NITEM, i.CPROD, i.CEAN, i.XPROD, i.NCM, i.CFOP, i.UCOM, i.QCOM, i.VUNCOM, i.VPROD, i.CEANTRIB, i.UTRIB, i.QTRIB, i.VUNTRIB FROM NFE_ITENS i WHERE i.ID_NFE = :IDNFE AND i.NITEM = :NUMITEM;';
var
  Conn   : TIBConnection;
  Trans  : TSQLTransaction;
  Qry    : TSQLQuery;
  Produto: TProdutoResultado;
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
    Qry.ParamByName('IDNFE').AsInteger := IDNFe;
    Qry.ParamByName('NUMITEM').AsInteger := NumItem;

    Conn.Open;
    Qry.Open; // <--- LINHA ADICIONADA: Executa a consulta de fato

    // Boa prática: Verificar se a consulta retornou algum registro antes de ler
    if not Qry.EOF then
    begin
      Produto.cProd := Qry.FieldByName('CPROD').AsString;
      Produto.xProd := Qry.FieldByName('XPROD').AsString;
      Produto.CFOP := Qry.FieldByName('CFOP').AsString;
      Produto.qCom := Qry.FieldByName('QCOM').AsCurrency;
      Produto.vUnCom := Qry.FieldByName('VUNCOM').AsCurrency;
      Produto.vProd := Qry.FieldByName('VPROD').AsCurrency;
      Produto.qTrib := Qry.FieldByName('QTRIB').AsCurrency;
      Produto.vUnTrib := Qry.FieldByName('VUNTRIB').AsCurrency;
      Produto.vItem := Qry.FieldByName('VPROD').AsCurrency;
    end
    else
    begin
      // Opcional: Tratar caso a nota não seja encontrada (zerar a variável Cliente, etc)
      Produto := Default(TProdutoResultado);
    end;
    Result := Produto;
  finally
    Qry.Active:=False;
    Qry.Free;
    Trans.Free;
    Conn.Close(False);
    Conn.Free;
  end;
end;

function GetDadosGeraisNFe(const NumNFe: Integer): TDadosGeraisNFe;
const
  cSQL = 'SELECT a.ID, a.DEST_ENDERDEST_UF, a.TOTAL_ICMSTOT_VPROD, a.TOTAL_ICMSTOT_VNF, a.IDE_NATOP, a.INFADIC_INFCPL, a.INFADIC_INFADFISCO, a.TRANSP_MODFRETE, a.TRANSP_TRANSPORTA_CNPJCPF, a.TRANSP_TRANSPORTA_XNOME, a.TRANSP_TRANSPORTA_IE, a.TRANSP_TRANSPORTA_XMUN, a.TRANSP_TRANSPORTA_UF,  a.TRANSP_TRANSPORTA_XENDER, r.QVOL, r.ESP, r.MARCA, r.NVOL, r.PESOB, r.PESOL, s.NDUP, s.DVENC, s.VDUP FROM NFE a LEFT JOIN NFE_TRANSP_VOL r ON (a.ID = r.ID_NFE) LEFT JOIN NFE_COBR_DUP s ON (a.ID = s.ID_NFE) WHERE a.IDE_NNF = :NUMNNF;';
var
  Conn   : TIBConnection;
  Trans  : TSQLTransaction;
  Qry    : TSQLQuery;
  DadosGerais: TDadosGeraisNFe;
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
    Qry.Open; // <--- LINHA ADICIONADA: Executa a consulta de fato

    // Boa prática: Verificar se a consulta retornou algum registro antes de ler
    if not Qry.EOF then
    begin
      DadosGerais.ID := Qry.FieldByName('ID').AsString;
      DadosGerais.Ide_natOp := Qry.FieldByName('IDE_NATOP').AsString;
      DadosGerais.UF_OPER := Qry.FieldByName('DEST_ENDERDEST_UF').AsString;
      DadosGerais.InfAdic_infCpl := Qry.FieldByName('INFADIC_INFCPL').AsString;;
      DadosGerais.InfAdic_infAdFisco := Qry.FieldByName('INFADIC_INFADFISCO').AsString;;
      DadosGerais.Total_ICMSTot_vNF := Qry.FieldByName('TOTAL_ICMSTOT_VNF').AsCurrency;
      DadosGerais.Total_ICMSTot_vProd := Qry.FieldByName('TOTAL_ICMSTOT_VPROD').AsCurrency;
      DadosGerais.Transp_modFrete := Qry.FieldByName('TRANSP_MODFRETE').AsInteger;
      DadosGerais.Transp_Transporta_CNPJCPF := Qry.FieldByName('TRANSP_TRANSPORTA_CNPJCPF').AsString;
      DadosGerais.Transp_Transporta_IE := Qry.FieldByName('TRANSP_TRANSPORTA_IE').AsString;
      DadosGerais.Transp_Transporta_UF := Qry.FieldByName('TRANSP_TRANSPORTA_UF').AsString;
      DadosGerais.Transp_Transporta_xEnder := Qry.FieldByName('TRANSP_TRANSPORTA_XENDER').AsString;
      DadosGerais.Transp_Transporta_xMun := Qry.FieldByName('TRANSP_TRANSPORTA_XMUN').AsString;
      DadosGerais.Transp_Transporta_xNome := Qry.FieldByName('TRANSP_TRANSPORTA_XNOME').AsString;
      DadosGerais.Volume_qVol := Qry.FieldByName('QVOL').AsInteger;
      DadosGerais.Volume_esp := Qry.FieldByName('ESP').AsString;
      DadosGerais.Volume_marca := Qry.FieldByName('MARCA').AsString;
      DadosGerais.Volume_nVol := Qry.FieldByName('NVOL').AsString;
      DadosGerais.Volume_pesoL := Qry.FieldByName('PESOB').AsCurrency;
      DadosGerais.Volume_pesoB := Qry.FieldByName('PESOL').AsCurrency;
      DadosGerais.Duplicata_nDup  := '001';//Qry.FieldByName('NDUP').AsString;
      DadosGerais.Duplicata_dVenc := Qry.FieldByName('DVENC').AsDateTime;
      DadosGerais.Duplicata_vDup  := Qry.FieldByName('VDUP').AsCurrency;
    end
    else
    begin
      // Opcional: Tratar caso a nota não seja encontrada (zerar a variável Cliente, etc)
      DadosGerais := Default(TDadosGeraisNFe);
    end;
    Result := DadosGerais;
  finally
    Qry.Active:=False;
    Qry.Free;
    Trans.Free;
    Conn.Close(False);
    Conn.Free;
  end;
end;

end.

