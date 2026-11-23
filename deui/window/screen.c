// deui's screen, native (SDL3 and ThorVG)
// =======================================
//
// The effects in screen.bend. SDL3 gives the window, its events and an
// OpenGL context; ThorVG's OpenGL engine draws each frame into it, its
// labels in a TrueType font. Bend splices this file into the generated C
// program after its runtime, so the runtime's helpers (Term, Env, io_done,
// io_fail, io_node, ...) are in scope. Bend links no library for it, so
// SDL3 and ThorVG are opened with dlopen on first use; their headers only
// supply the types.
//
// One window at a time, named by the id 1. Events cross into Bend as a flat
// list of words, and a frame comes back as one; screen.bend says how each
// is laid out.
//
// Bend's coordinates are the window's, as SDL reports the mouse in. The
// window has the display's full resolution: a frame's coordinates and its
// labels' sizes are multiplied by its pixel density when drawn, so
// everything, text included, is drawn at full resolution.

#include <dlfcn.h>
#include <SDL3/SDL.h>
#include <thorvg-1/thorvg_capi.h>

// The libraries, opened
// ---------------------

static __typeof__(SDL_Init)* ds_SDL_Init;
static __typeof__(SDL_Quit)* ds_SDL_Quit;
static __typeof__(SDL_GetError)* ds_SDL_GetError;
static __typeof__(SDL_CreateWindow)* ds_SDL_CreateWindow;
static __typeof__(SDL_DestroyWindow)* ds_SDL_DestroyWindow;
static __typeof__(SDL_GL_SetAttribute)* ds_SDL_GL_SetAttribute;
static __typeof__(SDL_GL_CreateContext)* ds_SDL_GL_CreateContext;
static __typeof__(SDL_GL_DestroyContext)* ds_SDL_GL_DestroyContext;
static __typeof__(SDL_GL_MakeCurrent)* ds_SDL_GL_MakeCurrent;
static __typeof__(SDL_GL_SetSwapInterval)* ds_SDL_GL_SetSwapInterval;
static __typeof__(SDL_GL_SwapWindow)* ds_SDL_GL_SwapWindow;
static __typeof__(SDL_GetWindowSizeInPixels)* ds_SDL_GetWindowSizeInPixels;
static __typeof__(SDL_GetWindowPixelDensity)* ds_SDL_GetWindowPixelDensity;
static __typeof__(SDL_StartTextInput)* ds_SDL_StartTextInput;
static __typeof__(SDL_WaitEventTimeout)* ds_SDL_WaitEventTimeout;
static __typeof__(SDL_PollEvent)* ds_SDL_PollEvent;
static __typeof__(SDL_LoadFile)* ds_SDL_LoadFile;
static __typeof__(SDL_free)* ds_SDL_free;
static __typeof__(tvg_engine_init)* ds_tvg_engine_init;
static __typeof__(tvg_engine_term)* ds_tvg_engine_term;
static __typeof__(tvg_glcanvas_create)* ds_tvg_glcanvas_create;
static __typeof__(tvg_glcanvas_set_target)* ds_tvg_glcanvas_set_target;
static __typeof__(tvg_canvas_destroy)* ds_tvg_canvas_destroy;
static __typeof__(tvg_canvas_add)* ds_tvg_canvas_add;
static __typeof__(tvg_canvas_remove)* ds_tvg_canvas_remove;
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

// Opens both libraries and finds every function, once; false if any is
// missing.
static bool ds_load(void) {
  static int state = 0;
  if (state != 0) {
    return state == 1;
  }
  void* libsdl = dlopen("libSDL3.so.0", RTLD_NOW | RTLD_GLOBAL);
  void* libtvg = libsdl ? dlopen("libthorvg-1.so.1", RTLD_NOW | RTLD_GLOBAL) : NULL;
  bool ok = libsdl != NULL && libtvg != NULL;
  ok = ok && (ds_SDL_Init = (__typeof__(SDL_Init)*)dlsym(libsdl, "SDL_Init"));
  ok = ok && (ds_SDL_Quit = (__typeof__(SDL_Quit)*)dlsym(libsdl, "SDL_Quit"));
  ok = ok && (ds_SDL_GetError = (__typeof__(SDL_GetError)*)dlsym(libsdl, "SDL_GetError"));
  ok = ok && (ds_SDL_CreateWindow = (__typeof__(SDL_CreateWindow)*)dlsym(libsdl, "SDL_CreateWindow"));
  ok = ok && (ds_SDL_DestroyWindow = (__typeof__(SDL_DestroyWindow)*)dlsym(libsdl, "SDL_DestroyWindow"));
  ok = ok && (ds_SDL_GL_SetAttribute = (__typeof__(SDL_GL_SetAttribute)*)dlsym(libsdl, "SDL_GL_SetAttribute"));
  ok = ok && (ds_SDL_GL_CreateContext = (__typeof__(SDL_GL_CreateContext)*)dlsym(libsdl, "SDL_GL_CreateContext"));
  ok = ok && (ds_SDL_GL_DestroyContext = (__typeof__(SDL_GL_DestroyContext)*)dlsym(libsdl, "SDL_GL_DestroyContext"));
  ok = ok && (ds_SDL_GL_MakeCurrent = (__typeof__(SDL_GL_MakeCurrent)*)dlsym(libsdl, "SDL_GL_MakeCurrent"));
  ok = ok && (ds_SDL_GL_SetSwapInterval = (__typeof__(SDL_GL_SetSwapInterval)*)dlsym(libsdl, "SDL_GL_SetSwapInterval"));
  ok = ok && (ds_SDL_GL_SwapWindow = (__typeof__(SDL_GL_SwapWindow)*)dlsym(libsdl, "SDL_GL_SwapWindow"));
  ok = ok && (ds_SDL_GetWindowSizeInPixels = (__typeof__(SDL_GetWindowSizeInPixels)*)dlsym(libsdl, "SDL_GetWindowSizeInPixels"));
  ok = ok && (ds_SDL_GetWindowPixelDensity = (__typeof__(SDL_GetWindowPixelDensity)*)dlsym(libsdl, "SDL_GetWindowPixelDensity"));
  ok = ok && (ds_SDL_StartTextInput = (__typeof__(SDL_StartTextInput)*)dlsym(libsdl, "SDL_StartTextInput"));
  ok = ok && (ds_SDL_WaitEventTimeout = (__typeof__(SDL_WaitEventTimeout)*)dlsym(libsdl, "SDL_WaitEventTimeout"));
  ok = ok && (ds_SDL_PollEvent = (__typeof__(SDL_PollEvent)*)dlsym(libsdl, "SDL_PollEvent"));
  ok = ok && (ds_SDL_LoadFile = (__typeof__(SDL_LoadFile)*)dlsym(libsdl, "SDL_LoadFile"));
  ok = ok && (ds_SDL_free = (__typeof__(SDL_free)*)dlsym(libsdl, "SDL_free"));
  ok = ok && (ds_tvg_engine_init = (__typeof__(tvg_engine_init)*)dlsym(libtvg, "tvg_engine_init"));
  ok = ok && (ds_tvg_engine_term = (__typeof__(tvg_engine_term)*)dlsym(libtvg, "tvg_engine_term"));
  ok = ok && (ds_tvg_glcanvas_create = (__typeof__(tvg_glcanvas_create)*)dlsym(libtvg, "tvg_glcanvas_create"));
  ok = ok && (ds_tvg_glcanvas_set_target = (__typeof__(tvg_glcanvas_set_target)*)dlsym(libtvg, "tvg_glcanvas_set_target"));
  ok = ok && (ds_tvg_canvas_destroy = (__typeof__(tvg_canvas_destroy)*)dlsym(libtvg, "tvg_canvas_destroy"));
  ok = ok && (ds_tvg_canvas_add = (__typeof__(tvg_canvas_add)*)dlsym(libtvg, "tvg_canvas_add"));
  ok = ok && (ds_tvg_canvas_remove = (__typeof__(tvg_canvas_remove)*)dlsym(libtvg, "tvg_canvas_remove"));
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
  SDL_GLContext gl;
  Tvg_Canvas    canvas;
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

#ifdef CID(screen_open)

// A window with an OpenGL 3.3 context, synced to the display, taking text
// input, and a ThorVG canvas drawing into it.
Term ds_screen_open_run(Env e, Term* f, IoWork* w) {
  u64 n = 0;
  char* title = io_cstr(e, f[0], &n);
  u32 width = (u32)f[1];
  u32 height = (u32)f[2];
  if (!ds_load()) {
    free(title);
    return io_fail(e, 95, "screen: SDL3 and ThorVG (libSDL3.so.0, libthorvg-1.so.1) not found");
  }
  if (ds.open || width < 1 || height < 1 || width > 16384 || height > 16384) {
    free(title);
    return DS_BAD(e, "window: one at a time, and its size");
  }
  if (!ds_SDL_Init(SDL_INIT_VIDEO)) {
    free(title);
    return ds_sdl_fail(e, "SDL_Init");
  }
  ds_SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3);
  ds_SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 3);
  ds_SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE);
  ds_SDL_GL_SetAttribute(SDL_GL_STENCIL_SIZE, 8);
  ds.window = ds_SDL_CreateWindow(title, (int)width, (int)height,
    SDL_WINDOW_OPENGL | SDL_WINDOW_RESIZABLE | SDL_WINDOW_HIGH_PIXEL_DENSITY);
  free(title);
  if (ds.window == NULL) {
    return ds_sdl_fail(e, "SDL_CreateWindow");
  }
  ds.gl = ds_SDL_GL_CreateContext(ds.window);
  if (ds.gl == NULL) {
    ds_SDL_DestroyWindow(ds.window);
    return ds_sdl_fail(e, "SDL_GL_CreateContext");
  }
  ds_SDL_GL_MakeCurrent(ds.window, ds.gl);
  ds_SDL_GL_SetSwapInterval(1);
  if (ds_tvg_engine_init(0) != TVG_RESULT_SUCCESS
    || (ds.canvas = ds_tvg_glcanvas_create(TVG_ENGINE_OPTION_DEFAULT)) == NULL) {
    ds_SDL_GL_DestroyContext(ds.gl);
    ds_SDL_DestroyWindow(ds.window);
    return io_fail(e, 5, "screen: ThorVG's OpenGL engine didn't start");
  }
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


// Drawing
// -------

// The words of a List<U32>, consumed.
static void ds_words(Env e, Term s, DsWords* b) {
  while (term_aux(s) == CID(Con)) {
    Term fb[2];
    spare_free(e, cls_fit(2), ctr_take(e, s, 2, fb));
    ds_put(b, (u32)fb[0]);
    s = fb[1];
  }
}

// A filled rectangle, in pixels.
static void ds_rect(float x, float y, float w, float h, u32 rgb) {
  Tvg_Paint p = ds_tvg_shape_new();
  ds_tvg_shape_append_rect(p, x, y, w, h, 0, 0, true);
  ds_tvg_shape_set_fill_color(p, (uint8_t)(rgb >> 16), (uint8_t)(rgb >> 8), (uint8_t)rgb, 255);
  ds_tvg_canvas_add(ds.canvas, p);
}

// One label: its code points, up to the 0 after them, as UTF-8, drawn
// with its top left at (x, y), size pixels tall, both in pixels. ThorVG
// takes sizes in points at 96 per inch, 4/3 of a pixel each. Returns where
// its words end.
static u32 ds_label(const DsWords* b, u32 at, float x, float y, float size, u32 rgb) {
  u32 end = at;
  while (end < b->n && b->w[end] != 0) {
    end += 1;
  }
  if (ds.font && end > at && size > 0) {
    char* s = io_mem(malloc((end - at) * 4 + 1));
    u64 n = 0;
    for (u32 i = at; i < end; i += 1) {
      n += io_utf8(s + n, b->w[i]);
    }
    s[n] = 0;
    Tvg_Paint t = ds_tvg_text_new();
    ds_tvg_text_set_font(t, "deui");
    ds_tvg_text_set_size(t, size * 0.75f);
    ds_tvg_text_set_text(t, s);
    ds_tvg_text_set_color(t, (uint8_t)(rgb >> 16), (uint8_t)(rgb >> 8), (uint8_t)rgb);
    ds_tvg_paint_translate(t, x, y);
    ds_tvg_canvas_add(ds.canvas, t);
    free(s);
  }
  return end + 1;
}

#ifdef CID(screen_draw)

// A frame: the background, then each fill and label in order, drawn by
// ThorVG at the window's size in pixels, and shown.
Term ds_screen_draw_run(Env e, Term* f, IoWork* w) {
  DsWords b = { 0 };
  ds_words(e, f[2], &b);
  if (!ds_window((u32)f[0])) {
    free(b.w);
    return DS_BAD(e, "window");
  }
  int pw = 0, ph = 0;
  ds_SDL_GetWindowSizeInPixels(ds.window, &pw, &ph);
  if (pw != ds.width || ph != ds.height) {
    ds_tvg_glcanvas_set_target(ds.canvas, NULL, NULL, ds.gl, 0, (uint32_t)pw, (uint32_t)ph,
      TVG_COLORSPACE_ABGR8888S);
    ds.width = pw;
    ds.height = ph;
  }
  float d = ds_SDL_GetWindowPixelDensity(ds.window);
  d = d > 0.0f ? d : 1.0f;
  ds_tvg_canvas_remove(ds.canvas, NULL);
  ds_rect(0, 0, (float)pw, (float)ph, (u32)f[1]);
  u32 i = 0;
  while (i < b.n) {
    u32 op = b.w[i];
    if (op == 1 && i + 6 <= b.n) {
      ds_rect((float)(int32_t)b.w[i + 1] * d, (float)(int32_t)b.w[i + 2] * d,
        (float)(int32_t)b.w[i + 3] * d, (float)(int32_t)b.w[i + 4] * d, b.w[i + 5]);
      i += 6;
    } else if (op == 2 && i + 5 <= b.n) {
      i = ds_label(&b, i + 5, (float)(int32_t)b.w[i + 1] * d,
        (float)(int32_t)b.w[i + 2] * d, (float)b.w[i + 3] * d, b.w[i + 4]);
    } else {
      break;
    }
  }
  free(b.w);
  ds_tvg_canvas_draw(ds.canvas, true);
  ds_tvg_canvas_sync(ds.canvas);
  ds_SDL_GL_SwapWindow(ds.window);
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
  ds_tvg_canvas_destroy(ds.canvas);
  if (ds.font) {
    ds_tvg_font_unload("deui");
  }
  ds_tvg_engine_term();
  ds_SDL_GL_DestroyContext(ds.gl);
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
