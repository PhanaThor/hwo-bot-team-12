Tcp = require('./tcp_client')
log = console.log

lasttime = 0
lastDirection = 0

think = (pall, mina) ->
    if pall < mina
       -1
    else 
       1

kuinkaLahella = (pall, mina) ->
  if pall < mina
    mina - pall
  else
    pall - mina


gameInfo =
  level:
    top: 0
    bottom: 480
    left: 0
    right: 640
    ifConfigured: 0
  ballVectorX: 0
  ballVectorY: 0
  ballVelocityInPaddleBounce: 0
  previousTime: 0
  previousBallX: 0
  previousBallY: 0

CalculateBallVector = (time, ballX, ballY) ->
    timeSpan = time - gameInfo.previousTime
    moveX = ballX - gameInfo.previousBallX
    moveY = ballY - gameInfo.previousBallY
       
    gameInfo.ballVectorX = moveX / timeSpan
    gameInfo.ballVectorY = moveY / timeSpan  
    
    gameInfo.previousTime = time
    gameInfo.previousBallX = ballX
    gameInfo.previousBallY = ballY


hunchBallEndLocation = (temp) ->
  # initial hunch is center of level:
  hunch = gameInfo.level.bottom / 2
 
  if lasttime == 0
     return hunch

  if gameInfo.ballVectorX > 500 or gameInfo.ballVectorY > 500
     return hunch

  if gameInfo.ballVectorX < -500 or gameInfo.ballVectorY < -500
     return hunch

  
  # lets play forward for temp ball and see where it goes:
  tempBallX = gameInfo.previousBallX
  tempBallY = gameInfo.previousBallY
  tempBallVectorX = gameInfo.ballVectorX
  tempBallVectorY = gameInfo.ballVectorY

  if tempBallVectorX == 0
    tempBallVectorX = -1

  # lets make failsafe
  failStick = 1

  # loop until we are at skin of our own paddle:
  while tempBallX > gameInfo.level.left
    tempBallX += tempBallVectorX
    tempBallY += tempBallVectorY

    failStick++     

    # at the level borders:
    if tempBallY > gameInfo.level.bottom or tempBallY < gameInfo.level.top
      tempBallVectorY = -tempBallVectorY
      tempBallY += tempBallVectorY
         
    # at the enemy gates:
    if tempBallX > gameInfo.level.right
      tempBallVectorX = -tempBallVectorX
      # tempBallVectorX += -0.4
      tempBallX += tempBallVectorX

    if failStick > 40000
      return hunch
      
  # loop is over, returning the hunch:
  hunch = tempBallY
  #log "meidan arvaus on: #{hunch}"
  return hunch


class Client extends Tcp.Client
  constructor: (@name, host, port) ->
    super(host, port)

  onConnect: (socket) ->
    @join @name, socket
    @socket = socket

  onDisconnect: ->
    process.exit


  onMessage: (message, socket) ->
    try
      switch message.msgType
        when "joined"
         log "Game visualization URL #{message.data}"

        when "gameStarted"
          log "Bring it on #{message.data[1]} !"

        when "gameIsOver"
          winner = message.data
          if winner is @name then log "Victory!" else log "We lost :("
          lastDirection = 3

        when "gameIsOn"
          meno = 0
          
          if gameInfo.level.ifConfigured == 0
            gameInfo.level.top = message.data.conf.ballRadius / 2
            gameInfo.level.bottom = message.data.conf.maxHeight - (message.data.conf.ballRadius / 2)
            gameInfo.level.left = message.data.conf.ballRadius
            gameInfo.level.right = message.data.conf.maxWidth - (message.data.conf.ballRadius + message.data.conf.paddleWidth)
            gameInfo.level.ifConfigured = 1

          CalculateBallVector(message.data.time, message.data.ball.pos.x, message.data.ball.pos.y)
          
          
          hunchY = hunchBallEndLocation(3)
          hunchY -= (message.data.conf.paddleHeight / 2)
          if message.data.ball.pos.x < 100
            if message.data.ball.pos.y > hunchY
              hunchY = hunchY + 20
            else
              hunchY = hunchY - 20
          lahellaHunchia = kuinkaLahella(hunchY, message.data.left.y)




          meno = think(hunchY, message.data.left.y)
          if lahellaHunchia < 30
            if meno < 0
               meno = -0.7
            else 
               meno = 0.7

          if lahellaHunchia < 10
            if meno < 0
               meno = -0.4
            else 
               meno = 0.4
          
          if lahellaHunchia < 5
            if meno < 0
               meno = -0.2
            else 
               meno = 0.2

          if lahellaHunchia < 1
            meno = 0.0

          
          killekalle = message.data.time - lasttime
          if killekalle > 100
            
            moveUp =
              msgType: "changeDir"
              data: meno
            @respond moveUp, socket
            lasttime = message.data.time
            lastDirection = meno
          else
            kalle = 3

        else
          log "-- unrecognized message encountered:"
          log message
    catch error
      log "-- ball hit safety net: #{error}"

  join: (name, socket) ->
    joinGame =
      msgType: "join"
      data: name
    @respond joinGame, socket


if process.argv.length >= 4
  name = process.argv[2]
  host = process.argv[3]
  port = process.argv[4]
  new Client name, host, port
else
  log "Usage: client <name> <host> <port>"

