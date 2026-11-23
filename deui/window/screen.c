// deui's screen, native (SDL3, WebGPU and ThorVG)
// =================================================
//
// The effects in screen.bend. SDL3 gives the window and its events,
// wgpu-native gives WebGPU on Vulkan (or Metal, or DirectX), and ThorVG's
// WebGPU engine draws each frame onto the window's surface, its labels in
// a TrueType font. Bend splices this file into the generated C program
// after its runtime, so the runtime's helpers (Term, Env, io_done, io_fail,
// io_node, ...) are in scope. Bend links no library for it, so the three
// are opened with dlopen on first use; their headers only supply the
// types.
//
// One window at a time, named by the id 1. Events cross into Bend as a flat
// list of words, and a frame comes back as one; screen.bend says how each
// is laid out.
//
// Bend's coordinates are the window's, as SDL reports the mouse in. The
// window has the display's full resolution, and the kept scene is drawn
// scaled by its pixel density, so everything, text included, is drawn at
// full resolution.
//
// The screen keeps a copy of the scene, set once and then changed only by
// the scene's edits, and ThorVG keeps a paint for each part of it that's
// drawn. A frame only asks ThorVG to draw what it keeps.

#include <dlfcn.h>
#include <SDL3/SDL.h>
#include <webgpu/webgpu.h>
#include <thorvg-1/thorvg_capi.h>

// The libraries, opened
// ---------------------

static __typeof__(SDL_Init)* ds_SDL_Init;
static __typeof__(SDL_Quit)* ds_SDL_Quit;
static __typeof__(SDL_GetError)* ds_SDL_GetError;
static __typeof__(SDL_CreateWindow)* ds_SDL_CreateWindow;
static __typeof__(SDL_DestroyWindow)* ds_SDL_DestroyWindow;
static __typeof__(SDL_GetWindowProperties)* ds_SDL_GetWindowProperties;
static __typeof__(SDL_GetPointerProperty)* ds_SDL_GetPointerProperty;
static __typeof__(SDL_GetNumberProperty)* ds_SDL_GetNumberProperty;
static __typeof__(SDL_GetCurrentVideoDriver)* ds_SDL_GetCurrentVideoDriver;
static __typeof__(SDL_GetWindowSizeInPixels)* ds_SDL_GetWindowSizeInPixels;
static __typeof__(SDL_GetWindowPixelDensity)* ds_SDL_GetWindowPixelDensity;
static __typeof__(SDL_StartTextInput)* ds_SDL_StartTextInput;
static __typeof__(SDL_WaitEventTimeout)* ds_SDL_WaitEventTimeout;
static __typeof__(SDL_PollEvent)* ds_SDL_PollEvent;
static __typeof__(SDL_LoadFile)* ds_SDL_LoadFile;
static __typeof__(SDL_free)* ds_SDL_free;
static __typeof__(wgpuCreateInstance)* ds_wgpuCreateInstance;
static __typeof__(wgpuInstanceCreateSurface)* ds_wgpuInstanceCreateSurface;
static __typeof__(wgpuInstanceRequestAdapter)* ds_wgpuInstanceRequestAdapter;
static __typeof__(wgpuAdapterRequestDevice)* ds_wgpuAdapterRequestDevice;
static __typeof__(wgpuInstanceProcessEvents)* ds_wgpuInstanceProcessEvents;
static __typeof__(wgpuSurfacePresent)* ds_wgpuSurfacePresent;
static __typeof__(wgpuSurfaceRelease)* ds_wgpuSurfaceRelease;
static __typeof__(wgpuDeviceRelease)* ds_wgpuDeviceRelease;
static __typeof__(wgpuAdapterRelease)* ds_wgpuAdapterRelease;
static __typeof__(wgpuInstanceRelease)* ds_wgpuInstanceRelease;
static __typeof__(tvg_engine_init)* ds_tvg_engine_init;
static __typeof__(tvg_engine_term)* ds_tvg_engine_term;
static __typeof__(tvg_wgcanvas_create)* ds_tvg_wgcanvas_create;
static __typeof__(tvg_wgcanvas_set_target_with_context)* ds_tvg_wgcanvas_set_target_with_context;
static __typeof__(tvg_canvas_destroy)* ds_tvg_canvas_destroy;
static __typeof__(tvg_canvas_add)* ds_tvg_canvas_add;
static __typeof__(tvg_canvas_remove)* ds_tvg_canvas_remove;
static __typeof__(tvg_paint_rel)* ds_tvg_paint_rel;
static __typeof__(tvg_shape_reset)* ds_tvg_shape_reset;
static __typeof__(tvg_canvas_update)* ds_tvg_canvas_update;
static __typeof__(tvg_paint_scale)* ds_tvg_paint_scale;
static __typeof__(tvg_scene_remove)* ds_tvg_scene_remove;
static __typeof__(tvg_scene_insert)* ds_tvg_scene_insert;
static __typeof__(tvg_scene_add)* ds_tvg_scene_add;
static __typeof__(tvg_scene_new)* ds_tvg_scene_new;
static __typeof__(tvg_canvas_draw)* ds_tvg_canvas_draw;
static __typeof__(tvg_canvas_sync)* ds_tvg_canvas_sync;
static __typeof__(tvg_shape_new)* ds_tvg_shape_new;
static __typeof__(tvg_shape_append_rect)* ds_tvg_shape_append_rect;
static __typeof__(tvg_shape_set_fill_color)* ds_tvg_shape_set_fill_color;
static __typeof__(tvg_text_new)* ds_tvg_text_new;
static __typeof__(tvg_text_set_font)* ds_tvg_text_set_font;
static __typeof__(tvg_text_set_size)* ds_tvg_text_set_size;
static __typeof__(tvg_text_set_text)* ds_tvg_text_set_text;
static __typeof__(tvg_text_set_color)* ds_tvg_text_set_color;
static __typeof__(tvg_paint_translate)* ds_tvg_paint_translate;
static __typeof__(tvg_font_load_data)* ds_tvg_font_load_data;
static __typeof__(tvg_font_unload)* ds_tvg_font_unload;

// Opens the libraries and finds every function, once; false if any is
// missing.
static bool ds_load(void) {
  static int state = 0;
  if (state != 0) {
    return state == 1;
  }
  void* libsdl = dlopen("libSDL3.so.0", RTLD_NOW | RTLD_GLOBAL);
  void* libwgpu = dlopen("libwgpu_native.so", RTLD_NOW | RTLD_GLOBAL);
  void* libtvg = dlopen("libthorvg-1.so.1", RTLD_NOW | RTLD_GLOBAL);
  bool ok = libsdl != NULL && libwgpu != NULL && libtvg != NULL;
  ok = ok && (ds_SDL_Init = (__typeof__(SDL_Init)*)dlsym(libsdl, "SDL_Init"));
  ok = ok && (ds_SDL_Quit = (__typeof__(SDL_Quit)*)dlsym(libsdl, "SDL_Quit"));
  ok = ok && (ds_SDL_GetError = (__typeof__(SDL_GetError)*)dlsym(libsdl, "SDL_GetError"));
  ok = ok && (ds_SDL_CreateWindow = (__typeof__(SDL_CreateWindow)*)dlsym(libsdl, "SDL_CreateWindow"));
  ok = ok && (ds_SDL_DestroyWindow = (__typeof__(SDL_DestroyWindow)*)dlsym(libsdl, "SDL_DestroyWindow"));
  ok = ok && (ds_SDL_GetWindowProperties = (__typeof__(SDL_GetWindowProperties)*)dlsym(libsdl, "SDL_GetWindowProperties"));
  ok = ok && (ds_SDL_GetPointerProperty = (__typeof__(SDL_GetPointerProperty)*)dlsym(libsdl, "SDL_GetPointerProperty"));
  ok = ok && (ds_SDL_GetNumberProperty = (__typeof__(SDL_GetNumberProperty)*)dlsym(libsdl, "SDL_GetNumberProperty"));
  ok = ok && (ds_SDL_GetCurrentVideoDriver = (__typeof__(SDL_GetCurrentVideoDriver)*)dlsym(libsdl, "SDL_GetCurrentVideoDriver"));
  ok = ok && (ds_SDL_GetWindowSizeInPixels = (__typeof__(SDL_GetWindowSizeInPixels)*)dlsym(libsdl, "SDL_GetWindowSizeInPixels"));
  ok = ok && (ds_SDL_GetWindowPixelDensity = (__typeof__(SDL_GetWindowPixelDensity)*)dlsym(libsdl, "SDL_GetWindowPixelDensity"));
  ok = ok && (ds_SDL_StartTextInput = (__typeof__(SDL_StartTextInput)*)dlsym(libsdl, "SDL_StartTextInput"));
  ok = ok && (ds_SDL_WaitEventTimeout = (__typeof__(SDL_WaitEventTimeout)*)dlsym(libsdl, "SDL_WaitEventTimeout"));
  ok = ok && (ds_SDL_PollEvent = (__typeof__(SDL_PollEvent)*)dlsym(libsdl, "SDL_PollEvent"));
  ok = ok && (ds_SDL_LoadFile = (__typeof__(SDL_LoadFile)*)dlsym(libsdl, "SDL_LoadFile"));
  ok = ok && (ds_SDL_free = (__typeof__(SDL_free)*)dlsym(libsdl, "SDL_free"));
  ok = ok && (ds_wgpuCreateInstance = (__typeof__(wgpuCreateInstance)*)dlsym(libwgpu, "wgpuCreateInstance"));
  ok = ok && (ds_wgpuInstanceCreateSurface = (__typeof__(wgpuInstanceCreateSurface)*)dlsym(libwgpu, "wgpuInstanceCreateSurface"));
  ok = ok && (ds_wgpuInstanceRequestAdapter = (__typeof__(wgpuInstanceRequestAdapter)*)dlsym(libwgpu, "wgpuInstanceRequestAdapter"));
  ok = ok && (ds_wgpuAdapterRequestDevice = (__typeof__(wgpuAdapterRequestDevice)*)dlsym(libwgpu, "wgpuAdapterRequestDevice"));
  ok = ok && (ds_wgpuInstanceProcessEvents = (__typeof__(wgpuInstanceProcessEvents)*)dlsym(libwgpu, "wgpuInstanceProcessEvents"));
  ok = ok && (ds_wgpuSurfacePresent = (__typeof__(wgpuSurfacePresent)*)dlsym(libwgpu, "wgpuSurfacePresent"));
  ok = ok && (ds_wgpuSurfaceRelease = (__typeof__(wgpuSurfaceRelease)*)dlsym(libwgpu, "wgpuSurfaceRelease"));
  ok = ok && (ds_wgpuDeviceRelease = (__typeof__(wgpuDeviceRelease)*)dlsym(libwgpu, "wgpuDeviceRelease"));
  ok = ok && (ds_wgpuAdapterRelease = (__typeof__(wgpuAdapterRelease)*)dlsym(libwgpu, "wgpuAdapterRelease"));
  ok = ok && (ds_wgpuInstanceRelease = (__typeof__(wgpuInstanceRelease)*)dlsym(libwgpu, "wgpuInstanceRelease"));
  ok = ok && (ds_tvg_engine_init = (__typeof__(tvg_engine_init)*)dlsym(libtvg, "tvg_engine_init"));
  ok = ok && (ds_tvg_engine_term = (__typeof__(tvg_engine_term)*)dlsym(libtvg, "tvg_engine_term"));
  ok = ok && (ds_tvg_wgcanvas_create = (__typeof__(tvg_wgcanvas_create)*)dlsym(libtvg, "tvg_wgcanvas_create"));
  ok = ok && (ds_tvg_wgcanvas_set_target_with_context = (__typeof__(tvg_wgcanvas_set_target_with_context)*)dlsym(libtvg, "tvg_wgcanvas_set_target_with_context"));
  ok = ok && (ds_tvg_canvas_destroy = (__typeof__(tvg_canvas_destroy)*)dlsym(libtvg, "tvg_canvas_destroy"));
  ok = ok && (ds_tvg_canvas_add = (__typeof__(tvg_canvas_add)*)dlsym(libtvg, "tvg_canvas_add"));
  ok = ok && (ds_tvg_canvas_remove = (__typeof__(tvg_canvas_remove)*)dlsym(libtvg, "tvg_canvas_remove"));
  ok = ok && (ds_tvg_paint_rel = (__typeof__(tvg_paint_rel)*)dlsym(libtvg, "tvg_paint_rel"));
  ok = ok && (ds_tvg_shape_reset = (__typeof__(tvg_shape_reset)*)dlsym(libtvg, "tvg_shape_reset"));
  ok = ok && (ds_tvg_canvas_update = (__typeof__(tvg_canvas_update)*)dlsym(libtvg, "tvg_canvas_update"));
  ok = ok && (ds_tvg_paint_scale = (__typeof__(tvg_paint_scale)*)dlsym(libtvg, "tvg_paint_scale"));
  ok = ok && (ds_tvg_scene_remove = (__typeof__(tvg_scene_remove)*)dlsym(libtvg, "tvg_scene_remove"));
  ok = ok && (ds_tvg_scene_insert = (__typeof__(tvg_scene_insert)*)dlsym(libtvg, "tvg_scene_insert"));
  ok = ok && (ds_tvg_scene_add = (__typeof__(tvg_scene_add)*)dlsym(libtvg, "tvg_scene_add"));
  ok = ok && (ds_tvg_scene_new = (__typeof__(tvg_scene_new)*)dlsym(libtvg, "tvg_scene_new"));
  ok = ok && (ds_tvg_canvas_draw = (__typeof__(tvg_canvas_draw)*)dlsym(libtvg, "tvg_canvas_draw"));
  ok = ok && (ds_tvg_canvas_sync = (__typeof__(tvg_canvas_sync)*)dlsym(libtvg, "tvg_canvas_sync"));
  ok = ok && (ds_tvg_shape_new = (__typeof__(tvg_shape_new)*)dlsym(libtvg, "tvg_shape_new"));
  ok = ok && (ds_tvg_shape_append_rect = (__typeof__(tvg_shape_append_rect)*)dlsym(libtvg, "tvg_shape_append_rect"));
  ok = ok && (ds_tvg_shape_set_fill_color = (__typeof__(tvg_shape_set_fill_color)*)dlsym(libtvg, "tvg_shape_set_fill_color"));
  ok = ok && (ds_tvg_text_new = (__typeof__(tvg_text_new)*)dlsym(libtvg, "tvg_text_new"));
  ok = ok && (ds_tvg_text_set_font = (__typeof__(tvg_text_set_font)*)dlsym(libtvg, "tvg_text_set_font"));
  ok = ok && (ds_tvg_text_set_size = (__typeof__(tvg_text_set_size)*)dlsym(libtvg, "tvg_text_set_size"));
  ok = ok && (ds_tvg_text_set_text = (__typeof__(tvg_text_set_text)*)dlsym(libtvg, "tvg_text_set_text"));
  ok = ok && (ds_tvg_text_set_color = (__typeof__(tvg_text_set_color)*)dlsym(libtvg, "tvg_text_set_color"));
  ok = ok && (ds_tvg_paint_translate = (__typeof__(tvg_paint_translate)*)dlsym(libtvg, "tvg_paint_translate"));
  ok = ok && (ds_tvg_font_load_data = (__typeof__(tvg_font_load_data)*)dlsym(libtvg, "tvg_font_load_data"));
  ok = ok && (ds_tvg_font_unload = (__typeof__(tvg_font_unload)*)dlsym(libtvg, "tvg_font_unload"));
  state = ok ? 1 : 2;
  return ok;
}

// The window
// ----------

static struct {
  bool          open;
  SDL_Window*   window;
  WGPUInstance  instance;
  WGPUSurface   surface;
  WGPUAdapter   adapter;
  WGPUDevice    device;
  Tvg_Canvas    canvas;
  Tvg_Paint     background;  // a shape filling the window, below the scene
  Tvg_Paint     base;        // a scene holding the kept scene's paint,
                             // scaled by the pixel density
  float         density;
  struct DsNode* root;       // the kept scene
  int           width;   // the canvas's target, in pixels
  int           height;
  bool          font;    // whether a font is loaded, as "deui"
} ds;

#define DS_UNIT(e) io_done(e, term_pak(CID(Unit), 0))
#define DS_BAD(e, what) io_fail(e, 22, "screen: invalid " what)

static Term ds_sdl_fail(Env e, const char* what) {
  char msg[512];
  snprintf(msg, sizeof msg, "screen: %s: %s", what, ds_SDL_GetError());
  return io_fail(e, 5, msg);
}

static bool ds_window(u32 id) {
  return id == 1 && ds.open;
}

// The window's WebGPU surface, from its Wayland or X11 handles.
static WGPUSurface ds_surface(void) {
  SDL_PropertiesID props = ds_SDL_GetWindowProperties(ds.window);
  const char* driver = ds_SDL_GetCurrentVideoDriver();
  WGPUSurfaceDescriptor desc = { 0 };
  WGPUSurfaceSourceWaylandSurface wayland = { 0 };
  WGPUSurfaceSourceXlibWindow xlib = { 0 };
  if (driver && strcmp(driver, "wayland") == 0) {
    wayland.chain.sType = WGPUSType_SurfaceSourceWaylandSurface;
    wayland.display = ds_SDL_GetPointerProperty(props, SDL_PROP_WINDOW_WAYLAND_DISPLAY_POINTER, NULL);
    wayland.surface = ds_SDL_GetPointerProperty(props, SDL_PROP_WINDOW_WAYLAND_SURFACE_POINTER, NULL);
    desc.nextInChain = &wayland.chain;
  } else if (driver && strcmp(driver, "x11") == 0) {
    xlib.chain.sType = WGPUSType_SurfaceSourceXlibWindow;
    xlib.display = ds_SDL_GetPointerProperty(props, SDL_PROP_WINDOW_X11_DISPLAY_POINTER, NULL);
    xlib.window = (uint64_t)ds_SDL_GetNumberProperty(props, SDL_PROP_WINDOW_X11_WINDOW_NUMBER, 0);
    desc.nextInChain = &xlib.chain;
  } else {
    return NULL;
  }
  return ds_wgpuInstanceCreateSurface(ds.instance, &desc);
}

static void ds_adapter_got(WGPURequestAdapterStatus status, WGPUAdapter adapter,
  WGPUStringView message, void* out, void* unused) {
  *(WGPUAdapter*)out = status == WGPURequestAdapterStatus_Success ? adapter : NULL;
}

static void ds_device_got(WGPURequestDeviceStatus status, WGPUDevice device,
  WGPUStringView message, void* out, void* unused) {
  *(WGPUDevice*)out = status == WGPURequestDeviceStatus_Success ? device : NULL;
}

// The GPU for the window's surface, and a device on it. wgpu-native answers
// these requests at once; the events are processed in case it doesn't.
static const char* ds_gpu(void) {
  ds.instance = ds_wgpuCreateInstance(NULL);
  if (ds.instance == NULL) {
    return "wgpuCreateInstance";
  }
  ds.surface = ds_surface();
  if (ds.surface == NULL) {
    return "the window's surface (Wayland or X11 only)";
  }
  WGPURequestAdapterOptions options = { 0 };
  options.compatibleSurface = ds.surface;
  options.powerPreference = WGPUPowerPreference_HighPerformance;
  WGPURequestAdapterCallbackInfo on_adapter = { 0 };
  on_adapter.mode = WGPUCallbackMode_AllowSpontaneous;
  on_adapter.callback = ds_adapter_got;
  on_adapter.userdata1 = &ds.adapter;
  ds_wgpuInstanceRequestAdapter(ds.instance, &options, on_adapter);
  for (int i = 0; i < 100 && ds.adapter == NULL; i += 1) {
    ds_wgpuInstanceProcessEvents(ds.instance);
  }
  if (ds.adapter == NULL) {
    return "a WebGPU adapter";
  }
  WGPURequestDeviceCallbackInfo on_device = { 0 };
  on_device.mode = WGPUCallbackMode_AllowSpontaneous;
  on_device.callback = ds_device_got;
  on_device.userdata1 = &ds.device;
  ds_wgpuAdapterRequestDevice(ds.adapter, NULL, on_device);
  for (int i = 0; i < 100 && ds.device == NULL; i += 1) {
    ds_wgpuInstanceProcessEvents(ds.instance);
  }
  return ds.device == NULL ? "a WebGPU device" : NULL;
}

static void ds_gpu_release(void) {
  if (ds.device) ds_wgpuDeviceRelease(ds.device);
  if (ds.adapter) ds_wgpuAdapterRelease(ds.adapter);
  if (ds.surface) ds_wgpuSurfaceRelease(ds.surface);
  if (ds.instance) ds_wgpuInstanceRelease(ds.instance);
  ds.device = NULL;
  ds.adapter = NULL;
  ds.surface = NULL;
  ds.instance = NULL;
}

#ifdef CID(screen_open)

// A window, taking text input, with a WebGPU device for its surface and a
// ThorVG canvas drawing onto it.
Term ds_screen_open_run(Env e, Term* f, IoWork* w) {
  u64 n = 0;
  char* title = io_cstr(e, f[0], &n);
  u32 width = (u32)f[1];
  u32 height = (u32)f[2];
  if (!ds_load()) {
    free(title);
    return io_fail(e, 95, "screen: SDL3, wgpu-native and ThorVG (libSDL3.so.0, libwgpu_native.so, libthorvg-1.so.1) not all found");
  }
  if (ds.open || width < 1 || height < 1 || width > 16384 || height > 16384) {
    free(title);
    return DS_BAD(e, "window: one at a time, and its size");
  }
  if (!ds_SDL_Init(SDL_INIT_VIDEO)) {
    free(title);
    return ds_sdl_fail(e, "SDL_Init");
  }
  ds.window = ds_SDL_CreateWindow(title, (int)width, (int)height,
    SDL_WINDOW_RESIZABLE | SDL_WINDOW_HIGH_PIXEL_DENSITY);
  free(title);
  if (ds.window == NULL) {
    return ds_sdl_fail(e, "SDL_CreateWindow");
  }
  const char* missing = ds_gpu();
  if (missing != NULL) {
    char msg[256];
    snprintf(msg, sizeof msg, "screen: no %s", missing);
    ds_gpu_release();
    ds_SDL_DestroyWindow(ds.window);
    return io_fail(e, 5, msg);
  }
  if (ds_tvg_engine_init(0) != TVG_RESULT_SUCCESS
    || (ds.canvas = ds_tvg_wgcanvas_create(TVG_ENGINE_OPTION_DEFAULT)) == NULL) {
    ds_gpu_release();
    ds_SDL_DestroyWindow(ds.window);
    return io_fail(e, 5, "screen: ThorVG's WebGPU engine didn't start");
  }
  ds.background = ds_tvg_shape_new();
  ds.base = ds_tvg_scene_new();
  ds_tvg_canvas_add(ds.canvas, ds.background);
  ds_tvg_canvas_add(ds.canvas, ds.base);
  ds.density = 0;
  ds.root = NULL;
  ds_SDL_StartTextInput(ds.window);
  ds.width = 0;
  ds.height = 0;
  ds.open = true;
  return io_done(e, (Term)1);
}

static void __attribute__((constructor)) ds_screen_open_use(void) {
  io_eff(CID(screen_open), ds_screen_open_run);
}

#endif

#ifdef CID(screen_font)

// The TrueType font labels are drawn in, from its path.
Term ds_screen_font_run(Env e, Term* f, IoWork* w) {
  u64 n = 0;
  char* path = io_cstr(e, f[1], &n);
  if (!ds_window((u32)f[0])) {
    free(path);
    return DS_BAD(e, "window");
  }
  size_t size = 0;
  void* data = ds_SDL_LoadFile(path, &size);
  free(path);
  if (data == NULL) {
    return ds_sdl_fail(e, "the font");
  }
  if (ds.font) {
    ds_tvg_font_unload("deui");
  }
  ds.font = ds_tvg_font_load_data("deui", data, (uint32_t)size, "ttf", true) == TVG_RESULT_SUCCESS;
  ds_SDL_free(data);
  return ds.font ? DS_UNIT(e) : io_fail(e, 22, "screen: ThorVG couldn't read the font");
}

static void __attribute__((constructor)) ds_screen_font_use(void) {
  io_eff(CID(screen_font), ds_screen_font_run);
}

#endif

// Events
// ------

typedef struct {
  u32* w;
  u32  n;
  u32  cap;
} DsWords;

static void ds_put(DsWords* b, u32 x) {
  if (b->n == b->cap) {
    b->cap = b->cap ? b->cap * 2 : 256;
    b->w = io_mem(realloc(b->w, b->cap * sizeof(u32)));
  }
  b->w[b->n++] = x;
}

static u32 ds_bits(float x) {
  u32 u;
  memcpy(&u, &x, 4);
  return u;
}

static u32 ds_ms(Uint64 ns) {
  return (u32)(ns / 1000000ull);
}

// SDL's key as Base's Key code: a key's character in lower case (Return 13,
// Tab 9, Escape 27, Space 32), Backspace 127, the arrows from 63232, the
// function keys from 63236, Insert, Delete, Home, End and the Page keys in
// the private-use area, the modifiers as 65536 + their Mac key code; any
// other key, 131072 + its SDL scancode.
static u32 ds_key(SDL_Keycode k, SDL_Scancode sc) {
  switch (k) {
    case SDLK_BACKSPACE: return 127;
    case SDLK_UP: return 63232;
    case SDLK_DOWN: return 63233;
    case SDLK_LEFT: return 63234;
    case SDLK_RIGHT: return 63235;
    case SDLK_INSERT: return 63271;
    case SDLK_DELETE: return 63272;
    case SDLK_HOME: return 63273;
    case SDLK_END: return 63275;
    case SDLK_PAGEUP: return 63276;
    case SDLK_PAGEDOWN: return 63277;
    case SDLK_RGUI: return 65590;
    case SDLK_LGUI: return 65591;
    case SDLK_LSHIFT: return 65592;
    case SDLK_CAPSLOCK: return 65593;
    case SDLK_LALT: return 65594;
    case SDLK_LCTRL: return 65595;
    case SDLK_RSHIFT: return 65596;
    case SDLK_RALT: return 65597;
    case SDLK_RCTRL: return 65598;
  }
  if (k >= SDLK_F1 && k <= SDLK_F12) {
    return 63236 + (u32)(k - SDLK_F1);
  }
  if (k < 0x40000000u) {
    return (u32)k;
  }
  return 131072 + (u32)sc;
}

// SDL's mouse button as W3C's: 0 the main one, 1 the middle, 2 the right,
// 3 back, 4 forward.
static u32 ds_button(Uint8 b) {
  switch (b) {
    case SDL_BUTTON_LEFT: return 0;
    case SDL_BUTTON_MIDDLE: return 1;
    case SDL_BUTTON_RIGHT: return 2;
    case SDL_BUTTON_X1: return 3;
    case SDL_BUTTON_X2: return 4;
  }
  return b;
}

// UTF-8 as code points, each put as a word.
static void ds_text(DsWords* b, const char* s) {
  const unsigned char* p = (const unsigned char*)s;
  while (*p) {
    u32 c = *p;
    int k = c < 0x80 ? 0 : c < 0xE0 ? 1 : c < 0xF0 ? 2 : 3;
    c = k == 0 ? c : c & (0x3F >> k);
    p += 1;
    for (int i = 0; i < k && (*p & 0xC0) == 0x80; i += 1, p += 1) {
      c = (c << 6) | (*p & 0x3F);
    }
    ds_put(b, c);
  }
}

// One event as words, as screen.bend reads them; nothing for the rest.
static void ds_event(DsWords* b, SDL_Event* ev) {
  switch (ev->type) {
    case SDL_EVENT_MOUSE_BUTTON_DOWN:
    case SDL_EVENT_MOUSE_BUTTON_UP:
      ds_put(b, 1);
      ds_put(b, ds_bits(ev->button.x));
      ds_put(b, ds_bits(ev->button.y));
      ds_put(b, ds_ms(ev->button.timestamp));
      ds_put(b, ds_button(ev->button.button));
      ds_put(b, ev->button.down ? 1 : 0);
      break;
    case SDL_EVENT_MOUSE_MOTION:
      ds_put(b, 2);
      ds_put(b, ds_bits(ev->motion.x));
      ds_put(b, ds_bits(ev->motion.y));
      ds_put(b, ds_ms(ev->motion.timestamp));
      break;
    case SDL_EVENT_KEY_DOWN:
    case SDL_EVENT_KEY_UP:
      ds_put(b, 3);
      ds_put(b, ds_key(ev->key.key, ev->key.scancode));
      ds_put(b, ev->key.down ? 1 : 0);
      break;
    case SDL_EVENT_TEXT_INPUT:
      ds_put(b, 4);
      ds_text(b, ev->text.text);
      break;
    case SDL_EVENT_MOUSE_WHEEL:
      ds_put(b, 5);
      ds_put(b, ds_bits(ev->wheel.mouse_x));
      ds_put(b, ds_bits(ev->wheel.mouse_y));
      ds_put(b, ds_bits(-ev->wheel.x));
      ds_put(b, ds_bits(ev->wheel.y));
      break;
    case SDL_EVENT_WINDOW_CLOSE_REQUESTED:
    case SDL_EVENT_QUIT:
      ds_put(b, 6);
      break;
    case SDL_EVENT_WINDOW_MOUSE_LEAVE:
      ds_put(b, 7);
      break;
    case SDL_EVENT_WINDOW_FOCUS_GAINED:
    case SDL_EVENT_WINDOW_FOCUS_LOST:
      ds_put(b, 8);
      ds_put(b, ev->type == SDL_EVENT_WINDOW_FOCUS_GAINED ? 1 : 0);
      break;
  }
}

static Term ds_list(Env e, const u32* w, u32 n) {
  Term xs = term_pak(CID(Nil), 0);
  for (u32 i = n; i > 0; i -= 1) {
    xs = io_node(e, CID(Con), (Term)w[i - 1], xs);
  }
  return xs;
}

#ifdef CID(screen_wait)

// Waits up to ms milliseconds (4294967295: for as long as it takes) for an
// event, then takes every event waiting.
Term ds_screen_wait_run(Env e, Term* f, IoWork* w) {
  if (!ds_window((u32)f[0])) {
    return DS_BAD(e, "window");
  }
  u32 ms = (u32)f[1];
  DsWords b = { 0 };
  DsWords starts = { 0 };
  SDL_Event ev;
  bool any = ds_SDL_WaitEventTimeout(&ev, ms == 4294967295u ? -1 : (Sint32)ms);
  while (any) {
    u32 at = b.n;
    ds_event(&b, &ev);
    if (b.n > at) {
      ds_put(&starts, at);
    }
    any = ds_SDL_PollEvent(&ev);
  }
  Term xs = term_pak(CID(Nil), 0);
  u32 end = b.n;
  for (u32 i = starts.n; i > 0; i -= 1) {
    u32 at = starts.w[i - 1];
    xs = io_node(e, CID(Con), ds_list(e, b.w + at, end - at), xs);
    end = at;
  }
  free(b.w);
  free(starts.w);
  return io_done(e, xs);
}

static void __attribute__((constructor)) ds_screen_wait_use(void) {
  io_eff(CID(screen_wait), ds_screen_wait_run);
}

#endif


// The words of a List<U32>, consumed.
static void ds_words(Env e, Term s, DsWords* b) {
  while (term_aux(s) == CID(Con)) {
    Term fb[2];
    spare_free(e, cls_fit(2), ctr_take(e, s, 2, fb));
    ds_put(b, (u32)fb[0]);
    s = fb[1];
  }
}

// The kept scene
// --------------

// A part of the scene. A Fill, Label or Target is at (x, y) in its group; a
// Group at (x, y) holds its children in body; a chain, an End or Child, is
// its children in order and then whatever ends it: tail, which is NULL for
// End, or any part that isn't a Child. Fills, labels, groups and chains
// have a paint, in the paint of the group or chain they're in; targets
// have none.
enum { DS_FILL = 1, DS_LABEL, DS_TARGET, DS_GROUP, DS_CHAIN };

typedef struct DsNode {
  int              kind;
  float            x, y;
  Tvg_Paint        paint;
  struct DsNode*   body;      // a group's
  struct DsNode**  kids;      // a chain's
  u32              len, cap;
  struct DsNode*   tail;      // a chain's, or NULL for End
} DsNode;

// Frees a part and everything in it; its paints are ThorVG's to free.
static void ds_free(DsNode* n) {
  if (n == NULL) {
    return;
  }
  ds_free(n->body);
  for (u32 i = 0; i < n->len; i += 1) {
    ds_free(n->kids[i]);
  }
  free(n->kids);
  ds_free(n->tail);
  free(n);
}

static DsNode* ds_node(int kind) {
  DsNode* n = io_mem(calloc(1, sizeof(DsNode)));
  n->kind = kind;
  return n;
}

static void ds_place(DsNode* n) {
  if (n->paint) {
    ds_tvg_paint_translate(n->paint, n->x, n->y);
  }
}

// Reading the words of a scene, from b->w[*at] on.
typedef struct {
  const u32* w;
  u32 n;
  u32 at;
} DsReader;

static u32 ds_next(DsReader* r) {
  return r->at < r->n ? r->w[r->at++] : 0;
}

static float ds_i32(DsReader* r) {
  return (float)(int32_t)ds_next(r);
}

// The paint a part is drawn by within a chain, or NULL.
static Tvg_Paint ds_paint(DsNode* n) {
  return n ? n->paint : NULL;
}

static DsNode* ds_read(DsReader* r);

// A label's text, as UTF-8, from its code points up to a 0.
static char* ds_utf8(DsReader* r) {
  u32 from = r->at;
  while (r->at < r->n && r->w[r->at] != 0) {
    r->at += 1;
  }
  char* s = io_mem(malloc((r->at - from) * 4 + 1));
  u64 k = 0;
  for (u32 i = from; i < r->at; i += 1) {
    k += io_utf8(s + k, r->w[i]);
  }
  s[k] = 0;
  if (r->at < r->n) {
    r->at += 1;
  }
  return s;
}

static void ds_chain_put(DsNode* c, u32 i, DsNode* kid);

// A chain from its first Child on: its children, then what ends it.
static DsNode* ds_read_chain(DsReader* r) {
  DsNode* c = ds_node(DS_CHAIN);
  c->paint = ds_tvg_scene_new();
  for (;;) {
    u32 k = r->at < r->n ? r->w[r->at] : 5;
    if (k == 6) {
      r->at += 1;
      ds_chain_put(c, c->len, ds_read(r));
    } else if (k == 5) {
      r->at += 1;
      return c;
    } else {
      c->tail = ds_read(r);
      if (c->tail->paint) {
        ds_tvg_scene_add(c->paint, c->tail->paint);
      }
      return c;
    }
  }
}

static DsNode* ds_read(DsReader* r) {
  u32 k = r->at < r->n ? r->w[r->at] : 5;
  if (k == 5 || k == 6) {
    return ds_read_chain(r);
  }
  r->at += 1;
  DsNode* n;
  if (k == 1) {
    n = ds_node(DS_FILL);
    n->x = ds_i32(r);
    n->y = ds_i32(r);
    float w = ds_i32(r), h = ds_i32(r);
    u32 rgb = ds_next(r);
    n->paint = ds_tvg_shape_new();
    ds_tvg_shape_append_rect(n->paint, 0, 0, w, h, 0, 0, true);
    ds_tvg_shape_set_fill_color(n->paint, (uint8_t)(rgb >> 16), (uint8_t)(rgb >> 8), (uint8_t)rgb, 255);
  } else if (k == 2) {
    n = ds_node(DS_LABEL);
    n->x = ds_i32(r);
    n->y = ds_i32(r);
    float size = (float)ds_next(r);
    u32 rgb = ds_next(r);
    char* text = ds_utf8(r);
    n->paint = ds_tvg_text_new();
    // ThorVG takes sizes in points at 96 per inch, 4/3 of a pixel each.
    ds_tvg_text_set_font(n->paint, "deui");
    ds_tvg_text_set_size(n->paint, size * 0.75f);
    ds_tvg_text_set_text(n->paint, ds.font ? text : "");
    ds_tvg_text_set_color(n->paint, (uint8_t)(rgb >> 16), (uint8_t)(rgb >> 8), (uint8_t)rgb);
    free(text);
  } else if (k == 3) {
    n = ds_node(DS_TARGET);
  } else if (k == 4) {
    n = ds_node(DS_GROUP);
    n->x = ds_i32(r);
    n->y = ds_i32(r);
    n->paint = ds_tvg_scene_new();
    n->body = ds_read(r);
    if (n->body->paint) {
      ds_tvg_scene_add(n->paint, n->body->paint);
    }
  } else {
    r->at = r->n;
    return ds_node(DS_TARGET);
  }
  ds_place(n);
  return n;
}

// Puts kid at position i among a chain's children, its paint before the
// next paint after it, in the chain's.
static void ds_chain_put(DsNode* c, u32 i, DsNode* kid) {
  if (c->len == c->cap) {
    c->cap = c->cap ? c->cap * 2 : 8;
    c->kids = io_mem(realloc(c->kids, c->cap * sizeof(DsNode*)));
  }
  memmove(c->kids + i + 1, c->kids + i, (c->len - i) * sizeof(DsNode*));
  c->kids[i] = kid;
  c->len += 1;
  if (kid->paint) {
    Tvg_Paint before = NULL;
    for (u32 j = i + 1; j < c->len && before == NULL; j += 1) {
      before = ds_paint(c->kids[j]);
    }
    before = before ? before : ds_paint(c->tail);
    if (before) {
      ds_tvg_scene_insert(c->paint, kid->paint, before);
    } else {
      ds_tvg_scene_add(c->paint, kid->paint);
    }
  }
}

static void ds_chain_take(DsNode* c, u32 i) {
  DsNode* kid = c->kids[i];
  memmove(c->kids + i, c->kids + i + 1, (c->len - i - 1) * sizeof(DsNode*));
  c->len -= 1;
  if (kid->paint) {
    ds_tvg_scene_remove(c->paint, kid->paint);
  }
  ds_free(kid);
}

static void ds_skip_scene(DsReader* r);
static void ds_skip_edit(DsReader* r);

static void ds_apply(DsNode* n, DsReader* r);

static void ds_translate(DsNode* n, float dx, float dy) {
  if (n->kind == DS_FILL || n->kind == DS_LABEL || n->kind == DS_TARGET || n->kind == DS_GROUP) {
    n->x += dx;
    n->y += dy;
    ds_place(n);
  }
}

// Shift from position `from` in what n's chain edits reach: n itself if
// it's a chain, a group's body, nothing otherwise.
static void ds_shift(DsNode* n, u32 from, float dx, float dy) {
  if (n->kind == DS_GROUP) {
    ds_shift(n->body, from, dx, dy);
  } else if (n->kind == DS_CHAIN) {
    for (u32 j = from; j < n->len; j += 1) {
      ds_translate(n->kids[j], dx, dy);
    }
    if (n->tail) {
      ds_shift(n->tail, from > n->len ? from - n->len : 0, dx, dy);
    }
  }
}

// Insert at i: a group's body, or a chain's children; past a chain's end,
// what ends it, or appended after End. Returns whether kid was put.
static bool ds_insert(DsNode* n, u32 i, DsNode* kid) {
  if (n->kind == DS_GROUP) {
    return ds_insert(n->body, i, kid);
  }
  if (n->kind != DS_CHAIN) {
    return false;
  }
  if (i < n->len || n->tail == NULL) {
    ds_chain_put(n, i < n->len ? i : n->len, kid);
    return true;
  }
  return ds_insert(n->tail, i - n->len, kid);
}

static void ds_delete(DsNode* n, u32 i) {
  if (n->kind == DS_GROUP) {
    ds_delete(n->body, i);
  } else if (n->kind == DS_CHAIN) {
    if (i < n->len) {
      ds_chain_take(n, i);
    } else if (n->tail) {
      ds_delete(n->tail, i - n->len);
    }
  }
}

// The part at i that Update reaches, or NULL.
static DsNode* ds_at(DsNode* n, u32 i) {
  if (n->kind == DS_GROUP) {
    return ds_at(n->body, i);
  }
  if (n->kind != DS_CHAIN) {
    return NULL;
  }
  if (i < n->len) {
    return n->kids[i];
  }
  return n->tail ? ds_at(n->tail, i - n->len) : NULL;
}

static void ds_skip_scene(DsReader* r) {
  u32 k = ds_next(r);
  if (k == 1) {
    r->at += 5;
  } else if (k == 2) {
    r->at += 4;
    while (r->at < r->n && r->w[r->at] != 0) {
      r->at += 1;
    }
    r->at += 1;
  } else if (k == 4) {
    r->at += 2;
    ds_skip_scene(r);
  } else if (k == 6) {
    ds_skip_scene(r);
    ds_skip_scene(r);
  }
}

static void ds_skip_edit(DsReader* r) {
  u32 k = ds_next(r);
  if (k == 1) {
    r->at += 2;
  } else if (k == 2) {
    r->at += 1;
    ds_skip_scene(r);
  } else if (k == 3) {
    r->at += 1;
  } else if (k == 4) {
    r->at += 1;
    ds_skip_edit(r);
  } else if (k == 5) {
    r->at += 3;
  }
}

// An edit, read from the words, applied to n as S.apply does, which leaves
// a part an edit doesn't fit as it is. The words are read whether or not
// the edit applies.
static void ds_apply(DsNode* n, DsReader* r) {
  u32 k = ds_next(r);
  if (k == 1) {
    float dx = ds_i32(r), dy = ds_i32(r);
    ds_translate(n, dx, dy);
  } else if (k == 2) {
    u32 i = ds_next(r);
    DsNode* kid = ds_read(r);
    if (!ds_insert(n, i, kid)) {
      if (kid->paint) {
        ds_tvg_paint_rel(kid->paint);
      }
      ds_free(kid);
    }
  } else if (k == 3) {
    ds_delete(n, ds_next(r));
  } else if (k == 4) {
    DsNode* at = ds_at(n, ds_next(r));
    if (at) {
      ds_apply(at, r);
    } else {
      ds_skip_edit(r);
    }
  } else if (k == 5) {
    u32 from = ds_next(r);
    float dx = ds_i32(r), dy = ds_i32(r);
    ds_shift(n, from, dx, dy);
  } else {
    r->at = r->n;
  }
}

#ifdef CID(screen_scene)

// Sets the kept scene, replacing the one before.
Term ds_screen_scene_run(Env e, Term* f, IoWork* w) {
  DsWords b = { 0 };
  ds_words(e, f[1], &b);
  if (!ds_window((u32)f[0])) {
    free(b.w);
    return DS_BAD(e, "window");
  }
  if (ds.root) {
    if (ds.root->paint) {
      ds_tvg_scene_remove(ds.base, ds.root->paint);
    }
    ds_free(ds.root);
  }
  DsReader r = { b.w, b.n, 0 };
  ds.root = ds_read(&r);
  if (ds.root->paint) {
    ds_tvg_scene_add(ds.base, ds.root->paint);
  }
  free(b.w);
  return DS_UNIT(e);
}

static void __attribute__((constructor)) ds_screen_scene_use(void) {
  io_eff(CID(screen_scene), ds_screen_scene_run);
}

#endif

#ifdef CID(screen_edit)

// Applies a run of edits to the kept scene, in order.
Term ds_screen_edit_run(Env e, Term* f, IoWork* w) {
  DsWords b = { 0 };
  ds_words(e, f[1], &b);
  if (!ds_window((u32)f[0]) || ds.root == NULL) {
    free(b.w);
    return DS_BAD(e, "window, or no scene");
  }
  DsReader r = { b.w, b.n, 0 };
  while (r.at < r.n) {
    ds_apply(ds.root, &r);
  }
  free(b.w);
  return DS_UNIT(e);
}

static void __attribute__((constructor)) ds_screen_edit_use(void) {
  io_eff(CID(screen_edit), ds_screen_edit_run);
}

#endif

#ifdef CID(screen_draw)

// Draws the kept scene on a background of 0xRRGGBB, at the window's size
// and pixel density, and presents it.
Term ds_screen_draw_run(Env e, Term* f, IoWork* w) {
  if (!ds_window((u32)f[0])) {
    return DS_BAD(e, "window");
  }
  int pw = 0, ph = 0;
  ds_SDL_GetWindowSizeInPixels(ds.window, &pw, &ph);
  if (pw != ds.width || ph != ds.height) {
    Tvg_WgContext ctx = { ds.instance, ds.adapter, ds.device };
    ds_tvg_wgcanvas_set_target_with_context(ds.canvas, &ctx, ds.surface, (uint32_t)pw,
      (uint32_t)ph, TVG_COLORSPACE_ABGR8888S, 0);
    ds.width = pw;
    ds.height = ph;
  }
  u32 rgb = (u32)f[1];
  ds_tvg_shape_reset(ds.background);
  ds_tvg_shape_append_rect(ds.background, 0, 0, (float)pw, (float)ph, 0, 0, true);
  ds_tvg_shape_set_fill_color(ds.background, (uint8_t)(rgb >> 16), (uint8_t)(rgb >> 8), (uint8_t)rgb, 255);
  float d = ds_SDL_GetWindowPixelDensity(ds.window);
  d = d > 0.0f ? d : 1.0f;
  if (d != ds.density) {
    ds_tvg_paint_scale(ds.base, d);
    ds.density = d;
  }
  ds_tvg_canvas_update(ds.canvas);
  ds_tvg_canvas_draw(ds.canvas, true);
  ds_tvg_canvas_sync(ds.canvas);
  ds_wgpuSurfacePresent(ds.surface);
  return DS_UNIT(e);
}

static void __attribute__((constructor)) ds_screen_draw_use(void) {
  io_eff(CID(screen_draw), ds_screen_draw_run);
}

#endif

#ifdef CID(screen_close)

Term ds_screen_close_run(Env e, Term* f, IoWork* w) {
  if (!ds_window((u32)f[0])) {
    return DS_BAD(e, "window");
  }
  ds_free(ds.root);
  ds.root = NULL;
  ds_tvg_canvas_destroy(ds.canvas);
  if (ds.font) {
    ds_tvg_font_unload("deui");
  }
  ds_tvg_engine_term();
  ds_gpu_release();
  ds_SDL_DestroyWindow(ds.window);
  ds_SDL_Quit();
  ds.open = false;
  ds.font = false;
  return DS_UNIT(e);
}

static void __attribute__((constructor)) ds_screen_close_use(void) {
  io_eff(CID(screen_close), ds_screen_close_run);
}

#endif
