unit DemoCustomFileSystemMain;

{$I apiConfig.inc}

interface

uses
{$IFDEF MSWINDOWS}
  ShlObj,
  Windows,
{$ENDIF}
  // RTL
  Classes,
  SysUtils,
  System.IOUtils,
  Types,
  // API
  apiActions,
  apiCore,
  apiFileManager,
  apiMenu,
  apiObjects,
  apiPlaylists,
  apiPlugin,
  apiTypes,
  apiWrappers,
  AIMPCustomPlugin;

type

  { TMenuItemHandler }

  TMenuItemHandler = class(TInterfacedObject, IAIMPActionEvent)
  strict private
    FEvent: TNotifyEvent;
  public
    constructor Create(AEvent: TNotifyEvent);
    procedure OnExecute(Data: IInterface); stdcall;
  end;

  { TMyMusicFileSystem }

  (*
    Common idea of the TMyMusicFileSystem:
    1. Replace path to "My Music" system folder with the "mymusic" scheme when adding it to playlist
    2. Implement all file system commands that will be replace "mymusic" scheme by real path of the "MyMusic"
       folder and forward call to the "default" file system handler
  *)

  TMyMusicFileSystem = class(TAIMPPropertyList,
    IAIMPFileSystemCommandCopyToClipboard,
    IAIMPFileSystemCommandDelete,
    IAIMPFileSystemCommandDropSource,
    IAIMPFileSystemCommandFileInfo,
    IAIMPFileSystemCommandOpenFileFolder,
    IAIMPFileSystemCommandStreaming,
    IAIMPExtensionFileSystem)
  strict private
    FRootPath: string;

    function GetCommandForDefaultFileSystem(const IID: TGUID; out Obj): Boolean;
    function TranslateFileName(const AFileName: IAIMPString): IAIMPString;
  protected
    // IAIMPExtensionFileSystem
    procedure DoGetValue(PropertyID: Integer; out Value: Variant; var Result: HRESULT); override;
    // IAIMPFileSystemCommandCopyToClipboard
    function CopyToClipboard(Files: IAIMPObjectList): HRESULT; stdcall;
    // IAIMPFileSystemCommandDropSource
    function CreateStream(FileName: IAIMPString; out Stream: IAIMPStream): HRESULT; overload; stdcall;
    // IAIMPFileSystemCommandDelete
    function IAIMPFileSystemCommandDelete.CanProcess = CanDelete;
    function IAIMPFileSystemCommandDelete.Process = Delete;
    function CanDelete(FileName: IAIMPString): HRESULT; stdcall;
    function Delete(FileName: IAIMPString): HRESULT; stdcall;
    // IAIMPFileSystemCommandFileInfo
    function GetFileAttrs(FileName: IAIMPString; out Attrs: TAIMPFileAttributes): HRESULT; stdcall;
    function GetFileSize(FileName: IAIMPString; out Size: Int64): HRESULT; stdcall;
    function IsFileExists(FileName: IAIMPString): HRESULT; stdcall;
    // IAIMPFileSystemCommandOpenFileFolder
    function IAIMPFileSystemCommandOpenFileFolder.CanProcess = CanOpenFileFolder;
    function IAIMPFileSystemCommandOpenFileFolder.Process = OpenFileFolder;
    function CanOpenFileFolder(FileName: IAIMPString): HRESULT; stdcall;
    function OpenFileFolder(FileName: IAIMPString): HRESULT; stdcall;
    // IAIMPFileSystemCommandStreaming
    function CreateStream(FileName: IAIMPString; const Offset, Size: Int64;
      Flags: Cardinal; out Stream: IAIMPStream): HRESULT; overload; stdcall;
  public
    constructor Create; virtual;
  end;

  { TDemoCustomFileSystemPlugin }

  TDemoCustomFileSystemPlugin = class(TAIMPCustomPlugin)
  strict private
    procedure HandlerMenuItemClick(Sender: TObject);
  protected
    function InfoGet(Index: Integer): PChar; override; stdcall;
    function InfoGetCategories: Cardinal; override; stdcall;
    function Initialize(Core: IAIMPCore): HRESULT; override; stdcall;
  end;

implementation

const
  sMyScheme = 'mymusic';
  sMySchemePrefix = sMyScheme + '://';

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

{ TMenuItemHandler }

constructor TMenuItemHandler.Create(AEvent: TNotifyEvent);
begin
  FEvent := AEvent;
end;

procedure TMenuItemHandler.OnExecute(Data: IInterface); stdcall;
begin
  FEvent(nil);
end;

{ TMyMusicFileSystem }

constructor TMyMusicFileSystem.Create;
begin
  FRootPath := ShellGetMyMusic;
end;

procedure TMyMusicFileSystem.DoGetValue(
  PropertyID: Integer; out Value: Variant; var Result: HRESULT);
begin
  case PropertyID of
    AIMP_FILESYSTEM_PROPID_READONLY:
      Value := 0;
    AIMP_FILESYSTEM_PROPID_SCHEME:
      Value := sMyScheme;
  else
    inherited;
  end
end;

function TMyMusicFileSystem.CopyToClipboard(Files: IAIMPObjectList): HRESULT; stdcall;
var
  AFileName: IAIMPString;
  LIntf: IAIMPFileSystemCommandCopyToClipboard;
  AList: IAIMPObjectList;
  I: Integer;
begin
  if GetCommandForDefaultFileSystem(IAIMPFileSystemCommandCopyToClipboard, LIntf) then
  begin
    CoreCreateObject(IAIMPObjectList, AList);
    for I := 0 to Files.GetCount - 1 do
    begin
      if Succeeded(Files.GetObject(I, IAIMPString, AFileName)) then
        AList.Add(TranslateFileName(AFileName));
    end;
    Result := LIntf.CopyToClipboard(AList);
  end
  else
    Result := E_NOTIMPL;
end;

function TMyMusicFileSystem.CreateStream(FileName: IAIMPString; out Stream: IAIMPStream): HRESULT; stdcall;
begin
  Result := CreateStream(FileName, -1, -1, 0, Stream);
end;

function TMyMusicFileSystem.GetFileAttrs(FileName: IAIMPString; out Attrs: TAIMPFileAttributes): HRESULT; stdcall;
var
  LIntf: IAIMPFileSystemCommandFileInfo;
begin
  if GetCommandForDefaultFileSystem(IAIMPFileSystemCommandFileInfo, LIntf) then
    Result := LIntf.GetFileAttrs(TranslateFileName(FileName), Attrs)
  else
    Result := E_NOTIMPL;
end;

function TMyMusicFileSystem.GetFileSize(FileName: IAIMPString; out Size: Int64): HRESULT; stdcall;
var
  LIntf: IAIMPFileSystemCommandFileInfo;
begin
  if GetCommandForDefaultFileSystem(IAIMPFileSystemCommandFileInfo, LIntf) then
    Result := LIntf.GetFileSize(TranslateFileName(FileName), Size)
  else
    Result := E_NOTIMPL;
end;

function TMyMusicFileSystem.IsFileExists(FileName: IAIMPString): HRESULT; stdcall;
var
  LIntf: IAIMPFileSystemCommandFileInfo;
begin
  if GetCommandForDefaultFileSystem(IAIMPFileSystemCommandFileInfo, LIntf) then
    Result := LIntf.IsFileExists(TranslateFileName(FileName))
  else
    Result := E_NOTIMPL;
end;

function TMyMusicFileSystem.CanDelete(FileName: IAIMPString): HRESULT; stdcall;
var
  LIntf: IAIMPFileSystemCommandDelete;
begin
  if GetCommandForDefaultFileSystem(IAIMPFileSystemCommandDelete, LIntf) then
    Result := LIntf.CanProcess(TranslateFileName(FileName))
  else
    Result := E_NOTIMPL;
end;

function TMyMusicFileSystem.Delete(FileName: IAIMPString): HRESULT; stdcall;
var
  LIntf: IAIMPFileSystemCommandDelete;
begin
  if GetCommandForDefaultFileSystem(IAIMPFileSystemCommandDelete, LIntf) then
    Result := LIntf.Process(TranslateFileName(FileName))
  else
    Result := E_NOTIMPL;
end;

function TMyMusicFileSystem.CanOpenFileFolder(FileName: IAIMPString): HRESULT; stdcall;
var
  LIntf: IAIMPFileSystemCommandOpenFileFolder;
begin
  if GetCommandForDefaultFileSystem(IAIMPFileSystemCommandOpenFileFolder, LIntf) then
    Result := LIntf.CanProcess(TranslateFileName(FileName))
  else
    Result := E_NOTIMPL;
end;

function TMyMusicFileSystem.OpenFileFolder(FileName: IAIMPString): HRESULT; stdcall;
var
  LIntf: IAIMPFileSystemCommandOpenFileFolder;
begin
  if GetCommandForDefaultFileSystem(IAIMPFileSystemCommandOpenFileFolder, LIntf) then
    Result := LIntf.Process(TranslateFileName(FileName))
  else
    Result := E_NOTIMPL;
end;

function TMyMusicFileSystem.CreateStream(FileName: IAIMPString;
  const Offset, Size: Int64; Flags: Cardinal; out Stream: IAIMPStream): HRESULT; stdcall;
var
  LIntf: IAIMPFileSystemCommandStreaming;
begin
  if GetCommandForDefaultFileSystem(IAIMPFileSystemCommandStreaming, LIntf) then
    Result := LIntf.CreateStream(TranslateFileName(FileName), Offset, Size, Flags, Stream)
  else
    Result := E_NOTIMPL;
end;

function TMyMusicFileSystem.GetCommandForDefaultFileSystem(const IID: TGUID; out Obj): Boolean;
var
  AService: IAIMPServiceFileSystems;
begin
  Result := CoreGetService(IAIMPServiceFileSystems, AService) and Succeeded(AService.GetDefault(IID, Obj));
end;

function TMyMusicFileSystem.TranslateFileName(const AFileName: IAIMPString): IAIMPString;
begin
  CheckResult(AFileName.Clone(Result));
  Result.Replace(MakeString(sMySchemePrefix), MakeString(FRootPath), AIMP_STRING_FIND_IGNORECASE);
end;

{ TDemoCustomFileSystemPlugin }

function TDemoCustomFileSystemPlugin.InfoGet(Index: Integer): PChar; stdcall;
begin
  case Index of
    AIMP_PLUGIN_INFO_NAME:
      Result := 'MyMusic - Custom File System Demo';
    AIMP_PLUGIN_INFO_AUTHOR:
      Result := 'Artem Izmaylov';
  else
    Result := '';
  end;
end;

function TDemoCustomFileSystemPlugin.InfoGetCategories: Cardinal; stdcall;
begin
  Result := AIMP_PLUGIN_CATEGORY_ADDONS;
end;

function TDemoCustomFileSystemPlugin.Initialize(Core: IAIMPCore): HRESULT; stdcall;
var
  AMenuItem: IAIMPMenuItem;
  AMenuServiceIntf: IAIMPServiceMenuManager;
  AParentMenuItem: IAIMPMenuItem;
begin
  Result := inherited Initialize(Core);
  if Succeeded(Result) then
  begin
    // Create Menu item
    if CoreGetService(IAIMPServiceMenuManager, AMenuServiceIntf) then
    begin
      if Succeeded(AMenuServiceIntf.GetBuiltIn(AIMP_MENUID_PLAYER_PLAYLIST_ADDING, AParentMenuItem)) then
      begin
        CoreCreateObject(IAIMPMenuItem, AMenuItem);
        CheckResult(AMenuItem.SetValueAsObject(AIMP_MENUITEM_PROPID_NAME, MakeString('MyMusic: Add All Files')));
        CheckResult(AMenuItem.SetValueAsObject(AIMP_MENUITEM_PROPID_EVENT, TMenuItemHandler.Create(HandlerMenuItemClick)));
        CheckResult(AMenuItem.SetValueAsObject(AIMP_MENUITEM_PROPID_PARENT, AParentMenuItem));
        Core.RegisterExtension(IAIMPServiceMenuManager, AMenuItem);
      end;
    end;

    // Register custom file system
    Core.RegisterExtension(IAIMPServiceFileSystems, TMyMusicFileSystem.Create);
  end;
end;

procedure TDemoCustomFileSystemPlugin.HandlerMenuItemClick(Sender: TObject);
var
  AFileFormatService: IAIMPServiceFileFormats;
  AFileList: IAIMPObjectList;
  AFiles: TStringDynArray;
  APlaylist: IAIMPPlaylist;
  APlaylistService: IAIMPServicePlaylistManager;
  ARootPath: string;
  I: Integer;
begin
  if CoreGetService(IAIMPServiceFileFormats, AFileFormatService) then
  begin
    // Get all files from MyMusic folder and sub-folders
    ARootPath := ShellGetMyMusic;
    AFiles := TDirectory.GetFiles(ARootPath, '*', TSearchOption.soAllDirectories,
      {$IFDEF FPC}TFilterPredicate(nil){$ELSE}nil{$ENDIF});
    if Length(AFiles) = 0 then
      Exit;

    // Check the format type of returned files and replace the path of "My Music" folder by our scheme.
    CoreCreateObject(IAIMPObjectList, AFileList);
    for I := 0 to Length(AFiles) - 1 do
    begin
      if Succeeded(AFileFormatService.IsSupported(MakeString(AFiles[I]), AIMP_SERVICE_FILEFORMATS_CATEGORY_AUDIO)) then
        AFileList.Add(MakeString(sMySchemePrefix + Copy(AFiles[I], Length(ARootPath) + 1, MaxInt)));
    end;

    // Put supported files to the playlist
    if CoreGetService(IAIMPServicePlaylistManager, APlaylistService) then
    begin
      if Succeeded(APlaylistService.GetActivePlaylist(APlaylist)) then
        APlaylist.AddList(AFileList, AIMP_PLAYLIST_ADD_FLAGS_NOCHECKFORMAT, -1);
    end;
  end;
end;

end.
