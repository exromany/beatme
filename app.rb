require 'presto'
require './beatme'

class App
    include Presto::Api
    http.map

    def index
        table = BeatMe::Table.new
    end

end