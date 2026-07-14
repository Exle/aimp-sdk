unit aimp_visDemoMain;

{$I apiConfig.inc}

interface

uses
{$IFDEF MSWINDOWS}
  Windows,
{$ELSE}
  Cairo,
{$ENDIF}
  Math,
  Types,
  SysUtils,
  // SDK
  apiCore,
  apiObjects,
  apiPlugin,
  apiTypes,
  apiVisuals,
  apiWrappers,
  AIMPCustomPlugin;

type

  { TVisualPlugin }

  TVisualPlugin = class(TAIMPCustomPlugin)
  protected
    function InfoGet(Index: Integer): PChar; override;
    function InfoGetCategories: Cardinal; override;
    function Initialize(Core: IAIMPCore): HRESULT; override;
  end;

  { TVisualization }

  TVisualization = class(TInterfacedObject,
    IAIMPExtensionEmbeddedVisualization)
  strict private
  {$IFDEF MSWINDOWS}
    FBrush: HBRUSH;
  {$ENDIF}
    FWidth, FHeight: Integer;
    procedure DrawSpectrum(DC: HCANVAS; const Data: TAIMPVisualDataSpectrum; Area: TRect);
  public
    // IAIMPExtensionEmbeddedVisualization
    function GetFlags: Integer; stdcall;
    function GetMaxDisplaySize(out Width, Height: Integer): HRESULT; stdcall;
    function GetName(out S: IAIMPString): HRESULT; stdcall;
    // Initialization / Finalization
    function Initialize(Width, Height: Integer): HRESULT; stdcall;
    procedure Finalize; stdcall;
    // Basic functionality
    procedure Click(X, Y: Integer; Button: Integer); stdcall;
    procedure Draw(DC: HCANVAS; Data: PAIMPVisualData); stdcall;
    procedure Resize(NewWidth, NewHeight: Integer); stdcall;
  end;

implementation

{ TVisualPlugin }

function TVisualPlugin.InfoGet(Index: Integer): PChar;
begin
  case Index of
    AIMP_PLUGIN_INFO_NAME:
      Result := 'Embedded spectrum-based visualization demo';
    AIMP_PLUGIN_INFO_AUTHOR:
      Result := 'Artem Izmaylov';
  else
    Result := '';
  end;
end;

function TVisualPlugin.InfoGetCategories: Cardinal;
begin
  Result := AIMP_PLUGIN_CATEGORY_VISUALS;
end;

function TVisualPlugin.Initialize(Core: IAIMPCore): HRESULT;
begin
  Result := inherited;
  Core.RegisterExtension(IID_IAIMPServiceVisualizations, TVisualization.Create)
end;

{ TVisualization }

procedure TVisualization.Click(X, Y, Button: Integer);
begin
  // do nothing
end;

procedure TVisualization.Draw(DC: HCANVAS; Data: PAIMPVisualData);
begin
  // fill the background
{$IFDEF MSWINDOWS}
  FillRect(DC, Rect(0, 0, FWidth, FHeight), GetStockObject(BLACK_BRUSH));
{$ELSE}
  cairo_set_source_rgb(DC, 0, 0, 0); // Black
  cairo_rectangle(DC, 0, 0, FWidth, FHeight);
  cairo_fill(DC);
{$ENDIF}

  // draw spectrums
  DrawSpectrum(DC, Data^.Spectrum[0], Rect(0, 0, FWidth, FHeight div 2));
  DrawSpectrum(DC, Data^.Spectrum[1], Rect(0, FHeight div 2, FWidth, FHeight));
end;

procedure TVisualization.DrawSpectrum(DC: HCANVAS; const Data: TAIMPVisualDataSpectrum; Area: TRect);
var
  I: Integer;
  LBar: TRect;
begin
{$IFNDEF MSWINDOWS}
  cairo_set_source_rgb(DC, 1, 1, 1); // White
{$ENDIF}

  Area.Width := Max(1, Area.Width div AIMP_VISUAL_SPECTRUM_SIZE);
  for I := 0 to AIMP_VISUAL_SPECTRUM_SIZE - 1 do
  begin
    LBar := Area;
    LBar.Top := LBar.Bottom - Round(Data[I] * LBar.Height);
    Area.Offset(Area.Width, 0);

  {$IFDEF MSWINDOWS}
    FillRect(DC, LBar, FBrush);
  {$ELSE}
    cairo_rectangle(DC, LBar.Left, LBar.Top, LBar.Width, LBar.Height);
    cairo_fill(DC);
  {$ENDIF}
  end;
end;

procedure TVisualization.Finalize;
begin
{$IFDEF MSWINDOWS}
  DeleteObject(FBrush);
{$ENDIF}
end;

function TVisualization.GetFlags: Integer;
begin
  Result := AIMP_VISUAL_FLAGS_RQD_DATA_SPECTRUM; // this visualization requires spectrum data
end;

function TVisualization.GetMaxDisplaySize(out Width, Height: Integer): HRESULT;
begin
  Result := E_FAIL; // Our plugin have no limitation
end;

function TVisualization.GetName(out S: IAIMPString): HRESULT;
begin
  S := MakeString('Simple Wave Visualization');
  Result := S_OK;
end;

function TVisualization.Initialize(Width, Height: Integer): HRESULT;
begin
{$IFDEF MSWINDOWS}
  FBrush := CreateSolidBrush(RGB(255, 255, 255)); // White
{$ENDIF}
  Resize(Width, Height);
  Result := S_OK;
end;

procedure TVisualization.Resize(NewWidth, NewHeight: Integer);
begin
  FHeight := NewHeight;
  FWidth := NewWidth;
end;

end.
