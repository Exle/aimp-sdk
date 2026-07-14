unit uPlugin;

{$I apiConfig.inc}

interface

uses
  AIMPCustomPlugin,
  // API
  apiCore,
  apiGUI,
  apiPlugin,
  apiTypes,
  apiWrappers,
  // Plugin
  uDemoForm,
  uDataProvider;

type

  { TAIMPMusicLibraryBrowserDemoPlugin }

  TAIMPMusicLibraryBrowserDemoPlugin = class(TAIMPCustomPlugin, IAIMPExternalSettingsDialog)
  strict private
    FDataProvider: TMLDataProvider;
  protected
    function Initialize(Core: IAIMPCore): HRESULT; override; stdcall;
    procedure Finalize; override; stdcall;
  public
    function InfoGet(Index: Integer): PChar; override;
    function InfoGetCategories: Cardinal; override;
    // IAIMPExternalSettingsDialog
    procedure Show(ParentWindow: HWND); stdcall;
  end;

implementation

{ TAIMPMusicLibraryBrowserDemoPlugin }

procedure TAIMPMusicLibraryBrowserDemoPlugin.Finalize;
begin
  inherited;
  FDataProvider.Free;
  FDataProvider := nil;
end;

function TAIMPMusicLibraryBrowserDemoPlugin.InfoGet(Index: Integer): PChar;
begin
  case Index of
    AIMP_PLUGIN_INFO_NAME:
      Result := 'MusicLibraryBrowser Demo';
    AIMP_PLUGIN_INFO_AUTHOR:
      Result := 'Artem Izmaylov';
    AIMP_PLUGIN_INFO_SHORT_DESCRIPTION:
      Result := 'Demo shows how to implement custom music library browser';
  else
    Result := nil;
  end;
end;

function TAIMPMusicLibraryBrowserDemoPlugin.InfoGetCategories: Cardinal;
begin
  Result := AIMP_PLUGIN_CATEGORY_ADDONS;
end;

function TAIMPMusicLibraryBrowserDemoPlugin.Initialize(Core: IAIMPCore): HRESULT;
begin
  if CoreCheckVersion(Core, 6000) then // We use the API that was introduced in v6.0
  begin
    Result := inherited;
    if Succeeded(Result) then
      FDataProvider := TMLDataProvider.Create;
  end
  else
    Result := E_FAIL;
end;

procedure TAIMPMusicLibraryBrowserDemoPlugin.Show(ParentWindow: HWND);
var
  AService: IAIMPServiceUI;
begin
  if CoreGetService(IAIMPServiceUI, AService) then
    TDemoForm.Create(AService, FDataProvider).ShowModal;
end;

end.
