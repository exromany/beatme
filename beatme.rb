module BeatMe

    CardValues = %w(2 3 4 5 6 7 8 9 10 J Q K A)
    CardSuits = %w(&spades; &clubs; &hearts; &diams;)

    MaxPlayers = 5

    class Card

        def initialize _value, _suit
            @value, @suit = _value, _suit
        end

        def to_s
            CardValues[@value] + CardSuits[@suit]
        end

    end

    class Place
        attr_accessor :cards

        def initialize
            @empty, @cards = true, []
        end

        def empty?
            @empty
        end

        def take
            @empty = false
            self
        end

        def realize
            cards, @cards, @empty = @cards, [], true
            cards
        end

    end

    class Table
        attr_reader :cards, :places

        def initialize
            @game = :off
            @places = Array.new(MaxPlayers){ |i| Place.new }
            @cards = []
            CardValues.each_index do |v|
                CardSuits.each_index do |s|
                    @cards << Card.new(v, s)
                end
            end
        end

        def empty_places
            @places.select{ |place| place.empty? }.size
        end

        def busy_places
            @places.size - self.empty_places
        end

        def to_s
            "cards: #{@cards.size}<br>\
            game: #{@game}<br>\
            places: #{self.empty_places} of #{@places.size} is empty"
        end

        def sign_in key = nil
            if key.class != Fixnum || !key.between?(1, @places.size) ||
                !@places[key].empty?
                key = nil
                @places.each_with_index do |place, i|
                    key = i and break if place.empty?
                end
            end
            @places[key].take
        end

        def sign_out place
            if !place.empty?
                @cards.unshift(place.realize).flatten!
                @game = :off if self.busy_places <= 1
            end
        end

        def start
            if @game == :off && self.busy_places > 1
                @cards.shuffle!
                @places.each{ |place| place.cards = @cards.pop(2) }
                @game = :on
            end
        end

    end

end
