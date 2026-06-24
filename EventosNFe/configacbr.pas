unit ConfigACBr;

{$mode ObjFPC}{$H+}

interface

uses
  Classes
  , SysUtils
  , ACBrNFe
  , ACBrDFe.Conversao
  , ACBrNFe.Classes
  , ACBrDFeUtil
  , ACBrDFeSSL
  , FileLoggerUnit
  , Utils
  , DTOs
  ;

const
  FREENFEXMLPATH = 'C:\FreeNFe\09167426000109\NFE\';

procedure ConfiguracoesPadraoNFe(ACBrNFe1: TACBrNFe; AAmbiente: TACBrTipoAmbiente);

implementation



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

end.

