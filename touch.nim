import
    random,
    sdl2/sdl,
    sdl2/sdl_gfx_primitives as gfx


const
  Title = "SDL2 Touch"
  ScreenW = 480 # Window width
  ScreenH = 272 # Window height
  WindowFlags = 0
  RendererFlags = sdl.RendererAccelerated or sdl.RendererPresentVsync


type
  App = ref AppObj
  AppObj = object
    window*: sdl.Window # Window pointer
    renderer*: sdl.Renderer # Rendering state pointer

type Vector3 = tuple[x, y, z : float]
type Line = tuple[v0, v1 : Vector3]

proc paint(line: Line, renderer: sdl.Renderer): int {.discardable.} =
  renderer.lineRGBA(line.v0.x.int16, line.v0.y.int16, line.v1.x.int16,
    line.v1.y.int16, 255, 255, 255, 255)

let line = (v0: (0.0, 0.0, 0.0), v1:(100.0, 100.0, 100.0))

##########
# COMMON #
##########

# Initialization sequence
proc init(app: App): bool =
  # Init SDL
  if sdl.init(sdl.InitVideo) != 0:
    sdl.logCritical(sdl.LogCategoryError,
                    "Can't initialize SDL: %s",
                    sdl.getError())
    return false

  # Create window
  app.window = sdl.createWindow(
    Title,
    sdl.WindowPosUndefined,
    sdl.WindowPosUndefined,
    ScreenW,
    ScreenH,
    WindowFlags)
  if app.window == nil:
    sdl.logCritical(sdl.LogCategoryError,
                    "Can't create window: %s",
                    sdl.getError())
    return false

  # Create renderer
  app.renderer = sdl.createRenderer(app.window, -1, RendererFlags)
  if app.renderer == nil:
    sdl.logCritical(sdl.LogCategoryError,
                    "Can't create renderer: %s",
                    sdl.getError())
    return false

  # Set draw color
  if app.renderer.setRenderDrawColor(0x00, 0x00, 0x00, 0xFF) != 0:
    sdl.logWarn(sdl.LogCategoryVideo,
                "Can't set draw color: %s",
                sdl.getError())
    return false

  randomize()
  return true


# Shutdown sequence
proc exit(app: App) =
  app.renderer.destroyRenderer()
  app.window.destroyWindow()
  sdl.quit()


# Event handling
# Return true on app shutdown request, otherwise return false
proc events(pressed: var seq[sdl.Keycode]): bool =
  result = false
  var e: sdl.Event
  if pressed != nil:
    pressed = @[]

  while sdl.pollEvent(addr(e)) != 0:

    # Quit requested
    if e.kind == sdl.Quit:
      return true

    # Key pressed
    elif e.kind == sdl.KeyDown:
      # Add pressed key to sequence
      if pressed != nil:
        pressed.add(e.key.keysym.sym)

      # Exit on Escape key press
      if e.key.keysym.sym == sdl.K_Escape:
        return true


########
# MAIN #
########

var
  app = App(window: nil, renderer: nil)
  done = false # Main loop exit condition
  pressed: seq[sdl.Keycode] = @[] # Pressed keys
  mousePos: sdl.Point

if init(app):

  # Main loop
  while not done:
    # Clear screen with draw color
    discard app.renderer.setRenderDrawColor(0x00, 0x00, 0x00, 0xFF)
    if app.renderer.renderClear() != 0:
      sdl.logWarn(sdl.LogCategoryVideo,
                  "Can't clear screen: %s",
                  sdl.getError())

    if sdl.getMouseState(addr(mousePos.x), addr(mousePos.y)).int64 > 0:
      discard app.renderer.boxRGBA(
        mousePos.x.int16 - 25, mousePos.y.int16 - 25,
        mousePos.x.int16 + 25, mousePos.y.int16 + 25,
        random(255).uint8, random(255).uint8, random(255).uint8, 255)


    # Update renderer
    app.renderer.renderPresent()

    # Event handling
    done = events(pressed)


# Shutdown
exit(app)

