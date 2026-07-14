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
    FBarIndent: Integer;
    FBarHeight: Integer;
    FWidth, FHeight: Integer;
  {$IFDEF MSWINDOWS}
    FBrush: HBRUSH;
  {$ENDIF}
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
      Result := 'Embedded peak-based visualization demo';
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
  // --------------------------------------------
  // INDENT
  // [======= BAR =========]
  // INDENT
  // [======= BAR =========]
  // INDENT
  // --------------------------------------------
{$IFDEF MSWINDOWS}

  // fill the background
  FillRect(DC, Rect(0, 0, FWidth, FHeight), GetStockObject(BLACK_BRUSH));

  // draw left peak
  FillRect(DC, Bounds(0, FBarIndent, Round(FWidth * Data^.Peaks[0]), FBarHeight), FBrush);

  // draw right peak
  FillRect(DC, Bounds(0, FBarIndent + FBarHeight + FBarIndent, Round(FWidth * Data^.Peaks[1]), FBarHeight), FBrush);

{$ELSE}

  // fill the background
  cairo_set_source_rgb(DC, 0, 0, 0); // Black
  cairo_rectangle(DC, 0, 0, FWidth, FHeight);
  cairo_fill(DC);

  // draw left peak
  cairo_set_source_rgb(DC, 0, 1.0, 0); // Green
  cairo_rectangle(DC, 0, FBarIndent, FWidth * Data^.Peaks[0], FBarHeight);
  cairo_fill(DC);

  // draw right peak
  cairo_set_source_rgb(DC, 0, 1.0, 0); // Green
  cairo_rectangle(DC, 0, FBarIndent + FBarHeight + FBarIndent, FWidth * Data^.Peaks[1], FBarHeight);
  cairo_fill(DC);

{$ENDIF}
end;

procedure TVisualization.Finalize;
begin
{$IFDEF MSWINDOWS}
  DeleteObject(FBrush);
{$ENDIF}
end;

function TVisualization.GetFlags: Integer;
begin
  Result := 0; // this visualization uses peak data only
end;

function TVisualization.GetMaxDisplaySize(out Width, Height: Integer): HRESULT;
begin
  Result := E_FAIL; // Our plugin have no limitation
end;

function TVisualization.GetName(out S: IAIMPString): HRESULT;
begin
  S := MakeString('Simple Peak Visualization');
  Result := S_OK;
end;

function TVisualization.Initialize(Width, Height: Integer): HRESULT;
begin
{$IFDEF MSWINDOWS}
  FBrush := CreateSolidBrush(RGB(0, 255, 0)); // Green
{$ENDIF}
  Resize(Width, Height);
  Result := S_OK;
end;

procedure TVisualization.Resize(NewWidth, NewHeight: Integer);
begin
  // --------------------------------------------
  // INDENT
  // [======= BAR =========]
  // INDENT
  // [======= BAR =========]
  // INDENT
  // --------------------------------------------
  FHeight := NewHeight;
  FWidth := NewWidth;
  FBarIndent := (NewHeight div 8);
  FBarHeight := (FHeight - 3 * FBarIndent) div 2;
end;

end.
