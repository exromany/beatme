require 'presto'
require './app'

Presto.http.encoding 'UTF-8'

map '/assets' do
  run Rack::Directory.new 'public'
end

map '/' do
  run Presto::App.new { mount App; helper ViewHelper }.app
end
