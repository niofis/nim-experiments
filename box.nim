import
    random,
    sdl2/sdl,
    sdl2/sdl_gfx_primitives as gfx,
    math,
    basic3d,
    sequtils,
    times,
    strutils


const
  Title = "SDL2 Test"
  ScreenW = 480 # Window width
  ScreenH = 272 # Window height
  WindowFlags = 0
  RendererFlags = sdl.RendererAccelerated


type
  App = ref AppObj
  AppObj = object
    window*: sdl.Window # Window pointer
    renderer*: sdl.Renderer # Rendering state pointer

type Ray = tuple[origin:Vector3d, direction:Vector3d]
type Camera = tuple[eye:Vector3d, lt:Vector3d, rt:Vector3d, lb:Vector3d, width:float, height:float]

proc newCamera():Camera =
  let width:float = ScreenW
  let height:float = ScreenH
  let eye = vector3d(0,0,-100)
  let lt = vector3d( 0 - (width/2),height/2, -50)
  let rt = vector3d(width / 2, height / 2, -50)
  let lb = vector3d(0 - (width/2), 0 - (height / 2), -50)
  return (eye, lt, rt, lb, width, height)

proc rotate(camera:var Camera) =
  let rt = rotateY(0.1)
  camera.lt &= rt
  camera.rt &= rt
  camera.lb &= rt
  camera.eye &= rt

var camera = newCamera()

proc ray(camera:Camera, x:float, y:float):Ray =
  let du = (camera.rt - camera.lt) / camera.width
  let dv = (camera.lb - camera.lt) / camera.height
  let pu = du * x
  let pv = dv * y
  var point = camera.lt + pu + pv - camera.eye
  point.normalize()
  return (camera.eye, point)

type BBox = tuple[min:Vector3d, max:Vector3d]

proc hit(box:BBox, ray:Ray):float =
  var t1 = (box.min.x - ray.origin.x) / ray.direction.x
  var t2 = (box.max.x - ray.origin.x) / ray.direction.x
  var tmin = min(t1,t2)
  var tmax = max(t1,t2)

  t1 = (box.min.y - ray.origin.y) / ray.direction.y
  t2 = (box.max.y - ray.origin.y) / ray.direction.y
  tmin = max(tmin,min(t1,t2))
  tmax = min(tmax,max(t1,t2))

  t1 = (box.min.z - ray.origin.z) / ray.direction.z
  t2 = (box.max.z - ray.origin.z) / ray.direction.z
  tmin = max(tmin,min(t1,t2))
  tmax = min(tmax,max(t1,t2))

  if tmax >= tmin and tmax > 0.0:
    return tmax
  else:
    return 0.0
 
type Grid3d = tuple[box:BBox, width:float, pixels:seq[bool], cell_count_1d:float]

proc newGrid(center:Vector3d, width:float, cell_count_1d:float):Grid3d =
  let bmin = center - width
  let bmax = center + width
  #let count = cell_count_1d * cell_count_1d * cell_count_1d
  let count = 100.0 * 100.0 * 100.0
  var cells = newSeq[bool](count.int)
  cells[0] = true
  cells[0*100*100 + 0*100 + 99] = true
  cells[0*100*100 + 99*100 + 0] = true
  cells[0*100*100 + 99*100 + 99] = true
  cells[99*100*100 + 0*100 + 0] = true
  cells[99*100*100 + 0*100 + 99] = true
  cells[99*100*100 + 99*100 + 0] = true
  cells[99*100*100 + 99*100 + 99] = true
  for i in 0..999:
    let r = random(1_000_000)
    cells[r] = true
  let grid:Grid3d = ((bmin, bmax), width, cells, cell_count_1d)
  return grid

let grid = newGrid(vector3d(0,0,0), 50.0, 50)

proc idx(pt:Vector3d): int =
  return (pt.z.int * 100 * 100) + (pt.y.int * 100) + pt.x.int


proc hit(grid:Grid3d, ray:Ray):bool =
  let d = grid.box.hit(ray)
  if (d == 0):
    return false
  var pt = ((ray.origin + (ray.direction * d)) - grid.box.min)# / grid.cell_count_1d
  var id = idx(pt)
  while id > 0 and id < 1_000_000:
    if grid.pixels[id]:
      return true
    pt = pt + ray.direction
    id = idx(pt)
  return false

proc render[I](buffer:var array[I, uint32]) =
  for y in 0..(ScreenH-1):
    for x in 0..(ScreenW-1):
      let ray = camera.ray(x.float, y.float)
      if grid.hit(ray):
        buffer[y * ScreenW + x] = (0xFFFFFFFF).uint32
      else:
        buffer[y * ScreenW + x] = 0



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

  #sdl.logInfo(sdl.LogCategoryApplication, "SDL initialized successfully")
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
  pixels: array[ScreenW * ScreenH, uint32]

if init(app):

  var texture = app.renderer.createTexture(sdl.PIXEL_FORMAT_ARGB8888, sdl.TEXTUREACCESS_STREAMING, ScreenW, ScreenH)
  
  #let ray = camera.ray(240.0, 100.0)
  #echo grid.hit(ray)
  # Main loop
  while not done:
    var start = cpuTime()
    # Clear screen with draw color
    #mdiscard app.renderer.setRenderDrawColor(0x00, 0x00, 0x00, 0xFF)
    #if app.renderer.renderClear() != 0:
    #  sdl.logWarn(sdl.LogCategoryVideo,
    #              "Can't clear screen: %s",
    #              sdl.getError())

    #pixels[100*100 - 1] = cast[int32](0xFFFFFFFF)
   
    #texture.render(app.renderer, 0, 0)
    
    render(pixels)
    discard texture.updateTexture(nil, addr(pixels), ScreenW*sizeof(uint32))
    #if texture.updateTexture(nil, addr(pixels), ScreenW*sizeof(uint32)) != 0:
    #  sdl.logCritical(sdl.LogCategoryError,
    #                "Can't update texture: %s",
    #                sdl.getError())
    camera.rotate()

    discard app.renderer.renderCopy(texture, nil, nil)

    let fps = 1.0/(cpuTime() - start)
    discard app.renderer.stringRGBA(0, 0, (fps.formatFloat).cstring, 255.uint8, 255.uint8, 255.uint8, 255.uint8)

    # Update renderer
    app.renderer.renderPresent()

    # Event handling
    done = events(pressed)

# Shutdown
exit(app)

