unit CancelamentoNFe;

{$mode ObjFPC}{$H+}

interface

uses
  Classes
  , SysUtils
  , DTOs
  ;


function CancelarNFe(const NumNFe: Integer; const MotivoUsuario: string;
  const AAmbiente: TTipoAmbiente; var Cancelamento: TCancelamento): Boolean;

implementation

uses
  FirebirdRepository
  , FileLoggerUnit
  , ACBrService
  ;


function CancelarNFe(const NumNFe: Integer; const MotivoUsuario: string;
  const AAmbiente: TTipoAmbiente; var Cancelamento: TCancelamento): Boolean;
var
  JustificativaLegal: String;
begin
  // Concatena o motivo do usuário com a declaração exigida pela legislação
  JustificativaLegal := 'Declaramos que nao houve circulacao de mercadoria - ' + Trim(MotivoUsuario);

  // Trunca em 255 caracteres para evitar rejeição de schema da SEFAZ
  if Length(JustificativaLegal) > 255 then
    JustificativaLegal := Copy(JustificativaLegal, 1, 255);

  GetDadosNFe(NumNFe, Cancelamento);

  if CancelarNFeACBr(NumNFe, JustificativaLegal, AAmbiente, Cancelamento) then
  begin
    //SetSummaryData(NumNFe); //deprecated
    SetCancelada(NumNFe, Cancelamento.XMLAtualizado);
  end;
end;

end.

