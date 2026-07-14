library aimp_infobar_demo;

uses
  apiPlugin,
  uInfoBarDemo in 'uInfoBarDemo.pas';

function AIMPPluginGetHeader(out Header: IAIMPPlugin): HRESULT; stdcall;
begin
  try
    Header := TAIMPDemoPlugin.Create;
    Result := S_OK;
  except
    Result := E_UNEXPECTED;
  end;
end;

exports
  AIMPPluginGetHeader;
begin
end.
