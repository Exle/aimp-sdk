library aimp_optionFrameDemo;

uses
  apiPlugin,
  apiTypes,
  uOptionFrameDemo in 'uOptionFrameDemo.pas';

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
