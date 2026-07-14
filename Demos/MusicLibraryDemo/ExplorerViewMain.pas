unit ExplorerViewMain;

{$I apiConfig.inc}

interface

uses
  Classes,
  System.IOUtils,
  SysUtils,
  // API
  apiCore,
  apiFileManager,
  apiMusicLibrary,
  apiObjects,
  apiPlugin,
  apiTypes,
  apiWrappers,
  // Wrappers
  AIMPCustomPlugin;

type

  { TDemoExplorerViewPlugin }

  TDemoExplorerViewPlugin = class(TAIMPCustomPlugin)
  protected
    function InfoGet(Index: Integer): PChar; override; stdcall;
    function InfoGetCategories: LongWord; override; stdcall;
    function Initialize(Core: IAIMPCore): HRESULT; override; stdcall;
  end;

  { TDemoExplorerViewDataStorage }

  TDemoExplorerViewDataStorage = class(TAIMPPropertyList,
    IAIMPMLDataProvider,
    IAIMPMLExtensionDataStorage)
  strict private
    FManager: IAIMPMLDataStorageManager;

    function CreateField(const AName: string; AType: Integer; AFlags: Integer = 0): IAIMPMLDataField;
    function GetRootPath(const AFilter: IAIMPMLDataFilter; out APath: string): Boolean;
  protected
    procedure DoGetValue(PropID: Integer; out Value: Variant; var Result: HRESULT); override;
    function DoGetValueAsObject(PropertyID: Integer): IInterface; override;
  public
    // IAIMPMLDataProvider
    function GetData(Fields: IAIMPObjectList; Filter: IAIMPMLDataFilter; out Data: IUnknown): HRESULT; stdcall;

    // IAIMPMLExtensionDataStorage
    function ConfigLoad(Config: IAIMPConfig; Section: IAIMPString): HRESULT; stdcall;
    function ConfigSave(Config: IAIMPConfig; Section: IAIMPString): HRESULT; stdcall;
    function GetFields(Schema: Integer; out List: IAIMPObjectList): HRESULT; stdcall;
    function GetGroupingPresets(Schema: Integer; Presets: IAIMPMLGroupingPresets): HRESULT; stdcall;
    procedure Finalize; stdcall;
    procedure FlushCache(Reserved: Integer); stdcall;
    procedure Initialize(AManager: IAIMPMLDataStorageManager); stdcall;
  end;

  { TDemoExplorerViewAbstractDataProviderSelection }

  TDemoExplorerViewAbstractDataProviderSelection = class abstract(TInterfacedObject,
    IAIMPMLDataProviderSelection)
  strict private
    FTempBuffer: string;
  public
    // IAIMPMLDataProviderSelection
    function GetValueAsFloat(AFieldIndex: Integer): Double; virtual; stdcall;
    function GetValueAsInt32(AFieldIndex: Integer): Integer; virtual; stdcall;
    function GetValueAsInt64(AFieldIndex: Integer): Int64; virtual; stdcall;
    function GetValueAsString(AFieldIndex: Integer; out ALength: Integer): PChar; overload; stdcall;
    function GetValueAsString(AFieldIndex: Integer): string; overload; virtual; abstract;
    function NextRow: LongBool; virtual; stdcall; abstract;
  end;

  { TDemoExplorerViewCustomDataProviderSelection }

  TDemoExplorerViewCustomDataProviderSelection = class abstract(TDemoExplorerViewAbstractDataProviderSelection)
  protected
    FRootPath: string;
    FSearchRec: TSearchRec;
    function CheckRecordAttr: Boolean; virtual; abstract;
  public
    constructor Create(const APath: string);
    destructor Destroy; override;
    function NextRow: LongBool; override;
  end;

  { TDemoExplorerViewGroupingTreeFoldersProvider }

  TDemoExplorerViewGroupingTreeFoldersProvider = class(TDemoExplorerViewCustomDataProviderSelection)
  protected
    function CheckRecordAttr: Boolean; override;
  public
    function GetValueAsString(AFieldIndex: Integer): string; override;
  end;

  { TDemoExplorerViewGroupingTreeRootProvider }

  TDemoExplorerViewGroupingTreeRootProvider = class(TDemoExplorerViewAbstractDataProviderSelection)
  strict private
    FList: TStrings;
    FListIndex: Integer;
  public
    constructor Create;
    destructor Destroy; override;
    function GetValueAsString(AFieldIndex: Integer): string; override;
    function NextRow: LongBool; override; stdcall;
  end;

  { TDemoExplorerViewDataProviderSelection }

  TDemoExplorerViewDataProviderSelection = class(TDemoExplorerViewCustomDataProviderSelection)
  strict private
    FAudioExts: string;
    FFieldFileAccessTime: Integer;
    FFieldFileCreationTime: Integer;
    FFieldFileFormat: Integer;
    FFieldFileName: Integer;
    FFieldID: Integer;
  protected
    function CheckRecordAttr: Boolean; override;
  public
    constructor Create(const APath: string; AFields: IAIMPObjectList);
    function GetValueAsFloat(FieldIndex: Integer): Double; override;
    function GetValueAsInt64(FieldIndex: Integer): Int64; override;
    function GetValueAsString(AFieldIndex: Integer): string; override;
  end;

implementation

{$IF DEFINED(HAS_ACL)}
uses
  ACL.Utils.FileSystem.Watcher;
{$ENDIF}

const
  // DataStorage Fields
  EVDS_ID               = AIMPML_RESERVED_FIELD_ID;
  EVDS_FileName         = AIMPML_RESERVED_FIELD_FILENAME;
  EVDS_FileFormat       = 'FileFormat';
  EVDS_FileAccessTime   = 'FileAccessTime';
  EVDS_FileCreationTime = 'FileCreationTime';
  EVDS_FileSize         = 'FileSize';
  EVDS_Fake             = 'Fake';

type
  TEnumDataFieldFiltersProc = reference to function (AFilter: IAIMPMLDataFieldFilter): Boolean;

function EnumDataFieldFilters(
  const AFilter: IAIMPMLDataFilterGroup;
  const AProc: TEnumDataFieldFiltersProc): Boolean;
var
  AFieldFilter: IAIMPMLDataFieldFilter;
  AGroup: IAIMPMLDataFilterGroup;
  I: Integer;
begin
  Result := False;
  if AFilter <> nil then
    for I := 0 to AFilter.GetChildCount - 1 do
    begin
      if Succeeded(AFilter.GetChild(I, IAIMPMLDataFilterGroup, AGroup)) then
        Result := EnumDataFieldFilters(AGroup, AProc)
      else
        if Succeeded(AFilter.GetChild(I, IAIMPMLDataFieldFilter, AFieldFilter)) then
          Result := AProc(AFieldFilter);

      if Result then
        Break;
    end;
end;

function GetFieldIndex(AFields: IAIMPObjectList; const AFieldName: string): Integer;
var
  S: IAIMPString;
  I: Integer;
begin
  Result := -1;
  for I := 0 to AFields.GetCount - 1 do
    if Succeeded(AFields.GetObject(I, IAIMPString, S)) then
    begin
      if IAIMPStringToString(S) = AFieldName then
        Exit(I);
    end;
end;

function acExtractFileFormat(const FileName: string): string;
var
  I: Integer;
begin
  I := LastDelimiter('.\/', FileName);
  if (I > 0) and (FileName[I] = '.') then
    Result := UpperCase(Copy(FileName, I + 1, MaxInt))
  else
    Result := '';
end;

{ TDemoExplorerViewPlugin }

function TDemoExplorerViewPlugin.InfoGet(Index: Integer): PChar;
begin
  case Index of
    AIMP_PLUGIN_INFO_NAME:
      Result := 'Explorer View Demo';
    AIMP_PLUGIN_INFO_SHORT_DESCRIPTION:
      Result := 'Shows how to integrate a custom data source into the Music Library';
    AIMP_PLUGIN_INFO_AUTHOR:
      Result := 'Artem Izmaylov';
  else
    Result := '';
  end;
end;

function TDemoExplorerViewPlugin.InfoGetCategories: Cardinal;
begin
  Result := AIMP_PLUGIN_CATEGORY_ADDONS;
end;

function TDemoExplorerViewPlugin.Initialize(Core: IAIMPCore): HRESULT;
begin
  Result := inherited Initialize(Core);
{$IF DEFINED(HAS_ACL)}
  TACLDriveManager.EnsureInit;
{$ENDIF}
  Core.RegisterExtension(IAIMPServiceMusicLibrary, TDemoExplorerViewDataStorage.Create);
end;

{ TDemoExplorerViewDataStorage }

function TDemoExplorerViewDataStorage.GetData(
  Fields: IAIMPObjectList; Filter: IAIMPMLDataFilter; out Data: IInterface): HRESULT;
var
  LPath: string;
begin
  try
    if (Fields.GetCount = 1) and (GetFieldIndex(Fields, EVDS_Fake) = 0) then // Is it request from grouping tree?
    begin
      if GetRootPath(Filter, LPath) then
        Data := TDemoExplorerViewGroupingTreeFoldersProvider.Create(LPath)
      else
        Data := TDemoExplorerViewGroupingTreeRootProvider.Create;
    end
    else
      if GetRootPath(Filter, LPath) then
        Data := TDemoExplorerViewDataProviderSelection.Create(LPath, Fields)
      else
        Data := LangLoadStringEx('ExplorerView\NoData');

    Result := S_OK;
  except
    Result := E_FAIL;
  end;
end;

function TDemoExplorerViewDataStorage.ConfigLoad(Config: IAIMPConfig; Section: IAIMPString): HRESULT;
begin
  Result := S_OK;
end;

function TDemoExplorerViewDataStorage.ConfigSave(Config: IAIMPConfig; Section: IAIMPString): HRESULT;
begin
  Result := S_OK;
end;

function TDemoExplorerViewDataStorage.GetFields(Schema: Integer; out List: IAIMPObjectList): HRESULT;
begin
  CoreCreateObject(IAIMPObjectList, List);
  case Schema of
    AIMPML_FIELDS_SCHEMA_ALL:
      begin
        List.Add(CreateField(EVDS_ID, AIMPML_FIELDTYPE_STRING, AIMPML_FIELDFLAG_INTERNAL));
        List.Add(CreateField(EVDS_FileName, 0));
        List.Add(CreateField(EVDS_FileFormat, AIMPML_FIELDTYPE_STRING));
        List.Add(CreateField(EVDS_FileSize, AIMPML_FIELDTYPE_FILESIZE));
        List.Add(CreateField(EVDS_FileAccessTime, AIMPML_FIELDTYPE_DATETIME));
        List.Add(CreateField(EVDS_FileCreationTime, AIMPML_FIELDTYPE_DATETIME));

        // EVDS_Fake is a fake field, that uses to populate GroupingTree data
        List.Add(CreateField(EVDS_Fake, AIMPML_FIELDTYPE_FILENAME,
          AIMPML_FIELDFLAG_INTERNAL or AIMPML_FIELDFLAG_GROUPING));
      end;

    AIMPML_FIELDS_SCHEMA_TABLE_VIEW_DEFAULT,
    AIMPML_FIELDS_SCHEMA_TABLE_VIEW_ALBUMTHUMBNAILS,
    AIMPML_FIELDS_SCHEMA_TABLE_VIEW_GROUPDETAILS:
      begin
        // Fields that will be displayed in TableView by default
        List.Add(MakeString(EVDS_FileFormat));
        List.Add(MakeString(EVDS_FileName));
        List.Add(MakeString(EVDS_FileSize));
        List.Add(MakeString(EVDS_FileAccessTime));
        List.Add(MakeString(EVDS_FileCreationTime));
      end;
  end;

  Result := S_OK;
end;

function TDemoExplorerViewDataStorage.GetGroupingPresets(
  Schema: Integer; Presets: IAIMPMLGroupingPresets): HRESULT;
var
  APreset: IAIMPMLGroupingPresetStandard;
begin
  if Schema = AIMPML_GROUPINGPRESETS_SCHEMA_BUILTIN then
    Result := Presets.Add3(MakeString('Demo.ExplorerView.GroupingPreset.Default'), nil, 0, MakeString(EVDS_Fake), APreset)
  else
    Result := S_OK;
end;

procedure TDemoExplorerViewDataStorage.Finalize;
begin
  FManager := nil;
end;

procedure TDemoExplorerViewDataStorage.FlushCache(Reserved: Integer);
begin
  // do nothing
end;

procedure TDemoExplorerViewDataStorage.Initialize(AManager: IAIMPMLDataStorageManager);
begin
  FManager := AManager;
end;

procedure TDemoExplorerViewDataStorage.DoGetValue(
  PropID: Integer; out Value: Variant; var Result: HRESULT);
begin
  case PropID of
    AIMPML_DATASTORAGE_PROPID_CAPABILITIES:
      Value := 0; // Supress all features
  else
    inherited;
  end;
end;

function TDemoExplorerViewDataStorage.DoGetValueAsObject(PropertyID: Integer): IInterface;
begin
  case PropertyID of
    AIMPML_DATASTORAGE_PROPID_ID:
      Result := MakeString('DemoExplorerViewID');
    AIMPML_DATASTORAGE_PROPID_CAPTION:
      Result := LangLoadStringEx('ExplorerView\Caption');
  else
    Result := inherited DoGetValueAsObject(PropertyID);
  end
end;

function TDemoExplorerViewDataStorage.CreateField(
  const AName: string; AType: Integer; AFlags: Integer = 0): IAIMPMLDataField;
begin
  CoreCreateObject(IAIMPMLDataField, Result);
  CheckResult(Result.SetValueAsInt32(AIMPML_FIELD_PROPID_TYPE, AType));
  CheckResult(Result.SetValueAsObject(AIMPML_FIELD_PROPID_NAME, MakeString(AName)));
  CheckResult(Result.SetValueAsInt32(AIMPML_FIELD_PROPID_FLAGS, AIMPML_FIELDFLAG_FILTERING or AFlags));
end;

function TDemoExplorerViewDataStorage.GetRootPath(
  const AFilter: IAIMPMLDataFilter; out APath: string): Boolean;
var
  AString: IAIMPString;
begin
  AString := nil;
  Result := EnumDataFieldFilters(AFilter,
    function (AFilter: IAIMPMLDataFieldFilter): Boolean
    var
      AField: IAIMPMLDataField;
      AValue: Integer;
    begin
      // Check Is Our Fake Field
      Result :=
        Succeeded(AFilter.GetValueAsObject(AIMPML_FIELDFILTER_FIELD, IAIMPMLDataField, AField)) and
        SameText(PropListGetStr(AField, AIMPML_FIELD_PROPID_NAME), EVDS_Fake);

      // Check Field Operation
      Result := Result and Succeeded(AFilter.GetValueAsInt32(AIMPML_FIELDFILTER_OPERATION, AValue)) and
        ((AValue = AIMPML_FIELDFILTER_OPERATION_BEGINSWITH) or
         (AValue = AIMPML_FIELDFILTER_OPERATION_EQUALS));

      // Extract the value
      Result := Result and Succeeded(AFilter.GetValueAsObject(AIMPML_FIELDFILTER_VALUE1, IAIMPString, AString));
    end);

  if Result then
    APath := IAIMPStringToString(AString);
end;

{ TDemoExplorerViewAbstractDataProviderSelection }

function TDemoExplorerViewAbstractDataProviderSelection.GetValueAsFloat(AFieldIndex: Integer): Double;
begin
  Result := 0;
end;

function TDemoExplorerViewAbstractDataProviderSelection.GetValueAsInt32(AFieldIndex: Integer): Integer;
begin
  Result := 0;
end;

function TDemoExplorerViewAbstractDataProviderSelection.GetValueAsInt64(AFieldIndex: Integer): Int64;
begin
  Result := 0;
end;

function TDemoExplorerViewAbstractDataProviderSelection.GetValueAsString(
  AFieldIndex: Integer; out ALength: Integer): PChar;
begin
  FTempBuffer := GetValueAsString(AFieldIndex);
  ALength := Length(FTempBuffer);
  Result := PChar(FTempBuffer);
end;

{ TDemoExplorerViewCustomDataProviderSelection }

constructor TDemoExplorerViewCustomDataProviderSelection.Create(const APath: string);
begin
  FRootPath := IncludeTrailingPathDelimiter(APath);
  if FindFirst(FRootPath + '*', faAnyFile, FSearchRec) <> 0 then
    Abort;
  while not CheckRecordAttr do
  begin
    if not NextRow then
      Abort;
  end;
end;

destructor TDemoExplorerViewCustomDataProviderSelection.Destroy;
begin
  FindClose(FSearchRec);
  inherited Destroy;
end;

function TDemoExplorerViewCustomDataProviderSelection.NextRow: LongBool;
begin
  repeat
    Result := FindNext(FSearchRec) = 0;
  until not Result or CheckRecordAttr;
end;

{ TDemoExplorerViewGroupingTreeRootProvider }

constructor TDemoExplorerViewGroupingTreeRootProvider.Create;
begin
  FList := TStringList.Create;
{$IFDEF MSWINDOWS}
  FList.AddStrings(TDirectory.GetLogicalDrives);
{$ELSE}
  FList.Add(TPath.GetHomePath);
{$ENDIF}
  // Linux: if we have the ACL library, use it to get a list of mounted flash drives.
{$IF DEFINED(HAS_ACL)}
  TACLDriveManager.Enum(
    procedure (const Drive: TACLDriveInfo)
    begin
      if not FList.Contains(Drive.Path) then
        FList.Add(Drive.Path);
    end);
{$ENDIF}
end;

destructor TDemoExplorerViewGroupingTreeRootProvider.Destroy;
begin
  FreeAndNil(FList);
  inherited;
end;

function TDemoExplorerViewGroupingTreeRootProvider.GetValueAsString(AFieldIndex: Integer): string;
begin
  Result := FList[FListIndex];
end;

function TDemoExplorerViewGroupingTreeRootProvider.NextRow: LongBool;
begin
  Inc(FListIndex);
  Result := FListIndex < FList.Count;
end;

{ TDemoExplorerViewGroupingTreeFoldersProvider }

function TDemoExplorerViewGroupingTreeFoldersProvider.CheckRecordAttr: Boolean;
begin
  Result :=
    (FSearchRec.Attr and faDirectory = faDirectory) and
    (FSearchRec.Attr and faSysFile = 0) and (FSearchRec.Name[1] <> '.');
end;

function TDemoExplorerViewGroupingTreeFoldersProvider.GetValueAsString(AFieldIndex: Integer): string;
begin
  Result := FRootPath + IncludeTrailingPathDelimiter(FSearchRec.Name);
end;

{ TDemoExplorerViewDataProviderSelection }

constructor TDemoExplorerViewDataProviderSelection.Create(const APath: string; AFields: IAIMPObjectList);
var
  AService: IAIMPServiceFileFormats;
  AString: IAIMPString;
begin
  if CoreGetService(IAIMPServiceFileFormats, AService) then
  begin
    if Succeeded(AService.GetFormats(AIMP_SERVICE_FILEFORMATS_CATEGORY_AUDIO, AString)) then
      FAudioExts := LowerCase(IAIMPStringToString(AString));
  end;

  inherited Create(APath);

  FFieldFileFormat := GetFieldIndex(AFields, EVDS_FileFormat);
  FFieldFileAccessTime := GetFieldIndex(AFields, EVDS_FileAccessTime);
  FFieldFileCreationTime := GetFieldIndex(AFields, EVDS_FileCreationTime);
  FFieldFileName := GetFieldIndex(AFields, EVDS_FileName);
  FFieldID := GetFieldIndex(AFields, EVDS_ID);
end;

function TDemoExplorerViewDataProviderSelection.CheckRecordAttr: Boolean;
begin
  Result := (FSearchRec.Attr and faDirectory = 0) and
    (Pos(LowerCase('*' + ExtractFileExt(FSearchRec.Name) + ';'), FAudioExts) > 0);
end;

function TDemoExplorerViewDataProviderSelection.GetValueAsFloat(FieldIndex: Integer): Double;
begin
  if FieldIndex = FFieldFileAccessTime then
    Result := TFile.GetLastAccessTime(GetValueAsString(FFieldFileName))
  else if FieldIndex = FFieldFileCreationTime then
    Result := TFile.GetCreationTime(GetValueAsString(FFieldFileName))
  else
    Result := 0;
end;

function TDemoExplorerViewDataProviderSelection.GetValueAsInt64(FieldIndex: Integer): Int64;
begin
  Result := FSearchRec.Size;
end;

function TDemoExplorerViewDataProviderSelection.GetValueAsString(AFieldIndex: Integer): string;
begin
  if AFieldIndex = FFieldFileFormat then
    Result := acExtractFileFormat(FSearchRec.Name)
  else if AFieldIndex = FFieldID then
    Result := LowerCase(FSearchRec.Name)
  else
    Result := FRootPath + FSearchRec.Name;
end;

end.
