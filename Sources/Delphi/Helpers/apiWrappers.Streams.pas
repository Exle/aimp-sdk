////////////////////////////////////////////////////////////////////////////////
//
//  Project:   AIMP
//             Programming Interface
//
//  Target:    v6.00 build 3000
//
//  Author:    Artem Izmaylov
//             © 2006-2026
//             www.aimp.ru
//
//  FPC:       OK
//
unit apiWrappers.Streams;

{$I apiConfig.inc}

interface

uses
{$IFDEF FPC}
  LCLIntf,
  LCLType,
{$ELSE}
  Windows,
{$ENDIF}
  // System
  Classes,
  SysUtils,
  Types,
  // API
  apiCore,
  apiFileManager,
  apiMUI,
  apiObjects,
  apiWrappers,
  apiTypes;

type

  { TAIMPStreamWrapper }

  TAIMPStreamWrapper = class(TStream)
  strict private
    FSource: IAIMPStream;
  protected
    function GetSize: Int64; override;
    procedure SetSize(const NewSize: Int64); override;
  public
    constructor Create(ASource: IAIMPStream); virtual;
    function Read(var Buffer; Count: Longint): Longint; override;
    function Seek(const Offset: Int64; Origin: TSeekOrigin): Int64; override;
    function Write(const Buffer; Count: Longint): Longint; override;
  end;

  { TAIMPStreamAdapter }

  TAIMPStreamAdapter = class(TInterfacedObjectEx, IAIMPStream)
  strict private
    FOwnership: TStreamOwnership;
  protected
    FSource: TStream;
    FSourceIsReadOnly: Boolean;

    function TestSource(ASource: TStream): Boolean; virtual;
    // IAIMPStream
    function GetSize: Int64; stdcall;
    function SetSize(const Value: Int64): HRESULT; stdcall;
    function GetPosition: Int64; stdcall;
    function Seek(const Offset: Int64; Mode: Integer): HRESULT; stdcall;
    function Read(Buffer: PByte; Count: LongWord): Integer; virtual; stdcall;
    function Write(Buffer: PByte; Count: LongWord; Written: PLongWord = nil): HRESULT; stdcall;
  public
    constructor Create(ASource: TStream; AOwnership: TStreamOwnership = soOwned);
    constructor CreateFromResource(const AName: string; AType: PChar);
    destructor Destroy; override;
  end;

  { TAIMPMemoryStreamAdapter }

  TAIMPMemoryStreamAdapter = class(TAIMPStreamAdapter, IAIMPMemoryStream)
  protected
    function TestSource(ASource: TStream): Boolean; override;
    // IAIMPMemoryStream
    function GetData: PByte; stdcall;
  public
    constructor Create; overload;
  end;

  { TAIMPFileStreamAdapter }

  TAIMPFileStreamAdapter = class(TAIMPStreamAdapter, IAIMPFileStream)
  protected
    function CreateStream(const AFileName: string; AMode: Integer): TStream; virtual;
    function Read(Buffer: PByte; Count: DWORD): Integer; override;
    function TestSource(ASource: TStream): Boolean; override;
    // IAIMPFileStream
    function GetClipping(out Offset, Size: Int64): HRESULT; virtual; stdcall;
    function GetFileName(out S: IAIMPString): HRESULT; virtual; stdcall;
  public
    constructor Create(const AFileName: IAIMPString; AMode: Integer); overload;
    constructor Create(const AFileName: string; AMode: Integer); overload;
  end;

function CreateResourceStream(const AName: string; AType: PChar): IAIMPStream;
function uiLoadGlyphFromResource(const AName: string): IAIMPImageContainer; overload;
function uiLoadGlyphFromResource(const AName: string; AType: PChar): IAIMPImageContainer; overload;
implementation

function CreateResourceStream(const AName: string; AType: PChar): IAIMPStream;
begin
  Result := TAIMPStreamAdapter.Create(TResourceStream.Create(HInstance, AName, AType));
end;

function uiLoadGlyphFromResource(const AName: string): IAIMPImageContainer;
begin
  Result := uiLoadGlyphFromResource(AName, 'PNG');
end;

function uiLoadGlyphFromResource(const AName: string; AType: PChar): IAIMPImageContainer; overload;
var
  LStream: TStream;
begin
  if AName <> '' then
  begin
    LStream := TResourceStream.Create(HInstance, AName, AType);
    try
      CoreCreateObject(IAIMPImageContainer, Result);
      Result.SetDataSize(LStream.Size);
      LStream.ReadBuffer(Result.GetData^, Result.GetDataSize);
    finally
      LStream.Free;
    end;
  end
  else
    Result := nil;
end;

{ TAIMPStreamWrapper }

constructor TAIMPStreamWrapper.Create(ASource: IAIMPStream);
begin
  inherited Create;
  FSource := ASource;
end;

function TAIMPStreamWrapper.Read(var Buffer; Count: Integer): Longint;
begin
  Result := FSource.Read(@Buffer, Count);
end;

function TAIMPStreamWrapper.Seek(const Offset: Int64; Origin: TSeekOrigin): Int64;
begin
  case Origin of
    soBeginning:
      FSource.Seek(Offset, AIMP_STREAM_SEEKMODE_FROM_BEGINNING);
    soCurrent:
      FSource.Seek(Offset, AIMP_STREAM_SEEKMODE_FROM_CURRENT);
    soEnd:
      FSource.Seek(Offset, AIMP_STREAM_SEEKMODE_FROM_END);
  end;
  Result := FSource.GetPosition;
end;

function TAIMPStreamWrapper.Write(const Buffer; Count: Integer): Longint;
var
  AWritten: DWORD;
begin
  if Succeeded(FSource.Write(@Buffer, Count, @AWritten)) then
    Result := AWritten
  else
    Result := 0
end;

function TAIMPStreamWrapper.GetSize: Int64;
begin
  Result := FSource.GetSize;
end;

procedure TAIMPStreamWrapper.SetSize(const NewSize: Int64);
begin
  if Failed(FSource.SetSize(NewSize)) then
    Abort;
end;

{ TAIMPStreamAdapter }

constructor TAIMPStreamAdapter.Create(ASource: TStream; AOwnership: TStreamOwnership = soOwned);
begin
  inherited Create;
  if not TestSource(ASource) then
    raise EStreamError.Create('Unsupported stream class');
  FSource := ASource;
  FOwnership := AOwnership;
end;

constructor TAIMPStreamAdapter.CreateFromResource(const AName: string; AType: PChar);
begin
  Create(TResourceStream.Create(HINSTANCE, AName, AType));
end;

destructor TAIMPStreamAdapter.Destroy;
begin
  if FOwnership = soOwned then
    FreeAndNil(FSource);
  inherited Destroy;
end;

function TAIMPStreamAdapter.TestSource(ASource: TStream): Boolean;
begin
  Result := True;
end;

function TAIMPStreamAdapter.GetPosition: Int64;
begin
  Result := FSource.Position;
end;

function TAIMPStreamAdapter.GetSize: Int64;
begin
  Result := FSource.Size;
end;

function TAIMPStreamAdapter.Read(Buffer: PByte; Count: DWORD): Integer;
begin
  try
    Result := FSource.Read(Buffer^, Count);
  except
    Result := -1;
  end;
end;

function TAIMPStreamAdapter.Seek(const Offset: Int64; Mode: Integer): HRESULT;
var
  ASeekOrigin: TSeekOrigin;
begin
  case Mode of
    AIMP_STREAM_SEEKMODE_FROM_BEGINNING:
      ASeekOrigin := soBeginning;
    AIMP_STREAM_SEEKMODE_FROM_CURRENT:
      ASeekOrigin := soCurrent;
    AIMP_STREAM_SEEKMODE_FROM_END:
      ASeekOrigin := soEnd;
  else
    Exit(E_INVALIDARG);
  end;

  try
    if FSource.Seek(Offset, ASeekOrigin) = Offset then
      Result := S_OK
    else
      Result := E_FAIL;
  except
    Result := E_UNEXPECTED;
  end;
end;

function TAIMPStreamAdapter.SetSize(const Value: Int64): HRESULT;
begin
  if FSourceIsReadOnly then
    Result := E_NOTIMPL
  else
    try
      FSource.Size := Value;
      Result := S_OK;
    except
      Result := E_UNEXPECTED;
    end;
end;

function TAIMPStreamAdapter.Write(Buffer: PByte; Count: LongWord; Written: PLongWord = nil): HRESULT;
begin
  if FSourceIsReadOnly then
    Result := E_NOTIMPL
  else
    try
      Count := FSource.Write(Buffer^, Count);
      if Written <> nil then
        Written^ := Count;
      Result := S_OK;
    except
      Result := E_UNEXPECTED;
    end;
end;

{ TAIMPMemoryStreamAdapter }

constructor TAIMPMemoryStreamAdapter.Create;
begin
  inherited Create(TMemoryStream.Create);
end;

function TAIMPMemoryStreamAdapter.TestSource(ASource: TStream): Boolean;
begin
  Result := ASource is TMemoryStream;
end;

function TAIMPMemoryStreamAdapter.GetData: PByte;
begin
  Result := TMemoryStream(FSource).Memory;
end;

{ TAIMPFileStreamAdapter }

constructor TAIMPFileStreamAdapter.Create(const AFileName: string; AMode: Integer);
begin
  Create(CreateStream(AFileName, AMode));
end;

constructor TAIMPFileStreamAdapter.Create(const AFileName: IAIMPString; AMode: Integer);
begin
  Create(IAIMPStringToString(AFileName), AMode);
end;

function TAIMPFileStreamAdapter.TestSource(ASource: TStream): Boolean;
begin
  Result := ASource is TFileStream;
end;

function TAIMPFileStreamAdapter.GetClipping(out Offset, Size: Int64): HRESULT;
begin
  Result := E_FAIL;
end;

function TAIMPFileStreamAdapter.GetFileName(out S: IAIMPString): HRESULT;
begin
  try
    S := MakeString(TFileStream(FSource).FileName);
    Result := S_OK;
  except
    Result := E_UNEXPECTED;
  end;
end;

function TAIMPFileStreamAdapter.Read(Buffer: PByte; Count: DWORD): Integer;
begin
  try
    Result := FSource.Read(Buffer^, Count);
    if (Result = 0) and (Count > 0){$IFDEF MSWINDOWS}and (GetLastError <> ERROR_SUCCESS){$ENDIF} then
    begin
      if FSource.Position <> FSource.Size then
        Result := -1;
        //RaiseLastOSError;
    end;
  except
    Result := -1;
  end;
end;

function TAIMPFileStreamAdapter.CreateStream(const AFileName: string; AMode: Integer): TStream;
begin
  Result := TFileStream.Create(AFileName, AMode);
end;

end.
