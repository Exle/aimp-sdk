{*********************************************}
{*                                           *}
{*            AIMP Update Plugin             *}
{*               Internal API                *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2013-2020                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit apiUpdater;

{$I apiConfig.inc}

interface

uses
  Windows, apiObjects, apiCore;

const
  SID_IAIMPServiceUpdater = '{41494D50-5372-7655-7064-617465720000}';
  IID_IAIMPServiceUpdater: TGUID = SID_IAIMPServiceUpdater;

type

  { IAIMPServiceUpdater }

  IAIMPServiceUpdater = interface
  [SID_IAIMPServiceUpdater]
    function CheckForUpdates: HRESULT; stdcall;
  end;

implementation
end.
