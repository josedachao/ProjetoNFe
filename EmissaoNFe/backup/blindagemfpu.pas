unit BlindagemFPU;

{$mode objfpc}{$H+}
{$codepage utf8}

interface

implementation
uses
  {$IFDEF LINUX}
  Math;
 {$ENDIF}
  SysUtils
  , LazUTF8;


initialization
  {$IFDEF LINUX}
  // Aplica a máscara no exato momento em que esta unit é carregada
  SetExceptionMask([exInvalidOp, exDenormalized, exZeroDivide, exOverflow, exUnderflow, exPrecision]);
  {$ENDIF}
end.


