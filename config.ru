require './app'

run Presto::App.new { mount App }.app :server => :Thin
