require 'slim'
require './beatme'

Presto::View.register :Slim, Slim::Template
Presto.http.session.ttl 1200

class App
  include Presto::Api
  http.map

  view.engine :Slim
  view.layouts_path 'view/layouts'
  view.layout :main, :index

  http.before do
    $table = BeatMe::Table.new unless $table
  end

  def index
    view.render table: $table, my_place: http.session[:place]
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

module ViewHelper

  FACES = %w(2 3 4 5 6 7 8 9 10 J Q K A)
  SUITS = %w(&spades; &clubs; &diams; &hearts;)

  def color_cards cards
    cards.map do |card|
      color = card.suit >= 2 ? 'red' : 'black'
      "<span class='card #{color}'>#{FACES[card.face] + SUITS[card.suit]}</span>"
    end.join(' ')
  end
end
