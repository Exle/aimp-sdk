library DemoCustomFileSystem;

uses
  apiCore,
  apiPlugin,
  DemoCustomFileSystemMain in 'DemoCustomFileSystemMain.pas';

{$R *.res}

  function AIMPPluginGetHeader(out Header: IAIMPPlugin): HRESULT; stdcall;
  begin
    Header := TDemoCustomFileSystemPlugin.Create;
    Result := S_OK;
  end;

exports
  AIMPPluginGetHeader;
begin
end.
