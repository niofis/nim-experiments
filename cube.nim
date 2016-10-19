import
    random,
    sdl2/sdl,
    sdl2/sdl_gfx_primitives as gfx,
    math,
    sequtils


const
  Title = "SDL2 Test"
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

proc `+`*(a, b: Vector3): Vector3 = (x: a.x + b.x, y: a.y + b.y, z: a.z + b.z)
proc `+`*(a: Vector3, s: float): Vector3 = (x: a.x + s, y: a.y + s, z: a.z + s)
proc `*`*(a, b: Vector3): Vector3 = (x: a.x * b.x, y: a.y * b.y, z: a.z * b.z)
proc `*`*(a: Vector3, s: float): Vector3 = (x: a.x * s, y: a.y * s, z: a.z * s)
proc `-`*(a, b: Vector3): Vector3 = (x: a.x - b.x, y: a.y - b.y, z: a.z - b.z)
proc `/`*(a: Vector3, s: float): Vector3 = (x: a.x / s, y: a.y / s, z: a.z / s)
proc dot(a, b: Vector3): float = a.x * b.x + a.y * b.y + a.z * b.z
proc norm(a: Vector3): float = sqrt(a.dot(a))
proc unit(a: Vector3): Vector3 = a / a.norm
proc rotate(a: Vector3, rx, ry, rz: float): Vector3 =
  var x = a.x
  var y = a.y
  var z = a.z
  if rx != 0:
    y = a.y*cos(rx) + a.z*sin(rx)
    z = a.z*cos(rx) - a.y*sin(rx)
  if ry != 0:
    x = a.x*cos(ry) - a.z*sin(ry)
    z = a.x*sin(ry) + a.z*cos(ry)
  if rz != 0:
    x = a.x*cos(rz) + a.y*sin(rz)
    y = a.y*cos(rz) - a.x*sin(rz)
  return (x, y, z)

type Line = tuple[v0, v1 : Vector3]
type
  Cube = ref object of RootObj
    center: Vector3
    radius: float
    lines: seq[Line]

const points = @[
  (-1.0,-1.0,-1.0), #back left bottom
  ( 1.0,-1.0,-1.0), #back right bottom
  (-1.0, 1.0,-1.0), #back left top
  ( 1.0, 1.0,-1.0), #back right top
  (-1.0,-1.0, 1.0), #front left bottom
  ( 1.0,-1.0, 1.0), #front right bottom
  (-1.0, 1.0, 1.0), #fromt left top
  ( 1.0, 1.0, 1.0)] #front right top

#Translate line
proc `+`*(ln: Line, v: Vector3): Line = (ln.v0 + v, ln.v1 + v)
#Rotate line
proc rotate(ln: Line, rx, ry, rz: float): Line =
  return (ln.v0.rotate(rx, ry, rz), ln.v1.rotate(rx,ry, rz))


proc paint(line: Line, renderer: sdl.Renderer): int {.discardable.} =
  renderer.lineRGBA((line.v0.x + ScreenW/2).int16,
    (line.v0.y + ScreenH/2).int16, (line.v1.x + ScreenW/2).int16,
    (line.v1.y + ScreenH/2).int16, 255, 255, 255, 255)

proc newCube(center: Vector3, radius: float): Cube =
  var lines: seq[Line] = @[]
  let pts = points.map do (v: Vector3) -> Vector3:
    v * radius
  #back
  lines.add((pts[0], pts[1]))
  lines.add((pts[0], pts[2]))
  lines.add((pts[1], pts[3]))
  lines.add((pts[2], pts[3]))
  #front
  lines.add((pts[4], pts[5]))
  lines.add((pts[4], pts[6]))
  lines.add((pts[5], pts[7]))
  lines.add((pts[6], pts[7]))
  #other
  lines.add((pts[0], pts[4]))
  lines.add((pts[1], pts[5]))
  lines.add((pts[2], pts[6]))
  lines.add((pts[3], pts[7]))
  return Cube(center: center, radius: radius, lines: lines)

proc paint(cube: Cube, renderer: sdl.Renderer): int {.discardable.} =
  for line in cube.lines:
    paint(line + cube.center, renderer)
  return 0

proc rotate(cube: Cube, rx, ry, rz: float): Cube {.discardable.} =
  cube.lines = cube.lines.map do (ln: Line) -> Line: ln.rotate(rx, ry, rz)
  return cube

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

  #sdl.logInfo(sdl.LogCategoryApplication, "SDL initialized successfully")
  randomize()
  return true


# Shutdown sequence
proc exit(app: App) =
  app.renderer.destroyRenderer()
  app.window.destroyWindow()
  #sdl.logInfo(sdl.LogCategoryApplication, "SDL shutdown completed")
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
  cube:Cube = newCube((0.0, 0.0, 0.0), 50.0)

if init(app):

  # Main loop
  while not done:
    # Clear screen with draw color
    discard app.renderer.setRenderDrawColor(0x00, 0x00, 0x00, 0xFF)
    if app.renderer.renderClear() != 0:
      sdl.logWarn(sdl.LogCategoryVideo,
                  "Can't clear screen: %s",
                  sdl.getError())

    cube.paint(app.renderer)

    # Update renderer
    app.renderer.renderPresent()

    # Event handling
    done = events(pressed)

    if pressed.contains(sdl.K_Up):
      cube.rotate(0.1, 0, 0)
    if pressed.contains(sdl.K_Down):
      cube.rotate(-0.1, 0, 0)
    if pressed.contains(sdl.K_Left):
      cube.rotate(0, 0.1, 0)
    if pressed.contains(sdl.K_Right):
      cube.rotate(0, -0.1, 0)
    if pressed.contains(sdl.K_Q):
      cube.rotate(0, 0, 0.1)
    if pressed.contains(sdl.K_W):
      cube.rotate(0, 0, -0.1)





  #echo(pressed.contains(sdl.K_Escape))

# Shutdown
exit(app)

