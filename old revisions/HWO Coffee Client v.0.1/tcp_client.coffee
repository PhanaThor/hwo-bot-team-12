Net = require('net')
Binary = require('binary')

class Client
  constructor: (host, port) ->
    socket = Net.createConnection port, host
    socket.on 'connect', () =>
      socket.setKeepAlive true
      socket.setNoDelay true
      @bindToSocket socket
      @onConnect socket

  bindToSocket: (socket) =>
    socket.on 'end', @onDisconnect
    self = this
    Binary.stream(socket).loop () ->
      this.scan('message', '\n').tap (stash) ->
        self.onMessage JSON.parse(stash.message), socket

  respond: (message, socket) ->
    socket.write "#{JSON.stringify message}\n"

exports.Client = Client
