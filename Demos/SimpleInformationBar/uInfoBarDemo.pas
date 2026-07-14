unit uInfoBarDemo;

{$I apiConfig.inc}

interface

uses
  Classes,
  Types,
  // API
  apiFileManager,
  apiOptions,
  apiObjects,
  apiCore,
  apiGUI,
  apiPlugin,
  apiPlayer,
  apiMessages,
  apiTypes,
  apiWrappers,
  AIMPCustomPlugin;

type

  { TAIMPDemoNowPlayingCard }

  TAIMPDemoNowPlayingCard = class
  strict private
    FAlbum: IAIMPUILabel;
    FAlbumArt: IAIMPUIImage;
    FArtist: IAIMPUILabel;
    FForm: IAIMPUIForm2;
    FTitle: IAIMPUILabel;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Show;
    procedure UpdateInfo(Info: IAIMPFileInfo);
  end;

  { TAIMPDemoPlugin }

  TAIMPDemoPlugin = class(TAIMPCustomPlugin, IAIMPMessageHook)
  strict private
    FCard: TAIMPDemoNowPlayingCard;

    procedure ShowPlayingFileInfo;
    // IAIMPMessageHook
    procedure CoreMessage(Message: Cardinal;
      P1: Integer; P2: Pointer; var Result: HRESULT); stdcall;
  protected
    procedure Finalize; override; stdcall;
    function InfoGet(Index: Integer): PChar; override; stdcall;
    function InfoGetCategories: Cardinal; override; stdcall;
    function Initialize(Core: IAIMPCore): HRESULT; override; stdcall;
  end;

implementation

uses
  SysUtils;

{ TAIMPDemoNowPlayingCard }

constructor TAIMPDemoNowPlayingCard.Create;
var
  LForm: IAIMPUIForm;
  LService: IAIMPServiceUI;
begin
  CoreGetService(IID_IAIMPServiceUI, LService);
  // Create Form
  LService.CreateForm(0, 0, nil, nil, LForm);
  FForm := LForm as IAIMPUIForm2;
  PropListSetInt32(FForm, AIMPUI_FORM_PROPID_BORDERSTYLE, AIMPUI_FLAGS_BORDERSTYLE_TOOLWINDOW);
  PropListSetInt32(FForm, AIMPUI_FORM_PROPID_CLIENTHEIGHT, 122);
  PropListSetInt32(FForm, AIMPUI_FORM_PROPID_CLIENTWIDTH, 568);
  PropListSetStr(FForm, AIMPUI_FORM_PROPID_CAPTION, 'Now Playing');
  // Create AlbumArt
  LService.CreateControl(FForm, FForm, nil, nil, IAIMPUIImage, FAlbumArt);
  FAlbumArt.SetPlacement(TAIMPUIControlPlacement.Create(Bounds(8, 8, 100, 100)));
  FAlbumArt.SetValueAsInt32(AIMPUI_IMAGE_PROPID_IMAGESTRETCHMODE, AIMP_IMAGE_DRAW_STRETCHMODE_FILL);
  // Create Title label
  LService.CreateControl(FForm, FForm, nil, nil, IAIMPUILabel, FTitle);
  FTitle.SetPlacement(TAIMPUIControlPlacement.Create(Bounds(116, 8, 100, 15)));
  FTitle.SetValueAsInt32(AIMPUI_LABEL_PROPID_AUTOSIZE, 1);
  // Create Album label
  LService.CreateControl(FForm, FForm, nil, nil, IAIMPUILabel, FAlbum);
  FAlbum.SetPlacement(TAIMPUIControlPlacement.Create(Bounds(116, 30, 100, 15)));
  FAlbum.SetValueAsInt32(AIMPUI_LABEL_PROPID_AUTOSIZE, 1);
  // Create Artist label
  LService.CreateControl(FForm, FForm, nil, nil, IAIMPUILabel, FArtist);
  FArtist.SetPlacement(TAIMPUIControlPlacement.Create(Bounds(116, 52, 100, 15)));
  FArtist.SetValueAsInt32(AIMPUI_LABEL_PROPID_AUTOSIZE, 1);
end;

destructor TAIMPDemoNowPlayingCard.Destroy;
begin
  FAlbum := nil;
  FAlbumArt := nil;
  FArtist := nil;
  FTitle := nil;
  FForm.Release(False);
  FForm := nil;
  inherited;
end;

procedure TAIMPDemoNowPlayingCard.Show;
begin
  FForm.ShowNoActivate;
end;

procedure TAIMPDemoNowPlayingCard.UpdateInfo(Info: IAIMPFileInfo);
begin
  FAlbum.SetValueAsObject(AIMPUI_LABEL_PROPID_TEXT,
    PropListGetObj(Info, AIMP_FILEINFO_PROPID_ALBUM));
  FArtist.SetValueAsObject(AIMPUI_LABEL_PROPID_TEXT,
    PropListGetObj(Info, AIMP_FILEINFO_PROPID_ARTIST));
  FTitle.SetValueAsObject(AIMPUI_LABEL_PROPID_TEXT,
    PropListGetObj(Info, AIMP_FILEINFO_PROPID_TITLE));
  FAlbumArt.SetValueAsObject(AIMPUI_IMAGE_PROPID_IMAGE,
    PropListGetObj(Info, AIMP_FILEINFO_PROPID_ALBUMART));
end;

{ TAIMPDemoPlugin }

procedure TAIMPDemoPlugin.CoreMessage(
  Message: Cardinal; P1: Integer; P2: Pointer; var Result: HRESULT);
begin
  case Message of
    AIMP_MSG_EVENT_STREAM_START,
    AIMP_MSG_EVENT_STREAM_START_SUBTRACK,
    AIMP_MSG_EVENT_STREAM_END,
    AIMP_MSG_EVENT_PLAYING_FILE_INFO:
      ShowPlayingFileInfo;
  end;
end;

procedure TAIMPDemoPlugin.Finalize;
var
  LService: IAIMPServiceMessageDispatcher;
begin
  if CoreGetService(IAIMPServiceMessageDispatcher, LService) then
    LService.Unhook(Self);
  FreeAndNil(FCard);
  inherited;
end;

function TAIMPDemoPlugin.InfoGet(Index: Integer): PChar;
begin
  case Index of
    AIMP_PLUGIN_INFO_NAME:
      Result := 'InfoBar Demo';
    AIMP_PLUGIN_INFO_AUTHOR:
      Result := 'Artem Izmaylov';
    AIMP_PLUGIN_INFO_SHORT_DESCRIPTION:
      Result := 'This plugin show how to fetch info about playing track';
  else
    Result := nil;
  end;
end;

function TAIMPDemoPlugin.InfoGetCategories: Cardinal;
begin
  Result := AIMP_PLUGIN_CATEGORY_ADDONS;
end;

function TAIMPDemoPlugin.Initialize(Core: IAIMPCore): HRESULT;
var
  LService: IAIMPServiceMessageDispatcher;
begin
  if CoreCheckVersion(Core, 6000) then // We use the API that was introduced in v6.0
  begin
    inherited;
    if CoreGetService(IAIMPServiceMessageDispatcher, LService) then
      LService.Hook(Self);
    Result := S_OK;
  end
  else
    Result := E_FAIL;
end;

procedure TAIMPDemoPlugin.ShowPlayingFileInfo;
var
  LService: IAIMPServicePlayer;
  LInfo: IAIMPFileInfo;
begin
  if CoreGetService(IAIMPServicePlayer, LService) and Succeeded(LService.GetInfo(LInfo)) then
  begin
    if FCard = nil then
      FCard := TAIMPDemoNowPlayingCard.Create;
    FCard.UpdateInfo(LInfo);
    FCard.Show;
  end
  else
    if FCard <> nil then
      FCard.UpdateInfo(nil);
end;

end.
