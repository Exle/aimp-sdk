unit uDataProvider;

{$I apiConfig.inc}

interface

uses
  Variants,
  // Generics
  Generics.Collections,
  Generics.Defaults,
  // API
  apiObjects,
  apiMusicLibrary,
  apiThreading,
  apiTypes,
  apiWrappers;

type

  { THashSet }

  THashSet<T> = class(TEnumerable<T>)
  strict private
    FData: TDictionary<T, Pointer>;
  protected
    function DoGetEnumerator: TEnumerator<T>; override;
  public
    constructor Create;
    destructor Destroy; override;
    function Contains(const Item: T): Boolean;
    function Exclude(const Item: T): Boolean;
    function Include(const Item: T): Boolean;
  end;

  TStringSetCallback = reference to procedure (AStringSet: THashSet<string>);

  { TMLDataProvider }

  TMLDataProvider = class
  public
    procedure CancelRequest(AHandle: TTaskHandle);
    function FetchAlbums(AArtist: IAIMPString; ACallback: TStringSetCallback): TTaskHandle;
    function FetchArtists(ACallback: TStringSetCallback): TTaskHandle;
    function FetchTracks(AArtist, AAlbum: IAIMPString; ACallback: TStringSetCallback): TTaskHandle;
    function Run(ATask: IAIMPTask): TTaskHandle;
  end;

  { TMLFetchFieldDataTask }

  TMLFetchFieldDataTask = class abstract(TInterfacedObject, IAIMPTask)
  strict private
    // IAIMPTask
    procedure Execute(Owner: IAIMPTaskOwner); stdcall;
  protected
    FCallback: TStringSetCallback;
    FData: THashSet<string>;
    FDataStorage: IAIMPMLDataStorage2;

    function BuildFieldList: IAIMPObjectList; virtual; abstract;
    function BuildFilter: IAIMPMLDataFilter; virtual;
    procedure PopulateData(AOwner: IAIMPTaskOwner);
    procedure SyncComplete;
  public
    constructor Create(ACallback: TStringSetCallback);
    destructor Destroy; override;
  end;

  { TMLFetchFieldDataTaskCallbackSynchronizer }

  TMLFetchFieldDataTaskCallbackSynchronizer = class(TInterfacedObject, IAIMPTask)
  strict private
    FCaller: TMLFetchFieldDataTask;

    // IAIMPTask
    procedure Execute(Owner: IAIMPTaskOwner); stdcall;
  public
    constructor Create(ACaller: TMLFetchFieldDataTask);
  end;

  { TMLFetchAlbumsTask }

  TMLFetchAlbumsTask = class(TMLFetchFieldDataTask)
  strict private
    FArtist: IAIMPString;
  protected
    function BuildFieldList: IAIMPObjectList; override;
    function BuildFilter: IAIMPMLDataFilter; override;
  public
    constructor Create(AArtist: IAIMPString; ACallback: TStringSetCallback);
  end;

  { TMLFetchArtistsTask }

  TMLFetchArtistsTask = class(TMLFetchFieldDataTask)
  protected
    function BuildFieldList: IAIMPObjectList; override;
  end;

  { TMLFetchTracksTask }

  TMLFetchTracksTask = class(TMLFetchFieldDataTask)
  strict private
    FAlbum: IAIMPString;
    FArtist: IAIMPString;
  protected
    function BuildFieldList: IAIMPObjectList; override;
    function BuildFilter: IAIMPMLDataFilter; override;
  public
    constructor Create(AArtist, AAlbum: IAIMPString; ACallback: TStringSetCallback);
  end;

implementation

uses
  SysUtils;

{ THashSet<T> }

constructor THashSet<T>.Create;
begin
  FData := TDictionary<T, Pointer>.Create;
end;

destructor THashSet<T>.Destroy;
begin
  FreeAndNil(FData);
  inherited;
end;

function THashSet<T>.DoGetEnumerator: TEnumerator<T>;
begin
  Result := FData.Keys.GetEnumerator;
end;

function THashSet<T>.Contains(const Item: T): Boolean;
begin
  Result := FData.ContainsKey(Item);
end;

function THashSet<T>.Exclude(const Item: T): Boolean;
begin
  Result := FData.ContainsKey(Item);
  if Result then
    FData.Remove(Item);
end;

function THashSet<T>.Include(const Item: T): Boolean;
begin
  Result := not FData.ContainsKey(Item);
  if Result then
    FData.AddOrSetValue(Item, nil);
end;

{ TMLDataProvider }

procedure TMLDataProvider.CancelRequest(AHandle: TTaskHandle);
var
  AService: IAIMPServiceThreads;
begin
  if CoreGetService(IAIMPServiceThreads, AService) then
    AService.Cancel(AHandle, AIMP_SERVICE_THREADS_FLAGS_WAITFOR);
end;

function TMLDataProvider.Run(ATask: IAIMPTask): TTaskHandle;
var
  AService: IAIMPServiceThreads;
begin
  Result := 0;
  if CoreGetService(IAIMPServiceThreads, AService) then
  begin
    if Failed(AService.ExecuteInThread(ATask, Result)) then
      Result := 0;
  end;
end;

function TMLDataProvider.FetchAlbums(AArtist: IAIMPString; ACallback: TStringSetCallback): TTaskHandle;
begin
  Result := Run(TMLFetchAlbumsTask.Create(AArtist, ACallback));
end;

function TMLDataProvider.FetchArtists(ACallback: TStringSetCallback): TTaskHandle;
begin
  Result := Run(TMLFetchArtistsTask.Create(ACallback));
end;

function TMLDataProvider.FetchTracks(AArtist, AAlbum: IAIMPString; ACallback: TStringSetCallback): TTaskHandle;
begin
  Result := Run(TMLFetchTracksTask.Create(AArtist, AAlbum, ACallback));
end;

{ TMLFetchFieldDataTask }

constructor TMLFetchFieldDataTask.Create(ACallback: TStringSetCallback);
var
  AService: IAIMPServiceMusicLibrary;
begin
  FCallback := ACallback;
  FData := THashSet<string>.Create;

  if CoreGetService(IAIMPServiceMusicLibrary, AService) then
  begin
    if Failed(AService.GetStorageByID(MakeString(AIMPML_LOCALDATASTORAGE_ID), IAIMPMLDataStorage2, FDataStorage)) then
      FDataStorage := nil;
  end;
end;

destructor TMLFetchFieldDataTask.Destroy;
begin
  FreeAndNil(FData);
  inherited;
end;

function TMLFetchFieldDataTask.BuildFilter: IAIMPMLDataFilter;
begin
  Result := nil;
end;

procedure TMLFetchFieldDataTask.PopulateData(AOwner: IAIMPTaskOwner);
var
  AData: IUnknown;
  ADataProvider: IAIMPMLDataProvider;
  ALength: Integer;
  ASelection: IAIMPMLDataProviderSelection;
  AValue: string;
begin
  if Supports(FDataStorage, IAIMPMLDataProvider, ADataProvider) then
  begin
    if Succeeded(ADataProvider.GetData(BuildFieldList, BuildFilter, AData)) then
    begin
      if Supports(AData, IAIMPMLDataProviderSelection, ASelection) then
      repeat
        SetString(AValue, ASelection.GetValueAsString(0, ALength), ALength);
        FData.Include(AValue);
      until (AOwner <> nil) and AOwner.IsCanceled or not ASelection.NextRow;
    end;
  end;
end;

procedure TMLFetchFieldDataTask.SyncComplete;
begin
  FCallback(FData);
end;

procedure TMLFetchFieldDataTask.Execute(Owner: IAIMPTaskOwner);
var
  AService: IAIMPServiceThreads;
begin
  if FDataStorage <> nil then
    PopulateData(Owner);
  if (Owner = nil) or not Owner.IsCanceled then
  begin
    if CoreGetService(IAIMPServiceThreads, AService) then
      AService.ExecuteInMainThread(
        TMLFetchFieldDataTaskCallbackSynchronizer.Create(Self),
        AIMP_SERVICE_THREADS_FLAGS_WAITFOR);
  end;
end;

{ TMLFetchFieldDataTaskCallbackSynchronizer }

constructor TMLFetchFieldDataTaskCallbackSynchronizer.Create(ACaller: TMLFetchFieldDataTask);
begin
  FCaller := ACaller;
end;

procedure TMLFetchFieldDataTaskCallbackSynchronizer.Execute(Owner: IAIMPTaskOwner);
begin
  FCaller.SyncComplete;
end;

{ TMLFetchArtistsTask }

function TMLFetchArtistsTask.BuildFieldList: IAIMPObjectList;
begin
  CoreCreateObject(IAIMPObjectList, Result);
  Result.Add(MakeString('Artist'));
end;

{ TMLFetchAlbumsTask }

constructor TMLFetchAlbumsTask.Create(AArtist: IAIMPString; ACallback: TStringSetCallback);
begin
  inherited Create(ACallback);
  FArtist := AArtist;
end;

function TMLFetchAlbumsTask.BuildFieldList: IAIMPObjectList;
begin
  CoreCreateObject(IAIMPObjectList, Result);
  Result.Add(MakeString('Album'));
end;

function TMLFetchAlbumsTask.BuildFilter: IAIMPMLDataFilter;
var
  LFilter: IAIMPMLDataFieldFilter;
  LValue: VarValue;
begin
  LValue := VarValueInit(IAIMPStringToString(FArtist));
  try
    CheckResult(FDataStorage.CreateObject(IAIMPMLDataFilter, Result));
    CheckResult(Result.Add(MakeString('Artist'),
      LValue, VarValueNull, AIMPML_FIELDFILTER_OPERATION_EQUALS, LFilter));
  finally
    VarValueFree(LValue);
  end;
end;

{ TMLFetchTracksTask }

constructor TMLFetchTracksTask.Create(AArtist, AAlbum: IAIMPString; ACallback: TStringSetCallback);
begin
  inherited Create(ACallback);
  FArtist := AArtist;
  FAlbum := AAlbum;
end;

function TMLFetchTracksTask.BuildFieldList: IAIMPObjectList;
begin
  CoreCreateObject(IAIMPObjectList, Result);
  Result.Add(MakeString('FileName'));
  Result.Add(MakeString('Title'));
end;

function TMLFetchTracksTask.BuildFilter: IAIMPMLDataFilter;
var
  LFilter: IAIMPMLDataFieldFilter;
  LValue1: VarValue;
  LValue2: VarValue;
begin
  LValue1 := VarValueInit(IAIMPStringToString(FArtist));
  LValue2 := VarValueInit(IAIMPStringToString(FAlbum));
  try
    CheckResult(FDataStorage.CreateObject(IAIMPMLDataFilter, Result));
    CheckResult(Result.SetValueAsInt32(AIMPML_FILTERGROUP_OPERATION, AIMPML_FILTERGROUP_OPERATION_AND));
    CheckResult(Result.Add(MakeString('Artist'), LValue1, VarValueNull, AIMPML_FIELDFILTER_OPERATION_EQUALS, LFilter));
    CheckResult(Result.Add(MakeString('Album'), LValue2, VarValueNull, AIMPML_FIELDFILTER_OPERATION_EQUALS, LFilter));
  finally
    VarValueFree(LValue2);
    VarValueFree(LValue1);
  end;
end;

end.
