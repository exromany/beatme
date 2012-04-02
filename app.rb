require 'presto'
require 'slim'
require './beatme'

Presto::View.register :Slim, Slim::Template
Presto.http.session_ttl 1200

class App
  include Presto::Api
  http.map

  view.engine :Slim
  view.layout :main, :index

  http.before do
    $table = BeatMe::Table.new unless $table
  end

  def index
    view.render table: $table, my_place: http.session[:place]
  end

  def assets * args
    case args[0]
    when 'scss'
      view.render_scss_view "assets/#{ args.join '/' }"
    else
      http.send_file "./view/assets/#{ args.join '/' }"
    end
  end

  def signin
    place = http.params[:place].to_i - 1
    http.session[:place] = $table.sign_in(place) unless http.session[:place]
    http.redirect http.route
  end

  def signout
    $table.sign_out http.session[:place] if http.session[:place]
    http.session.delete :place
    http.redirect http.route
  end

end
