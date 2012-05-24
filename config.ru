require 'presto'
require 'faye/websocket'
require 'coffee-script'
require 'rack/coffee'
require 'slim'
require './beatme'
require './app/socket'
require './app/app'

Faye::WebSocket.load_adapter 'thin'

use Rack::Reloader, 0
use Rack::CommonLogger

map '/ws' do
  faye = lambda do |env|
    if Faye::WebSocket.websocket?(env)
      ws = Faye::WebSocket.new(env, ['beatme'], ping:15)
      if ws.protocol.empty?
        ws.close
      else
        Socket.new(ws)
      end
      ws.rack_response
    else
      [404, {'Content-Type'=>'text/plain'}, ['This is WebSocket']]
    end
  end
  run faye
end

map '/assets' do
  run Rack::Directory.new 'public'
end

map '/' do
  #run Presto::App.new { mount App }.app
  app = Presto::App.new
  app.mount App
  run app.app
end
