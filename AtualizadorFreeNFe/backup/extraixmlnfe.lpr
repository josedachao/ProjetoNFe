program ExtraiXMLNFe;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cwstring,
  {$ENDIF}
  Classes, SysUtils, XMLRead, DOM, IBConnection, SQLDB, db;

var
  CaminhoXML: String;
  XMLDoc: TXMLDocument;
  NodeList: TDOMNodeList;
  Node: TDOMNode;

  // Variáveis para os dados do XML
  Chave, Protocolo, NumNF: String;
  DataHoraDB: TDateTime;
  ConteudoXML: TStringList;
  ChaveAtualNoBanco: String;

  // Componentes de Banco de Dados
  Conexao: TIBConnection;
  Transacao: TSQLTransaction;
  Query: TSQLQuery;

// Função auxiliar para buscar o texto de uma Tag XML por nome
function ObterTextoTag(ANode: TDOMNode; const NomeTag: String): String;
var
  Lista: TDOMNodeList;
begin
  Result := '';
  if Assigned(ANode) then
  begin
    if ANode is TDOMDocument then
      Lista := TDOMDocument(ANode).GetElementsByTagName(NomeTag)
    else if ANode is TDOMElement then
      Lista := TDOMElement(ANode).GetElementsByTagName(NomeTag)
    else
      Exit;

    if (Lista.Count > 0) and Assigned(Lista.Item[0]) and Assigned(Lista.Item[0].FirstChild) then
      Result := Lista.Item[0].FirstChild.NodeValue;
  end;
end;

// Converte a string do XML diretamente em um TDateTime nativo do Pascal
function ExtrairDataHoraNativa(DataXML: String): TDateTime;
var
  Ano, Mes, Dia, Hora, Min, Seg: Word;
begin
  Result := 0;
  if Length(DataXML) >= 19 then
  begin
    Ano := StrToIntDef(Copy(DataXML, 1, 4), 2026);
    Mes := StrToIntDef(Copy(DataXML, 6, 2), 1);
    Dia := StrToIntDef(Copy(DataXML, 9, 2), 1);
    Hora := StrToIntDef(Copy(DataXML, 12, 2), 0);
    Min := StrToIntDef(Copy(DataXML, 15, 2), 0);
    Seg := StrToIntDef(Copy(DataXML, 18, 2), 0);

    Result := EncodeDate(Ano, Mes, Dia) + EncodeTime(Hora, Min, Seg, 0);
  end;
end;

begin
  // 1. Validação do Parâmetro de Entrada
  if ParamCount < 1 then
  begin
    Writeln('ERRO: Informe o caminho completo do arquivo XML como parametro.');
    ExitCode := 1;
    Exit;
  end;

  CaminhoXML := ParamStr(1);

  if not FileExists(CaminhoXML) then
  begin
    Writeln('ERRO: O arquivo XML informado nao foi encontrado.');
    ExitCode := 2;
    Exit;
  end;

  ConteudoXML := TStringList.Create;
  Conexao := TIBConnection.Create(nil);
  Transacao := TSQLTransaction.Create(nil);
  Query := TSQLQuery.Create(nil);

  try
    // 2. Carregamento e Leitura do XML
    try
      ConteudoXML.LoadFromFile(CaminhoXML);
      ReadXMLFile(XMLDoc, CaminhoXML);

      NodeList := XMLDoc.GetElementsByTagName('infNFe');
      if (NodeList.Count > 0) then
      begin
        Node := NodeList.Item[0];
        if Assigned(Node) and Assigned(Node.Attributes) then
        begin
          Chave := TDOMElement(Node).GetAttribute('Id');
          if Pos('NFe', Chave) = 1 then
            Delete(Chave, 1, 3);
        end;
      end;

      NumNF      := ObterTextoTag(XMLDoc, 'nNF');
      Protocolo  := ObterTextoTag(XMLDoc, 'nProt');
      DataHoraDB := ExtrairDataHoraNativa(ObterTextoTag(XMLDoc, 'dhRecbto'));

      XMLDoc.Free;
    except
      on E: Exception do
      begin
        Writeln('ERRO ao ler ou processar o arquivo XML: ' + E.Message);
        ExitCode := 3;
        Exit;
      end;
    end;

    if (NumNF = '') or (Chave = '') or (Protocolo = '') or (DataHoraDB = 0) then
    begin
      Writeln('ERRO: Nao foi possivel extrair todos os dados obrigatorios do XML.');
      ExitCode := 4;
      Exit;
    end;

    // 3. Configuração da Conexão com o Firebird 2.5
    Conexao.DatabaseName := 'C:\FreeNFe\Banco\HMNFE.FDB';
    Conexao.UserName     := 'SYSDBA';
    Conexao.Password     := 'masterkey';
    Conexao.CharSet      := 'ISO8859_1';
    Conexao.Transaction  := Transacao;
    Transacao.Database   := Conexao;
    Query.Database       := Conexao;
    Query.Transaction    := Transacao;

    // 4. Fluxo de Banco de Dados
    try
      Conexao.Open;
      Transacao.StartTransaction;

      // ---- UPGRADE: Verificação prévia da Chave atual ----
      Query.SQL.Clear;
      Query.SQL.Add('SELECT NFE_CHAVE FROM NFE WHERE IDE_NNF = :NUM_NF');
      Query.ParamByName('NUM_NF').DataType := ftString;
      Query.Prepare;
      Query.ParamByName('NUM_NF').AsString := NumNF;
      Query.Open;

      if Query.EOF then
      begin
        Transacao.Rollback;
        Writeln(Format('AVISO: O numero de nota %s nao foi localizado na tabela NFE.', [NumNF]));
        ExitCode := 6; // Mantém o código 6 para o lote saber que não existe no banco
        Exit;
      end;

      ChaveAtualNoBanco := Trim(Query.FieldByName('NFE_CHAVE').AsString);
      Query.Close; // Fecha o SELECT para liberar o componente para o UPDATE

      // Se a chave já existir (não for nula nem vazia), ignora o update e simula sucesso
      if ChaveAtualNoBanco <> '' then
      begin
        Transacao.Commit; // Fecha a transação de leitura com segurança
        Writeln(Format('AVISO: Nota Numero %s ja possui chave gravada (%s). Operacao pulada.', [NumNF, ChaveAtualNoBanco]));
        ExitCode := 0; // Código 0 ativa o "move" do arquivo no .bat
        Exit;
      end;
      // ----------------------------------------------------

      // 5. Execução do comando SQL (Apenas se o campo estiver vazio)
      Query.SQL.Clear;
      Query.SQL.Add('UPDATE NFE SET ');
      Query.SQL.Add('  NFE_CHAVE = :CHAVE, ');
      Query.SQL.Add('  NFE_PROTOCOLO = :PROTOCOLO, ');
      Query.SQL.Add('  NFE_DT_PROTOCOLO = :DATA_PROT, ');
      Query.SQL.Add('  NFE_SITUACAO = :SITUACAO, ');
      Query.SQL.Add('  NFE_XML = :XML, ');
      Query.SQL.Add('  DANFE_IMPRESSO = :DANFE, ');
      Query.SQL.Add('  XML_ENVIADO = :ENVIADO ');
      Query.SQL.Add('WHERE IDE_NNF = :NUM_NF');

      Query.ParamByName('CHAVE').DataType     := ftString;
      Query.ParamByName('PROTOCOLO').DataType := ftString;
      Query.ParamByName('DATA_PROT').DataType := ftDateTime;
      Query.ParamByName('SITUACAO').DataType  := ftSmallint;
      Query.ParamByName('XML').DataType       := ftMemo;
      Query.ParamByName('DANFE').DataType     := ftInteger;
      Query.ParamByName('ENVIADO').DataType   := ftInteger;
      Query.ParamByName('NUM_NF').DataType    := ftString;

      Query.Prepare;

      Query.ParamByName('CHAVE').AsString       := Chave;
      Query.ParamByName('PROTOCOLO').AsString   := Protocolo;
      Query.ParamByName('DATA_PROT').AsDateTime := DataHoraDB;
      Query.ParamByName('SITUACAO').AsInteger   := 3;
      Query.ParamByName('XML').AsString         := ConteudoXML.Text;
      Query.ParamByName('DANFE').AsInteger      := 1;
      Query.ParamByName('ENVIADO').AsInteger    := 1;
      Query.ParamByName('NUM_NF').AsString      := NumNF;

      Query.ExecSQL;

      Transacao.Commit;
      Writeln(Format('SUCESSO: Nota Numero %s atualizada com exito.', [NumNF]));
      ExitCode := 0;

    except
      on E: Exception do
      begin
        if Transacao.Active then
          Transacao.Rollback;
        Writeln('ERRO ao atualizar o Banco de Dados Firebird: ' + E.Message);
        ExitCode := 5;
      end;
    end;

  finally
    ConteudoXML.Free;
    Query.Free;
    Transacao.Free;
    Conexao.Free;
  end;
end.

