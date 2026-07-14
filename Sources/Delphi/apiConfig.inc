{$IFDEF FPC}
  {$mode delphi}
  {$codepage UTF8}
  {$inline off}
  {$define API_VAR_NEXTGEN}
{$ELSE}
  {$IFNDEF UNICODE}
    {$MESSAGE FATAL 'You MUST use unicode version of Delphi to build this library!'}
  {$ENDIF}
{$ENDIF}

{$MINENUMSIZE 4}
{.$DEFINE API_VAR_NEXTGEN}
