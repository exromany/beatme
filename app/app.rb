Presto.http.encoding 'UTF-8'
Presto::View.register :Slim, Slim::Template

class App
  include Presto::Api
  http.map

  http.use Rack::Static, :urls => ['/js'], :root => 'public/js'

  view.engine :Slim
  view.layouts_path 'view/layouts'
  view.layout :main, :index

  def index
    view.render :socket
  end

end
