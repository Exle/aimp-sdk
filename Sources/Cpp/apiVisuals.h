////////////////////////////////////////////////////////////////////////////////
//
//  Project:   AIMP
//             Programming Interface
//
//  Target:    v6.00 build 3000
//
//  Purpose:   Visualization API
//
//  Author:    Artem Izmaylov
//             © 2006-2026
//             www.aimp.ru
//
#ifndef apiVisualsH
#define apiVisualsH

#include "apiTypes.h"
#include "apiObjects.h"
#include "apiCore.h"

static const GUID IID_IAIMPExtensionCustomVisualization = {0x41494D50, 0x4578, 0x7443, 0x73, 0x74, 0x6D, 0x56, 0x69, 0x73, 0x00, 0x00};
static const GUID IID_IAIMPExtensionEmbeddedVisualization = {0x41494D50, 0x4578, 0x7445, 0x6D, 0x62, 0x64, 0x56, 0x69, 0x73, 0x00, 0x00};
static const GUID IID_IAIMPServiceVisualizations = {0x41494D50, 0x5372, 0x7656, 0x69, 0x73, 0x75, 0x61, 0x6C, 0x00, 0x00, 0x00};
static const GUID IID_IAIMPVisualizationDirectOutput = { 0x41494D50, 0x5669, 0x7344, 0x4F, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 };

// Button ID for IAIMPExtensionEmbeddedVisualization.Click
const INT32 AIMP_VISUAL_CLICK_BUTTON_LEFT   = 0;
const INT32 AIMP_VISUAL_CLICK_BUTTON_MIDDLE = 1;

// flags for IAIMPExtensionEmbeddedVisualization.GetFlags and IAIMPExtensionCustomVisualization.GetFlags
const DWORD AIMP_VISUAL_FLAGS_RQD_DATA_WAVEFORM = 1;
const DWORD AIMP_VISUAL_FLAGS_RQD_DATA_SPECTRUM = 2;
const DWORD AIMP_VISUAL_FLAGS_NOT_SUSPEND	    = 4;
const DWORD AIMP_VISUAL_FLAGS_RGBA				= 8;
const DWORD AIMP_VISUAL_FLAGS_TOPDOWN			= 16;

const int AIMP_VISUAL_SPECTRUM_MAX = 256;
const int AIMP_VISUAL_WAVEFORM_MAX = 512;

typedef SINGLE TAIMPVisualDataSpectrum[AIMP_VISUAL_SPECTRUM_MAX];
typedef SINGLE TAIMPVisualDataWaveform[AIMP_VISUAL_WAVEFORM_MAX];

#pragma pack(push, 1)
struct TAIMPVisualData
{
	SINGLE Peaks[2];
	TAIMPVisualDataSpectrum Spectrum[3];
	TAIMPVisualDataWaveform WaveForm[2];
	INT32 Reserved;
};
#pragma pack(pop)
typedef TAIMPVisualData* PAIMPVisualData;

/* IAIMPVisualExtension */

class IAIMPExtensionCustomVisualization: public IUnknown
{
		// Common Information
		virtual DWORD WINAPI GetFlags() = 0;
		// Basic functionality
		virtual void WINAPI Draw(PAIMPVisualData Data) = 0;
};

/* IAIMPExtensionEmbeddedVisualization */

class IAIMPExtensionEmbeddedVisualization: public IUnknown
{
	public:
		// Common Information
		virtual DWORD WINAPI GetFlags() = 0;
		virtual HRESULT WINAPI GetMaxDisplaySize(INT32 *Width, INT32 *Height) = 0;
		virtual HRESULT WINAPI GetName(IAIMPString **S) = 0;
		// Initialization / Finalization
		virtual HRESULT WINAPI Initialize(INT32 Width, INT32 Height) = 0;
		virtual void WINAPI Finalize() = 0;
		// Basic functionality
		virtual void WINAPI Click(INT32 X, INT32 Y, INT32 Button) = 0;
		virtual void WINAPI Draw(HCANVAS Canvas, PAIMPVisualData Data) = 0;
		virtual void WINAPI Resize(INT32 NewWidth, INT32 NewHeight) = 0;
};

/* IAIMPVisualizationDirectOutput */

class IAIMPVisualizationDirectOutput : public IUnknown
{
	public:
		virtual void WINAPI Draw(RGBQUAD* Buffer, PAIMPVisualData Data) = 0;
};

/* IAIMPServiceVisual */

class IAIMPServiceVisualizations: public IUnknown
{
};

#endif // !apiVisualsH