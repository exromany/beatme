require 'presto'
require 'slim'
require './beatme'

Presto::View.register :Slim, Slim::Template

class App
    include Presto::Api
    http.map

    view.engine :Slim
    view.layout :main

    def index
        @table = BeatMe::Table.new unless @table
        view.render
    end

end
