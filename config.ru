require './app'

Presto.http.encoding 'UTF-8'
run Presto::App.new { mount App }.app
