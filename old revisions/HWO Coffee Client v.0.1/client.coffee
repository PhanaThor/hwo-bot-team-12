Tcp = require('./tcp_client')
Tekoaly = require('./Tekoaly')
log = console.log

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
		  Tekoaly.PeliOhi

        when "gameIsOn"
		  Tekoaly.AjatteleSeuraavaLiike message

        else
          log "-- unrecognized message encountered:"
          log message
    catch error
      log "-- ball hit safety net: #{error}"

  join: (name, socket) ->
    joinGame =
      data: name
      msgType: "join"
    @respond joinGame, socket

if process.argv.length >= 4
  name = process.argv[2]
  host = process.argv[3]
  port = process.argv[4]
  new Client name, host, port
else
  log "Usage: client <name> <host> <port>"

