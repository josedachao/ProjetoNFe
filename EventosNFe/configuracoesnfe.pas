unit configuracoesnfe;

{$mode ObjFPC}{$H+}
{$codepage utf8}

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


procedure PreencherEmitente(var NotaF: NotaFiscal);

implementation

uses
  DateUtils;

procedure PreencherEmitente(var NotaF: NotaFiscal);
begin
    {NotaF.NFe.Emit.CNPJCPF           := '09.167.426/0001-09';
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
    NotaF.NFe.Emit.CRT := crtRegimeNormal;//<--- necessário verificar com a contabilidade}
end;

end.

