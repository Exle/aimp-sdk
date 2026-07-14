unit aimp_visDemoMain;

{$I apiConfig.inc}

interface

uses
{$IFDEF MSWINDOWS}
  Windows,
{$ELSE}
  Cairo,
{$ENDIF}
  // System
  Classes,
  SysUtils,
  // SDK
  apiCore,
  apiObjects,
  apiPlugin,
  apiVisuals,
  apiTypes,
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
    FPen: HPEN;
  {$ENDIF}
    FWidth, FHeight: Integer;
    procedure DrawWave(DC: HCANVAS; const Wave: TAIMPVisualDataWaveform; const Area: TRect);
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
      Result := 'Embedded wave-based visualization demo';
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

  // draw waves
  DrawWave(DC, Data^.Waveform[0], Rect(0, 0, FWidth, FHeight div 2));
  DrawWave(DC, Data^.Waveform[1], Rect(0, FHeight div 2, FWidth, FHeight));
end;

procedure TVisualization.DrawWave(DC: HCANVAS;
  const Wave: TAIMPVisualDataWaveform; const Area: TRect);
var
  LMiddle: Integer;
  LHeight: Integer;
  I, X, Y: Integer;
begin
{$IFDEF MSWINDOWS}
  var LOldPen := SelectObject(DC, FPen);
{$ELSE}
  cairo_set_source_rgb(DC, 1, 1, 1); // White;
{$ENDIF}

  LHeight := Area.Height div 2;
  LMiddle := (Area.Top + Area.Bottom) div 2;

{$IFDEF MSWINDOWS}
  MoveToEx(DC, Area.Left, LMiddle, nil);
{$ELSE}
  cairo_move_to(DC, Area.Left, LMiddle);
{$ENDIF}

  for I := 0 to AIMP_VISUAL_WAVEFORM_SIZE - 1 do
  begin
    X := Area.Left + (Area.Width * (I + 1)) div AIMP_VISUAL_WAVEFORM_SIZE;
    Y := LMiddle + Round(Wave[I] * LHeight);
  {$IFDEF MSWINDOWS}
    LineTo(DC, X, Y);
  {$ELSE}
    cairo_line_to(DC, X, Y);
  {$ENDIF}
  end;

{$IFDEF MSWINDOWS}
  SelectObject(DC, LOldPen);
{$ELSE}
  cairo_stroke(DC);
{$ENDIF}
end;

procedure TVisualization.Finalize;
begin
{$IFDEF MSWINDOWS}
  DeleteObject(FPen);
{$ENDIF}
end;

function TVisualization.GetFlags: Integer;
begin
  Result := AIMP_VISUAL_FLAGS_RQD_DATA_WAVEFORM; // this visualization requires wave data
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
  FPen := CreatePen(PS_SOLID, 1, RGB(255, 255, 255)); // White Pen
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
