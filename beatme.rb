module BeatMe

  class Card
    attr_reader :face, :suit

    SUITS = %w(s c d h)
    FACES = %w(L 2 3 4 5 6 7 8 9 T J Q K A)

    def initialize face, suit
      @face, @suit = face, suit
    end

    def to_s
      FACES[@face] + SUITS[@suit]
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

    def initialize cards, rank = nil
      @cards = case cards
               when Array
                 cards
               when String
                 cards.scan(/\S{2}/).map do |s|
                     Card.new(Card::FACES.index(s[0]), Card::SUITS.index(s[1]))
                 end
               end
      raise "Hands with #{@cards.size} cards is not supported" if @cards.size != 5
      @value = rank ? [rank, cards] : processing
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
      Hand.new(@value[1], @value[0])
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

    def processing
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
    attr_reader :amount, :stack, :action

    def initialize
      @empty, @cards = true, []
      @stack = @amount = @full_amount = 0
    end

    def empty?
      @empty
    end

    def play?
      !@empty && @cards.any?
    end

    def take sum
      @stack, @empty = sum, false
      @amount = @full_amount = 0
      self
    end

    def realize
      cards, @cards, @empty = @cards, [], true
      @stack = @amount = @full_amount = 0
      cards
    end

    def hand cards = []
      return nil if cards.empty? && @cards.empty?
      cards.concat(@cards).combination(5).to_a.inject do |hand, cards|
        [hand, Hand.new(cards)].max
      end
    end

    def bet sum
      sum = @stack if @stack < sum
      @stack -= sum
      @amount = sum
    end

    def trush_amount
      amount, @amount = @amount || 0, 0
      @full_amount += amount
      amount
    end

  end

  class Table
    attr_reader :cards, :places, :turn, :dealer, :game

    def initialize
      @max_players = 5
      @start_stack = 300
      @m_blind = 10
      @blind = 20

      @places = Array.new(@max_players){ |i| Place.new }
      @cards, @dealer, @game = [], nil, :off
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
      @places.size - empty_places
    end

    def in_game
      @places.select{ |place| place.play? }.size
    end

    def to_s
      "cards: #{@cards.size}<br>\
      game: #{@game}<br>\
      places: #{empty_places} of #{@places.size} is empty"
    end

    def sign_in key = nil
      if !key.is_a?(Integer) || !key.between?(1, @places.size) ||
        !@places[key].empty?
        key = @places.index( @places.find{ |place| place.empty? } )
      end
      @places[key].take(@start_stack) if key
      start if busy_places > 1
      @places[key]
    end

    def sign_out place
      unless place.empty?
        @cards = place.realize + @cards
        finish if busy_places <= 1
      end
    end

    private

    def start
      if @game == :off && busy_places > 1
        @cards.shuffle!
        @bank = 0
        count, f = busy_places + 1, 0
        @places.rotate(-(@dealer || -1) - 1).cycle(2).to_a.each do |place|
          unless place.empty?
            break if f > count
            @dealer = @places.index(place) if f == 0
            place.bet @m_blind if f == 1
            place.bet @blind if f == 2
            @wait_to = @turn = @places.index(place) if f == 3
            place.cards = @cards.pop(2) if place.cards.empty? && f > 0
            f += 1
          end
        end
        @game = :on
      end
    end

    def next_turn
      @turn = @places.rotate(-@turn - 1).find{ |place| place.play? }
      @wait_to = nil if @turn == @wait_to
      next_round and return 0 if @wait_to.nil? && equal_amounts
      next_turn if @places[@turn].stack == 0
    end

    def equal_amounts
      max = @places.max_by{ |place| place.amount }.amount
      @places.find do |place|
        place.play? && place.amount < max && place.stack > 0
      end.empty?
    end

    def update_bank
      @places.each { |place| @bank += place.trush_amount }
    end

    def finish
      if @game == :on
        @dealer = @turn = nil
        update_bank
        @game = :off
      end
    end

  end

end
