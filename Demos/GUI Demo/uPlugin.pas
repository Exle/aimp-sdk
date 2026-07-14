unit uPlugin;

{$I apiConfig.inc}

interface

uses
  AIMPCustomPlugin,
  apiPlugin,
  apiTypes;

type

  { TAIMPGuiDemoPlugin }

  TAIMPGuiDemoPlugin = class(TAIMPCustomPlugin, IAIMPExternalSettingsDialog)
  public
    function InfoGet(Index: Integer): PChar; override;
    function InfoGetCategories: Cardinal; override;
    function Initialize(Core: IAIMPCore): HRESULT; override; stdcall;
    // IAIMPExternalSettingsDialog
    procedure Show(ParentWindow: HWND); stdcall;
  end;

implementation

uses
  uDemoForm, apiGUI, apiWrappers;

{ TAIMPGuiDemoPlugin }

function TAIMPGuiDemoPlugin.InfoGet(Index: Integer): PChar;
begin
  case Index of
    AIMP_PLUGIN_INFO_NAME:
      Result := 'GUI Demo';
    AIMP_PLUGIN_INFO_AUTHOR:
      Result := 'Artem Izmaylov';
    AIMP_PLUGIN_INFO_SHORT_DESCRIPTION:
      Result := 'Demo shows how to use GUI API';
  else
    Result := nil;
  end;
end;

function TAIMPGuiDemoPlugin.InfoGetCategories: Cardinal;
begin
  Result := AIMP_PLUGIN_CATEGORY_ADDONS;
end;

function TAIMPGuiDemoPlugin.Initialize(Core: IAIMPCore): HRESULT; stdcall;
begin
  if CoreCheckVersion(Core, 6000) then // We use the API that was introduced in v6.0
    Result := inherited
  else
    Result := E_FAIL;
end;

procedure TAIMPGuiDemoPlugin.Show(ParentWindow: HWND); stdcall;
var
  AService: IAIMPServiceUI;
begin
  if CoreGetService(IAIMPServiceUI, AService) then
    TDemoForm.Create(AService).ShowModal;
end;

end.
