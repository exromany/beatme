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

    class Player
        attr_reader :key
        attr_accessor :cards

        def initialize key
            @key, @cards = key, []
        end

        def to_s
            "player ##{@key}" + (@cards.any? ? "with #{@cards.join(', ')}" : '')
        end

    end

    class Table

        def initialize
            @game = :off
            @players = {}
            @cards = []
            CardValues.each_index do |v|
                CardSuits.each_index do |s|
                    @cards << Card.new(v, s)
                end
            end
        end

        def to_s

            "cards: #{@cards.size} \nplayers: #{@players.size} \ngame: #{@game}\n"
        end

        def sit_up key = nil
            if key.class != Fixnum || !key.between?(1, MaxPlayers) ||
                @players.has_key?(key)
                key = nil
                (1..MaxPlayers).each do |i|
                    key = i and break unless @players.has_key?(i)
                end
            end
            @players[key] = Player.new(key) if key
        end

        def out player
            if @players.delete player.key
                @cards.unshift(player.cards).flatten!
                player = nil
                @game = :off if @players.empty?
                self
            end
        end

        def start
            if @game == :off && @players.any?
                @cards.shuffle!
                @players.each{ |i, p| p.cards = @cards.pop(2) }
                @game = :on
            end
        end

    end

end
