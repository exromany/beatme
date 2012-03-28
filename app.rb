# coding: utf-8
# encoding: utf-8
require 'presto'
require './beatme'

class App
    include Presto::Api
    http.map

    def index
        table = BeatMe::Table.new
    end

end

Presto.http.encoding 'UTF-8'

