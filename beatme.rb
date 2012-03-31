module BeatMe

    class Card
        attr_reader :face, :suit

        SUITS = %w(s c d h)
        FACES = %w(L 2 3 4 5 6 7 8 9 T J Q K A)

        def initialize face, suit
            @face, @suit = face, suit
        end

        def to_s
            Card::FACES[@face] + Card::SUITS[@suit]
        end

        def <=> another_card
            @face <=> another_card.face
        end

        def == another_card
            @face == another_card.face && @suit == another_card.suit
        end
        alias :eql? :==

        def hash
            [@face, @suit].hash
        end

        def to_ary
            [@face, @suit]
        end

    end

    class Hand
        attr_reader :value

        def initialize cards
            @cards = case cards
                     when Array
                         cards
                     when String
                         cards.scan(/\S{2}/).map do |s|
                             Card.new(Card::FACES.index(s[0]), Card::SUITS.index(s[1]))
                         end
                     end
            @value = process
        end

        def rank
            ['Highest Card',
             'Pair',
             'Two pairs',
             'Three of a kind',
             'Straight',
             'Flush',
             'Full House',
             'Four of a kind',
             'Straight Flush',
             'Royal Flush',
             'Five of a kind',
            ][@value[0]]
        end

        def by_rank
            Hand.new(@cards)
        end

        def cards_by_face
            @cards.sort_by{ |c| [c.face, c.suit] }
        end

        def to_s
            @cards.join(' ') "(#{rank})"
        end

        def to_a
            @cards
        end

        def <=> other_hand
            @value <=> other_hand.value
        end

        private

        def process
            faces, suits = cards_by_face.transpose
            flush = suits.uniq.size == 1
            straight = faces == (faces[0]...faces[0] + 5).to_a
            alt_faces = faces.map{ |f| f == Card::FACES.size - 1 ? 0 : f}.sort
            if !straight && alt_faces == (alt_faces[0]...alt_faces[0] + 5).to_a
                straight, faces = true, alt_faces
            end
            faces.reverse!
            uniq = faces.uniq
            return [10, faces[0]] if uniq.size == 1
            return [9] if straight && flush && faces[0] == Card::FACES.size - 1
            return [8, faces[0]] if straight && flush
            second = uniq[ uniq.index(faces[2]) - 1 ]
            groups = faces.group_by{ |f| faces.count(f) }
            return [7, faces[2], groups[1][0]] if groups[4]
            return [6, faces[2], groups[2][0]] if uniq.size == 2
            return [5, faces] if flush
            return [4, faces[0]] if straight
            return [3, faces[2], groups[1]] if groups[3]
            return [2, groups[2].uniq, groups[1]] if uniq.size == 3
            return [1, groups[2][0], groups[1]] if uniq.size == 4
            return [0, faces]
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

        def hand cards = []
            return nil if cards.empty? && @cards.empty?
            cards.concat(@cards).combination(5) do |h|
                #
            end
        end

    end

    class Table
        attr_reader :cards, :places

        def initialize
            @game = :off
            @places = Array.new(MaxPlayers){ |i| Place.new }
            @cards = []
            Card::FACES[1..-1].each_index do |f|
                Card::SUITS.each_index do |s|
                    @cards << Card.new(f, s)
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
            if !key.is_a?(Integer) || !key.between?(1, @places.size) ||
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
                @cards = place.realize + @cards
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
