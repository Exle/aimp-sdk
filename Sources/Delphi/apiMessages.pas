﻿////////////////////////////////////////////////////////////////////////////////
//
//  Project:   AIMP
//             Programming Interface
//
//  Target:    v5.40 build 2650
//
//  Purpose:   Messages API
//
//  Author:    Artem Izmaylov
//             © 2006-2025
//             www.aimp.ru
//
//  FPC:       OK
//
unit apiMessages;

{$I apiConfig.inc}

interface

uses
  apiFileManager, apiTypes, apiPlayer;

const

// -----------------------------------------------------------------------------
// Commands
// -----------------------------------------------------------------------------

  AIMP_MSG_CMD_BASE = 0;
  // AParam1: Command ID (see AIMP_MSG_CMD_XXX)
  // Result: S_OK, if enabled
  AIMP_MSG_CMD_STATE_GET = AIMP_MSG_CMD_BASE + 1;

  // Show "Quick File Info" card for playing file
  // AParam1:
  //    LoWord: Display Time (in milliseconds), 0 - default
  //    HiWord: 0 - Popup near system tray,
  //            1 - Popup near mouse cursor
  // AParam2: unused
  AIMP_MSG_CMD_QFI_PLAYING_TRACK = AIMP_MSG_CMD_BASE + 2;

  // Show custom text in display of RunningLine or Text elements
  // AParam1: 0 - Hide text automaticly after 2 seconds
  //          1 - Text will be hidden manually (put nil to AParam2 to hide previous text)
  // AParam2: Pointer to char-array
  AIMP_MSG_CMD_SHOW_NOTIFICATION = AIMP_MSG_CMD_BASE + 3;

  AIMP_MSG_CMD_TOGGLE_PARTREPEAT = AIMP_MSG_CMD_BASE + 5;

  // Show the "About" dialog
  // AParam1, AParam2: unused
  AIMP_MSG_CMD_ABOUT = AIMP_MSG_CMD_BASE + 6;

  // Show the "Options" Dialog
  // AParam1, AParam2: unused
  AIMP_MSG_CMD_OPTIONS = AIMP_MSG_CMD_BASE + 7;

  // Show the "Options" Dialog with active "plugins" sheet
  // AParam1: page index (starts from 1), 0 is for previous user choice (default)
  // AParam2: unused
  AIMP_MSG_CMD_PLUGINS = AIMP_MSG_CMD_BASE + 8;

  // Close the App
  // AParam1, AParam2: unused
  AIMP_MSG_CMD_QUIT = AIMP_MSG_CMD_BASE + 9;

  // Show Simple Scheduler Options Dialog
  // AParam1, AParam2: unused
  AIMP_MSG_CMD_SCHEDULER = AIMP_MSG_CMD_BASE + 11;

  // Switch to next visualization
  // AParam1, AParam2: unused
  AIMP_MSG_CMD_VISUAL_NEXT = AIMP_MSG_CMD_BASE + 12;

  // Switch to previous visualization
  // AParam1, AParam2: unused
  AIMP_MSG_CMD_VISUAL_PREV = AIMP_MSG_CMD_BASE + 13;

  // Start / Resume playback
  // AParam1, AParam2: unused
  AIMP_MSG_CMD_PLAY = AIMP_MSG_CMD_BASE + 14;

  // Pause / Start playback
  // AParam1, AParam2: unused
  AIMP_MSG_CMD_PLAYPAUSE = AIMP_MSG_CMD_BASE + 15;

  // Start playback of previous playlist
  // AParam1, AParam2: unused
  AIMP_MSG_CMD_PLAY_PREV_PLAYLIST = AIMP_MSG_CMD_BASE + 16;

  // Resume / Pause playback
  // AParam1, AParam2: unused
  AIMP_MSG_CMD_PAUSE = AIMP_MSG_CMD_BASE + 17;

  // Stop playback
  // AParam1, AParam2: unused
  AIMP_MSG_CMD_STOP = AIMP_MSG_CMD_BASE + 18;

  // Next Track
  // AParam1, AParam2: unused
  AIMP_MSG_CMD_NEXT = AIMP_MSG_CMD_BASE + 19;

  // Previous Track
  // AParam1, AParam2: unused
  AIMP_MSG_CMD_PREV = AIMP_MSG_CMD_BASE + 20;

  // Execute "Open Files" dialog
  // AParam1, AParam2: unused
  AIMP_MSG_CMD_OPEN_FILES = AIMP_MSG_CMD_BASE + 21;

  // Execute "Open Folders" dialog
  // AParam1, AParam2: unused
  AIMP_MSG_CMD_OPEN_FOLDERS = AIMP_MSG_CMD_BASE + 22;

  // Execute "Open Playlist" dialog
  // AParam1, AParam2: unused
  AIMP_MSG_CMD_OPEN_PLAYLISTS  = AIMP_MSG_CMD_BASE + 23;

  // Execute "Save Playlist" dialog
  // AParam1, AParam2: unused
  AIMP_MSG_CMD_SAVE_PLAYLISTS  = AIMP_MSG_CMD_BASE + 24;

  // Execute "Bookmarks" dialog
  // AParam1, AParam2: unused
  AIMP_MSG_CMD_BOOKMARKS = AIMP_MSG_CMD_BASE + 25;

  // Add files to Bookmarks
  // AParam1: 0 - add playing file, 1 - add selected files from active playlist
  // AParam2: unused
  AIMP_MSG_CMD_BOOKMARKS_ADD = AIMP_MSG_CMD_BASE + 26;

  // Rescan tags in active playlist
  // AParam1, AParam2: unused
  AIMP_MSG_CMD_PLS_RESCAN  = AIMP_MSG_CMD_BASE + 27;

  // Jump focus in playlist to playing file
  // AParam1, AParam2: unused
  AIMP_MSG_CMD_PLS_FOCUS_PLAYING = AIMP_MSG_CMD_BASE + 28;

  // Delete all items from active playlist
  // AParam1, AParam2: unused
  AIMP_MSG_CMD_PLS_DELETE_ALL = AIMP_MSG_CMD_BASE + 29;

  // Delete non exists items from active playlist
  // AParam1, AParam2: unused
  AIMP_MSG_CMD_PLS_DELETE_NON_EXISTS = AIMP_MSG_CMD_BASE + 30;

  // Delete non selected items from active playlist
  // AParam1, AParam2: unused
  AIMP_MSG_CMD_PLS_DELETE_NON_SELECTED = AIMP_MSG_CMD_BASE + 31;

  // Delete Playing Item from playlist and disk
  // AParam1, AParam2: unused
  AIMP_MSG_CMD_PLS_DELETE_PLAYING_FROM_HDD = AIMP_MSG_CMD_BASE + 32;

  // Delete selected items from active playlist
  // AParam1, AParam2: unused
  AIMP_MSG_CMD_PLS_DELETE_SELECTED = AIMP_MSG_CMD_BASE + 33;

  // Delete selected items from active playlist and disk
  // AParam1, AParam2: unused
  AIMP_MSG_CMD_PLS_DELETE_SELECTED_FROM_HDD = AIMP_MSG_CMD_BASE + 34;

  // Delete switched off items from active playlist
  // AParam1, AParam2: unused
  AIMP_MSG_CMD_PLS_DELETE_SWITCHEDOFF = AIMP_MSG_CMD_BASE + 35;

  // Delete switched off items from active playlist and disk
  // AParam1, AParam2: unused
  AIMP_MSG_CMD_PLS_DELETE_SWITCHEDOFF_FROM_HDD = AIMP_MSG_CMD_BASE + 36;

  // Delete duplicates from active playlist
  // AParam1, AParam2: unused
  AIMP_MSG_CMD_PLS_DELETE_DUPLICATES = AIMP_MSG_CMD_BASE + 37;

  // AParam1, AParam2: unused
  AIMP_MSG_CMD_PLS_SORT_BY_ARTIST = AIMP_MSG_CMD_BASE + 38;

  // AParam1, AParam2: unused
  AIMP_MSG_CMD_PLS_SORT_BY_TITLE = AIMP_MSG_CMD_BASE + 39;

  // AParam1, AParam2: unused
  AIMP_MSG_CMD_PLS_SORT_BY_PATH = AIMP_MSG_CMD_BASE + 40;

  // AParam1, AParam2: unused
  AIMP_MSG_CMD_PLS_SORT_BY_DURATION = AIMP_MSG_CMD_BASE + 41;

  // AParam1:
  //   0 - all
  //   1 - groups
  //   2 - items inside groups
  //   3 - groups and it items
  // AParam2: unused
  AIMP_MSG_CMD_PLS_SORT_RANDOMIZE = AIMP_MSG_CMD_BASE + 42;

  // AParam1, AParam2: unused
  AIMP_MSG_CMD_PLS_SORT_INVERT = AIMP_MSG_CMD_BASE + 43;

  // Switch on autoplaying markers for selected items in active playlist
  // AParam1, AParam2: unused
  AIMP_MSG_CMD_PLS_SWITCH_ON = AIMP_MSG_CMD_BASE + 44;

  // Switch on autoplaying markers for selected items in active playlist
  // AParam1, AParam2: unused
  AIMP_MSG_CMD_PLS_SWITCH_OFF = AIMP_MSG_CMD_BASE + 45;

  // Execute "Add files" dialog
  // AParam1, AParam2: unused
  AIMP_MSG_CMD_ADD_FILES = AIMP_MSG_CMD_BASE + 46;

  // Execute "Add folders" dialog
  // AParam1, AParam2: unused
  AIMP_MSG_CMD_ADD_FOLDERS = AIMP_MSG_CMD_BASE + 47;

  // Execute "Add Playlists" dialog
  // AParam1, AParam2: unused
  AIMP_MSG_CMD_ADD_PLAYLISTS = AIMP_MSG_CMD_BASE + 48;

  // Execute "Add URL" dialog
  // AParam1, AParam2: unused
  AIMP_MSG_CMD_ADD_URL = AIMP_MSG_CMD_BASE + 49;

  // Execute "Quick Tag Editor" for playing file
  // AParam1, AParam2: unused
  AIMP_MSG_CMD_QTE_PLAYING_TRACK = AIMP_MSG_CMD_BASE + 51;

  // Show Advanced Search Dialog
  // AParam1, AParam2: unused
  AIMP_MSG_CMD_SEARCH = AIMP_MSG_CMD_BASE + 52;

  // Show DSP Manager Dialog
  // AParam1: Active tab sheet index [0..5]
  // AParam2: unused
  AIMP_MSG_CMD_DSPMANAGER = AIMP_MSG_CMD_BASE + 53;

  // Sync active playlist with preimage
  // AParam1, AParam2: unused
  AIMP_MSG_CMD_PLS_RELOAD_FROM_PREIMAGE = AIMP_MSG_CMD_BASE + 55;

  // Starts first visualization
  // AParam1, AParam2: unused
  AIMP_MSG_CMD_VISUAL_START = AIMP_MSG_CMD_BASE + 57;

  // Switch off the visualization
  // AParam1, AParam2: unused
  AIMP_MSG_CMD_VISUAL_STOP = AIMP_MSG_CMD_BASE + 58;

  // Rescan tags for selected files in active playlist
  // AParam1, AParam2: unused
  AIMP_MSG_CMD_PLS_RESCAN_SELECTED = AIMP_MSG_CMD_BASE + 59;

  // Extended control of "Quick File Info" card that displaying information about playing file
  // AParam2: pointer to TAIMPQuickFileInfoParams
  AIMP_MSG_CMD_QFI = AIMP_MSG_CMD_BASE + 60;

  // Delete selected items with folders from active playlist and disk
  // AParam1, AParam2: unused
  AIMP_MSG_CMD_PLS_DELETE_SELECTED_FROM_HDD_W_FOLDERS = AIMP_MSG_CMD_BASE + 61;

// -----------------------------------------------------------------------------
// Properties
// -----------------------------------------------------------------------------

  AIMP_MSG_PROPERTY_BASE = $1000;

  // Flags for AParam1
  AIMP_MSG_PROPVALUE_GET = 0;
  AIMP_MSG_PROPVALUE_SET = 1;

  // AParam1: AIMP_MSG_PROPVALUE_GET / AIMP_MSG_PROPVALUE_SET
  // AParam2: Pointer to 32-bit floating-point variable, Range [0.0 .. 1.0]
  AIMP_MSG_PROPERTY_VOLUME = AIMP_MSG_PROPERTY_BASE + 1;

  // AParam1: AIMP_MSG_PROPVALUE_GET / AIMP_MSG_PROPVALUE_SET
  // AParam2: Pointer to LongBool (32-bit Boolean) variable
  AIMP_MSG_PROPERTY_MUTE = AIMP_MSG_PROPERTY_BASE + 2;

  // AParam1: AIMP_MSG_PROPVALUE_GET / AIMP_MSG_PROPVALUE_SET
  // AParam2: Pointer to Single (32-bit floating point value) variable
  //          [-1.0 .. +1.0], Default: 0.0
  AIMP_MSG_PROPERTY_BALANCE = AIMP_MSG_PROPERTY_BASE + 3;

  // AParam1: AIMP_MSG_PROPVALUE_GET / AIMP_MSG_PROPVALUE_SET
  // AParam2: Pointer to Single (32-bit floating point value) variable
  //          [0.0 .. 1.0], Default: 0.0 (switched off)
  AIMP_MSG_PROPERTY_CHORUS = AIMP_MSG_PROPERTY_BASE + 4;

  // AParam1: AIMP_MSG_PROPVALUE_GET / AIMP_MSG_PROPVALUE_SET
  // AParam2: Pointer to Single (32-bit floating point value) variable
  //          [0.0 .. 1.0], Default: 0.0 (switched off)
  AIMP_MSG_PROPERTY_ECHO = AIMP_MSG_PROPERTY_BASE + 5;

  // AParam1: AIMP_MSG_PROPVALUE_GET / AIMP_MSG_PROPVALUE_SET
  // AParam2: Pointer to Single (32-bit floating point value) variable
  //          [1.0 .. 4.0], Default: 1.0 (switched off)
  AIMP_MSG_PROPERTY_ENHANCER = AIMP_MSG_PROPERTY_BASE + 6;

  // AParam1: AIMP_MSG_PROPVALUE_GET / AIMP_MSG_PROPVALUE_SET
  // AParam2: Pointer to Single (32-bit floating point value) variable
  //          [0.0 .. 1.0], Default: 0.0 (switched off)
  AIMP_MSG_PROPERTY_FLANGER = AIMP_MSG_PROPERTY_BASE + 7;

  // AParam1: AIMP_MSG_PROPVALUE_GET / AIMP_MSG_PROPVALUE_SET
  // AParam2: Pointer to Single (32-bit floating point value) variable
  //          [0.0 .. 1.0], Default: 0.0 (switched off)
  AIMP_MSG_PROPERTY_REVERB = AIMP_MSG_PROPERTY_BASE + 8;

  // AParam1: AIMP_MSG_PROPVALUE_GET / AIMP_MSG_PROPVALUE_SET
  // AParam2: Pointer to Single (32-bit floating point value) variable
  //          [-10.0 .. +10.0], Default: 0.0 (switched off)
  AIMP_MSG_PROPERTY_PITCH = AIMP_MSG_PROPERTY_BASE + 9;

  // AParam1: AIMP_MSG_PROPVALUE_GET / AIMP_MSG_PROPVALUE_SET
  // AParam2: Pointer to Single (32-bit floating point value) variable
  //          [0.5 .. 1.5], Default: 1.0 (switched off)
  AIMP_MSG_PROPERTY_SPEED = AIMP_MSG_PROPERTY_BASE + 10;

  // AParam1: AIMP_MSG_PROPVALUE_GET / AIMP_MSG_PROPVALUE_SET
  // AParam2: Pointer to Single (32-bit floating point value) variable
  //          [0.8 .. 1.5], Default: 1.0 (switched off)
  AIMP_MSG_PROPERTY_TEMPO = AIMP_MSG_PROPERTY_BASE + 11;

  // AParam1: AIMP_MSG_PROPVALUE_GET / AIMP_MSG_PROPVALUE_SET
  // AParam2: Pointer to Single (32-bit floating point value) variable
  //          [0.0 .. 2.0], Default: 0.0 (switched off)
  AIMP_MSG_PROPERTY_TRUEBASS = AIMP_MSG_PROPERTY_BASE + 12;

  // AParam1: AIMP_MSG_PROPVALUE_GET / AIMP_MSG_PROPVALUE_SET
  // AParam2: Pointer to Single (32-bit floating point value) variable
  //          [-15.0 .. 15.0] (in db), Default: 0.0 (switched off)
  AIMP_MSG_PROPERTY_PREAMP = AIMP_MSG_PROPERTY_BASE + 13;

  // AParam1: AIMP_MSG_PROPVALUE_GET / AIMP_MSG_PROPVALUE_SET
  // AParam2: Pointer to LongBool (32-bit boolean value) variable
  //          Default: False (switched off)
  AIMP_MSG_PROPERTY_EQUALIZER =  AIMP_MSG_PROPERTY_BASE + 14;

  // AParam1: LoWord: AIMP_MSG_PROPVALUE_GET / AIMP_MSG_PROPVALUE_SET
  //          HiWord: Band Index [0..18]
  // AParam2: Pointer to Single (32-bit floating point value) variable
  //          [-15.0 .. 15.0] (in db), Default: 0.0 (switched off)
  // !!!NOTE: AParam2 in AIMP_MSG_EVENT_PROPERTY_VALUE will be nil;
  AIMP_MSG_PROPERTY_EQUALIZER_BAND = AIMP_MSG_PROPERTY_BASE + 15;

  // !!!ReadOnly property
  // AParam1: AIMP_MSG_PROPVALUE_GET
  // AParam2: Pointer to Integer variable
  //			    One of the AIMP_PLAYER_STATE_XXX
  // See AIMP_MSG_EVENT_PLAYER_STATE event
  AIMP_MSG_PROPERTY_PLAYER_STATE = AIMP_MSG_PROPERTY_BASE + 16;

  // AParam1: AIMP_MSG_PROPVALUE_GET / AIMP_MSG_PROPVALUE_SET
  // AParam2: Pointer to Single (32-bit floating point value) variable
  //          New position in Seconds
  // See AIMP_MSG_EVENT_PROPERTY_VALUE and AIMP_MSG_EVENT_PLAYER_UPDATE_POSITION
  AIMP_MSG_PROPERTY_PLAYER_POSITION = AIMP_MSG_PROPERTY_BASE + 17;

  // !!!ReadOnly property
  // AParam1: AIMP_MSG_PROPVALUE_GET
  // AParam2: Pointer to Single (32-bit floating point value) variable, in Seconds
  AIMP_MSG_PROPERTY_PLAYER_DURATION = AIMP_MSG_PROPERTY_BASE + 18;

  // !!!ReadOnly property
  // AParam1: AIMP_MSG_PROPVALUE_GET
  // AParam2: Pointer to Integer variable
  //    0 = Disabled,
  //    1 = A point is assigned,
  //    2 = B point is assigned, repeat started
  AIMP_MSG_PROPERTY_PARTREPEAT = AIMP_MSG_PROPERTY_BASE + 19;

  // AParam1: AIMP_MSG_PROPVALUE_GET / AIMP_MSG_PROPVALUE_SET
  // AParam2: Pointer to LongBool (32-bit boolean value) variable
  AIMP_MSG_PROPERTY_REPEAT = AIMP_MSG_PROPERTY_BASE + 20;

  // AParam1: AIMP_MSG_PROPVALUE_GET / AIMP_MSG_PROPVALUE_SET
  // AParam2: Pointer to LongBool (32-bit boolean value) variable
  AIMP_MSG_PROPERTY_SHUFFLE = AIMP_MSG_PROPERTY_BASE + 21;

  // !!!ReadOnly property
  // AParam1: One of AIMP_MPH_XXX flags
  // AParam2: Pointer to HWND
  AIMP_MSG_PROPERTY_HWND = AIMP_MSG_PROPERTY_BASE + 22;
    AIMP_MPH_MAINFORM      = 0;
    AIMP_MPH_APPLICATION   = 1;
    AIMP_MPH_TRAYCONTROL   = 2;
    AIMP_MPH_PLAYLISTFORM  = 3;
    AIMP_MPH_EQUALIZERFORM = 4;

  // AParam1: AIMP_MSG_PROPVALUE_GET / AIMP_MSG_PROPVALUE_SET
  // AParam2: Pointer to LongBool (32-bit boolean value) variable
  AIMP_MSG_PROPERTY_STAYONTOP = AIMP_MSG_PROPERTY_BASE + 23;

  // AParam1: AIMP_MSG_PROPVALUE_GET / AIMP_MSG_PROPVALUE_SET
  // AParam2: Pointer to LongBool (32-bit boolean value) variable
  AIMP_MSG_PROPERTY_REVERSETIME = AIMP_MSG_PROPERTY_BASE + 24;

  // AParam1: AIMP_MSG_PROPVALUE_GET / AIMP_MSG_PROPVALUE_SET
  // AParam2: Pointer to LongBool (32-bit boolean value) variable
  AIMP_MSG_PROPERTY_MINIMIZED_TO_TRAY = AIMP_MSG_PROPERTY_BASE + 25;

  // AParam1: AIMP_MSG_PROPVALUE_GET / AIMP_MSG_PROPVALUE_SET
  // AParam2: Pointer to LongBool (32-bit boolean value) variable
  AIMP_MSG_PROPERTY_REPEAT_SINGLE_FILE_PLAYLISTS = AIMP_MSG_PROPERTY_BASE + 26;

  // AParam1: AIMP_MSG_PROPVALUE_GET / AIMP_MSG_PROPVALUE_SET
  // AParam2: Pointer to Integer variable
  //   0 - Jump to next playlist
  //   1 - Repeat playlist
  //   2 - Do nothing
  AIMP_MSG_PROPERTY_ACTION_ON_END_OF_PLAYLIST = AIMP_MSG_PROPERTY_BASE + 27;

  // AParam1: AIMP_MSG_PROPVALUE_GET / AIMP_MSG_PROPVALUE_SET
  // AParam2: Pointer to LongBool (32-bit boolean value) variable
  AIMP_MSG_PROPERTY_STOP_AFTER_TRACK = AIMP_MSG_PROPERTY_BASE + 28 deprecated 'use the AIMP_MSG_PROPERTY_ACTION_ON_END_OF_TRACK instead';

  // Start / Stop Internet Radio capture
  // AParam1: AIMP_MSG_PROPVALUE_GET / AIMP_MSG_PROPVALUE_SET
  // AParam2: Pointer to LongBool (32-bit boolean value) variable
  AIMP_MSG_PROPERTY_RADIOCAP = AIMP_MSG_PROPERTY_BASE + 29;

  // See AIMP_MSG_EVENT_LOADED
  // AParam1: AIMP_MSG_PROPVALUE_GET (ReadOnly)
  // AParam2: Pointer to LongBool (32-bit boolean value) variable
  AIMP_MSG_PROPERTY_LOADED = AIMP_MSG_PROPERTY_BASE + 30;

  // AParam1: AIMP_MSG_PROPVALUE_GET / AIMP_MSG_PROPVALUE_SET
  // AParam2: Pointer to LongBool (32-bit boolean value) variable
  AIMP_MSG_PROPERTY_VISUAL_FULLSCREEN = AIMP_MSG_PROPERTY_BASE + 31;

  // !!!ReadOnly property
  // AParam1: AIMP_MSG_PROPVALUE_GET
  // AParam2: Pointer to Single (32-bit floating point value) variable, [0..100]%
  AIMP_MSG_PROPERTY_PLAYER_BUFFERING = AIMP_MSG_PROPERTY_BASE + 32;

  // Toggles the Internet Radio capture mode - single track only / all tracks
  // AParam1: AIMP_MSG_PROPVALUE_GET / AIMP_MSG_PROPVALUE_SET
  // AParam2: Pointer to LongBool (32-bit boolean value) variable
  AIMP_MSG_PROPERTY_RADIOCAP_SINGLE_TRACK = AIMP_MSG_PROPERTY_BASE + 33;

  // State of cross-mixing feature
  // AParam1: AIMP_MSG_PROPVALUE_GET / AIMP_MSG_PROPVALUE_SET
  // AParam2: Pointer to LongBool (32-bit boolean value) variable
  AIMP_MSG_PROPERTY_CROSSMIXING = AIMP_MSG_PROPERTY_BASE + 34;

  // AParam1: AIMP_MSG_PROPVALUE_GET / AIMP_MSG_PROPVALUE_SET
  // AParam2: Pointer to Integer variable
  //   0 - Default Action
  //   1 - Jump to next track and stop playback
  //   2 - Jump to next track and pause playback
  AIMP_MSG_PROPERTY_ACTION_ON_END_OF_TRACK = AIMP_MSG_PROPERTY_BASE + 35;

  // AParam1: AIMP_MSG_PROPVALUE_GET / AIMP_MSG_PROPVALUE_SET
  // AParam2: Pointer to LongBool (32-bit boolean value) variable
  //          Default: False (switched off)
  AIMP_MSG_PROPERTY_EQUALIZER_AUTO =  AIMP_MSG_PROPERTY_BASE + 36;

  // AParam1: AIMP_MSG_PROPVALUE_GET / AIMP_MSG_PROPVALUE_SET
  // AParam2: Pointer to first element of array of two Single (32-bit floating point value) values
  // 1st element is position of the A point (in seconds) of part-repeat range or -1 if point is not specified
  // 2nd element is position of the B point (in seconds) of part-repeat range or -1 if point is not specified
  AIMP_MSG_PROPERTY_PARTREPEAT_RANGE = AIMP_MSG_PROPERTY_BASE + 37;

  // State of the "automatically jump to next track" option
  // AParam1: AIMP_MSG_PROPVALUE_GET / AIMP_MSG_PROPVALUE_SET
  // AParam2: Pointer to LongBool (32-bit boolean value) variable
  AIMP_MSG_PROPERTY_AUTOJUMP_TO_NEXT_TRACK = AIMP_MSG_PROPERTY_BASE + 38;

// -----------------------------------------------------------------------------
// Events
// -----------------------------------------------------------------------------

  AIMP_MSG_EVENT_BASE = $2000;

  // Called, when Command state changed; AParam1: Command ID (see AIMP_MSG_CMD_XXX)
  AIMP_MSG_EVENT_CMD_STATE = AIMP_MSG_EVENT_BASE + 1;

  // Called, when Options has been changed
  AIMP_MSG_EVENT_OPTIONS = AIMP_MSG_EVENT_BASE + 2;

  // Called, when audio stream starts playing
  AIMP_MSG_EVENT_STREAM_START = AIMP_MSG_EVENT_BASE + 3;
  // Similar to AIMP_MSG_EVENT_STREAM_START event, but called when an Internet radio station changes the track
  AIMP_MSG_EVENT_STREAM_START_SUBTRACK = AIMP_MSG_EVENT_BASE + 4;
  // Called, when audio stream has been finished
  AIMP_MSG_EVENT_STREAM_END = AIMP_MSG_EVENT_BASE + 5;
    // AParam1 contains combination of following flags:
    AIMP_MES_END_OF_QUEUE    = 1;
    AIMP_MES_END_OF_PLAYLIST = 2;
    AIMP_MES_HAS_NEXT_TRACK  = 4;

  // Called, when player state has been changed (Played / Paused / Stopped)
  // AParam1: One of the AIMP_PLAYER_STATE_XXX
  AIMP_MSG_EVENT_PLAYER_STATE = AIMP_MSG_EVENT_BASE + 6;

  // Called, when property value has been changed
  // AParam1: PropertyID (see AIMP_MSG_PROPERTY_XXX)
  // AParam2: like AParam2 for each PropertyID
  AIMP_MSG_EVENT_PROPERTY_VALUE = AIMP_MSG_EVENT_BASE + 7;

  // Called, when options frame added / removed
  // AParam1, AParam2: unused
  AIMP_MSG_EVENT_OPTIONS_FRAME_LIST = AIMP_MSG_EVENT_BASE + 8;

  // Called, when options frame content changed
  // AParam1, AParam2: unused
  AIMP_MSG_EVENT_OPTIONS_FRAME_MODIFIED = AIMP_MSG_EVENT_BASE + 9;

  // Called, when swithing between visual plugins
  // AParam1, AParam2: unused
  AIMP_MSG_EVENT_VISUAL_PLUGIN = AIMP_MSG_EVENT_BASE + 11;

  // Called, when mark of file has been changed
  // AParam1: New Mark Value (0..5)
  // AParam2: FileName (Pointer to Char)
  // !!!WARNING: You must not fire this event manually!
  AIMP_MSG_EVENT_FILEMARK = AIMP_MSG_EVENT_BASE + 12;

  // Called, when statistics of the file changed
  // AParam2: FileName (Pointer to Char)
  // !!!Note: If filename is empty or AParam2 is nil - statistics for all files has been changed
  // !!!WARNING: You must not fire this event manually!
  AIMP_MSG_EVENT_STATISTICS_CHANGED = AIMP_MSG_EVENT_BASE + 14;

  // Called after skin changed
  // AParam1, AParam2: unused
  AIMP_MSG_EVENT_SKIN = AIMP_MSG_EVENT_BASE + 15;

  // Called every second by timer unlike AIMP_MSG_EVENT_PROPERTY_VALUE event for AIMP_MSG_PROPERTY_PLAYER_POSITION property
  // that fires only if user change position of the track
  // AParam1, AParam2: unused
  AIMP_MSG_EVENT_PLAYER_UPDATE_POSITION = AIMP_MSG_EVENT_BASE + 16;

  // Called, when inteface language has been changed
  // AParam1, AParam2: unused
  AIMP_MSG_EVENT_LANGUAGE = AIMP_MSG_EVENT_BASE + 17;

  // Called, when AIMP completely loaded
  // AParam1, AParam2: unused
  AIMP_MSG_EVENT_LOADED = AIMP_MSG_EVENT_BASE + 18;

  // Called, when AIMP is preparing to terminate
  // AParam1, AParam2: unused
  AIMP_MSG_EVENT_TERMINATING = AIMP_MSG_EVENT_BASE + 19;

  // Called, when information about playing file changed (album, title, album art and etc)
  // AParam1, AParam2: unused
  AIMP_MSG_EVENT_PLAYING_FILE_INFO	= AIMP_MSG_EVENT_BASE + 20;

  // High resolution version of the AIMP_MSG_EVENT_PLAYER_UPDATE_POSITION event
  // Called few times per second by a timer (is about 10 fps, real FPS is depended from some internal and external factors)
  // AParam1, AParam2: unused
  AIMP_MSG_EVENT_PLAYER_UPDATE_POSITION_HR = AIMP_MSG_EVENT_BASE + 21;

  // Called, when name of equalizer preset has been changed
  // AParam1: Unused
  // AParam2: Pointer to char-array, can be = nil (ReadOnly!)
  AIMP_MSG_EVENT_EQUALIZER_PRESET_NAME = AIMP_MSG_EVENT_BASE + 22;

  // Callen, when playback queue changed
  // AParam1: Unused
  // AParam2: Unused
  AIMP_MSG_EVENT_PLAYBACK_QUEUE = AIMP_MSG_EVENT_BASE + 23;

  // Called, when list of DSP/VST plugins is changed
  // AParam1: Unused
  // AParam2: Unused
  AIMP_MSG_EVENT_DSP = AIMP_MSG_EVENT_BASE + 24;

  // Called, after chaning the accent color or night/day mode
  AIMP_MSG_EVENT_UI_MODE = AIMP_MSG_EVENT_BASE + 25;

// -----------------------------------------------------------------------------
// Quick File Info
// -----------------------------------------------------------------------------

const
  AIMP_QFI_ANIMATION_NONE = 0;
  AIMP_QFI_ANIMATION_FADE = 1;
  AIMP_QFI_SW_HIDE = 0;
  AIMP_QFI_SW_SHOW = 1;

type
  PAIMPQuickFileInfoParams = ^TAIMPQuickFileInfoParams;
  TAIMPQuickFileInfoParams = packed record
    cbSize: Integer; // struct size
    CmdShow: Integer; // refer to AIMP_QFI_SW_XXX
    AnimationType: Integer; // show / hide animation type, refer to AIMP_QFI_ANIMATION_XXX
    AnimationTime: Integer; // animation time in milliseconds
    DisplayTime: Integer; // in milliseconds, 0 - use default display time
    Opacity: Byte; // 0..100%
    FileInfo: IAIMPFileInfo; // file information to display
  end;

// -----------------------------------------------------------------------------
// General
// -----------------------------------------------------------------------------

const
  SID_IAIMPMessageHook = '{FC6FB524-A959-4089-AA0A-EA40AB7374CD}';
  IID_IAIMPMessageHook: TGUID = SID_IAIMPMessageHook;

  SID_IAIMPServiceMessageDispatcher = '{41494D50-5372-764D-7367-447370720000}';
  IID_IAIMPServiceMessageDispatcher: TGUID = SID_IAIMPServiceMessageDispatcher;

type

  { IAIMPMessageHook }

  IAIMPMessageHook = interface(IUnknown)
  [SID_IAIMPMessageHook]
    procedure CoreMessage(Message: LongWord; Param1: Integer; Param2: Pointer; var Result: HRESULT); stdcall;
  end;

  { IAIMPServiceMessageDispatcher }

  IAIMPServiceMessageDispatcher = interface(IUnknown)
  [SID_IAIMPServiceMessageDispatcher]
    function Send(Message: LongWord; Param1: Integer; Param2: Pointer): HRESULT; stdcall;
    // Custom Messages
    function Register(MessageName: PChar): LongWord; stdcall;
    // Hook
    function Hook(Hook: IAIMPMessageHook): HRESULT; stdcall;
    function Unhook(Hook: IAIMPMessageHook): HRESULT; stdcall;
  end;

implementation

end.
