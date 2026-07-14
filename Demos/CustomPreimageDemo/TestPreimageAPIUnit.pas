unit TestPreimageAPIUnit;

{$I apiConfig.inc}

interface

uses
{$IFDEF MSWINDOWS}
  ShellAPI,
  ShlObj,
  Windows,
{$ENDIF}
  Classes,
  Generics.Collections,
  Generics.Defaults,
  SysUtils,
  // API
  AIMPCustomPlugin,
  apiCore,
  apiMusicLibrary,
  apiObjects,
  apiGUI,
  apiPlaylists,
  apiPlugin,
  apiThreading,
  apiTypes,
  apiWrappers,
  apiWrappersGUI;

type
{$REGION ' Preimage Implementation '}
  TTestPreimage = class;

  { ITestPreimageFactory }

  ITestPreimageFactory = interface(IAIMPExtensionPlaylistPreimageFactory)
  ['{5FF0D01D-A956-47AE-80DA-76E10DDEA1C1}']
    procedure DataChanged;
  end;

  { TTestPreimageFactory }

  TTestPreimageFactory = class(TInterfacedObject,
    ITestPreimageFactory,
    IAIMPExtensionPlaylistPreimageFactory)
  protected
    FPreimages: TList<TTestPreimage>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure DataChanged;

    // IAIMPExtensionPlaylistPreimageFactory
    function CreatePreimage(out Intf: IAIMPPlaylistPreimage): HRESULT; stdcall;
    function GetID(out ID: IAIMPString): HRESULT; stdcall;
    function GetName(out Name: IAIMPString): HRESULT; stdcall;
    function GetFlags: Cardinal; stdcall;
  end;

  { TTestPreimage }

  TTestPreimage = class(TAIMPPropertyList,
    IAIMPPlaylistPreimageDataProvider,
    IAIMPPlaylistPreimage)
  strict private
    FFactory: TTestPreimageFactory;
    FManager: IAIMPPlaylistPreimageListener;
  protected
    procedure DoGetValue(PropID: Integer; out Value: Variant; var Result: HRESULT); override;
    function DoGetValueAsObject(PropertyID: Integer): IInterface; override;
  public
    constructor Create(AFactory: TTestPreimageFactory);
    destructor Destroy; override;
    procedure DataChanged;
    // IAIMPPlaylistPreimage
    procedure Finalize; stdcall;
    procedure Initialize(Manager: IAIMPPlaylistPreimageListener); stdcall;
    function ConfigLoad(Stream: IAIMPStream): HRESULT; stdcall;
    function ConfigSave(Stream: IAIMPStream): HRESULT; stdcall;
    function ExecuteDialog(OwnerWndHanle: HWND): HRESULT; stdcall;
    // IAIMPPlaylistPreimageDataProvider
    function GetFiles(Owner: IAIMPTaskOwner; out Flags: Cardinal; out List: IAIMPObjectList): HRESULT; stdcall;
  end;

{$ENDREGION}

{$REGION ' Test Form '}

  TTestPreimageDialog = class(TComponent, IAIMPExtensionPlaylistManagerListener)
  strict private
    FFactory: ITestPreimageFactory;
    FForm: IAIMPUIForm;
    FPlaylists: IAIMPUITreeList;
    FPreimageInfo: IAIMPUILabel;
    FSelectedPlaylistUUID: IAIMPString;
    FService: IAIMPServicePlaylistManager2;

    procedure ActionDataChanged;
    procedure ActionRelease;
    procedure ActionReload;
    procedure ActionSetCustom;
    procedure ActionSetFolders;
    procedure ActionTestIO;
    procedure CreateGUI;
    procedure OnNodeSelected(Sender: IAIMPUITreeList; Node: IAIMPUITreeListNode);
    procedure UpdatePreimageInfo;
    // IAIMPExtensionPlaylistManagerListener
    procedure PlaylistActivated(APlaylist: IAIMPPlaylist); stdcall;
    procedure PlaylistAdded(APlaylist: IAIMPPlaylist); stdcall;
    procedure PlaylistRemoved(APlaylist: IAIMPPlaylist); stdcall;
  strict private
    function GetPlaylistPreimage(APlaylist: IAIMPPlaylist; out APreimage: IAIMPPlaylistPreimage): Boolean;
    function GetPreimageInfo(APreimage: IAIMPPlaylistPreimage): string;
    function GetSelectedPlaylist(out APlaylist: IAIMPPlaylist): Boolean;
    procedure SetPlaylistPreimage(APlaylist: IAIMPPlaylist; APreimage: IAIMPPlaylistPreimage);
  public
    constructor Create(AService: IAIMPServicePlaylistManager2); reintroduce;
    destructor Destroy; override;
  end;

{$ENDREGION}

  { TTestPreimageAPIPlugin }

  TTestPreimageAPIPlugin = class(TAIMPCustomPlugin)
  strict private
    FForm: TTestPreimageDialog;
  protected
    function InfoGet(Index: Integer): PChar; override; stdcall;
    function InfoGetCategories: Cardinal; override; stdcall;
    function Initialize(Core: IAIMPCore): HRESULT; override; stdcall;
    procedure Finalize; override; stdcall;
  end;

implementation

{$IFDEF LINUX}
function g_get_user_special_dir(directory: DWORD): PChar; cdecl; external 'libgobject-2.0.so.0';
{$ENDIF}

function ShellGetMyMusic: string;
{$IFDEF MSWINDOWS}
var
  LBuffer: array[0..MAX_PATH] of WideChar;
begin
  if SHGetSpecialFolderPathW(0, @LBuffer[0], CSIDL_MYMUSIC, False) then
    Result := IncludeTrailingPathDelimiter(LBuffer)
  else
    Result := '';
{$ELSE}
begin
  Result := IncludeTrailingPathDelimiter(g_get_user_special_dir({G_USER_DIRECTORY_MUSIC}3));
{$ENDIF}
end;

{$REGION ' Preimage Implementation '}

{ TTestPreimage }

constructor TTestPreimage.Create(AFactory: TTestPreimageFactory);
begin
  inherited Create;
  FFactory := AFactory;
  FFactory.FPreimages.Add(Self);
end;

destructor TTestPreimage.Destroy;
begin
  FFactory.FPreimages.Remove(Self);
  FManager := nil;
  inherited Destroy;
end;

procedure TTestPreimage.DataChanged;
begin
  if FManager <> nil then
    FManager.DataChanged;
end;

procedure TTestPreimage.Finalize;
begin
  FManager := nil;
end;

procedure TTestPreimage.Initialize(Manager: IAIMPPlaylistPreimageListener);
begin
  FManager := Manager;
end;

function TTestPreimage.ConfigLoad(Stream: IAIMPStream): HRESULT;
begin
  Result := S_OK;
end;

function TTestPreimage.ConfigSave(Stream: IAIMPStream): HRESULT;
begin
  Result := S_OK;
end;

function TTestPreimage.ExecuteDialog(OwnerWndHanle: HWND): HRESULT;
var
  LMessage: IAIMPUIMessageDialog;
begin
  if CoreGetService(IAIMPUIMessageDialog, LMessage) then
    LMessage.Execute(OwnerWndHanle, MakeString('Preimage'), MakeString('Clicked!'), MB_ICONINFORMATION);
  Result := S_OK;
end;

procedure TTestPreimage.DoGetValue(PropID: Integer; out Value: Variant; var Result: HRESULT);
begin
  case PropID of
    AIMP_PLAYLISTPREIMAGE_PROPID_AUTOSYNC,
    AIMP_PLAYLISTPREIMAGE_PROPID_HASDIALOG:
      Value := 1;
  else
    inherited;
  end;
end;

function TTestPreimage.DoGetValueAsObject(PropertyID: Integer): IInterface;
var
  ID: IAIMPString;
begin
  if PropertyID = AIMP_PLAYLISTPREIMAGE_PROPID_FACTORYID then
  begin
    if Succeeded(FFactory.GetID(ID)) then
      Result := ID
    else
      Result := nil;
  end
  else
    Result := inherited DoGetValueAsObject(PropertyID);
end;

function TTestPreimage.GetFiles(Owner: IAIMPTaskOwner; out Flags: Cardinal; out List: IAIMPObjectList): HRESULT;
begin
  Flags := 0; // Combination of AIMP_PLAYLIST_ADD_FLAGS_XXX
  CoreCreateObject(IAIMPObjectList, List);
  CheckResult(List.Add(MakeString(ShellGetMyMusic)));
  Result := S_OK;
end;

{ TTestPreimageFactory }

constructor TTestPreimageFactory.Create;
begin
  inherited Create;
  FPreimages := TList<TTestPreimage>.Create;
end;

destructor TTestPreimageFactory.Destroy;
begin
  FreeAndNil(FPreimages);
  inherited Destroy;
end;

procedure TTestPreimageFactory.DataChanged;
var
  I: Integer;
begin
  for I := FPreimages.Count - 1 downto 0 do
    FPreimages[I].DataChanged;
end;

function TTestPreimageFactory.CreatePreimage(out Intf: IAIMPPlaylistPreimage): HRESULT;
begin
  Intf := TTestPreimage.Create(Self);
  Result := S_OK;
end;

function TTestPreimageFactory.GetID(out ID: IAIMPString): HRESULT;
begin
  ID := MakeString(ClassName);
  Result := S_OK;
end;

function TTestPreimageFactory.GetName(out Name: IAIMPString): HRESULT;
begin
  Name := MakeString('Test Preimage');
  Result := S_OK;
end;

function TTestPreimageFactory.GetFlags: DWORD;
begin
  Result := 0;
end;

{$ENDREGION}

{$REGION ' Test Form '}

constructor TTestPreimageDialog.Create(AService: IAIMPServicePlaylistManager2);
var
  I: Integer;
  LPlaylist: IAIMPPlaylist;
begin
  FService := AService;
  FFactory := TTestPreimageFactory.Create;

  // Create the GUI
  CreateGUI;

  // Register our extensions
  CoreIntf.RegisterExtension(IAIMPServicePlaylistManager, Self);
  CoreIntf.RegisterExtension(IAIMPServicePlaylistManager, FFactory);

  // List already loaded playlists (if plugin loads after after start)
  for I := 0 to AService.GetLoadedPlaylistCount - 1 do
  begin
    if Succeeded(AService.GetLoadedPlaylist(I, LPlaylist)) then
      PlaylistAdded(LPlaylist);
  end;
end;

procedure TTestPreimageDialog.CreateGUI;
var
  LButton: IAIMPUIButton;
  LGroup: IAIMPUIGroupBox;
  LGUI: IAIMPServiceUI;
  LPanel: IAIMPUIPanel;
begin
  // Create the form
  CoreGetService(IAIMPServiceUI, LGUI);
  CheckResult(LGUI.CreateForm(0, 0, nil, nil, FForm));
  PropListSetStr(FForm, AIMPUI_FORM_PROPID_CAPTION, 'Preimage Tester');
  PropListSetInt32(FForm, AIMPUI_FORM_PROPID_BORDERSTYLE, AIMPUI_FLAGS_BORDERSTYLE_TOOLWINDOW);
  PropListSetInt32(FForm, AIMPUI_FORM_PROPID_CLIENTHEIGHT, 345);
  PropListSetInt32(FForm, AIMPUI_FORM_PROPID_CLIENTWIDTH, 580);

  // Create "Loaded Playlists" group box
  CheckResult(LGUI.CreateControl(FForm, FForm, nil, nil, IAIMPUIGroupBox, LGroup));
  PropListSetStr(LGroup, AIMPUI_GROUPBOX_PROPID_CAPTION, 'Loaded Playlists');
  LGroup.SetPlacement(TAIMPUIControlPlacement.Create(ualTop, 284));

    // Create "Loaded Playlists" list
    CheckResult(LGUI.CreateControl(FForm, LGroup, nil,
      TAIMPUITreeListNodeSelectEventAdapter.Create(OnNodeSelected),
      IAIMPUITreeList, FPlaylists));
    FPlaylists.SetPlacement(TAIMPUIControlPlacement.Create(ualClient, 0));
    PropListSetBool(FPlaylists, AIMPUI_TL_PROPID_COLUMN_VISIBLE, False);

    // Create "Toolbar"
    CheckResult(LGUI.CreateControl(FForm, LGroup, nil, nil, IAIMPUIPanel, LPanel));
    LPanel.SetPlacement(TAIMPUIControlPlacement.Create(ualBottom, 25));
    PropListSetInt32(LPanel, AIMPUI_PANEL_PROPID_BORDERS, 0);

      CheckResult(LGUI.CreateControl(FForm, LPanel, nil, uiWrap(ActionReload), IAIMPUIButton, LButton));
      LButton.SetPlacement(TAIMPUIControlPlacement.Create(ualLeft, 100, Rect(0, 0, 6, 0)));
      PropListSetStr(LButton, AIMPUI_BUTTON_PROPID_CAPTION, 'Reload');

      CheckResult(LGUI.CreateControl(FForm, LPanel, nil, uiWrap(ActionRelease), IAIMPUIButton, LButton));
      LButton.SetPlacement(TAIMPUIControlPlacement.Create(ualLeft, 100, Rect(0, 0, 6, 0)));
      PropListSetStr(LButton, AIMPUI_BUTTON_PROPID_CAPTION, 'Release');

      CheckResult(LGUI.CreateControl(FForm, LPanel, nil, uiWrap(ActionSetFolders), IAIMPUIButton, LButton));
      LButton.SetPlacement(TAIMPUIControlPlacement.Create(ualLeft, 100, Rect(0, 0, 6, 0)));
      PropListSetStr(LButton, AIMPUI_BUTTON_PROPID_CAPTION, 'SetFolders');

      CheckResult(LGUI.CreateControl(FForm, LPanel, nil, uiWrap(ActionSetCustom), IAIMPUIButton, LButton));
      LButton.SetPlacement(TAIMPUIControlPlacement.Create(ualLeft, 100, Rect(0, 0, 6, 0)));
      PropListSetStr(LButton, AIMPUI_BUTTON_PROPID_CAPTION, 'SetCustom');

      CheckResult(LGUI.CreateControl(FForm, LPanel, nil, uiWrap(ActionTestIO), IAIMPUIButton, LButton));
      LButton.SetPlacement(TAIMPUIControlPlacement.Create(ualLeft, 100, Rect(0, 0, 6, 0)));
      PropListSetStr(LButton, AIMPUI_BUTTON_PROPID_CAPTION, 'TestIO');

    // Preimage Info
    CheckResult(LGUI.CreateControl(FForm, LGroup, nil, nil, IAIMPUILabel, FPreimageInfo));
    FPreimageInfo.SetPlacement(TAIMPUIControlPlacement.Create(ualBottom, 15));

  // Create "Custom Preimage Factory" group box
  CheckResult(LGUI.CreateControl(FForm, FForm, nil, nil, IAIMPUIGroupBox, LGroup));
  PropListSetStr(LGroup, AIMPUI_GROUPBOX_PROPID_CAPTION, 'Custom Preimage Factory');
  LGroup.SetPlacement(TAIMPUIControlPlacement.Create(ualBottom, 50));

    CheckResult(LGUI.CreateControl(FForm, LGroup, nil, uiWrap(ActionDataChanged), IAIMPUIButton, LButton));
    LButton.SetPlacement(TAIMPUIControlPlacement.Create(ualLeft, 100, Rect(0, 0, 6, 0)));
    PropListSetStr(LButton, AIMPUI_BUTTON_PROPID_CAPTION, 'ReloadData');

  PropListSetBool(FForm, AIMPUI_CONTROL_PROPID_VISIBLE, True);
end;

destructor TTestPreimageDialog.Destroy;
begin
  FService := nil;
  FPlaylists := nil;
  CoreIntf.UnregisterExtension(FFactory);
  CoreIntf.UnregisterExtension(Self);
  FForm.Release(False);
  FForm := nil;
  inherited;
end;

procedure TTestPreimageDialog.ActionDataChanged;
begin
  FFactory.DataChanged;
end;

procedure TTestPreimageDialog.ActionRelease;
var
  LPlaylist: IAIMPPlaylist;
begin
  if GetSelectedPlaylist(LPlaylist) then
    SetPlaylistPreimage(LPlaylist, nil);
  UpdatePreimageInfo;
end;

procedure TTestPreimageDialog.ActionReload;
var
  LPlaylist: IAIMPPlaylist;
  LPreimage: IAIMPPlaylistPreimage;
begin
  if GetSelectedPlaylist(LPlaylist) then
  begin
  {$REGION ' Test yourself '}
    if GetPlaylistPreimage(LPlaylist, LPreimage) then
      SetPlaylistPreimage(LPlaylist, LPreimage);
  {$ENDREGION}
    LPlaylist.ReloadFromPreimage;
  end;
end;

procedure TTestPreimageDialog.ActionSetCustom;
var
  LPlaylist: IAIMPPlaylist;
  LPreimage: IAIMPPlaylistPreimage;
begin
  if GetSelectedPlaylist(LPlaylist) then
  begin
    CheckResult(FFactory.CreatePreimage(LPreimage));
    LPreimage.SetValueAsInt32(AIMP_PLAYLISTPREIMAGE_PROPID_AUTOSYNC, 1);
    SetPlaylistPreimage(LPlaylist, LPreimage);
  end;
  UpdatePreimageInfo;
end;

procedure TTestPreimageDialog.ActionSetFolders;
var
  LFactory: IAIMPExtensionPlaylistPreimageFactory;
  LPlaylist: IAIMPPlaylist;
  LPreimage: IAIMPPlaylistPreimage;
  LPreimageFolders: IAIMPPlaylistPreimageFolders;
begin
  if GetSelectedPlaylist(LPlaylist) then
  begin
    CheckResult(FService.GetPreimageFactoryByID(MakeString(AIMP_PREIMAGEFACTORY_FOLDERS_ID), LFactory));
    CheckResult(LFactory.CreatePreimage(LPreimage));
    LPreimageFolders := LPreimage as IAIMPPlaylistPreimageFolders;
    LPreimageFolders.SetValueAsInt32(AIMP_PLAYLISTPREIMAGE_PROPID_AUTOSYNC, 1);
    LPreimageFolders.ItemsAdd(MakeString(ShellGetMyMusic), True);
    SetPlaylistPreimage(LPlaylist, LPreimageFolders);
  end;
  UpdatePreimageInfo;
end;

procedure TTestPreimageDialog.ActionTestIO;
var
  LPlaylist: IAIMPPlaylist;
  LPlaylistPreimage: IAIMPPlaylistPreimage;
  LStream: IAIMPMemoryStream;
begin
  if GetSelectedPlaylist(LPlaylist) and GetPlaylistPreimage(LPlaylist, LPlaylistPreimage) then
  begin
    CoreCreateObject(IAIMPMemoryStream, LStream);
    CheckResult(LPlaylistPreimage.ConfigSave(LStream));
    CheckResult(LPlaylistPreimage.Reset);
    CheckResult(LStream.Seek(0, AIMP_STREAM_SEEKMODE_FROM_BEGINNING));
    CheckResult(LPlaylistPreimage.ConfigLoad(LStream));
  end;
end;

function TTestPreimageDialog.GetPlaylistPreimage(
  APlaylist: IAIMPPlaylist; out APreimage: IAIMPPlaylistPreimage): Boolean;
begin
  Result := Succeeded((APlaylist as IAIMPPropertyList).GetValueAsObject(
    AIMP_PLAYLIST_PROPID_PREIMAGE, IAIMPPlaylistPreimage, APreimage));
end;

function TTestPreimageDialog.GetPreimageInfo(APreimage: IAIMPPlaylistPreimage): string;
var
  LType: string;
begin
  LType := PropListGetStr(APreimage, AIMP_PLAYLISTPREIMAGE_PROPID_FACTORYID);
  if Supports(APreimage, IAIMPPlaylistPreimageFolders) then
    LType := LType + ' (Folders)';
  if Supports(APreimage, IAIMPMLPlaylistPreimage) then
    LType := LType + ' (Music Library)';
  Result := Format('Preimage: %s [%x]', [LType, NativeUInt(APreimage)]);
end;

function TTestPreimageDialog.GetSelectedPlaylist(out APlaylist: IAIMPPlaylist): Boolean;
begin
  Result := (FSelectedPlaylistUUID <> nil) and
    Succeeded(FService.GetLoadedPlaylistByID(FSelectedPlaylistUUID, APlaylist));
end;

procedure TTestPreimageDialog.OnNodeSelected(Sender: IAIMPUITreeList; Node: IAIMPUITreeListNode);
begin
  if (Node = nil) or Failed(Node.GetValue(1, FSelectedPlaylistUUID)) then
    FSelectedPlaylistUUID := nil;
  UpdatePreimageInfo;
end;

procedure TTestPreimageDialog.PlaylistActivated(APlaylist: IAIMPPlaylist);
begin
  // do nothing
end;

procedure TTestPreimageDialog.PlaylistAdded(APlaylist: IAIMPPlaylist);
var
  LNode: IAIMPUITreeListNode;
  LProperties: IAIMPPropertyList;
  LRoot: IAIMPUITreeListNode;
  LText: IAIMPString;
begin
  if Succeeded(FPlaylists.GetRootNode(IAIMPUITreeListNode, LRoot)) and Succeeded(LRoot.Add(LNode)) then
  begin
    LProperties := APlaylist as IAIMPPropertyList;
    if PropListGetStr(LProperties, AIMP_PLAYLIST_PROPID_NAME, LText) then
      LNode.SetValue(0, LText);
    if PropListGetStr(LProperties, AIMP_PLAYLIST_PROPID_ID, LText) then
      LNode.SetValue(1, LText);
  end;
end;

procedure TTestPreimageDialog.PlaylistRemoved(APlaylist: IAIMPPlaylist);
var
  LID: IAIMPString;
  LNode: IAIMPUITreeListNode;
  LRoot: IAIMPUITreeListNode;
begin
  if Succeeded(FPlaylists.GetRootNode(IAIMPUITreeListNode, LRoot)) then
  begin
    if PropListGetStr(APlaylist as IAIMPPropertyList, AIMP_PLAYLIST_PROPID_ID, LID) then
    begin
      if Succeeded(LRoot.FindByValue(1, LID, True, IAIMPUITreeListNode, LNode)) then
        FPlaylists.Delete(LNode);
    end;
  end;
end;

procedure TTestPreimageDialog.SetPlaylistPreimage(
  APlaylist: IAIMPPlaylist; APreimage: IAIMPPlaylistPreimage);
begin
  (APlaylist as IAIMPPropertyList).SetValueAsObject(AIMP_PLAYLIST_PROPID_PREIMAGE, APreimage);
end;

procedure TTestPreimageDialog.UpdatePreimageInfo;
var
  LPlaylist: IAIMPPlaylist;
  LPlaylistPreimage: IAIMPPlaylistPreimage;
  LPlaylistPreimageInfo: string;
begin
  if not GetSelectedPlaylist(LPlaylist) then
    LPlaylistPreimageInfo := ''
  else if GetPlaylistPreimage(LPlaylist, LPlaylistPreimage) then
    LPlaylistPreimageInfo := GetPreimageInfo(LPlaylistPreimage)
  else
    LPlaylistPreimageInfo := 'Playlist has no preimage';

  PropListSetStr(FPreimageInfo, AIMPUI_LABEL_PROPID_TEXT, LPlaylistPreimageInfo);
end;

{$ENDREGION}

{ TTestPreimageAPIPlugin }

procedure TTestPreimageAPIPlugin.Finalize;
begin
  FreeAndNil(FForm);
  inherited;
end;

function TTestPreimageAPIPlugin.InfoGet(Index: Integer): PChar;
begin
  Result := 'Test Preimage Plugin';
end;

function TTestPreimageAPIPlugin.InfoGetCategories: Cardinal;
begin
  Result := AIMP_PLUGIN_CATEGORY_ADDONS;
end;

function TTestPreimageAPIPlugin.Initialize(Core: IAIMPCore): HRESULT;
var
  LService: IAIMPServicePlaylistManager2;
begin
  if not CoreCheckVersion(Core, 6000) then // We use the API that was introduced in v6.0
    Exit(E_FAIL);
  inherited;
  if CoreGetService(IAIMPServicePlaylistManager2, LService) then
    FForm := TTestPreimageDialog.Create(LService);
  Result := S_OK;
end;

end.
