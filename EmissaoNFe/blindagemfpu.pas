unit BlindagemFPU;

{$mode objfpc}{$H+}

interface

implementation
uses
  {$IFDEF LINUX}
  Math;
  {$ELSE}
  SysUtils;
  {$ENDIF}

initialization
  {$IFDEF LINUX}
  // Aplica a máscara no exato momento em que esta unit é carregada
  SetExceptionMask([exInvalidOp, exDenormalized, exZeroDivide, exOverflow, exUnderflow, exPrecision]);
  {$ENDIF}
end.


