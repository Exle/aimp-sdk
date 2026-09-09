////////////////////////////////////////////////////////////////////////////////
//
//  Project:   AIMP
//             Programming Interface
//
//  Target:    v6.00 build 3083
//
//  Purpose:   AlbumArts API
//
//  Author:    Artem Izmaylov
//             © 2006-2026
//             www.aimp.ru
//
//  FPC:       OK
//
unit apiAlbumArt;

{$I apiConfig.inc}

interface

uses
{$IFDEF MSWINDOWS}
  Windows,
{$ENDIF}
  Types,
  // api
  apiObjects,
  apiFileManager,
  apiTypes;

const
  SID_IAIMPAlbumArtRequest = '{41494D50-416C-6241-7274-526571737400}';
  IID_IAIMPAlbumArtRequest: TGUID = SID_IAIMPAlbumArtRequest;

  SID_IAIMPExtensionAlbumArtProvider = '{41494D50-4578-7441-6C62-417274507276}';
  IID_IAIMPExtensionAlbumArtProvider: TGUID = SID_IAIMPExtensionAlbumArtProvider;

  SID_IAIMPExtensionAlbumArtProvider2 = '{41494D50-4578-416C-6241-727450727632}';
  IID_IAIMPExtensionAlbumArtProvider2: TGUID = SID_IAIMPExtensionAlbumArtProvider2;

  SID_IAIMPExtensionAlbumArtProvider3 = '{41494D50-4578-416C-6241-727450727633}';
  IID_IAIMPExtensionAlbumArtProvider3: TGUID = SID_IAIMPExtensionAlbumArtProvider3;

  SID_IAIMPServiceAlbumArt = '{41494D50-5372-7641-6C62-417274000000}';
  IID_IAIMPServiceAlbumArt: TGUID = SID_IAIMPServiceAlbumArt;

  SID_IAIMPServiceAlbumArtCache = '{41494D50-5372-7641-6C62-417274434300}';
  IID_IAIMPServiceAlbumArtCache: TGUID = SID_IAIMPServiceAlbumArtCache;

  AIMP_ALBUMART_PROVIDER_CATEGORY_MASK            = $F;
  // Providers Categories
  AIMP_ALBUMART_PROVIDER_CATEGORY_TAGS            = 0;
  AIMP_ALBUMART_PROVIDER_CATEGORY_FILE            = 1;
  AIMP_ALBUMART_PROVIDER_CATEGORY_INTERNET        = 2;
  AIMP_ALBUMART_PROVIDER_CATEGORY_INTERNET_SEARCH = 3;

  // PropIDs for IAIMPAlbumArtRequest
  AIMP_ALBUMART_REQUEST_PROPID_FIND_IN_FILES                  = 1;
  AIMP_ALBUMART_REQUEST_PROPID_FIND_IN_FILES_MASKS            = 2;
  AIMP_ALBUMART_REQUEST_PROPID_FIND_IN_FILES_EXTS             = 3;
  AIMP_ALBUMART_REQUEST_PROPID_FIND_IN_INTERNET               = 4;
  AIMP_ALBUMART_REQUEST_PROPID_FIND_IN_INTERNET_MAX_FILE_SIZE = 5;
  AIMP_ALBUMART_REQUEST_PROPID_FIND_IN_TAGS                   = 6;
  AIMP_ALBUMART_REQUEST_PROPID_RESULTS                        = 7;
  AIMP_ALBUMART_REQUEST_PROPID_USER_ACTION                    = 8; // v6.0

  // Flags for IAIMPServiceAlbumArt.Get
  AIMP_SERVICE_ALBUMART_FLAGS_NOCACHE  = 1;
  AIMP_SERVICE_ALBUMART_FLAGS_ORIGINAL = 2;
  AIMP_SERVICE_ALBUMART_FLAGS_WAITFOR  = 4;
  AIMP_SERVICE_ALBUMART_FLAGS_OFFLINE  = 8;

type

  { IAIMPAlbumArtRequest }

  IAIMPAlbumArtRequest = interface(IAIMPPropertyList)
  [SID_IAIMPAlbumArtRequest]
    function CacheGet(Key: IAIMPString; var Image: IAIMPImageContainer): HRESULT; stdcall;
    function CachePut(Key: IAIMPString; var Image: IAIMPImageContainer): HRESULT; stdcall;
    function Download(URL: IAIMPString; out Image: IAIMPImageContainer): HRESULT; stdcall;
    function IsCanceled: LongBool; stdcall;
  end;

  // IAIMPExtensionAlbumArtCatalog, IAIMPExtensionAlbumArtCatalog2 are deprecated,
  //  use IAIMPExtensionAlbumArtProvider3 or IAIMPExtensionExternalCatalog instead

  { IAIMPExtensionAlbumArtProvider }

  IAIMPExtensionAlbumArtProvider = interface(IUnknown)
  [SID_IAIMPExtensionAlbumArtProvider]
    function Get(FileURI, Artist, Album: IAIMPString;
      Options: IAIMPPropertyList; out Image: IAIMPImageContainer): HRESULT; stdcall;
    function GetCategory: LongWord; stdcall;
  end;

  { IAIMPExtensionAlbumArtProvider2 }

  IAIMPExtensionAlbumArtProvider2 = interface(IAIMPExtensionAlbumArtProvider)
  [SID_IAIMPExtensionAlbumArtProvider2]
    function Get2(FileInfo: IAIMPFileInfo;
      Options: IAIMPPropertyList; out Image: IAIMPImageContainer): HRESULT; stdcall;
  end;

  { IAIMPExtensionAlbumArtProvider3 }

  IAIMPExtensionAlbumArtProvider3 = interface(IUnknown)
  [SID_IAIMPExtensionAlbumArtProvider3]
    function Get(FileInfo: IAIMPFileInfo; Request: IAIMPAlbumArtRequest;
      out Image: IAIMPImageContainer): HRESULT; stdcall;
    function GetCategory: LongWord; stdcall;
  end;

  { IAIMPServiceAlbumArt }

  TAIMPServiceAlbumArtReceiveProc = procedure (Image: IAIMPImage;
    ImageContainer: IAIMPImageContainer; UserData: Pointer); stdcall;

  IAIMPServiceAlbumArt = interface(IUnknown)
  [SID_IAIMPServiceAlbumArt]
    function Get(FileURI, Artist, Album: IAIMPString; Flags: LongWord;
      CallbackProc: TAIMPServiceAlbumArtReceiveProc;
      UserData: Pointer; out TaskID: TTaskHandle): HRESULT; stdcall;
    function Get2(FileInfo: IAIMPFileInfo; Flags: LongWord;
      CallbackProc: TAIMPServiceAlbumArtReceiveProc;
      UserData: Pointer; out TaskID: TTaskHandle): HRESULT; stdcall;
    function Cancel(TaskID: TTaskHandle; Flags: LongWord): HRESULT; stdcall;
  end;

  { IAIMPServiceAlbumArtCache }

  IAIMPServiceAlbumArtCache = interface(IUnknown)
  [SID_IAIMPServiceAlbumArtCache]
    function Flush: HRESULT; stdcall;
    function Get(Key: IAIMPString; var ImageContainer: IAIMPImageContainer): HRESULT; stdcall;
    function Put(Key: IAIMPString; var ImageContainer: IAIMPImageContainer): HRESULT; stdcall;
    function Remove(Key: IAIMPString): HRESULT; stdcall;
    function Stat(out Size: Int64; out NumberOfEntires: LongWord): HRESULT; stdcall;
  end;

implementation

end.
