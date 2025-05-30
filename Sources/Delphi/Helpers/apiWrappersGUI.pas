﻿////////////////////////////////////////////////////////////////////////////////
//
//  Project:   AIMP
//             Programming Interface
//
//  Target:    v5.40 build 2650
//
//  Purpose:   GUI Api Wrappers
//
//  Author:    Artem Izmaylov
//             © 2006-2025
//             www.aimp.ru
//
//  FPC:       OK
//
unit apiWrappersGUI;

{$I apiConfig.inc}

interface

uses
  Classes,
  SysUtils,
  Types,
  // API
  apiActions,
  apiGUI,
  apiObjects,
  apiOptions,
  apiWrappers,
  apiTypes;

type
  TAIMPUIDrawEvent = procedure (const Sender: IUnknown;
    Canvas: HCANVAS; const R: TRect) of object;
  TAIMPUIKeyEvent = procedure (const Sender: IUnknown;
    var Key: Word; Modifiers: TShiftState) of object;
  TAIMPUIKeyPressEvent = procedure (const Sender: IUnknown; var Key: WideChar) of object;
  TAIMPUIMouseEvent = procedure (const Sender: IUnknown;
    Button: TAIMPUIMouseButton; Shift: TShiftState; X, Y: Integer) of object;
  TAIMPUIMouseMoveEvent = procedure (const Sender: IUnknown;
    Shift: TShiftState; X, Y: Integer) of object;
  TAIMPUIMouseWheelEvent = procedure (const Sender: IUnknown;
    Shift: TShiftState; Delta, X, Y: Integer; var Handled: LongBool) of object;
  TAIMPUINotifyEvent = procedure (const Sender: IUnknown) of object;

  { TAIMPUICustomEventAdapter }

  TAIMPUICustomEventAdapter = class(TInterfacedObjectEx)
  private
    FMasterAdapter: IUnknown;
  protected
    // IUnknown
    function QueryInterface({$IFDEF FPC}constref{$ELSE}const{$ENDIF}
      IID: TGUID; out Obj): HRESULT; override;
  public
    constructor Create(AMasterAdapter: IUnknown);
  end;

  { TAIMPUIDrawEventAdapter }

  TAIMPUIDrawEventAdapter = class(TAIMPUICustomEventAdapter, IAIMPUIDrawEvents)
  private
    FOnDraw: TAIMPUIDrawEvent;
  protected
    // IAIMPUIDrawEvents
    procedure OnDraw(Sender: IInterface; Canvas: HCANVAS; const R: TRect); stdcall;
  public
    constructor Create(ADrawEvent: TAIMPUIDrawEvent; AMasterAdapter: IUnknown = nil);
  end;

  { TAIMPUIKeyboardEventsAdapter }

  TAIMPUIKeyboardEventsAdapter = class(TAIMPUICustomEventAdapter, IAIMPUIKeyboardEvents)
  private
    FOnEnter: TAIMPUINotifyEvent;
    FOnExit: TAIMPUINotifyEvent;
    FOnKeyDown: TAIMPUIKeyEvent;
    FOnKeyPress: TAIMPUIKeyPressEvent;
    FOnKeyUp: TAIMPUIKeyEvent;
  protected
    // IAIMPUIKeyboardEvents
    procedure OnEnter(Sender: IInterface); stdcall;
    procedure OnExit(Sender: IInterface); stdcall;
    procedure OnKeyDown(Sender: IInterface; var Key: Word; Modifiers: Word); stdcall;
    procedure OnKeyPress(Sender: IInterface; var Key: WideChar); stdcall;
    procedure OnKeyUp(Sender: IInterface; var Key: Word; Modifiers: Word); stdcall;
  public
    constructor Create(AEnterEvent, AExitEvent: TAIMPUINotifyEvent;
      AKeyDownEvent, AKeyUpEvent: TAIMPUIKeyEvent; AKeyPressEvent: TAIMPUIKeyPressEvent;
      AMasterAdapter: IUnknown = nil);
  end;

  { TAIMPUIMouseEventsAdapter }

  TAIMPUIMouseEventsAdapter = class(TAIMPUICustomEventAdapter, IAIMPUIMouseEvents)
  private
    FOnMouseDblClick: TAIMPUIMouseEvent;
    FOnMouseDown: TAIMPUIMouseEvent;
    FOnMouseLeave: TAIMPUINotifyEvent;
    FOnMouseMove: TAIMPUIMouseMoveEvent;
    FOnMouseUp: TAIMPUIMouseEvent;
  protected
    // IAIMPUIMouseEvents
    procedure OnMouseDoubleClick(Sender: IInterface; Button: TAIMPUIMouseButton; X, Y: Integer; Modifiers: Word); stdcall;
    procedure OnMouseDown(Sender: IInterface; Button: TAIMPUIMouseButton; X, Y: Integer; Modifiers: Word); stdcall;
    procedure OnMouseMove(Sender: IInterface; X, Y: Integer; Modifiers: Word); stdcall;
    procedure OnMouseLeave(Sender: IInterface); stdcall;
    procedure OnMouseUp(Sender: IInterface; Button: TAIMPUIMouseButton; X, Y: Integer; Modifiers: Word); stdcall;
  public
    constructor Create(AMouseDownEvent, AMouseUpEvent, AMouseDblClickEvent: TAIMPUIMouseEvent;
      AMouseMoveEvent: TAIMPUIMouseMoveEvent; AMouseLeaveEvent: TAIMPUINotifyEvent; AMasterAdapter: IUnknown = nil);
  end;

  { TAIMPUIMouseWheelEventAdapter }

  TAIMPUIMouseWheelEventAdapter = class(TAIMPUICustomEventAdapter, IAIMPUIMouseWheelEvents)
  private
    FOnMouseWheel: TAIMPUIMouseWheelEvent;
  protected
    // IAIMPUIMouseWheelEvents
    function OnMouseWheel(Sender: IInterface; WheelDelta: Integer; X, Y: Integer; Modifiers: Word): LongBool; stdcall;
  public
    constructor Create(AMouseWheelEvent: TAIMPUIMouseWheelEvent; AMasterAdapter: IUnknown = nil);
  end;

  { TAIMPUINotifyEventAdapter }

  TAIMPUINotifyEventAdapter = class(TAIMPUICustomEventAdapter, IAIMPActionEvent, IAIMPUIChangeEvents)
  private
    FEvent: TAIMPUINotifyEvent;
    FEvent2: TThreadMethod;
    // IAIMPActionEvent
    procedure OnExecute(Data: IInterface); stdcall;
    // IAIMPUIChangeEvents
    procedure OnChanged(Sender: IUnknown); stdcall;
  public
    constructor Create(AEvent: TAIMPUINotifyEvent; AMasterAdapter: IUnknown = nil); overload;
    constructor Create(AEvent: TThreadMethod; AMasterAdapter: IUnknown = nil); overload;
  end;

  { TAIMPUIContextPopupAdapter }

  TAIMPUIContextPopupAdapter = class(TAIMPUICustomEventAdapter, IAIMPUIPopupMenuEvents)
  private
    FEvent: TAIMPUINotifyEvent;
    // IAIMPUIPopupMenuEvents
    function OnContextPopup(Sender: IUnknown; X, Y: Integer): LongBool; stdcall;
  public
    constructor Create(AEvent: TAIMPUINotifyEvent; AMasterAdapter: IUnknown = nil);
  end;

function ModifiersToShiftState(Modifiers: Word): TShiftState;

function uiCreateAction(const ID: string; const Event: IUnknown): IAIMPAction; overload;
function uiCreateAction(const ID, Name, Group: string; const Event: IUnknown): IAIMPAction; overload;
function uiCreateAction(const Name, Group: string; const Event: IUnknown): IAIMPAction; overload;
function uiMakeActionId(const PluginName, ActionName: string): string;
function uiMessageBox(AOwner: IAIMPUIForm; AMessage: IAIMPString; AFlags: Cardinal): Integer;
function uiWrap(AEvent: TThreadMethod; AMasterAdapter: IUnknown = nil): IUnknown; overload;
function uiWrap(AEvent: TAIMPUINotifyEvent; AMasterAdapter: IUnknown = nil): IUnknown; overload;
implementation

function ModifiersToShiftState(Modifiers: Word): TShiftState;
begin
  Result := [];
  if Modifiers and AIMPUI_FLAGS_MOD_CTRL <> 0 then
    Include(Result, ssCtrl);
  if Modifiers and AIMPUI_FLAGS_MOD_ALT <> 0 then
    Include(Result, ssAlt);
  if Modifiers and AIMPUI_FLAGS_MOD_SHIFT <> 0 then
    Include(Result, ssShift);
end;

function uiCreateAction(const Name, Group: string; const Event: IUnknown): IAIMPAction;
begin
  Result := uiCreateAction(uiMakeActionId(Group, Name), Name, Group, Event);
end;

function uiCreateAction(const ID: string; const Event: IUnknown): IAIMPAction;
begin
  Result := uiCreateAction(ID, '', '', Event);
end;

function uiCreateAction(const ID, Name, Group: string; const Event: IUnknown): IAIMPAction;
begin
  CoreCreateObject(IAIMPAction, Result);
  PropListSetStr(Result, AIMP_ACTION_PROPID_ID, ID);
  PropListSetObj(Result, AIMP_ACTION_PROPID_EVENT, Event);
  if Name <> '' then
    PropListSetStr(Result, AIMP_ACTION_PROPID_NAME, Name);
  if Group <> '' then
    PropListSetStr(Result, AIMP_ACTION_PROPID_GROUPNAME, Group);
end;

function uiMakeActionId(const PluginName, ActionName: string): string;
begin
  Result := Format('aimp.%s.action.%s', [
    StringReplace(LowerCase(PluginName), ' ', '_', [rfReplaceAll]),
    StringReplace(LowerCase(ActionName), ' ', '_', [rfReplaceAll])]);
end;

function uiMessageBox(AOwner: IAIMPUIForm; AMessage: IAIMPString; AFlags: Cardinal): Integer;
var
  LCaption: IAIMPString;
  LService: IAIMPUIMessageDialog;
begin
  Result := 0;
  if CoreGetService(IAIMPUIMessageDialog, LService) then
  begin
    AOwner.GetValueAsObject(AIMPUI_FORM_PROPID_CAPTION, IAIMPString, LCaption);
    Result := LService.Execute(AOwner.GetHandle, LCaption, AMessage, AFlags);
  end;
end;

function uiWrap(AEvent: TThreadMethod; AMasterAdapter: IUnknown = nil): IUnknown;
begin
  Result := TAIMPUINotifyEventAdapter.Create(AEvent, AMasterAdapter);
end;

function uiWrap(AEvent: TAIMPUINotifyEvent; AMasterAdapter: IUnknown = nil): IUnknown;
begin
  Result := TAIMPUINotifyEventAdapter.Create(AEvent, AMasterAdapter);
end;

{ TAIMPUICustomEventAdapter }

constructor TAIMPUICustomEventAdapter.Create(AMasterAdapter: IInterface);
begin
  inherited Create;
  FMasterAdapter := AMasterAdapter;
end;

function TAIMPUICustomEventAdapter.QueryInterface;
begin
  Result := inherited;
  if Result = E_NOINTERFACE then
  begin
    if FMasterAdapter <> nil then
      Result := FMasterAdapter.QueryInterface(IID, Obj);
  end;
end;

{ TAIMPUIDrawEventAdapter }

constructor TAIMPUIDrawEventAdapter.Create(ADrawEvent: TAIMPUIDrawEvent; AMasterAdapter: IUnknown = nil);
begin
  inherited Create(AMasterAdapter);
  FOnDraw := ADrawEvent;
end;

procedure TAIMPUIDrawEventAdapter.OnDraw(Sender: IInterface; Canvas: HCANVAS; const R: TRect);
begin
  if Assigned(FOnDraw) then
    FOnDraw(Sender, Canvas, R);
end;

{ TAIMPUIKeyboardEventsAdapter }

constructor TAIMPUIKeyboardEventsAdapter.Create(AEnterEvent, AExitEvent: TAIMPUINotifyEvent;
  AKeyDownEvent, AKeyUpEvent: TAIMPUIKeyEvent; AKeyPressEvent: TAIMPUIKeyPressEvent; AMasterAdapter: IUnknown = nil);
begin
  inherited Create(AMasterAdapter);
  FOnEnter := AEnterEvent;
  FOnExit := AExitEvent;
  FOnKeyDown := AKeyDownEvent;
  FOnKeyPress := AKeyPressEvent;
  FOnKeyUp := AKeyUpEvent;
end;

procedure TAIMPUIKeyboardEventsAdapter.OnEnter(Sender: IInterface);
begin
  if Assigned(FOnEnter) then
    FOnEnter(Sender);
end;

procedure TAIMPUIKeyboardEventsAdapter.OnExit(Sender: IInterface);
begin
  if Assigned(FOnExit) then
    FOnExit(Sender);
end;

procedure TAIMPUIKeyboardEventsAdapter.OnKeyDown(Sender: IInterface; var Key: Word; Modifiers: Word);
begin
  if Assigned(FOnKeyDown) then
    FOnKeyDown(Sender, Key, ModifiersToShiftState(Modifiers));
end;

procedure TAIMPUIKeyboardEventsAdapter.OnKeyPress(Sender: IInterface; var Key: WideChar);
begin
  if Assigned(FOnKeyPress) then
    FOnKeyPress(Sender, Key);
end;

procedure TAIMPUIKeyboardEventsAdapter.OnKeyUp(Sender: IInterface; var Key: Word; Modifiers: Word);
begin
  if Assigned(FOnKeyUp) then
    FOnKeyUp(Sender, Key, ModifiersToShiftState(Modifiers));
end;

{ TAIMPUIMouseEventsAdapter }

constructor TAIMPUIMouseEventsAdapter.Create(
  AMouseDownEvent, AMouseUpEvent, AMouseDblClickEvent: TAIMPUIMouseEvent;
  AMouseMoveEvent: TAIMPUIMouseMoveEvent; AMouseLeaveEvent: TAIMPUINotifyEvent;
  AMasterAdapter: IUnknown = nil);
begin
  inherited Create(AMasterAdapter);
  FOnMouseLeave := AMouseLeaveEvent;
  FOnMouseDblClick := AMouseDblClickEvent;
  FOnMouseDown := AMouseDownEvent;
  FOnMouseUp := AMouseUpEvent;
  FOnMouseMove := AMouseMoveEvent;
end;

procedure TAIMPUIMouseEventsAdapter.OnMouseDoubleClick(
  Sender: IInterface; Button: TAIMPUIMouseButton; X, Y: Integer; Modifiers: Word);
begin
  if Assigned(FOnMouseDblClick) then
    FOnMouseDblClick(Sender, Button, ModifiersToShiftState(Modifiers), X, Y);
end;

procedure TAIMPUIMouseEventsAdapter.OnMouseDown(
  Sender: IInterface; Button: TAIMPUIMouseButton; X, Y: Integer; Modifiers: Word);
begin
  if Assigned(FOnMouseDown) then
    FOnMouseDown(Sender, Button, ModifiersToShiftState(Modifiers), X, Y);
end;

procedure TAIMPUIMouseEventsAdapter.OnMouseLeave(Sender: IInterface);
begin
  if Assigned(FOnMouseLeave) then
    FOnMouseLeave(Sender);
end;

procedure TAIMPUIMouseEventsAdapter.OnMouseMove(Sender: IInterface; X, Y: Integer; Modifiers: Word);
begin
  if Assigned(FOnMouseMove) then
    FOnMouseMove(Sender, ModifiersToShiftState(Modifiers), X, Y);
end;

procedure TAIMPUIMouseEventsAdapter.OnMouseUp(
  Sender: IInterface; Button: TAIMPUIMouseButton; X, Y: Integer; Modifiers: Word);
begin
  if Assigned(FOnMouseUp) then
    FOnMouseUp(Sender, Button, ModifiersToShiftState(Modifiers), X, Y);
end;

{ TAIMPUIMouseWheelEventAdapter }

constructor TAIMPUIMouseWheelEventAdapter.Create(
  AMouseWheelEvent: TAIMPUIMouseWheelEvent; AMasterAdapter: IUnknown = nil);
begin
  inherited Create(AMasterAdapter);
  FOnMouseWheel := AMouseWheelEvent;
end;

function TAIMPUIMouseWheelEventAdapter.OnMouseWheel(Sender: IInterface; WheelDelta, X, Y: Integer; Modifiers: Word): LongBool;
begin
  Result := False;
  if Assigned(FOnMouseWheel) then
    FOnMouseWheel(Sender, ModifiersToShiftState(Modifiers), WheelDelta, X, Y, Result);
end;

{ TAIMPUINotifyEventAdapter }

constructor TAIMPUINotifyEventAdapter.Create(AEvent: TAIMPUINotifyEvent; AMasterAdapter: IUnknown = nil);
begin
  inherited Create(AMasterAdapter);
  FEvent := AEvent;
end;

procedure TAIMPUINotifyEventAdapter.OnExecute(Data: IInterface);
begin
  OnChanged(Data);
end;

constructor TAIMPUINotifyEventAdapter.Create(AEvent: TThreadMethod; AMasterAdapter: IInterface);
begin
  inherited Create(AMasterAdapter);
  FEvent2 := AEvent;
end;

procedure TAIMPUINotifyEventAdapter.OnChanged(Sender: IInterface);
begin
  if Assigned(FEvent)  then FEvent(Sender);
  if Assigned(FEvent2) then FEvent2();
end;

{ TAIMPUIContextPopupAdapter }

constructor TAIMPUIContextPopupAdapter.Create(
  AEvent: TAIMPUINotifyEvent; AMasterAdapter: IInterface);
begin
  inherited Create(AMasterAdapter);
  FEvent := AEvent;
end;

function TAIMPUIContextPopupAdapter.OnContextPopup(
  Sender: IInterface; X, Y: Integer): LongBool;
begin
  FEvent(Sender);
  Result := False;
end;

end.
