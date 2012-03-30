require 'presto'
require 'slim'
require './beatme'

Presto::View.register :Slim, Slim::Template
Presto.http.session_ttl 1200

class App
    include Presto::Api
    http.map

    view.engine :Slim
    view.layout :main

    http.before do
        @table = BeatMe::Table.new unless @table
    end

    def index
        view.render
    end

    def login
        http.session[:player] = @table.sit_up unless http.session[:player]
        http.redirect http.route
    end

end
