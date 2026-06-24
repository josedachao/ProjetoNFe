unit utils;

{$mode ObjFPC}{$H+}

interface

uses
  Classes
  , SysUtils
  , FileUtil ;

function XMLParaString(const CaminhoArquivo: string): string;
function ObterAnoMes(const ADateTime: TDateTime): String;
procedure DuplicateAndRename(const FileName: string);
procedure SimpleRename(const FileName: string);
function CopyInUseFile(const FileName: string; out XMLContent: string): Boolean;
function CopyInUseFile(const FileName: string): Boolean;

implementation

procedure SimpleRename(const FileName: string);
var
  OldName, NewName: string;
begin
  OldName := FileName;
  NewName := StringReplace(FileName, 'nfe', 'ORIGINAL', [rfReplaceAll, rfIgnoreCase]);

  if RenameFile(OldName, NewName) then
    WriteLn('Arquivo renomeado com sucesso.')
  else
    WriteLn('Erro ao renomear o arquivo.');
end;

procedure DuplicateAndRename(const FileName: string);
var
  Source, Destination: string;
begin
  Source := FileName;
  Destination := StringReplace(FileName, 'nfe', 'ORIGINAL', [rfReplaceAll, rfIgnoreCase]);

  // Third parameter true will overwrite the destination file if it exists
  if CopyFile(Source, Destination, True) then
    WriteLn('Arquivo copiado e renomeado com sucesso!!')
  else
    WriteLn('Erro ao copiar e renomear o arquivo.');
end;

function ObterAnoMes(const ADateTime: TDateTime): String;
begin
  // 'yyyymm' extrai o ano com 4 dígitos e o mês com 2 dígitos e zero à esquerda
  Result := FormatDateTime('yyyymm', ADateTime);
end;

function XMLParaString(const CaminhoArquivo: string): string;
var
  ConteudoArquivo: TStringList;
begin
  Result := '';
  // Verifica se o arquivo realmente existe para evitar erros
  if not FileExists(CaminhoArquivo) then
    Exit;

  ConteudoArquivo := TStringList.Create;
  try
    // Carrega o arquivo XML
    ConteudoArquivo.LoadFromFile(CaminhoArquivo);
    // Atribui o texto completo à variável de retorno
    Result := ConteudoArquivo.Text;
  finally
    // Libera a memória do TStringList
    ConteudoArquivo.Free;
  end;
end;

function CopyInUseFile(const FileName: string): Boolean;
var
  SrcStream, DestStream: TFileStream;
  NewFileName: string;
begin
  Result := False;
  SrcStream := nil;
  DestStream := nil;
  NewFileName := StringReplace(FileName, '-nfe', '-ORIGINAL', [rfReplaceAll, rfIgnoreCase]);
  try
    try
      // fmShareDenyNone allows reading even if the file is locked/written to by another process
      SrcStream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
      DestStream := TFileStream.Create(NewFileName, fmCreate);

      DestStream.CopyFrom(SrcStream, SrcStream.Size);
      Result := True;
    except
      on E: Exception do
        WriteLn('Error: ', E.Message);
    end;
  finally
    SrcStream.Free;
    DestStream.Free;
  end;
end;

function CopyInUseFile(const FileName: string; out XMLContent: string): Boolean;
var
  SrcStream, DestStream: TFileStream;
  StrStream: TStringStream;
  NewFileName: string;
begin
  Result := False;
  XMLContent := ''; // Inicializa a string de retorno
  SrcStream := nil;
  DestStream := nil;

  NewFileName := StringReplace(FileName, '-nfe', '-ORIGINAL', [rfReplaceAll, rfIgnoreCase]);
  try
    try
      // Abre o arquivo original permitindo leitura mesmo se bloqueado
      SrcStream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
      DestStream := TFileStream.Create(NewFileName, fmCreate);

      // 1. Faz a cópia física do arquivo como você já fazia
      DestStream.CopyFrom(SrcStream, SrcStream.Size);

      // 2. Reposiciona o ponteiro do SrcStream para o início antes de ler o texto
      SrcStream.Position := 0;

      // 3. Lê o stream diretamente para a string (usa TEncoding.UTF8 nativo no Lazarus)
      StrStream := TStringStream.Create('', TEncoding.UTF8);
      try
        StrStream.CopyFrom(SrcStream, SrcStream.Size);
        XMLContent := StrStream.DataString; // Copia o texto para a sua variável
      finally
        StrStream.Free;
      end;

      Result := True;
    except
      on E: Exception do
        WriteLn('Error: ', E.Message);
    end;
  finally
    SrcStream.Free;
    DestStream.Free;
  end;
end;

end.

