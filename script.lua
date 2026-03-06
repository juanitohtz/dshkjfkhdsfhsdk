print("Working")

local ffi = require("ffi")

ffi.cdef[[
typedef void* HWND;
typedef void* HDC;
typedef unsigned long DWORD;
typedef unsigned int UINT;

HDC GetDC(HWND hWnd);
int ReleaseDC(HWND hWnd, HDC hDC);
DWORD GetPixel(HDC hdc, int nXPos, int nYPos);

typedef struct {
    long dx;
    long dy;
    DWORD mouseData;
    DWORD dwFlags;
    DWORD time;
    void* dwExtraInfo;
} MOUSEINPUT;

typedef struct {
    DWORD type;
    MOUSEINPUT mi;
} INPUT;

UINT SendInput(UINT cInputs, INPUT *pInputs, int cbSize);
void Sleep(unsigned int ms);
]]

local user32 = ffi.load("user32")
local gdi32 = ffi.load("gdi32")

local MOUSEEVENTF_LEFTDOWN = 0x0002
local MOUSEEVENTF_LEFTUP = 0x0004
local INPUT_MOUSE = 0

-- set your resolution
local screenX = 1920
local screenY = 1080
local cx = math.floor(screenX / 2)
local cy = math.floor(screenY / 2)

local function click()
    local inputs = ffi.new("INPUT[2]")

    inputs[0].type = INPUT_MOUSE
    inputs[0].mi.dwFlags = MOUSEEVENTF_LEFTDOWN

    inputs[1].type = INPUT_MOUSE
    inputs[1].mi.dwFlags = MOUSEEVENTF_LEFTUP

    user32.SendInput(2, inputs, ffi.sizeof("INPUT"))
end

local hdc = gdi32.GetDC(nil)

while true do
    local color = gdi32.GetPixel(hdc, cx, cy)

    local r = color % 256
    local g = math.floor(color / 256) % 256
    local b = math.floor(color / 65536) % 256

    -- detect red
    if r > 200 and g < 80 and b < 80 then
        click()
        ffi.C.Sleep(20)
    end

    ffi.C.Sleep(2)
end
