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
      @face == another_card.face
    end

    def eql? another_card
      @face == another_card.face && @suit == another_card.suit
    end

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
      raise "Hands with #{@cards.size} cards is not supported" if @cards.size != 5
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
      Hand.new(@value[1])
    end

    def cards_by_face
      @cards.sort_by{ |c| [c.face, c.suit] }
    end

    def to_s
      @cards.inject(''){ |str, c| str + c.to_s + ' '} + "(#{rank})"
    end

    def to_a
      @cards
    end
    alias :cards :to_a

    def <=> other_hand
      @value <=> other_hand.value
    end

    private

    def process
      cards = cards_by_face
      faces, suits = cards.transpose
      flush = suits.uniq.size == 1
      straight = faces == (faces[0]...faces[0] + 5).to_a
      alt_faces = faces.map{ |f| f == Card::FACES.size - 1 ? 0 : f}.sort
      if !straight && alt_faces == (alt_faces[0]...alt_faces[0] + 5).to_a
        straight = true
        cards.rotate!(-1)
      end
      cards.reverse!
      groups = cards.group_by{ |f| cards.count(f) }
      return [10, cards] if groups[5]
      return [9, cards] if straight && flush && cards[0].face == 13
      return [8, cards] if straight && flush
      return [7, groups[4] + groups[1]] if groups[4]
      return [6, groups[3] + groups[2]] if groups[3] && groups[2]
      return [5, cards] if flush
      return [4, cards] if straight
      return [3, groups[3] + groups[1]] if groups[3]
      return [2, groups[2] + groups[1]] if groups[2] && groups[2].size == 4
      return [1, groups[2] + groups[1]] if groups[2]
      return [0, cards]
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
