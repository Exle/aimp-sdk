{*********************************************}
{*                                           *}
{*             AIMP CDDA Plugin              *}
{*               Internal API                *}
{*                                           *}
{*            (c) Artem Izmaylov             *}
{*                 2006-2020                 *}
{*                www.aimp.ru                *}
{*                                           *}
{*********************************************}

unit apiCDDA;

{$I apiConfig.inc}

interface

uses
  Windows, apiObjects, apiCore;

const
  SID_IAIMPServiceCompactDiskAudio = '{41494D50-5372-7643-4444-410000000000}';
  IID_IAIMPServiceCompactDiskAudio: TGUID = SID_IAIMPServiceCompactDiskAudio;
  {0x504D4941, 0x7253, 0x4376, 0x44, 0x44, 0x41, 0x00, 0x00, 0x00, 0x00, 0x00}

  SID_IAIMPCompactDiskAudioDriveInfo = '{41494D50-4344-4441-4472-76496E660000}';
  IID_IAIMPCompactDiskAudioDriveInfo: TGUID = SID_IAIMPCompactDiskAudioDriveInfo;
  {0x41494D50, 0x4344, 0x4441, 0x44, 0x72, 0x76, 0x49, 0x6E, 0x66, 0x00, 0x00}

type

  { IAIMPCompactDiskAudioDriveInfo }

  IAIMPCompactDiskAudioDriveInfo = interface
  [SID_IAIMPCompactDiskAudioDriveInfo]
    function GetDriveFriendlyName(out S: IAIMPString): HRESULT; stdcall;
    function GetDriveIndex: Integer; stdcall;
    function GetDriveLetter: WideChar; stdcall;
  end;

  { IAIMPServiceCompactDiskAudio }

  IAIMPServiceCompactDiskAudio = interface
  [SID_IAIMPServiceCompactDiskAudio]
    function PopulateDrives(out List: IAIMPObjectList): HRESULT; stdcall;
    function PopulateFiles(DriveIndex: Integer; out List: IAIMPObjectList): HRESULT; stdcall;
    function PopulateFiles2(Drive: WideChar; out List: IAIMPObjectList): HRESULT; stdcall;
  end;

implementation

end.
