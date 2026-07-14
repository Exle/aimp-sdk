unit uDemoForm;

{$I apiConfig.inc}

interface

{$R uDemoForm.res}

uses
  Types,
  // API
  apiGUI,
  apiObjects,
  apiTypes,
  apiWrappers,
  apiWrappersGUI,
  // Plugin
  uDataProvider;

type
  TAIMPUITreeListNodeValueEvent = procedure (Sender: IAIMPUITreeList; NodeValue: IAIMPString) of object;

  { TAIMPUITreeListNodeSelectedEventAdapter }

  TAIMPUITreeListNodeSelectedEventAdapter = class(TAIMPUITreeListEventAdapter)
  strict private
    FEvent: TAIMPUITreeListNodeValueEvent;
  public
    constructor Create(AEvent: TAIMPUITreeListNodeValueEvent);
    procedure OnFocusedNodeChanged(Sender: IAIMPUITreeList); override;
  end;

  { TDemoForm }

  TDemoForm = class(TInterfacedObject,
    IAIMPUIPlacementEvents,
    IAIMPUIFormEvents)
  strict private
    // IAIMPUIPlacementEvents
    procedure OnBoundsChanged(Sender: IInterface); stdcall;
    // IAIMPUIFormEvents
    procedure OnActivated(Sender: IAIMPUIForm); stdcall;
    procedure OnDeactivated(Sender: IAIMPUIForm); stdcall;
    procedure OnCreated(Sender: IAIMPUIForm); stdcall;
    procedure OnDestroyed(Sender: IAIMPUIForm); stdcall;
    procedure OnCloseQuery(Sender: IAIMPUIForm; var CanClose: LongBool); stdcall;
    procedure OnLocalize(Sender: IAIMPUIForm); stdcall;
    procedure OnShortCut(Sender: IAIMPUIForm; Key, Modifiers: Word; var Handled: LongBool); stdcall;
    // TAIMPUITreeListNodeSelectedEventAdapter
    procedure OnSelectAlbum(Sender: IAIMPUITreeList; NodeValue: IAIMPString);
    procedure OnSelectArtist(Sender: IAIMPUITreeList; NodeValue: IAIMPString);
  protected
    FControlAlbumList: IAIMPUITreeList;
    FControlArtistList: IAIMPUITreeList;
    FControlTopPanel: IAIMPUIWinControl;
    FControlTrackList: IAIMPUITreeList;
    FDataProvider: TMLDataProvider;
    FForm: IAIMPUIForm;
    FService: IAIMPServiceUI;

    FSelectedAlbum: IAIMPString;
    FSelectedArtist: IAIMPString;

    procedure CreateControls;
    procedure FetchAlbums;
    procedure FetchArtists;
    procedure FetchTracks;
    procedure PopulateTreeList(ATreeList: IAIMPUITreeList; AData: THashSet<string>);
  public
    constructor Create(AService: IAIMPServiceUI; ADataProvider: TMLDataProvider);
    function ShowModal: Integer;
  end;

implementation

{ TAIMPUITreeListNodeSelectedEventAdapter }

constructor TAIMPUITreeListNodeSelectedEventAdapter.Create(AEvent: TAIMPUITreeListNodeValueEvent);
begin
  FEvent := AEvent;
end;

procedure TAIMPUITreeListNodeSelectedEventAdapter.OnFocusedNodeChanged(Sender: IAIMPUITreeList);
var
  ANode: IAIMPUITreeListNode;
  AValue: IAIMPString;
begin
  if Succeeded(Sender.GetFocused(IAIMPUITreeListNode, ANode)) then
  begin
    if Succeeded(ANode.GetValue(0, AValue)) then
      FEvent(Sender, AValue);
  end;
end;

{ TDemoForm }

constructor TDemoForm.Create(AService: IAIMPServiceUI; ADataProvider: TMLDataProvider);
begin
  FService := AService;
  FDataProvider := ADataProvider;

  CheckResult(AService.CreateForm(0, 0, MakeString('DemoForm'), Self, FForm));

  // Center the Form on screen
  FForm.SetValueAsInt32(AIMPUI_FORM_PROPID_CLIENTWIDTH, 1024);
  FForm.SetValueAsInt32(AIMPUI_FORM_PROPID_CLIENTHEIGHT, 600);

  // Create children controls
  CreateControls;

  // Show the data
  FetchArtists;
end;

procedure TDemoForm.CreateControls;
var
  AColumn: IAIMPUITreeListColumn;
begin
  // Create a top panel
  CheckResult(FService.CreateControl(FForm, FForm, nil, nil, IID_IAIMPUIPanel, FControlTopPanel));
  CheckResult(FControlTopPanel.SetPlacement(TAIMPUIControlPlacement.Create(ualTop, 200)));
  CheckResult(FControlTopPanel.SetValueAsInt32(AIMPUI_PANEL_PROPID_BORDERS, 0));

  // Create an artist view
  CheckResult(FService.CreateControl(FForm, FControlTopPanel, nil,
    TAIMPUITreeListNodeSelectedEventAdapter.Create(OnSelectArtist), IID_IAIMPUITreeList, FControlArtistList));
  CheckResult(FControlArtistList.SetPlacement(TAIMPUIControlPlacement.Create(ualNone, TRect.Empty)));
  CheckResult(FControlArtistList.AddColumn(IID_IAIMPUITreeListColumn, AColumn));
  PropListSetStr(AColumn, AIMPUI_TL_COLUMN_PROPID_CAPTION, 'Artists');

  // Create an album view
  CheckResult(FService.CreateControl(FForm, FControlTopPanel, nil,
    TAIMPUITreeListNodeSelectedEventAdapter.Create(OnSelectAlbum), IID_IAIMPUITreeList, FControlAlbumList));
  CheckResult(FControlAlbumList.SetPlacement(TAIMPUIControlPlacement.Create(ualClient, TRect.Empty)));
  CheckResult(FControlAlbumList.AddColumn(IID_IAIMPUITreeListColumn, AColumn));
  PropListSetStr(AColumn, AIMPUI_TL_COLUMN_PROPID_CAPTION, 'Albums');

  // Create a tracks view
  CheckResult(FService.CreateControl(FForm, FForm, nil, nil, IID_IAIMPUITreeList, FControlTrackList));
  CheckResult(FControlTrackList.SetPlacement(TAIMPUIControlPlacement.Create(ualClient, TRect.Empty)));
end;

procedure TDemoForm.FetchAlbums;
begin
  FDataProvider.FetchAlbums(FSelectedArtist,
    procedure (AStringSet: THashSet<string>)
    begin
      PopulateTreeList(FControlAlbumList, AStringSet);
    end);
end;

procedure TDemoForm.FetchArtists;
begin
  FDataProvider.FetchArtists(
    procedure (AStringSet: THashSet<string>)
    begin
      PopulateTreeList(FControlArtistList, AStringSet);
    end);
end;

procedure TDemoForm.FetchTracks;
begin
  FDataProvider.FetchTracks(FSelectedArtist, FSelectedAlbum,
    procedure (AStringSet: THashSet<string>)
    begin
      PopulateTreeList(FControlTrackList, AStringSet);
    end);
end;

procedure TDemoForm.PopulateTreeList(ATreeList: IAIMPUITreeList; AData: THashSet<string>);
var
  ARootNode: IAIMPUITreeListNode;
  ANode: IAIMPUITreeListNode;
  AValue: string;
begin
  ATreeList.BeginUpdate;
  try
    CheckResult(ATreeList.GetRootNode(IID_IAIMPUITreeListNode, ARootNode));
    CheckResult(ARootNode.ClearChildren);
    for AValue in AData do
    begin
      CheckResult(ARootNode.Add(ANode));
      CheckResult(ANode.SetValue(0, MakeString(AValue)));
    end;
  finally
    ATreeList.EndUpdate;
  end;
end;

function TDemoForm.ShowModal: Integer;
begin
  Result := FForm.ShowModal;
end;

// IAIMPUIPlacementEvents
procedure TDemoForm.OnBoundsChanged(Sender: IInterface);
var
  APlacement: TAIMPUIControlPlacement;
begin
  CheckResult(FControlTopPanel.GetPlacement(APlacement));
  CheckResult(FControlArtistList.SetPlacement(TAIMPUIControlPlacement.Create(ualLeft, APlacement.Bounds.Width div 2)));
end;

// IAIMPUIFormEvents
procedure TDemoForm.OnActivated(Sender: IAIMPUIForm);
begin
  // do nothing
end;

procedure TDemoForm.OnDeactivated(Sender: IAIMPUIForm); stdcall;
begin
  // do nothing
end;

procedure TDemoForm.OnCreated(Sender: IAIMPUIForm); stdcall;
begin
  // do nothing
end;

procedure TDemoForm.OnDestroyed(Sender: IAIMPUIForm); stdcall;
begin
  {$MESSAGE 'TODO - stop all requests in FDataProvider'}
  // Release all variables
  FControlTopPanel := nil;
  FControlArtistList := nil;
  FControlAlbumList := nil;
  FControlTrackList := nil;
  FForm := nil;
end;

procedure TDemoForm.OnCloseQuery(Sender: IAIMPUIForm; var CanClose: LongBool); stdcall;
begin
  // do nothing
end;

procedure TDemoForm.OnLocalize(Sender: IAIMPUIForm); stdcall;
begin
  // do nothing
end;

procedure TDemoForm.OnShortCut(Sender: IAIMPUIForm; Key, Modifiers: Word; var Handled: LongBool); stdcall;
begin
  // do nothing
end;

procedure TDemoForm.OnSelectAlbum(Sender: IAIMPUITreeList; NodeValue: IAIMPString);
begin
  FControlTrackList.Clear;
  FSelectedAlbum := NodeValue;
  FetchTracks;
end;

procedure TDemoForm.OnSelectArtist(Sender: IAIMPUITreeList; NodeValue: IAIMPString);
begin
  FControlAlbumList.Clear;
  FControlTrackList.Clear;
  FSelectedArtist := NodeValue;
  FSelectedAlbum := nil;
  FetchAlbums;
end;

end.

