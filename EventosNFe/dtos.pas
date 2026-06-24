unit DTOs;

{$mode ObjFPC}{$H+}

interface

uses
  Classes
  , SysUtils
  , ACBrDFe.Conversao
  ;

type

  TTipoAmbiente = ACBrDFe.Conversao.TACBrTipoAmbiente;

  TTipoEvento = ACBrDFe.Conversao.TACBrTipoEvento;

  TCancelamento =  record
    Chave: string;
    ProtocoloEnvio: string;
    DataEmissao: TDateTime;
    RetornoWS: string;
    RetWS: string;
    cStat:Integer;
    ProtocoloRetorno: string;
    Id: string;
    tpAmb: TTipoAmbiente;
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
    XMLAtualizado: string;
  end;

const
  // Enumerados do TACBrTipoAmbiente
  taHomologacao = {$IFDEF SUPPORTS_SCOPEDENUMS}TACBrTipoAmbiente.{$ENDIF}taHomologacao deprecated {$IfDef SUPPORTS_DEPRECATED_DETAILS} 'Use o tipo TACBrTipoAmbiente da Unit ACBrDFe.Conversao.pas' {$ENDIF};
  taProducao = {$IFDEF SUPPORTS_SCOPEDENUMS}TACBrTipoAmbiente.{$ENDIF}taProducao deprecated {$IfDef SUPPORTS_DEPRECATED_DETAILS} 'Use o tipo TACBrTipoAmbiente da Unit ACBrDFe.Conversao.pas' {$ENDIF};

  // Enumerados do TACBrTipoEvento
  teCCe = {$IFDEF SUPPORTS_SCOPEDENUMS}TACBrTipoEvento.{$ENDIF}teCCe deprecated {$IfDef SUPPORTS_DEPRECATED_DETAILS} 'Use o tipo TACBrTipoEvento da Unit ACBrDFe.Conversao.pas' {$ENDIF};
  teCancelamento = {$IFDEF SUPPORTS_SCOPEDENUMS}TACBrTipoEvento.{$ENDIF}teCancelamento deprecated {$IfDef SUPPORTS_DEPRECATED_DETAILS} 'Use o tipo TACBrTipoEvento da Unit ACBrDFe.Conversao.pas' {$ENDIF};


implementation

end.

