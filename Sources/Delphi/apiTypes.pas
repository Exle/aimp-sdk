////////////////////////////////////////////////////////////////////////////////
//
//  Project:   AIMP
//             Programming Interface
//
//  Target:    v6.00 build 3000
//
//  Purpose:   General Types
//
//  Author:    Artem Izmaylov
//             © 2006-2026
//             www.aimp.ru
//
//  FPC:       OK
//
unit apiTypes;

{$I apiConfig.inc}

interface

uses
  Variants,
{$IFDEF API_VAR_NEXTGEN}
  SysUtils,
{$ENDIF}
{$IFDEF MSWINDOWS}
  Windows;
{$ELSE}
  Cairo, LCLType;
{$ENDIF}

const
  E_ABORT           = {$IFDEF FPC}HRESULT($80004004){$ELSE}Windows.E_ABORT{$ENDIF};
  E_ACCESSDENIED    = {$IFDEF FPC}HRESULT($80070005){$ELSE}Windows.E_ACCESSDENIED{$ENDIF};
  E_FAIL            = {$IFDEF FPC}HRESULT($80004005){$ELSE}Windows.E_FAIL{$ENDIF};
  E_HANDLE          = {$IFDEF FPC}HRESULT($80070006){$ELSE}Windows.E_HANDLE{$ENDIF};
  E_INVALIDARG      = {$IFDEF FPC}HRESULT($80070057){$ELSE}Windows.E_INVALIDARG{$ENDIF};
  E_NOINTERFACE     = {$IFDEF FPC}HRESULT($80004002){$ELSE}Windows.E_NOINTERFACE{$ENDIF};
  E_NOTIMPL         = {$IFDEF FPC}HRESULT($80004001){$ELSE}Windows.E_NOTIMPL{$ENDIF};
  E_OUTOFMEMORY     = {$IFDEF FPC}HRESULT($8007000E){$ELSE}Windows.E_OUTOFMEMORY{$ENDIF};
  E_PENDING         = {$IFDEF FPC}HRESULT($8000000A){$ELSE}Windows.E_PENDING{$ENDIF};
  E_POINTER         = {$IFDEF FPC}HRESULT($80004003){$ELSE}Windows.E_POINTER{$ENDIF};

{$IFDEF API_VAR_NEXTGEN}
  // TVarValue.Type
  vvNull   = 0;
  vvString = 1;
  vvInt32  = 2;
  vvInt64  = 3;
  vvFloat  = 4;
{$ENDIF}

type
  Int32    = Integer;
  HICON    = {$IFDEF FPC}LCLType{$ELSE}Windows{$ENDIF}.HICON;
  HWND     = {$IFDEF FPC}LCLType{$ELSE}Windows{$ENDIF}.HWND;
  HBITMAP  = {$IFDEF FPC}LCLType{$ELSE}Windows{$ENDIF}.HBITMAP;
  PRGBQuad = {$IFDEF FPC}LCLType{$ELSE}Windows{$ENDIF}.PRGBQuad;
  TRGBQuad = {$IFDEF FPC}LCLType{$ELSE}Windows{$ENDIF}.TRGBQuad;

{$IFDEF MSWINDOWS}
  HCANVAS = HDC;
{$ELSE}
  HCANVAS = Pcairo_t;
{$ENDIF}

  TTaskHandle = NativeUInt;

function Failed(Status: HRESULT): Boolean;
function Succeeded(Status: HRESULT): Boolean;

{$REGION ' TVarValue '}
type
{$IFDEF API_VAR_NEXTGEN}
  VarValue = ^VarValueRec;
  VarValueRec = packed record
    Typa: Integer;
    Free: procedure (Ptr: Pointer); cdecl;
  end;
{$ELSE}
  VarValue = OleVariant;
{$ENDIF}
  PVarValue = ^VarValue;

procedure VarValueFree(var P: VarValue);
function VarValueNull: VarValue;
function VarValueCopy(const Value: VarValue): VarValue;
function VarValueInit(const Value: string): VarValue; overload;
function VarValueInit(const Value: Int32): VarValue; overload;
function VarValueInit(const Value: Int64): VarValue; overload;
function VarValueInit(const Value: Double): VarValue; overload;
function VarValueInit(const Value: Variant): VarValue; overload;
function VarValueIsFloat(const P: VarValue): Boolean;
function VarValueIsInt32(const P: VarValue): Boolean;
function VarValueIsInt64(const P: VarValue): Boolean;
function VarValueIsString(const P: VarValue): Boolean;
function VarValueToFloat(const P: VarValue): Double;
function VarValueToInt32(const P: VarValue): Int32;
function VarValueToInt64(const P: VarValue): Int64;
function VarValueToString(const P: VarValue): string;
function VarValueToVariant(const P: VarValue): Variant;
{$ENDREGION}
implementation

function Failed(Status: HRESULT): Boolean;
begin
  Result := Status and HRESULT($80000000) <> 0;
end;

function Succeeded(Status: HRESULT): Boolean;
begin
  Result := Status and HRESULT($80000000) = 0;
end;

{$REGION ' TVarValue '}

{$IFDEF API_VAR_NEXTGEN}
procedure VarValueFreeProc(Ptr: Pointer); cdecl;
begin
  FreeMem(Ptr);
end;

function VarValuePtr(P: VarValue): Pointer; inline;
begin
  Result := PByte(P) + SizeOf(VarValueRec);
end;

function VarValueInitCore(const AData; AType, ADataSize: Integer): VarValue;
begin
  Result := AllocMem(SizeOf(VarValueRec) + ADataSize);
  Result^.Free := VarValueFreeProc;
  Result^.Typa := AType;
  if ADataSize > 0 then
    Move(AData, VarValuePtr(Result)^, ADataSize);
end;
{$ENDIF}

procedure VarValueFree(var P: VarValue);
begin
{$IFDEF API_VAR_NEXTGEN}
  if P <> nil then
  begin
    P^.Free(P);
    P := nil;
  end;
{$ENDIF}
end;

function VarValueNull: VarValue;
begin
{$IFDEF API_VAR_NEXTGEN}
  Result := nil;
{$ELSE}
  Result := Null;
{$ENDIF}
end;

function VarValueCopy(const Value: VarValue): VarValue;
begin
  Result := VarValueInit(VarValueToVariant(Value));
end;

function VarValueInit(const Value: string): VarValue;
begin
{$IFDEF API_VAR_NEXTGEN}
  Result := VarValueInitCore(PChar(Value)^, vvString, (Length(Value) + 1) * SizeOf(Char));
{$ELSE}
  Result := Value;
{$ENDIF}
end;

function VarValueInit(const Value: Int32): VarValue;
begin
{$IFDEF API_VAR_NEXTGEN}
  Result := VarValueInitCore(Value, vvInt32, SizeOf(Value));
{$ELSE}
  Result := Value;
{$ENDIF}
end;

function VarValueInit(const Value: Int64): VarValue;
begin
{$IFDEF API_VAR_NEXTGEN}
  Result := VarValueInitCore(Value, vvInt64, SizeOf(Value));
{$ELSE}
  Result := Value;
{$ENDIF}
end;

function VarValueInit(const Value: Double): VarValue;
begin
{$IFDEF API_VAR_NEXTGEN}
  Result := VarValueInitCore(Value, vvFloat, SizeOf(Value));
{$ELSE}
  Result := Value;
{$ENDIF}
end;

function VarValueInit(const Value: Variant): VarValue;
begin
{$IFDEF API_VAR_NEXTGEN}
  case VarType(Value) of
    varEmpty, varNull:
      Result := VarValueInitCore(Value, vvNull, 0);
    varSingle, varDouble, varDate:
      Result := VarValueInit(Double(Value));
    varInt64, varUInt32, varUInt64:
      Result := VarValueInit(Int64(Value));
    varByte, varSmallint, varInteger, varWord:
      Result := VarValueInit(Int32(Value));
    varOleStr, varString, varUString:
      Result := VarValueInit(VarToStr(Value));
  else
    raise Exception.CreateFmt('VarValueInit: unsupported VarType(%d)', [VarType(Value)]);
  end;
{$ELSE}
  Result := Value;
{$ENDIF}
end;

function VarValueIsFloat(const P: VarValue): Boolean;
begin
{$IFDEF API_VAR_NEXTGEN}
  Result := P^.typa = vvFloat;
{$ELSE}
  Result := VarIsFloat(P);
{$ENDIF}
end;

function VarValueIsInt32(const P: VarValue): Boolean;
begin
{$IFDEF API_VAR_NEXTGEN}
  Result := P^.typa = vvInt32;
{$ELSE}
  Result := VarType(P) in [varSmallInt, varInteger, varShortInt, varByte, varWord, varUInt32];
{$ENDIF}
end;

function VarValueIsInt64(const P: VarValue): Boolean;
begin
{$IFDEF API_VAR_NEXTGEN}
  Result := P^.typa = vvInt64;
{$ELSE}
  Result := VarType(P) in [varInt64, varUInt64];
{$ENDIF}
end;

function VarValueIsString(const P: VarValue): Boolean;
begin
{$IFDEF API_VAR_NEXTGEN}
  Result := P^.typa = vvString;
{$ELSE}
  Result := VarIsStr(P);
{$ENDIF}
end;

function VarValueToFloat(const P: VarValue): Double;
begin
{$IFDEF API_VAR_NEXTGEN}
  case P^.Typa of
    vvNull:
      Result := 0;
    vvInt32, vvInt64:
      Result := VarValueToInt64(P);
    vvFloat:
      Result := PDouble(VarValuePtr(P))^;
  else
    Result := StrToFloat(VarValueToString(P));
  end;
{$ELSE}
  Result := P;
{$ENDIF}
end;

function VarValueToInt32(const P: VarValue): Int32;
begin
  Result := VarValueToInt64(P);
end;

function VarValueToInt64(const P: VarValue): Int64;
begin
{$IFDEF API_VAR_NEXTGEN}
  case P^.Typa of
    vvNull:
      Result := 0;
    vvInt32:
      Result := PInteger(VarValuePtr(P))^;
    vvInt64:
      Result := PInt64(VarValuePtr(P))^;
    vvFloat:
      Result := Round(VarValueToFloat(P));
  else
    Result := StrToInt64(VarValueToString(P));
  end;
{$ELSE}
  Result := P;
{$ENDIF}
end;

function VarValueToString(const P: VarValue): string;
{$IFDEF API_VAR_NEXTGEN}
var
  LStr: PChar;
  LStrLen: Integer;
begin
  case P^.Typa of
    vvFloat:
      Result := FloatToStr(VarValueToFloat(P));
    vvInt32, vvInt64:
      Result := IntToStr(VarValueToInt64(P));
    vvString:
      begin
        LStr := VarValuePtr(P);
        LStrLen := StrLen(LStr);
        SetString(Result, LStr, LStrLen);
      end;
  else
    Result := '';
  end;
{$ELSE}
begin
  Result := P;
{$ENDIF}
end;

function VarValueToVariant(const P: VarValue): Variant;
begin
{$IFDEF API_VAR_NEXTGEN}
  if P = nil then
    Exit(Null);
  case P^.Typa of
    vvFloat:
      Result := VarValueToFloat(P);
    vvInt32:
      Result := VarValueToInt32(P);
    vvInt64:
      Result := VarValueToInt64(P);
    vvString:
      Result := VarValueToString(P);
  else
    Result := Null;
  end;
{$ELSE}
  Result := P;
{$ENDIF}
end;
{$ENDREGION}
end.
