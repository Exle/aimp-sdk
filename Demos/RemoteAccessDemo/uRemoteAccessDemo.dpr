program uRemoteAccessDemo;

{$IFNDEF MSWINDOWS}
  {$MESSAGE FATAL ' Remote API available for Windows platform only '}
{$ENDIF}

uses
  Forms,
  uRemoteAccessDemoMain in 'uRemoteAccessDemoMain.pas' {frmRemoteAccessDemo};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmRemoteAccessDemo, frmRemoteAccessDemo);
  Application.Run;
end.
