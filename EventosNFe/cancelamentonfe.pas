unit CancelamentoNFe;

{$mode ObjFPC}{$H+}

interface

uses
  Classes
  , SysUtils
  , ACBrNFe
  , ACBrDFe.Conversao
  //, ACBrDFeException
  //, ACBrNFeNotasFiscais
  , ACBrNFe.Classes
  //, pcnConversaoNFe
  , ACBrDFeUtil
//  , ACBrNFeDANFeRLClass
  //, ACBrNFeDANFeFPDF
 // , ACBrMail
//  , SynHighlighterXML
  , ACBrDFeSSL
  , FileLoggerUnit
  , FileUtil
  ;

type
  TCancelamento =  record
    Chave: string;
    ProtocoloEnvio: string;
    DataEmissao: TDateTime;
    RetornoWS: string;
    RetWS: string;
    cStat:Integer;
    ProtocoloRetorno: string;
    Id: string;
    tpAmb: TACBrTipoAmbiente;
    verAplic: string;
    cOrgao: Integer;
    chNFe: string;
    tpEvento: TACBrTipoEvento;
    xMotivo: string;
    xEvento: string;
    dhRegEvento: TDateTime;
    CNPJDest: string;
    nSeqEvento: Integer;
    emailDest: string;
  end;

procedure CancelarNFe(const NumNFe: Integer; const MotivoUsuario: String; const AAmbiente: TACBrTipoAmbiente; var Cancelamento: TCancelamento);
function GetCNPJ: string;
procedure GetDadosNFe(const NumNFe: Integer; var Cancelamento: TCancelamento);
function SetSummaryData(const NumNFe: Integer): Boolean;
function SetCancelada(const NumNFe: Integer; const NFeXML: string): Boolean;

implementation

uses
  SQLDB
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
  {$IFDEF WINDOWS}
  DB_PORT     = 3050;
  {$ELSE}
  {$IFDEF Linux}
  DB_PORT     = 3050;
  {$ENDIF}
  {$ENDIF}
  DB_CHARSET  = 'ISO8859_1';

  FREENFEXMLPATH = 'C:\FreeNFe\09167426000109\NFE\';

function ObterAnoMes(const ADateTime: TDateTime): String;
begin
  // 'yyyymm' extrai o ano com 4 dígitos e o mês com 2 dígitos e zero à esquerda
  Result := FormatDateTime('yyyymm', ADateTime);
end;

procedure DuplicateAndRename(const FileName: string);
var
  Source, Destination: string;
begin
  Source := FileName;
  Destination := StringReplace(FileName, 'nfe', 'ORIGINAL', [rfReplaceAll, rfIgnoreCase]);

  // Third parameter true will overwrite the destination file if it exists
  if CopyFile(Source, Destination, True) then
    WriteLn('Arquivo copiado e renomeado com sucesso!!')
  else
    WriteLn('Erro ao copiar e renomear o arquivo.');
end;

procedure SimpleRename(const FileName: string);
var
  OldName, NewName: string;
begin
  OldName := FileName;
  NewName := StringReplace(FileName, 'nfe', 'ORIGINAL', [rfReplaceAll, rfIgnoreCase]);

  if RenameFile(OldName, NewName) then
    WriteLn('Arquivo renomeado com sucesso.')
  else
    WriteLn('Erro ao renomear o arquivo.');
end;

function XMLParaString(const CaminhoArquivo: string): string;
var
  ConteudoArquivo: TStringList;
begin
  Result := '';
  // Verifica se o arquivo realmente existe para evitar erros
  if not FileExists(CaminhoArquivo) then
    Exit;

  ConteudoArquivo := TStringList.Create;
  try
    // Carrega o arquivo XML
    ConteudoArquivo.LoadFromFile(CaminhoArquivo);
    // Atribui o texto completo à variável de retorno
    Result := ConteudoArquivo.Text;
  finally
    // Libera a memória do TStringList
    ConteudoArquivo.Free;
  end;
end;

{function CopyInUseFile(const FileName: string; out XMLContent: string): Boolean;
var
  SrcStream, DestStream: TFileStream;
  StrStream: TStringStream;
  NewFileName: string;
begin
  Result := False;
  XMLContent := ''; // Inicializa a string de retorno
  SrcStream := nil;
  DestStream := nil;

  NewFileName := StringReplace(FileName, '-nfe', '-ORIGINAL', [rfReplaceAll, rfIgnoreCase]);
  try
    try
      // Abre o arquivo original permitindo leitura mesmo se bloqueado
      SrcStream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
      DestStream := TFileStream.Create(NewFileName, fmCreate);

      // 1. Faz a cópia física do arquivo como você já fazia
      DestStream.CopyFrom(SrcStream, SrcStream.Size);

      // 2. Reposiciona o ponteiro do SrcStream para o início antes de ler o texto
      SrcStream.Position := 0;

      // 3. Lê o stream diretamente para a string (usa TEncoding.UTF8 nativo no Lazarus)
      StrStream := TStringStream.Create('', TEncoding.UTF8);
      try
        StrStream.CopyFrom(SrcStream, SrcStream.Size);
        XMLContent := StrStream.DataString; // Copia o texto para a sua variável
      finally
        StrStream.Free;
      end;

      Result := True;
    except
      on E: Exception do
        WriteLn('Error: ', E.Message);
    end;
  finally
    SrcStream.Free;
    DestStream.Free;
  end;
end; }

function CopyInUseFile(const FileName: string): Boolean;
var
  SrcStream, DestStream: TFileStream;
  NewFileName: string;
begin
  Result := False;
  SrcStream := nil;
  DestStream := nil;
  NewFileName := StringReplace(FileName, '-nfe', '-ORIGINAL', [rfReplaceAll, rfIgnoreCase]);
  try
    try
      // fmShareDenyNone allows reading even if the file is locked/written to by another process
      SrcStream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
      DestStream := TFileStream.Create(NewFileName, fmCreate);

      DestStream.CopyFrom(SrcStream, SrcStream.Size);
      Result := True;
    except
      on E: Exception do
        WriteLn('Error: ', E.Message);
    end;
  finally
    SrcStream.Free;
    DestStream.Free;
  end;
end;

procedure ConfiguracoesPadraoNFe(ACBrNFe1: TACBrNFe; AAmbiente: TACBrTipoAmbiente);
begin
  with ACBrNFe1.Configuracoes.Geral do
  begin
    ExibirErroSchema := False;
    FormatoAlerta := 'Campo:%DESCRICAO% - %MSG%';

    AtualizarXMLCancelado := True;

    // O LibXml2 funciona perfeitamente em Windows e Linux
    {$IFDEF MSWINDOWS}
    SSLXmlSignLib := xsLibXml2;
    {$ELSE}
    {$IFDEF Linux}
    SSLXmlSignLib := xsLibXml2;//SSLXmlSignLib := xsXmlSec;
    {$ENDIF}
    {$ENDIF}
    {$IFDEF MSWINDOWS}
    // Configuração otimizada para Windows (usa as APIs nativas do sistema)
    SSLLib := libWinCrypt;
    SSLCryptLib := cryWinCrypt;
    SSLHttpLib := httpWinHttp;
    {$ELSE}
    // Configuração obrigatória para Linux / Docker (usa OpenSSL)
    SSLLib        := libOpenSSL;
    SSLCryptLib   := cryOpenSSL;
    SSLHttpLib    := httpOpenSSL;
    {$ENDIF}
  end;

  // ADICIONE ESTA LINHA OBRIGATORIAMENTE PARA TIRAR AS JANELAS DE MENSAGEM
  ACBrNFe1.Configuracoes.WebServices.Visualizar := False;

  with ACBrNFe1.Configuracoes.Certificados do
  begin
    URLPFX      := '';
    {$IFDEF WINDOWS}
    ArquivoPFX  := 'C:\FreeNFe\Certificados\MARGARIDA PIRES DA CHAO E OUTRO_09167426000109.pfx';
    {$ELSE}
    {$IFDEF Linux}
    ArquivoPFX  := ExtractFile Path(ParamStr(0))+'cert/MARGARIDA PIRES DA CHAO E OUTRO_09167426000109.pfx';
    {$ENDIF}
    {$ENDIF}
    Senha       := '123456';
    //NumeroSerie := '00a8548246980eb1834a55';
  end;

//  ACBrNFe1.DANFE := ACBrNFeDANFe; //ACBrNFeDANFeFPDF1;//

  with ACBrNFe1.Configuracoes.Arquivos do
  begin
    Salvar           := True;
    SepararPorMes    := True;
    AdicionarLiteral := False;
    EmissaoPathNFe   := True;
    SalvarEvento     := True;
    //SepararPorCNPJ   := True;  // <<<------<<< comentado devido ao caminho do FreeNFe
    SepararPorModelo := True;
    {$IFDEF WINDOWS}
    PathSchemas      := ExtractFilePath(ParamStr(0))+'Schemas' + PathDelim + 'NFe';
    //PathNFe          := ExtractFilePath(ParamStr(0))+'NFe';  // <<<------<<< comentado devido ao caminho do FreeNFe
    PathInu          := ExtractFilePath(ParamStr(0))+'Inutilizacao';
    PathEvento       := ExtractFilePath(ParamStr(0))+'Evento';
//    PathMensal       := ExtractFilePath(ParamStr(0))+'NFe';
    PathSalvar       := ExtractFilePath(ParamStr(0))+'Logs';
    {$ELSE}
    {$IFDEF Linux}
    PathSchemas      := ExtractFilePath(ParamStr(0))+'Schemas' + PathDelim + 'NFe';
    PathNFe          := ExtractFilePath(ParamStr(0))+'NFe';
    PathInu          := ExtractFilePath(ParamStr(0))+'Inutilizacao';
    PathEvento       := ExtractFilePath(ParamStr(0))+'Evento';
//    PathMensal       := ExtractFilePath(ParamStr(0))+'NFe';
    PathSalvar       := ExtractFilePath(ParamStr(0))+'Logs';
    {$ENDIF}
    {$ENDIF}
  end;

  with ACBrNFe1.Configuracoes.WebServices do
  begin
    UF         := 'SP';
    Ambiente   := AAmbiente;
    Visualizar := False;    //FALSE para console
    Salvar     := True;
    TimeOut    := 5000;
    AjustaAguardaConsultaRet := True;
    Tentativas := 5;
    QuebradeLinha := ';';
  end;
end;

procedure CancelarNFe(const NumNFe: Integer; const MotivoUsuario: String; const AAmbiente: TACBrTipoAmbiente; var Cancelamento: TCancelamento);
var
  JustificativaLegal: String;
  CaminhoXMLOriginal: String;
  ACBrNFe1: TACBrNFe; // unit ACBrNFe
  ConteudoXML: string;
begin
  // Concatena o motivo do usuário com a declaração exigida pela legislação
  JustificativaLegal := 'Declaramos que nao houve circulacao de mercadoria - ' + Trim(MotivoUsuario);

  // Trunca em 255 caracteres para evitar rejeição de schema da SEFAZ
  if Length(JustificativaLegal) > 255 then
    JustificativaLegal := Copy(JustificativaLegal, 1, 255);

  ACBrNFe1 := TACBrNFe.Create(Nil);
  try
    ConfiguracoesPadraoNFe(ACBrNFe1, AAmbiente);
    GetDadosNFe(NumNFe, Cancelamento);

    // Define a variável com o caminho físico do XML
    CaminhoXMLOriginal := FREENFEXMLPATH + ObterAnoMes(Cancelamento.DataEmissao) + '\' + Cancelamento.Chave + '-nfe.xml';  //'C:\Users\ASUSTUFI56600K\Desktop\ProjetoNFe\ProjetoNFe\EmissaoNFe\executables\i386-win32\NFe\09167426000109\NFe\202606\' + Cancelamento.Chave + '-nfe.xml';
    ACBrNFe1.Configuracoes.Arquivos.PathNFe := FREENFEXMLPATH;

    // Trava de segurança: Garante que o arquivo físico realmente existe antes de prosseguir
    if not FileExists(CaminhoXMLOriginal) then
      raise Exception.Create('Falha ao cancelar: O arquivo XML original não foi encontrado no disco: ' + CaminhoXMLOriginal);

//---> não existe    ACBrNFe1.Configuracoes.Arquivos.AtualizarXMLCancelado := True;

    ACBrNFe1.NotasFiscais.Clear;
    ACBrNFe1.NotasFiscais.LoadFromFile(CaminhoXMLOriginal); //comentei para teste

    WriteLn('Arquivo a ser alterado apos cancelamento: ' + CaminhoXMLOriginal);
    LogToFile('Arquivo a ser alterado apos cancelamento: ' + CaminhoXMLOriginal);

    ACBrNFe1.EventoNFe.Evento.Clear;
    with ACBrNFe1.EventoNFe.Evento.Add do
    begin
      {NO CANCELAMENTO POR XML, CHAVE, CNPJ,SEQUENCIA E PROTOCOLO NÃO SÃO NECESSÁRIOS}
      //infEvento.chNFe     := Cancelamento.Chave;
      //infEvento.CNPJ      := GetCNPJ; // Aqui, certifique-se de que retorna apenas números
      infEvento.dhEvento  := Now;
      infEvento.tpEvento  := teCancelamento;
      //infEvento.nSeqEvento := 1;
      infEvento.detEvento.xJust := JustificativaLegal; // Justificativa blindada
      //infEvento.detEvento.nProt := Cancelamento.ProtocoloEnvio;
    end;

    // Envia o lote de evento
    ACBrNFe1.EnviarEvento(1);

    // Mapeamento de retorno
    Cancelamento.RetWS := ACBrNFe1.WebServices.EnvEvento.RetWS;
    Cancelamento.RetornoWS := ACBrNFe1.WebServices.EnvEvento.RetornoWS;

    if ACBrNFe1.WebServices.EnvEvento.EventoRetorno.retEvento.Count > 0 then
    begin
      Cancelamento.ProtocoloRetorno := ACBrNFe1.WebServices.EnvEvento.EventoRetorno.retEvento[0].RetInfEvento.nProt;
      Cancelamento.Id := ACBrNFe1.WebServices.EnvEvento.EventoRetorno.retEvento[0].RetInfEvento.Id;
      Cancelamento.tpAmb := ACBrNFe1.WebServices.EnvEvento.EventoRetorno.retEvento[0].RetInfEvento.TpAmb;
      Cancelamento.verAplic := ACBrNFe1.WebServices.EnvEvento.EventoRetorno.retEvento[0].RetInfEvento.verAplic;
      Cancelamento.cOrgao := ACBrNFe1.WebServices.EnvEvento.EventoRetorno.retEvento[0].RetInfEvento.cOrgao;
      Cancelamento.cStat := ACBrNFe1.WebServices.EnvEvento.EventoRetorno.retEvento[0].RetInfEvento.cStat;
      Cancelamento.xMotivo := ACBrNFe1.WebServices.EnvEvento.EventoRetorno.retEvento[0].RetInfEvento.xMotivo;
      Cancelamento.chNFe := ACBrNFe1.WebServices.EnvEvento.EventoRetorno.retEvento[0].RetInfEvento.chNFe;
      Cancelamento.tpEvento := ACBrNFe1.WebServices.EnvEvento.EventoRetorno.retEvento[0].RetInfEvento.tpEvento;
      Cancelamento.xEvento := ACBrNFe1.WebServices.EnvEvento.EventoRetorno.retEvento[0].RetInfEvento.xEvento;
      Cancelamento.nSeqEvento := ACBrNFe1.WebServices.EnvEvento.EventoRetorno.retEvento[0].RetInfEvento.nSeqEvento;
      Cancelamento.CNPJDest := ACBrNFe1.WebServices.EnvEvento.EventoRetorno.retEvento[0].RetInfEvento.CNPJDest;
      Cancelamento.emailDest := ACBrNFe1.WebServices.EnvEvento.EventoRetorno.retEvento[0].RetInfEvento.emailDest;
      Cancelamento.dhRegEvento := ACBrNFe1.WebServices.EnvEvento.EventoRetorno.retEvento[0].RetInfEvento.dhRegEvento;



      //DuplicateAndRename(CaminhoXMLOriginal);
      CopyInUseFile(CaminhoXMLOriginal);

      // O PULO DO GATO: Se a SEFAZ homologou o cancelamento (135 = no prazo, 155 = fora do prazo)
      if (Cancelamento.cStat = 135) or (Cancelamento.cStat = 155) then
      begin
         // 1. Injetamos manualmente o status de cancelamento no objeto NFe carregado
         ACBrNFe1.NotasFiscais.Items[0].NFe.procNFe.cStat    := Cancelamento.cStat;
         ACBrNFe1.NotasFiscais.Items[0].NFe.procNFe.xMotivo  := Cancelamento.xMotivo;
         ACBrNFe1.NotasFiscais.Items[0].NFe.procNFe.dhRecbto := Cancelamento.dhRegEvento;
         ACBrNFe1.NotasFiscais.Items[0].NFe.procNFe.nProt    := Cancelamento.ProtocoloRetorno;

         // 2. Limpamos o cache do XML velho que foi lido do disco
         ACBrNFe1.NotasFiscais.Items[0].XMLOriginal := '';

         // 3. Forçamos o componente a remontar a estrutura do XML com os novos dados (101)
         ACBrNFe1.NotasFiscais.Items[0].GerarXML;

         // 4. Agora sim, salvamos por cima do arquivo físico
         ACBrNFe1.NotasFiscais.Items[0].GravarXML(CaminhoXMLOriginal);


         if ACBrNFe1.Consultar then
         begin
           ConteudoXML := XMLParaString(CaminhoXMLOriginal);
           //ACBrNFe1.NotasFiscais.Items[0].GravarXML(Cancelamento.Chave + '-cancelamento-nfe.xml', 'C:\Users\ASUSTUFI56600K\Desktop\ProjetoNFe\ProjetoNFe\EmissaoNFe\executables\i386-win32\NFe\09167426000109\NFe\202606\');

           WriteLn('--------------------------------------------------');
           WriteLn('Caminho do arquivo xml a ser salvo no banco:');
           WriteLn(CaminhoXMLOriginal);
           WriteLn('--------------------------------------------------');

           LogToFile('--------------------------------------------------');
           LogToFile('Conteudo do novo xml a ser salvo no banco:');
           LogToFile(ConteudoXML);
           LogToFile('--------------------------------------------------');
         end;
      end;
      SetSummaryData(NumNFe);
      SetCancelada(NumNFe, ConteudoXML);
    end;
  finally
    ACBrNFe1.Free;
  end;
end;

function GetCNPJ: string;
begin
  Result := '09167426000109'; //09167426000109
end;

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
  cSQLNFE_DBG = 'UPDATE NFE_DBG SET NFE_SITUACAO = ''4'', NFE_XML = :NFEXML WHERE IDE_NNF = :NUMNFE;';
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

