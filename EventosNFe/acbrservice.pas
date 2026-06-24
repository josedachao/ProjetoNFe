unit ACBrService;

{$mode ObjFPC}{$H+}

interface

uses
  Classes
  , SysUtils
  , ConfigACBr
  , DTOs
  , ACBrNFe
  ;

function CancelarNFeACBr(const NumNFe: Integer; const Motivo: String;
  const AAmbiente: TTipoAmbiente; var Cancelamento: TCancelamento): Boolean;

implementation

uses
  Utils
  , FileLoggerUnit
  ;

function CancelarNFeACBr(const NumNFe: Integer; const Motivo: String;
  const AAmbiente: TTipoAmbiente; var Cancelamento: TCancelamento): Boolean;
var
  CaminhoXMLOriginal: String;
  ACBrNFe1: TACBrNFe; // unit ACBrNFe
  ConteudoXML: string;
begin
  Result := False;
  ACBrNFe1 := TACBrNFe.Create(Nil);
  try
    ConfiguracoesPadraoNFe(ACBrNFe1, AAmbiente);

    // Define a variável com o caminho físico do XML
    CaminhoXMLOriginal := FREENFEXMLPATH + ObterAnoMes(Cancelamento.DataEmissao) + '\' + Cancelamento.Chave + '-nfe.xml';  //'C:\Users\ASUSTUFI56600K\Desktop\ProjetoNFe\ProjetoNFe\EmissaoNFe\executables\i386-win32\NFe\09167426000109\NFe\202606\' + Cancelamento.Chave + '-nfe.xml';
    ACBrNFe1.Configuracoes.Arquivos.PathNFe := StringReplace(FREENFEXMLPATH, 'NFE\', '', [rfReplaceAll, rfIgnoreCase]);

    // Trava de segurança: Garante que o arquivo físico realmente existe antes de prosseguir
    if not FileExists(CaminhoXMLOriginal) then
      raise Exception.Create('Falha ao cancelar: O arquivo XML original não foi encontrado no disco: ' + CaminhoXMLOriginal);


    ACBrNFe1.NotasFiscais.Clear;
    ACBrNFe1.NotasFiscais.LoadFromFile(CaminhoXMLOriginal); //comentei para teste

    WriteLn('Arquivo a ser alterado apos cancelamento: ' + CaminhoXMLOriginal);
    LogToFile('Arquivo a ser alterado apos cancelamento: ' + CaminhoXMLOriginal);

    ACBrNFe1.EventoNFe.Evento.Clear;
    with ACBrNFe1.EventoNFe.Evento.Add do
    begin
      {NO CANCELAMENTO POR XML  NÃO É NECESSÁRIO INFORMAR: CHAVE, CNPJ,SEQUENCIA E PROTOCOLO}
      infEvento.dhEvento  := Now;
      infEvento.tpEvento  := teCancelamento;
      infEvento.detEvento.xJust := Motivo; // Justificativa blindada
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
         Result := True;
         // 1. Injetamos manualmente o status de cancelamento no objeto NFe carregado    <<<------<<< VERIFICAR SE REALMENTE É NECESSÁRIO
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
           LogToFile('Caminho do arquivo xml a ser salvo no banco:');
           LogToFile(CaminhoXMLOriginal);
           LogToFile('Conteudo do novo xml a ser salvo no banco:');
           LogToFile(ConteudoXML);
           LogToFile('--------------------------------------------------');
         end;
      end;
      Cancelamento.XMLAtualizado := ConteudoXML;
    end;
  finally
    ACBrNFe1.Free;
  end;
end;

end.

