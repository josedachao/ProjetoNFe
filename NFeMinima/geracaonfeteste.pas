unit geracaonfeteste;

{$mode ObjFPC}{$H+}

interface

uses
  Classes
  , SysUtils
  , ACBrNFeNotasFiscais
  , ACBrNFe.Classes
  , ACBrNFe
  , pcnConversaoNFe
  , ACBrDFeUtil
  , ACBrDFe.Conversao
  , uDBService
  , ACBrUtil.Base
  , FileLoggerUnit
  ;

procedure AlimentarNFe(ACBrNFe1: TACBrNFe; NumDFe: String; AAmbiente: TACBrTipoAmbiente);
procedure IdentificacaoNFeReforma(var NotaF: NotaFiscal);
procedure PreencherDadosBasicos(var NotaF: NotaFiscal; const NumDFe: string; const DadosGerais: TDadosGeraisNFe; AAmbiente: TACBrTipoAmbiente);
procedure PreencherDadosNotaReferenciada(var NotaF: NotaFiscal);
procedure PreencherDadosReformaTributariaItemNFe(var NotaF: NotaFiscal; const TotalItem: string);
procedure PreencherEmitente(var NotaF: NotaFiscal);
procedure PreencherDestinatario(var NotaF: NotaFiscal; const Cliente: TClienteResultado);
procedure PreencherEnderecoEntrega(var NotaF: NotaFiscal; const Cliente: TClienteResultado);
procedure AdicionarProdutos(var NotaF: NotaFiscal; var Produto: TDetCollectionItem; const NumItem: Integer; const Prod: TProdutoResultado);
procedure AnotacoesRegimeNormal(var NotaF: NotaFiscal);
procedure AnotacoesTribDiversas(var NotaF: NotaFiscal; const DadosGerais: TDadosGeraisNFe);

implementation

uses
  DateUtils;

const
  ccProd = '13';
  cxProd = 'COGUMELOS PORTOBELLO 200G BANDEJAS';
  cNCM = '07095100';
  cqCom = 1;
  cvUCom = 5.9;
  cvProd = 5.9;
  cqTrib = 1;
  cvUnTrib = 5.9;

procedure AlimentarNFe(ACBrNFe1: TACBrNFe; NumDFe: String; AAmbiente: TACBrTipoAmbiente);
var
  Ok: Boolean;
  NotaF: NotaFiscal;  //unit ACBrNFeNotasFiscais
  Produto: TDetCollectionItem;
  Volume: TVolCollectionItem;
  Duplicata: TDupCollectionItem;
  ObsComplementar: TobsContCollectionItem;
  ObsFisco: TobsFiscoCollectionItem;
  InfoPgto: TpagCollectionItem;
  Cliente: TClienteResultado;
  Prod: TProdutoResultado;
  NumItens: Integer = 0;
  i: Integer = 0;
  DadosGerais: TDadosGeraisNFe;
begin
  ACBrNFe1.NotasFiscais.Clear;
  NotaF := ACBrNFe1.NotasFiscais.Add;
  DadosGerais :=  GetDadosGeraisNFe(StrToInt(NumDFe));
  PreencherDadosBasicos(NotaF, NumDFe, DadosGerais, AAmbiente);
  IdentificacaoNFeReforma(NotaF);
  PreencherEmitente(NotaF);
  Cliente := GetClient(StrToInt(NumDFe));
  PreencherDestinatario(NotaF, Cliente);
  PreencherDadosNotaReferenciada(NotaF);
  NumItens := GetNumItens(Cliente.idNFE);
  if NumItens > 0 then
  begin
    for i := 0 to NumItens - 1 do
    begin
      Prod := GetItem(Cliente.idNFE, (i + 1));
      Produto := NotaF.NFe.Det.New;
      AdicionarProdutos(NotaF, Produto, (i + 1), Prod);
    end;
  end;

  PreencherDadosReformaTributariaItemNFe(NotaF, '');
  AnotacoesRegimeNormal(NotaF);
  AnotacoesTribDiversas(NotaF, DadosGerais);

  ACBrNFe1.NotasFiscais.GerarNFe;

  //ACBrNFe1.NotasFiscais.Assinar;

  ACBrNFe1.NotasFiscais.Items[0].GravarXML();

 // ACBrNFe1.Enviar(1, False, True, True);
end;

procedure IdentificacaoNFeReforma(var NotaF: NotaFiscal);
begin
  NotaF.NFe.Ide.cMunFGIBS := 3538204;
  NotaF.NFe.Ide.finNFe := fnNormal;
  NotaF.NFe.Ide.tpNFCredito := tcNenhum;
end;

procedure PreencherDadosBasicos(var NotaF: NotaFiscal; const NumDFe: string; const DadosGerais: TDadosGeraisNFe; AAmbiente: TACBrTipoAmbiente);
begin
  NotaF.NFe.Ide.natOp     := DadosGerais.Ide_natOp;//'Venda de produção do estabelecimento';
  if CompareDate(DadosGerais.Duplicata_dVenc, Date) = 0 then
    NotaF.NFe.Ide.indPag    := ipVista
  else
    NotaF.NFe.Ide.indPag    := ipPrazo;
//  NotaF.NFe.Ide.indPag    := ipPrazo;  //ipVista, ipPrazo, ipOutras, ipNenhum
  NotaF.NFe.Ide.modelo    := 55;
  NotaF.NFe.Ide.serie     := 1;
  NotaF.NFe.Ide.nNF       := StrToInt(NumDFe);
  NotaF.NFe.Ide.cNF       := GerarCodigoDFe(NotaF.NFe.Ide.nNF);  //código aleatório de 8 digitos
  if DadosGerais.UF_OPER = 'SP' then
    NotaF.NFe.Ide.idDest    := doInterna
  else
    NotaF.NFe.Ide.idDest    := doInterestadual; //doInterna, doInterestadual, doExterior;
  NotaF.NFe.Ide.dEmi      := Date;
  NotaF.NFe.Ide.tpNF      := tnSaida;   //tipo da NFe: entrada ou saída
  NotaF.NFe.Ide.tpEmis    := teNormal;  //teContingencia, teSCAN...
  NotaF.NFe.Ide.tpAmb     := AAmbiente;//taHomologacao;//taProducao; //taHomologacao;  //Lembre-se de trocar esta variável quando for para ambiente de produção
  NotaF.NFe.Ide.verProc   := '1.0.0.0'; //Versão do seu sistema
  NotaF.NFe.Ide.cUF       := UFparaCodigoUF('SP');  //unit: pcnConversao
  NotaF.NFe.Ide.cMunFG    := StrToInt('3538204');  //código município de Pinhalzinho
  NotaF.NFe.Ide.finNFe    := fnNormal;   //fnNormal, fnComplementar, fnAjuste, fnDevolucao, fnCredito, fnDebito
  NotaF.NFe.Ide.indPres   := pcTeleatendimento;
  NotaF.NFe.Ide.indIntermed := iiOperacaoSemIntermediador;   //O campo indIntermed é obrigatório se o indicador de presença (indPres) for 2 (não presencial, pela Internet), 3 (teleatendimento), 4 (NFC-e com entrega a domicílio) ou 9 (não presencial, outros).
end;

procedure PreencherDadosNotaReferenciada(var NotaF: NotaFiscal);
begin
  //nada a fazer
end;

procedure PreencherDadosReformaTributariaItemNFe(var NotaF: NotaFiscal; const TotalItem: string);
begin

end;

procedure PreencherEmitente(var NotaF: NotaFiscal);
begin
    NotaF.NFe.Emit.CNPJCPF           := '09.167.426/0001-09';
    NotaF.NFe.Emit.IE                := '531064575110';
    NotaF.NFe.Emit.xNome             := 'MARGARIDA PIRES DA CHAO E OUTRO';
    NotaF.NFe.Emit.xFant             := 'COGUMELOS DA CHAO';

    NotaF.NFe.Emit.EnderEmit.fone    := '11-940639527';
    NotaF.NFe.Emit.EnderEmit.CEP     := StrToInt('12995000');
    NotaF.NFe.Emit.EnderEmit.xLgr    := 'EST BAIRRO POSSE';
    NotaF.NFe.Emit.EnderEmit.nro     := 'S/N';
    NotaF.NFe.Emit.EnderEmit.xCpl    := '';
    NotaF.NFe.Emit.EnderEmit.xBairro := 'POSSE';
    NotaF.NFe.Emit.EnderEmit.cMun    := StrToInt('3538204');
    NotaF.NFe.Emit.EnderEmit.xMun    := 'PINHALZINHO';
    NotaF.NFe.Emit.EnderEmit.UF      := 'SP';
    NotaF.NFe.Emit.enderEmit.cPais   := 1058;
    NotaF.NFe.Emit.enderEmit.xPais   := 'BRASIL';

    //NotaF.NFe.Emit.IEST              := '';   //INSC. EST. DO SUBST. TRIBUTÁRIO
    //NotaF.NFe.Emit.IM                := '2648800'; // Preencher no caso de existir serviços na nota
    //NotaF.NFe.Emit.CNAE              := '6201500'; // Verifique na cidade do emissor da NFe se é permitido
                                                   // a inclusão de serviços na NFe

      // esta sendo somando 1 uma vez que o ItemIndex inicia do zero e devemos
      // passar os valores 1, 2 ou 3
      // (1-crtSimplesNacional, 2-crtSimplesExcessoReceita, 3-crtRegimeNormal)
    NotaF.NFe.Emit.CRT  := crtRegimeNormal;
end;

procedure PreencherDestinatario(var NotaF: NotaFiscal; const Cliente: TClienteResultado);
begin
   NotaF.NFe.Dest.CNPJCPF           := Cliente.CNPJCPF;
   NotaF.NFe.Dest.IE                := Cliente.IE;
   //NotaF.NFe.Dest.ISUF              := '';//SUFRAMA NÃO NECESSÁRIO
   NotaF.NFe.Dest.xNome              := Cliente.xNome;
   WriteLn(NotaF.NFe.Dest.xNome );
   LogToFile(NotaF.NFe.Dest.xNome );
   if Cliente.xNome = 'JOSE ANTONIO PIRES DA CHAO' then
   begin
     NotaF.NFe.Dest.indIEDest       := inNaoContribuinte;
     NotaF.NFe.Ide.indFinal := cfConsumidorFinal;
   end;
   NotaF.NFe.Dest.EnderDest.Fone    := Cliente.Fone;
   NotaF.NFe.Dest.EnderDest.CEP     := Cliente.CEP;
   NotaF.NFe.Dest.EnderDest.xLgr    := Cliente.xLgr;
   NotaF.NFe.Dest.EnderDest.nro     := Cliente.nro;
   NotaF.NFe.Dest.EnderDest.xCpl    := Cliente.xCpl;
   NotaF.NFe.Dest.EnderDest.xBairro := Cliente.xBairro;
   NotaF.NFe.Dest.EnderDest.cMun    := Cliente.cMun;
   NotaF.NFe.Dest.EnderDest.xMun    := Cliente.xMun;
   NotaF.NFe.Dest.EnderDest.UF      := Cliente.UF;
   NotaF.NFe.Dest.EnderDest.cPais   := Cliente.cPais;
   NotaF.NFe.Dest.EnderDest.xPais   := Cliente.xPais;

   if Cliente.Entrega then
   begin
     PreencherEnderecoEntrega(NotaF, Cliente);
   end;
end;

procedure PreencherEnderecoEntrega(var NotaF: NotaFiscal; const Cliente: TClienteResultado);
begin
  NotaF.NFE.Entrega.CNPJCPF := Cliente.EnderecoEntrega.CNPJCPF;
  NotaF.NFE.Entrega.xLgr    := Cliente.EnderecoEntrega.xLgr;
  NotaF.NFE.Entrega.nro     := Cliente.EnderecoEntrega.nro;
  NotaF.NFE.Entrega.xCpl    := Cliente.EnderecoEntrega.xCpl;
  NotaF.NFE.Entrega.xBairro := Cliente.EnderecoEntrega.xBairro;
  NotaF.NFE.Entrega.xMun    := Cliente.EnderecoEntrega.xMun;
  Notaf.NFe.Entrega.cMun    := Cliente.EnderecoEntrega.cMun;
  NotaF.NFE.Entrega.UF      := Cliente.EnderecoEntrega.UF;
  NotaF.NFe.Entrega.cPais   := 1058;
  NotaF.NFe.Entrega.xPais   := 'BRASIL';
end;

procedure AdicionarProdutos(var NotaF: NotaFiscal; var Produto: TDetCollectionItem; const NumItem: Integer; const Prod: TProdutoResultado);
var
  IBSCBS: TIBSCBS;
begin
    Produto.Prod.nItem     := NumItem; // Número sequencial, para cada item deve ser incrementado
    Produto.Prod.cProd     := Prod.cProd;
    Produto.Prod.cEAN      := 'SEM GTIN';
    Produto.Prod.xProd     := Prod.xProd;
    Produto.Prod.NCM       := cNCM;
    //Produto.Prod.EXTIPI   := '';//NÃO É NECESSÁRIO
    Produto.Prod.CFOP      := Prod.CFOP;
    Produto.Prod.uCom      := 'UN';
    Produto.Prod.qCom      := Prod.qCom;
    Produto.Prod.vUnCom    := Prod.vUnCom;
    Produto.Prod.vProd     := Prod.vProd;
    Produto.Prod.cEANTrib  := 'SEM GTIN';
    Produto.Prod.uTrib     := 'UN';
    Produto.Prod.qTrib     := Prod.qTrib;
    Produto.Prod.vUnTrib   := Prod.vUnTrib;
    Produto.Prod.vOutro    := 0;
    Produto.Prod.vFrete    := 0;
    Produto.Prod.vSeg      := 0;
    Produto.Prod.vDesc     := 0;
    Produto.vItem          := Prod.vItem;
    Produto.infAdProd      := 'Lote: L-' + FormatDateTime('ddmmyyyy', Date) + ' - isencao icms conf. art. 36 do anexo I RICMS/SP';    //FormattedDate := FormatDateTime('ddmmyyyy', MyDate);
    Produto.Prod.cBenef    := 'SP010360';
    with Produto.Imposto do
    begin
      with ICMS do
      begin
        orig := oeNacional;
        if NotaF.NFe.Emit.CRT in [crtSimplesExcessoReceita, crtRegimeNormal] then
        begin
          //verificar lançamento dos impostos
          CST := cst40;
        end;
      end;
      with PIS do
      begin
        CST  := pis08;
        vBC  := 0;
        pPIS := 0;
        vPIS := 0;
        qBCProd   := 0;
        vAliqProd := 0;
        vPIS      := 0;
      end;
      with PISST do
      begin
        vBc       := 0;
        pPis      := 0;
        qBCProd   := 0;
        vAliqProd := 0;
        vPIS      := 0;
        IndSomaPISST :=  ispNenhum;
      end;
      with COFINS do
      begin
        CST     := cof08;
        vBC     := 0;
        pCOFINS := 0;
        vCOFINS := 0;
        qBCProd   := 0;
        vAliqProd := 0;
      end;
      with COFINSST do
      begin
        vBC       := 0;
        pCOFINS   := 0;
        qBCProd   := 0;
        vAliqProd := 0;
        vCOFINS   := 0;
        indSomaCOFINSST :=  iscNenhum;
      end;
    end;
    IBSCBS := Produto.Imposto.IBSCBS;
    IBSCBS.CST := cst410;
    IBSCBS.cClassTrib := '410014';
    IBSCBS.gIBSCBS.vBC := cvProd;
    IBSCBS.gIBSCBS.gIBSUF.pIBSUF := 0;
    IBSCBS.gIBSCBS.gIBSUF.vIBSUF := 0;
    IBSCBS.gIBSCBS.gIBSUF.gRed.pRedAliq := 0;
    IBSCBS.gIBSCBS.gIBSUF.gRed.pAliqEfet := 0;
    IBSCBS.gIBSCBS.gIBSMun.pIBSMun := 0;
    IBSCBS.gIBSCBS.gIBSMun.vIBSMun := 0;
    IBSCBS.gIBSCBS.gIBSMun.gRed.pRedAliq := 0;
    IBSCBS.gIBSCBS.gIBSMun.gRed.pAliqEfet := 0;
    IBSCBS.gIBSCBS.vIBS := 0;
    IBSCBS.gIBSCBS.gCBS.pCBS := 0;
    IBSCBS.gIBSCBS.gCBS.vCBS := 0;
    IBSCBS.gIBSCBS.gCBS.gRed.pRedAliq := 0;
    IBSCBS.gIBSCBS.gCBS.gRed.pAliqEfet := 0;
end;

procedure AnotacoesRegimeNormal(var NotaF: NotaFiscal);
begin
  if NotaF.NFe.Emit.CRT in [crtSimplesExcessoReceita, crtRegimeNormal] then
  begin
    NotaF.NFe.Total.ICMSTot.vBC := 0;
    NotaF.NFe.Total.ICMSTot.vICMS := 0;
  end;
end;

procedure AnotacoesTribDiversas(var NotaF: NotaFiscal; const DadosGerais: TDadosGeraisNFe);
var
  Volume: TVolCollectionItem;
  Duplicata: TDupCollectionItem;
  ObsComplementar: TobsContCollectionItem;
  ObsFisco: TobsFiscoCollectionItem;
  InfoPgto: TpagCollectionItem;
  IBSCBSTot: TIBSCBSTot;
begin
  NotaF.NFe.Total.ICMSTot.vBCST   := 0;
  NotaF.NFe.Total.ICMSTot.vST     := 0;
  NotaF.NFe.Total.ICMSTot.vProd   := DadosGerais.Total_ICMSTot_vProd;
  NotaF.NFe.Total.ICMSTot.vFrete  := 0;
  NotaF.NFe.Total.ICMSTot.vSeg    := 0;
  NotaF.NFe.Total.ICMSTot.vDesc   := 0;
  NotaF.NFe.Total.ICMSTot.vII     := 0;
  NotaF.NFe.Total.ICMSTot.vIPI    := 0;
  NotaF.NFe.Total.ICMSTot.vPIS    := 0;
  NotaF.NFe.Total.ICMSTot.vCOFINS := 0;
  NotaF.NFe.Total.ICMSTot.vOutro  := 0;
  NotaF.NFe.Total.ICMSTot.vNF     := DadosGerais.Total_ICMSTot_vNF;


  // lei da transparencia de impostos
  NotaF.NFe.Total.ICMSTot.vTotTrib := 0;

  // partilha do icms e fundo de probreza
  NotaF.NFe.Total.ICMSTot.vFCPUFDest   := 0.00;
  NotaF.NFe.Total.ICMSTot.vICMSUFDest  := 0.00;
  NotaF.NFe.Total.ICMSTot.vICMSUFRemet := 0.00;

  NotaF.NFe.Total.retTrib.vRetPIS    := 0;
  NotaF.NFe.Total.retTrib.vRetCOFINS := 0;
  NotaF.NFe.Total.retTrib.vRetCSLL   := 0;
  NotaF.NFe.Total.retTrib.vBCIRRF    := 0;
  NotaF.NFe.Total.retTrib.vIRRF      := 0;
  NotaF.NFe.Total.retTrib.vBCRetPrev := 0;
  NotaF.NFe.Total.retTrib.vRetPrev   := 0;

  {NotaF.NFe.Total.IBSCBSTot.vBCIBSCBS := cvProd;
  NotaF.NFe.Total.IBSCBSTot.gIBS.vIBS := 0;
  NotaF.NFe.Total.IBSCBSTot.gIBS.vCredPres := 0;
  NotaF.NFe.Total.IBSCBSTot.gIBS.vCredPresCondSus := 0;

  NotaF.NFe.Total.IBSCBSTot.gIBS.gIBSUFTot.vDif := 0;
  NotaF.NFe.Total.IBSCBSTot.gIBS.gIBSUFTot.vDevTrib := 0;
  NotaF.NFe.Total.IBSCBSTot.gIBS.gIBSUFTot.vIBSUF := 0;

  NotaF.NFe.Total.IBSCBSTot.gIBS.gIBSMunTot.vDif := 0;
  NotaF.NFe.Total.IBSCBSTot.gIBS.gIBSMunTot.vDevTrib := 0;
  NotaF.NFe.Total.IBSCBSTot.gIBS.gIBSMunTot.vIBSMun := 0;


  NotaF.NFe.Total.IBSCBSTot.gCBS.vDif := 0;
  NotaF.NFe.Total.IBSCBSTot.gCBS.vDevTrib := 0;
  NotaF.NFe.Total.IBSCBSTot.gCBS.vCBS := 0;
  NotaF.NFe.Total.IBSCBSTot.gCBS.vCredPres := 0;
  NotaF.NFe.Total.IBSCBSTot.gCBS.vCredPresCondSus := 0; }

  {IBSCBSTot := NotaF.NFe.Total.IBSCBSTot;
  IBSCBSTot.vBCIBSCBS := cvProd;
  IBSCBSTot.gIBS.vIBS := 0;
  IBSCBSTot.gIBS.vCredPres := 0;
  IBSCBSTot.gIBS.vCredPresCondSus := 0;
  IBSCBSTot.gIBS.gIBSUFTot.vDif := 0;
  IBSCBSTot.gIBS.gIBSUFTot.vDevTrib := 0;
  IBSCBSTot.gIBS.gIBSUFTot.vIBSUF := 0;
  IBSCBSTot.gIBS.gIBSMunTot.vDif := 0;
  IBSCBSTot.gIBS.gIBSMunTot.vDevTrib := 0;
  IBSCBSTot.gIBS.gIBSMunTot.vIBSMun := 0;
  IBSCBSTot.gCBS.vDif := 0;
  IBSCBSTot.gCBS.vDevTrib := 0;
  IBSCBSTot.gCBS.vCBS := 0;
  IBSCBSTot.gCBS.vCredPres := 0;
  IBSCBSTot.gCBS.vCredPresCondSus := 0;   }

  case DadosGerais.Transp_modFrete of
    1: NotaF.NFe.Transp.modFrete := mfContaDestinatario;
    3: NotaF.NFe.Transp.modFrete := mfProprioRemetente;
  else
    NotaF.NFe.Transp.modFrete := mfSemFrete;
  end;
//  NotaF.NFe.Transp.modFrete := mfContaEmitente;



  NotaF.NFe.Transp.Transporta.CNPJCPF  := DadosGerais.Transp_Transporta_CNPJCPF;
  NotaF.NFe.Transp.Transporta.xNome    := DadosGerais.Transp_Transporta_xNome;
  NotaF.NFe.Transp.Transporta.IE       := DadosGerais.Transp_Transporta_IE;
  NotaF.NFe.Transp.Transporta.xEnder   := DadosGerais.Transp_Transporta_xEnder;
  NotaF.NFe.Transp.Transporta.xMun     := DadosGerais.Transp_Transporta_xMun;
  NotaF.NFe.Transp.Transporta.UF       := DadosGerais.Transp_Transporta_UF;

  NotaF.NFe.Transp.retTransp.vServ    := 0;
  NotaF.NFe.Transp.retTransp.vBCRet   := 0;
  NotaF.NFe.Transp.retTransp.pICMSRet := 0;
  NotaF.NFe.Transp.retTransp.vICMSRet := 0;
  NotaF.NFe.Transp.retTransp.CFOP     := '';
  NotaF.NFe.Transp.retTransp.cMunFG   := 0;

  Volume := NotaF.NFe.Transp.Vol.New;
  Volume.qVol  := DadosGerais.Volume_qVol;
  Volume.esp   := DadosGerais.Volume_esp;
  Volume.marca := DadosGerais.Volume_marca;
  Volume.nVol  := DadosGerais.Volume_nVol;
  Volume.pesoL := DadosGerais.Volume_pesoL;
  Volume.pesoB := DadosGerais.Volume_pesoB;

  //Lacres do volume. Pode ser adicionado vários
  (*
  Lacre := Volume.Lacres.Add;
  Lacre.nLacre := '';
  *)

  if NotaF.NFe.Ide.indPag <> ipVista then
  begin

    NotaF.NFe.Cobr.Fat.nFat  := DadosGerais.ID; // 'Numero da Fatura'
    NotaF.NFe.Cobr.Fat.vOrig := DadosGerais.Total_ICMSTot_vNF;
    NotaF.NFe.Cobr.Fat.vDesc := 0;
    NotaF.NFe.Cobr.Fat.vLiq  := DadosGerais.Total_ICMSTot_vNF;

    Duplicata := NotaF.NFe.Cobr.Dup.New;
    Duplicata.nDup  := DadosGerais.Duplicata_nDup;
    Duplicata.dVenc := DadosGerais.Duplicata_dVenc;
    Duplicata.vDup  := DadosGerais.Duplicata_vDup;
  end;

  {Duplicata := NotaF.NFe.Cobr.Dup.New;
  Duplicata.nDup  := '002';
  Duplicata.dVenc := now+20;
  Duplicata.vDup  := 50;}

    // O grupo infIntermed só deve ser gerado nos casos de operação não presencial
    // pela internet em site de terceiros (Intermediadores).
//  NotaF.NFe.infIntermed.CNPJ := '';
//  NotaF.NFe.infIntermed.idCadIntTran := '';

  NotaF.NFe.InfAdic.infCpl     :=  DadosGerais.InfAdic_infCpl;
  NotaF.NFe.InfAdic.infAdFisco :=  DadosGerais.InfAdic_infAdFisco;

 { ObsComplementar := NotaF.NFe.InfAdic.obsCont.New;
  ObsComplementar.xCampo := 'ObsCont';
  ObsComplementar.xTexto := 'Texto';}

{  ObsFisco := NotaF.NFe.InfAdic.obsFisco.New;
  ObsFisco.xCampo := 'ObsFisco';
  ObsFisco.xTexto := 'Texto';    }

  NotaF.NFe.exporta.UFembarq   := '';;
  NotaF.NFe.exporta.xLocEmbarq := '';

  NotaF.NFe.compra.xNEmp := '';
  NotaF.NFe.compra.xPed  := '';
  NotaF.NFe.compra.xCont := '';

// YA. Informações de pagamento

  InfoPgto := NotaF.NFe.pag.New;
  InfoPgto.indPag := ipPrazo;
  InfoPgto.tPag   := fpBoletoBancario;
  InfoPgto.vPag   := DadosGerais.Total_ICMSTot_vNF;



end;

end.

