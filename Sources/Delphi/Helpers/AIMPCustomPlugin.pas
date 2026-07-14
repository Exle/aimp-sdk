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
unit AIMPCustomPlugin;

{$I apiConfig.inc}

interface

uses
  apiCore,
  apiObjects,
  apiPlugin,
  apiWrappers;

type

  { TAIMPCustomPlugin }

  TAIMPCustomPlugin = class(TInterfacedObjectEx, IAIMPPlugin)
  protected
    // IAIMPPlugin
    function InfoGet(Index: Integer): PChar; virtual; stdcall; abstract;
    function InfoGetCategories: LongWord; virtual; stdcall; abstract;
    function Initialize(Core: IAIMPCore): HRESULT; virtual; stdcall;
    procedure Finalize; virtual; stdcall;
    procedure SystemNotification(NotifyID: Integer; Data: IUnknown); virtual; stdcall;
  end;

implementation

uses
  SysUtils, apiMUI;

{ TAIMPCustomPlugin }

procedure TAIMPCustomPlugin.Finalize;
begin
  TAIMPAPIWrappers.Finalize;
end;

function TAIMPCustomPlugin.Initialize(Core: IAIMPCore): HRESULT;
begin
  TAIMPAPIWrappers.Initialize(Core);
  Result := S_OK;
end;

procedure TAIMPCustomPlugin.SystemNotification(NotifyID: Integer; Data: IUnknown);
begin
  // do nothing
end;

end.
