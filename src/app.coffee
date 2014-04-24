
StopWatch = require './stop_watch.coffee'
KeyboardController = require './keyboard_controller.coffee'
BumperCatsWorld = require './bumper_cats_world.coffee'
        

window.gameConfig =
  stageWidth: 800
  stageHeight: 600
  imageAssets: [
    # "images/ball.png",
    # "images/box.jpg"
    "images/bumpercat_red.png"
    ]
  url: "http://#{window.location.hostname}:#{window.location.port}"

window.local =
  simulation: null
  stopWatch: null
  keyboardController: null
  stats: null
  vars: {}
  pixiWrapper: null

window.onload = ->
  stats = setupStats()

  pixiWrapper = buildPixiWrapper(
    width: window.gameConfig.stageWidth
    height: window.gameConfig.stageHeight
    assets: window.gameConfig.imageAssets
  )

  pixiWrapper.appendViewTo(document.body)

  pixiWrapper.loadAssets ->
    simulation = buildSimulation(url: window.gameConfig.url, pixiWrapper:pixiWrapper)
    keyboardController = buildKeyboardController()
    stopWatch = buildStopWatch()
    gameFramework = new GameFramework(
      window: window
      simulation: simulation
      pixiWrapper: pixiWrapper
      keyboardController: keyboardController
      stats: stats
      stopWatch: stopWatch
    )

    window.local.stats       = stats
    window.local.pixiWrapper = pixiWrapper
    window.local.simulation  = simulation
    window.local.stopWatch   = stopWatch
    window.local.gameFramework = gameFramework

    gameFramework.start()

buildStopWatch = ->
  stopWatch = new StopWatch()
  stopWatch.lap()
  stopWatch

buildSimulation = (opts={})->
  simulation = SimSim.createSimulation(
    adapter:
      type: 'socket_io'
      options:
        url: opts.url
    world: new BumperCatsWorld(
      pixiWrapper: opts.pixiWrapper
    )
    # spyOnDataIn: (simulation, data) ->
    #   step = "?"
    #   step = simulation.simState.step if simulation.simState
    #   console.log ">> turn: #{simulation.currentTurnNumber} step: #{simulation.simState.step} data:", data
    # spyOnDataOut: (simulation, data) ->
    #   step = "?"
    #   step = simulation.simState.step if simulation.simState
    #   console.log ">> turn: #{simulation.currentTurnNumber} step: #{simulation.simState.step} data:", data
  )

setupStats = ->
  container = document.createElement("div")
  document.body.appendChild(container)
  stats = new Stats()
  container.appendChild(stats.domElement)
  stats.domElement.style.position = "absolute"
  stats
  
class PixiWrapper
  constructor: (opts) ->
    @stage = new PIXI.Stage(0xDDDDDD, true)
    @renderer = PIXI.autoDetectRenderer(opts.width, opts.height, undefined, false)
    @loader = new PIXI.AssetLoader(opts.assets)

  appendViewTo: (el) ->
    el.appendChild(@renderer.view)

  loadAssets: (callback) ->
    @loader.onComplete = callback
    @loader.load()

  render: ->
    @renderer.render(@stage)

buildPixiWrapper = (opts={})->
  new PixiWrapper(opts)

buildKeyboardController = ->
  new KeyboardController(
    w: "forward"
    a: "left"
    d: "right"
    s: "back"
    up: "forward"
    left: "left"
    right: "right"
    back: "back"
  )

class GameFramework
  constructor: ({@window,@simulation,@pixiWrapper,@stats,@stopWatch,@keyboardController}) ->
    @shouldRun = false

  start: ->
    @shouldRun = true
    @update()

  update: ->
    @window.requestAnimationFrame => @update()
    for action,value of @keyboardController.update()
      @simulation.worldProxy "updateControl", action, value
    @simulation.update(@stopWatch.elapsedSeconds())
    @pixiWrapper.render()
    @stats.update()



window.dropEvents = ->
  console.log "Drop events"
  window.local.vars.dropEvents = true

window.stopDroppingEvents = ->
  console.log "Stop dropping events"
  window.local.vars.dropEvents = false

window.takeSnapshot = ->
  d = window.local.simulation.world.getData()
  ss = JSON.parse(JSON.stringify(d))
  console.log ss
  window.local.vars.snapshot = ss

window.restoreSnapshot = ->
  ss = window.local.vars.snapshot
  console.log ss
  window.local.simulation.world.setData ss
