import
    random,
    sdl2/sdl,
    sdl2/sdl_gfx_primitives as gfx,
    math,
    basic3d,
    sequtils


const
  Title = "SDL2 Test"
  ScreenW = 320 # Window width
  ScreenH = 240 # Window height
  WindowFlags = 0
  RendererFlags = sdl.RendererAccelerated or sdl.RendererPresentVsync


type
  App = ref AppObj
  AppObj = object
    window*: sdl.Window # Window pointer
    renderer*: sdl.Renderer # Rendering state pointer

type Ray = tuple[origin:Vector3d, direction:Vector3d]
type Camera = tuple[eye:Vector3d, lt:Vector3d, rt:Vector3d, lb:Vector3d, width:float, height:float]

proc newCamera():Camera =
  let width = 320.0
  let height = 240.0
  let eye = vector3d(0,0,100)
  let lt = vector3d( 0 - (width/2),height/2, 50)
  let rt = vector3d(width / 2, height / 2, 50)
  let lb = vector3d(0 - (width/2), 0 - (height / 2), 50)
  return (eye, lt, rt, lb, width, height)



proc ray(camera:Camera, x:float, y:float):Ray =
  var du = camera.rt - camera.lt
  var dv = camera.lb - camera.lt
  du.normalize()
  dv.normalize()
  let pu = du * x / camera.width
  let pv = dv * y / camera.height
  let point = camera.lt + pu + pv - camera.eye
  return (camera.eye, point)




#type BBox = tuple[min:Vector3d, max:Vector3d, used:bool]
#type Grid3d = tuple[min:Vector3d, pixel_size:float, pixels:seq[BBox]]

#proc newGrid(min:Vector3d, max:Vector3d, pixel_size:float):Grid3d =
  

  


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
  #for x in 0..(ScreenW * ScreenH - 1):
  #    pixels[x] = cast[uint32](0xFFFFFFFF)

  for y in 0..ScreenH-1:
      pixels[y*ScreenW + y] = cast[uint32](0xFFFFFFFF)

  if texture.updateTexture(nil, addr(pixels), ScreenW*sizeof(uint32)) != 0:
    sdl.logCritical(sdl.LogCategoryError,
                    "Can't update texture: %s",
                    sdl.getError())


  # Main loop
  while not done:
    # Clear screen with draw color
    #discard app.renderer.setRenderDrawColor(0x00, 0x00, 0x00, 0xFF)
    #if app.renderer.renderClear() != 0:
    #  sdl.logWarn(sdl.LogCategoryVideo,
    #              "Can't clear screen: %s",
    #              sdl.getError())

    #pixels[100*100 - 1] = cast[int32](0xFFFFFFFF)
   
    #texture.render(app.renderer, 0, 0)

    discard app.renderer.renderCopy(texture, nil, nil)

    # Update renderer
    app.renderer.renderPresent()

    # Event handling
    done = events(pressed)

# Shutdown
exit(app)

