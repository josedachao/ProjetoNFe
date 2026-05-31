unit EmissaoNFe;

{$mode ObjFPC}{$H+}

interface

uses
  Classes
  , SysUtils
  , ACBrDFeException
  , ACBrNFeNotasFiscais
  , ACBrNFe.Classes
  , ACBrNFe
  , pcnConversaoNFe
  , ACBrDFeUtil
  , ACBrDFe.Conversao
//  , ACBrNFeDANFeRLClass
  , ACBrNFeDANFeFPDF
  , ACBrMail
  , SynHighlighterXML
  , ACBrDFeSSL
  , uDBService
  , geracaonfeteste
  , FileLoggerUnit
  ;

procedure EmitirNFe(AAmbiente: TACBrTipoAmbiente; NumNFe: Integer);

implementation

var
  ACBrNFe1: TACBrNFe; //unit ACBrNFe
  ACBrNFeDANFeRL1: TACBrNFeDANFeFPDF;  //unit ACBrNFeDANFeRLClass
  ACBrMail1: TACBrMail;  //unit ACBrMail
  SynXMLSyn1: TSynXMLSyn;  //unit SynHighlighterXML

procedure ConfigurarEmail;
begin
  ACBrMail1.Host := 'smtp.gmail.com';
  ACBrMail1.Port := '465';
  ACBrMail1.Username := 'cogumelosdachao@gmail.com';
  ACBrMail1.Password := 'gabriela15jur06';
  ACBrMail1.From := 'cogumelosdachao@gmail.com';
  ACBrMail1.SetSSL := True; // SSL - Conexao Segura
  ACBrMail1.SetTLS := True; // Auto TLS
  ACBrMail1.ReadingConfirmation := False; // Pede confirmacao de leitura do email
  ACBrMail1.UseThread := False;           // Aguarda Envio do Email(nao usa thread)
  ACBrMail1.FromName := 'Cogumelos da Chão';
end;

procedure ConfiguracoesPadraoNFe(AAmbiente: TACBrTipoAmbiente);
begin
  with ACBrNFe1.Configuracoes.Geral do
  begin
    ModeloDF := moNFe;
    SSLLib := libWinCrypt;
    SSLCryptLib := cryWinCrypt;
    SSLHttpLib := httpWinHttp;
    SSLXmlSignLib := xsLibXml2;
    ExibirErroSchema := False;
    FormatoAlerta := 'Campo:%DESCRICAO% - %MSG%';
  end;

  // ADICIONE ESTA LINHA OBRIGATORIAMENTE PARA TIRAR AS JANELAS DE MENSAGEM
  ACBrNFe1.Configuracoes.WebServices.Visualizar := False;

  with ACBrNFe1.Configuracoes.Certificados do
  begin
    URLPFX      := '';
    ArquivoPFX  := 'C:\FreeNFe\Certificados\MARGARIDA PIRES DA CHAO E OUTRO_09167426000109.pfx';
    Senha       := '123456';
    //NumeroSerie := '00a8548246980eb1834a55';
  end;

  ACBrNFe1.DANFE := ACBrNFeDANFeRL1; //ACBrNFeDANFeFPDF1;//

  with ACBrNFe1.Configuracoes.Arquivos do
  begin
    Salvar           := True;
    SepararPorMes    := True;
    AdicionarLiteral := False;
    EmissaoPathNFe   := True;
    SalvarEvento     := True;
    SepararPorCNPJ   := True;
    SepararPorModelo := True;
    PathSchemas      := ExtractFilePath(ParamStr(0))+'Schemas\NFe';
    PathNFe          := ExtractFilePath(ParamStr(0))+'\NFe';
    PathInu          := ExtractFilePath(ParamStr(0))+'\Inutilizacao';
    PathEvento       := ExtractFilePath(ParamStr(0))+'\Evento';
//    PathMensal       := ExtractFilePath(ParamStr(0))+'\NFe';
    PathSalvar       := ExtractFilePath(ParamStr(0))+'\Logs';
  end;

  with ACBrNFe1.Configuracoes.WebServices do
  begin
    UF         := 'SP';
    Ambiente := AAmbiente;
    Visualizar := False;    //FALSE para console
    Salvar     := True;
    TimeOut    := 5000;
    AjustaAguardaConsultaRet := True;
    Tentativas := 5;
  end;
end;

procedure GerarNFe(NumNFe: string);
var
  NotaF: NotaFiscal;
begin
  if ConnectNFE then WriteLn('Conectado ao Banco de Dados');
  if NumNFe <> '' then
  begin
    AlimentarNFE(ACBrNFe1, NumNFe, ACBrNFe1.Configuracoes.WebServices.Ambiente);
    ACBrNFe1.NotasFiscais.GerarNFe;
    ACBrNFe1.NotasFiscais.Assinar;
    ACBrNFe1.NotasFiscais.Validar;
    NotaF := ACBrNFe1.NotasFiscais.Items[0];
    NotaF.GravarXML();
    try
      if NotaF.NFe.Ide.modelo = 55 then
        ACBrNFe1.Enviar(1, False, True, True)
      else
        ACBrNFe1.Enviar(1, False, True);
      // Validação correta após o envio:
      if NotaF.Confirmada then
      begin
        WriteLn('SUCESSO! NFe Autorizada.');
        LogToFile('SUCESSO! NFe Autorizada.');
        // Se você precisar gerar o PDF silenciosamente, o comando é este:
      // ACBrNFe1.NotasFiscais.Items[0].ImprimirPDF;
      end
      else
      begin
        WriteLn('ATENÇÃO: NFe enviada, mas não foi confirmada.');
        LogToFile('ATENÇÃO: NFe enviada, mas não foi confirmada.');
      end;
      WriteLn('Chave de acesso: ' + NotaF.NFe.procNFe.chNFe);
      WriteLn('Código Status: ' + IntToStr(NotaF.NFe.procNFe.cStat));
      WriteLn('Motivo: ' + NotaF.NFe.procNFe.xMotivo);
      LogToFile('Chave de acesso: ' + NotaF.NFe.procNFe.chNFe);
      LogToFile('Código Status: ' + IntToStr(NotaF.NFe.procNFe.cStat));
      LogToFile('Motivo: ' + NotaF.NFe.procNFe.xMotivo);
    except
      on E: EACBrDFeException do
      begin
        WriteLn('--------------------------------------------------');
        WriteLn('ERRO DURANTE O ENVIO DA NFE:');
        WriteLn(E.Message);
        WriteLn('--------------------------------------------------');
        LogToFile('--------------------------------------------------');
        LogToFile('ERRO DURANTE O ENVIO DA NFE:');
        LogToFile(E.Message);
        LogToFile('--------------------------------------------------');
        // Captura o código numérico (Ex: 232)
        WriteLn('Código do Erro SEFAZ: ' + IntToStr(ACBrNFe1.WebServices.Enviar.cStat));
        LogToFile('Código do Erro SEFAZ: ' + IntToStr(ACBrNFe1.WebServices.Enviar.cStat));
        // Captura a descrição textual
        WriteLn('Motivo da Rejeição: ' + ACBrNFe1.WebServices.Enviar.xMotivo);
        LogToFile('Motivo da Rejeição: ' + ACBrNFe1.WebServices.Enviar.xMotivo);
      end;
      on E: Exception do // Captura qualquer erro, inclusive Access Violation
      begin
        WriteLn('--------------------------------------------------');
        WriteLn('ERRO DURANTE O ENVIO DA NFE:');
        WriteLn(E.Message);
        WriteLn('--------------------------------------------------');
        LogToFile('--------------------------------------------------');
        LogToFile('ERRO DURANTE O ENVIO DA NFE:');
        LogToFile(E.Message);
        LogToFile('--------------------------------------------------');
        // Só tenta imprimir os dados se Sefaz chegou a retornar algo
        if NotaF.NFe.procNFe.cStat > 0 then
        begin
          WriteLn('Código Sefaz: ' + IntToStr(NotaF.NFe.procNFe.cStat));
          WriteLn('Motivo Sefaz: ' + NotaF.NFe.procNFe.xMotivo);
        end;
        raise;
      end;
    end;
  end;
end;

procedure EmitirNFe(AAmbiente: TACBrTipoAmbiente; NumNFe: Integer);
begin
  ConfigurarEmail;
  ConfiguracoesPadraoNFe(AAmbiente);
  GerarNFe(IntToStr(NumNFe));
end;

initialization
  ACBrNFe1 := TACBrNFe.Create(Nil);
  ACBrNFeDANFeRL1 := TACBrNFeDANFeFPDF.Create(Nil);
  //ACBrNFeDANFeRL1 := TACBrNFeDANFeRL.Create(Nil);
  //ACBrNFeDANFeRL1.MostraSetup    := False;
  //ACBrNFeDANFeRL1.InterfaceEps   := False; // Evita carregar fontes de tela
  ACBrNFeDANFeRL1.ACBrNFe := ACBrNFe1;
  ACBrNFe1.DANFE := ACBrNFeDANFeRL1;
  ACBrMail1 := TACBrMail.Create(Nil);
  SynXMLSyn1 := TSynXMLSyn.Create(Nil);

finalization
  ACBrNFe1.Free;
  ACBrNFeDANFeRL1.Free;
  ACBrMail1.Free;
  SynXMLSyn1.Free;

end.

