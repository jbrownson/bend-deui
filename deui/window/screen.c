// deui's screen, native (SDL3)
// ============================
//
// The effects in screen.bend, on SDL3 and SDL3_ttf. Bend splices this file
// into the generated C program after its runtime, so the runtime's helpers
// (Term, Env, io_done, io_fail, io_node, ...) are in scope. Bend links no
// library for it, so SDL3 and SDL3_ttf are opened with dlopen on first use;
// their headers only supply the types.
//
// One window at a time, named by the id 1. Events cross into Bend as a flat
// list of words, and a frame comes back as one; screen.bend says how each
// is laid out.
//
// Bend's coordinates are the window's, as SDL reports the mouse in. The
// window has the display's full resolution: a frame's coordinates are
// multiplied by its pixel density when drawn, and fonts are opened at
// their size times it, so text is rasterized at full resolution rather
// than stretched.

#include <dlfcn.h>
#include <SDL3/SDL.h>
#include <SDL3_ttf/SDL_ttf.h>

// SDL, opened
// -----------

static __typeof__(SDL_Init)* ds_SDL_Init;
static __typeof__(SDL_Quit)* ds_SDL_Quit;
static __typeof__(SDL_GetError)* ds_SDL_GetError;
static __typeof__(SDL_CreateWindowAndRenderer)* ds_SDL_CreateWindowAndRenderer;
static __typeof__(SDL_DestroyWindow)* ds_SDL_DestroyWindow;
static __typeof__(SDL_DestroyRenderer)* ds_SDL_DestroyRenderer;
static __typeof__(SDL_SetRenderVSync)* ds_SDL_SetRenderVSync;
static __typeof__(SDL_StartTextInput)* ds_SDL_StartTextInput;
static __typeof__(SDL_WaitEventTimeout)* ds_SDL_WaitEventTimeout;
static __typeof__(SDL_PollEvent)* ds_SDL_PollEvent;
static __typeof__(SDL_SetRenderDrawColor)* ds_SDL_SetRenderDrawColor;
static __typeof__(SDL_RenderClear)* ds_SDL_RenderClear;
static __typeof__(SDL_RenderFillRect)* ds_SDL_RenderFillRect;
static __typeof__(SDL_RenderPresent)* ds_SDL_RenderPresent;
static __typeof__(SDL_GetWindowPixelDensity)* ds_SDL_GetWindowPixelDensity;
static __typeof__(TTF_Init)* ds_TTF_Init;
static __typeof__(TTF_Quit)* ds_TTF_Quit;
static __typeof__(TTF_OpenFont)* ds_TTF_OpenFont;
static __typeof__(TTF_CloseFont)* ds_TTF_CloseFont;
static __typeof__(TTF_CreateRendererTextEngine)* ds_TTF_CreateRendererTextEngine;
static __typeof__(TTF_DestroyRendererTextEngine)* ds_TTF_DestroyRendererTextEngine;
static __typeof__(TTF_CreateText)* ds_TTF_CreateText;
static __typeof__(TTF_DestroyText)* ds_TTF_DestroyText;
static __typeof__(TTF_SetTextColor)* ds_TTF_SetTextColor;
static __typeof__(TTF_DrawRendererText)* ds_TTF_DrawRendererText;

// Opens both libraries and finds every function, once; false if any is
// missing.
static bool ds_load(void) {
  static int state = 0;
  if (state != 0) {
    return state == 1;
  }
  void* libsdl = dlopen("libSDL3.so.0", RTLD_NOW | RTLD_GLOBAL);
  void* libttf = libsdl ? dlopen("libSDL3_ttf.so.0", RTLD_NOW | RTLD_GLOBAL) : NULL;
  bool ok = libsdl != NULL && libttf != NULL;
  ok = ok && (ds_SDL_Init = (__typeof__(SDL_Init)*)dlsym(libsdl, "SDL_Init"));
  ok = ok && (ds_SDL_Quit = (__typeof__(SDL_Quit)*)dlsym(libsdl, "SDL_Quit"));
  ok = ok && (ds_SDL_GetError = (__typeof__(SDL_GetError)*)dlsym(libsdl, "SDL_GetError"));
  ok = ok && (ds_SDL_CreateWindowAndRenderer = (__typeof__(SDL_CreateWindowAndRenderer)*)dlsym(libsdl, "SDL_CreateWindowAndRenderer"));
  ok = ok && (ds_SDL_DestroyWindow = (__typeof__(SDL_DestroyWindow)*)dlsym(libsdl, "SDL_DestroyWindow"));
  ok = ok && (ds_SDL_DestroyRenderer = (__typeof__(SDL_DestroyRenderer)*)dlsym(libsdl, "SDL_DestroyRenderer"));
  ok = ok && (ds_SDL_SetRenderVSync = (__typeof__(SDL_SetRenderVSync)*)dlsym(libsdl, "SDL_SetRenderVSync"));
  ok = ok && (ds_SDL_StartTextInput = (__typeof__(SDL_StartTextInput)*)dlsym(libsdl, "SDL_StartTextInput"));
  ok = ok && (ds_SDL_WaitEventTimeout = (__typeof__(SDL_WaitEventTimeout)*)dlsym(libsdl, "SDL_WaitEventTimeout"));
  ok = ok && (ds_SDL_PollEvent = (__typeof__(SDL_PollEvent)*)dlsym(libsdl, "SDL_PollEvent"));
  ok = ok && (ds_SDL_SetRenderDrawColor = (__typeof__(SDL_SetRenderDrawColor)*)dlsym(libsdl, "SDL_SetRenderDrawColor"));
  ok = ok && (ds_SDL_RenderClear = (__typeof__(SDL_RenderClear)*)dlsym(libsdl, "SDL_RenderClear"));
  ok = ok && (ds_SDL_RenderFillRect = (__typeof__(SDL_RenderFillRect)*)dlsym(libsdl, "SDL_RenderFillRect"));
  ok = ok && (ds_SDL_RenderPresent = (__typeof__(SDL_RenderPresent)*)dlsym(libsdl, "SDL_RenderPresent"));
  ok = ok && (ds_SDL_GetWindowPixelDensity = (__typeof__(SDL_GetWindowPixelDensity)*)dlsym(libsdl, "SDL_GetWindowPixelDensity"));
  ok = ok && (ds_TTF_Init = (__typeof__(TTF_Init)*)dlsym(libttf, "TTF_Init"));
  ok = ok && (ds_TTF_Quit = (__typeof__(TTF_Quit)*)dlsym(libttf, "TTF_Quit"));
  ok = ok && (ds_TTF_OpenFont = (__typeof__(TTF_OpenFont)*)dlsym(libttf, "TTF_OpenFont"));
  ok = ok && (ds_TTF_CloseFont = (__typeof__(TTF_CloseFont)*)dlsym(libttf, "TTF_CloseFont"));
  ok = ok && (ds_TTF_CreateRendererTextEngine = (__typeof__(TTF_CreateRendererTextEngine)*)dlsym(libttf, "TTF_CreateRendererTextEngine"));
  ok = ok && (ds_TTF_DestroyRendererTextEngine = (__typeof__(TTF_DestroyRendererTextEngine)*)dlsym(libttf, "TTF_DestroyRendererTextEngine"));
  ok = ok && (ds_TTF_CreateText = (__typeof__(TTF_CreateText)*)dlsym(libttf, "TTF_CreateText"));
  ok = ok && (ds_TTF_DestroyText = (__typeof__(TTF_DestroyText)*)dlsym(libttf, "TTF_DestroyText"));
  ok = ok && (ds_TTF_SetTextColor = (__typeof__(TTF_SetTextColor)*)dlsym(libttf, "TTF_SetTextColor"));
  ok = ok && (ds_TTF_DrawRendererText = (__typeof__(TTF_DrawRendererText)*)dlsym(libttf, "TTF_DrawRendererText"));
  state = ok ? 1 : 2;
  return ok;
}

// The window
// ----------

// Labels are drawn in one font, opened once at each size a label asks for.
#define DS_SIZES 16

static struct {
  bool            open;
  SDL_Window*     window;
  SDL_Renderer*   renderer;
  TTF_TextEngine* engine;
  char*           font_path;
  u32             sizes[DS_SIZES];
  TTF_Font*       fonts[DS_SIZES];
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

static void ds_fonts_close(void) {
  for (int i = 0; i < DS_SIZES; i += 1) {
    if (ds.fonts[i]) {
      ds_TTF_CloseFont(ds.fonts[i]);
    }
    ds.fonts[i] = NULL;
    ds.sizes[i] = 0;
  }
}

// The font at a size in pixels, opened on first use; NULL without a font,
// or when every size is taken.
static TTF_Font* ds_font(u32 size) {
  if (ds.font_path == NULL || size == 0) {
    return NULL;
  }
  for (int i = 0; i < DS_SIZES; i += 1) {
    if (ds.sizes[i] == size) {
      return ds.fonts[i];
    }
    if (ds.sizes[i] == 0) {
      ds.sizes[i] = size;
      ds.fonts[i] = ds_TTF_OpenFont(ds.font_path, (float)size);
      return ds.fonts[i];
    }
  }
  return NULL;
}

#ifdef CID(screen_open)

// A window with a renderer, synced to the display, taking text input.
Term ds_screen_open_run(Env e, Term* f, IoWork* w) {
  u64 n = 0;
  char* title = io_cstr(e, f[0], &n);
  u32 width = (u32)f[1];
  u32 height = (u32)f[2];
  if (!ds_load()) {
    free(title);
    return io_fail(e, 95, "screen: SDL3 and SDL3_ttf (libSDL3.so.0, libSDL3_ttf.so.0) not found");
  }
  if (ds.open || width < 1 || height < 1 || width > 16384 || height > 16384) {
    free(title);
    return DS_BAD(e, "window: one at a time, and its size");
  }
  if (!ds_SDL_Init(SDL_INIT_VIDEO)) {
    free(title);
    return ds_sdl_fail(e, "SDL_Init");
  }
  if (!ds_TTF_Init()) {
    free(title);
    return ds_sdl_fail(e, "TTF_Init");
  }
  bool made = ds_SDL_CreateWindowAndRenderer(title, (int)width, (int)height,
    SDL_WINDOW_RESIZABLE | SDL_WINDOW_HIGH_PIXEL_DENSITY, &ds.window, &ds.renderer);
  free(title);
  if (!made) {
    return ds_sdl_fail(e, "SDL_CreateWindowAndRenderer");
  }
  ds_SDL_SetRenderVSync(ds.renderer, 1);
  ds_SDL_StartTextInput(ds.window);
  ds.engine = ds_TTF_CreateRendererTextEngine(ds.renderer);
  ds.open = true;
  return io_done(e, (Term)1);
}

static void __attribute__((constructor)) ds_screen_open_use(void) {
  io_eff(CID(screen_open), ds_screen_open_run);
}

#endif

#ifdef CID(screen_font)

// The TrueType font labels are drawn in, from its path. It's opened at a
// size when a label first asks for that size; this checks it opens.
Term ds_screen_font_run(Env e, Term* f, IoWork* w) {
  u64 n = 0;
  char* path = io_cstr(e, f[1], &n);
  if (!ds_window((u32)f[0])) {
    free(path);
    return DS_BAD(e, "window");
  }
  TTF_Font* probe = ds_TTF_OpenFont(path, 12.0f);
  if (probe == NULL) {
    free(path);
    return ds_sdl_fail(e, "TTF_OpenFont");
  }
  ds_TTF_CloseFont(probe);
  ds_fonts_close();
  free(ds.font_path);
  ds.font_path = path;
  return DS_UNIT(e);
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

static void ds_color(u32 rgb) {
  ds_SDL_SetRenderDrawColor(ds.renderer, (Uint8)(rgb >> 16), (Uint8)(rgb >> 8),
    (Uint8)rgb, 255);
}

// One label: its code points, up to the 0 after them, as UTF-8, drawn
// with its top left at (x, y), size pixels tall, both in pixels. Returns
// where its words end.
static u32 ds_label(const DsWords* b, u32 at, float x, float y, u32 size, u32 rgb) {
  u32 end = at;
  while (end < b->n && b->w[end] != 0) {
    end += 1;
  }
  TTF_Font* font = ds.engine ? ds_font(size) : NULL;
  if (font != NULL && end > at) {
    char* s = io_mem(malloc((end - at) * 4 + 1));
    u64 n = 0;
    for (u32 i = at; i < end; i += 1) {
      n += io_utf8(s + n, b->w[i]);
    }
    s[n] = 0;
    TTF_Text* t = ds_TTF_CreateText(ds.engine, font, s, n);
    if (t != NULL) {
      ds_TTF_SetTextColor(t, (Uint8)(rgb >> 16), (Uint8)(rgb >> 8), (Uint8)rgb, 255);
      ds_TTF_DrawRendererText(t, x, y);
      ds_TTF_DestroyText(t);
    }
    free(s);
  }
  return end + 1;
}

#ifdef CID(screen_draw)

// A frame: the background, then each fill and label in order, presented.
Term ds_screen_draw_run(Env e, Term* f, IoWork* w) {
  DsWords b = { 0 };
  ds_words(e, f[2], &b);
  if (!ds_window((u32)f[0])) {
    free(b.w);
    return DS_BAD(e, "window");
  }
  float d = ds_SDL_GetWindowPixelDensity(ds.window);
  d = d > 0.0f ? d : 1.0f;
  ds_color((u32)f[1]);
  ds_SDL_RenderClear(ds.renderer);
  u32 i = 0;
  while (i < b.n) {
    u32 op = b.w[i];
    if (op == 1 && i + 6 <= b.n) {
      SDL_FRect r = { (float)(int32_t)b.w[i + 1] * d, (float)(int32_t)b.w[i + 2] * d,
        (float)(int32_t)b.w[i + 3] * d, (float)(int32_t)b.w[i + 4] * d };
      ds_color(b.w[i + 5]);
      ds_SDL_RenderFillRect(ds.renderer, &r);
      i += 6;
    } else if (op == 2 && i + 5 <= b.n) {
      i = ds_label(&b, i + 5, (float)(int32_t)b.w[i + 1] * d,
        (float)(int32_t)b.w[i + 2] * d, (u32)((float)b.w[i + 3] * d + 0.5f), b.w[i + 4]);
    } else {
      break;
    }
  }
  free(b.w);
  ds_SDL_RenderPresent(ds.renderer);
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
  ds_fonts_close();
  free(ds.font_path);
  ds.font_path = NULL;
  if (ds.engine) {
    ds_TTF_DestroyRendererTextEngine(ds.engine);
  }
  ds_SDL_DestroyRenderer(ds.renderer);
  ds_SDL_DestroyWindow(ds.window);
  ds_TTF_Quit();
  ds_SDL_Quit();
  ds.open = false;
  ds.engine = NULL;
  return DS_UNIT(e);
}

static void __attribute__((constructor)) ds_screen_close_use(void) {
  io_eff(CID(screen_close), ds_screen_close_run);
}

#endif
