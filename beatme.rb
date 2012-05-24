module BeatMe

  class Card
    attr_reader :face, :suit

    SUITS = %w(s c d h)
    FACES = %w(2 3 4 5 6 7 8 9 T J Q K A)

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
      alt_faces = faces.map{ |f| f == Card::FACES.size - 1 ? -1 : f}.sort
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
    attr_reader :cards, :amount, :stack, :action

    def initialize
      @fold, @empty, @cards = true, true, []
      @stack = @amount = @full_amount = 0
    end

    def empty?
      @empty
    end

    def play?
      !@empty && @cards.any? && !@fold
    end

    def fold?
      !@empty && @cards.any? && @fold
    end

    def to_hash ext = false
      hash = { 
        status: (@empty ? :empty : (@cards.empty? ? :wait :(@fold ? :fold : :play))).to_s
      }
      hash[:stack] = @stack unless @empty
      hash[:amount] = @amount unless @empty
      hash[:cards] = @cards if ext
      hash
    end

    def take sum
      @stack, @empty = sum, false
      @amount = @full_amount = 0
      self
    end

    def realize
      @stack = @amount = @full_amount = 0
      @empty = true
      remove_cards
    end

    def cards= cards
      @full_amount = 0;
      @hand, @fold = nil, false
      @cards = cards
    end

    def remove_cards
      fold
      cards, @cards = @cards, []
      cards
    end

    def fold
      @fold = true
    end

    def hand cards = []
      return @hand unless @hand.nil?
      return nil if cards.empty? && @cards.empty?
      @hand = cards.concat(@cards).combination(5).to_a.inject do |hand, cards|
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

    def win sum
      @stack += sum
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
      Card::FACES.each_index do |f|
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

    def to_hash ext_place = nil
      hash = {
        game: @game.to_s,
        places_total: @places.size,
        places_empty: empty_places,
        places: {},
      }
      hash[:round] = @round if @game != :off
      hash[:bank] = @bank if @game != :off
      @places.each_with_index do |place, index|
        place_hash = place.to_hash(place == ext_place)
        place_hash[:dealer] = true if @dealer == index
        place_hash[:turn] = true if @turn == index
        hash[:places][index] = place_hash
      end
      hash
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
        recycle(place.realize)
        finish if busy_places <= 1
      end
    end

    def actions
      return nil if @game == :off
      max = max_amount
      place = @places[@turn]

      call = [max - place.amount, place.stack].min
      bet = [place.stack, @blind].min .. place.stack
      rais = [place.stack, @blind + call].min .. place.stack

      actions = { :fold => 0..0 }
      actions[:check] = 0..0 if call == 0
      actions[:call] = call if call > 0
      actions[:bet] = bet if max == 0
      actions[:raise] = rais if max > 0 && place.stack > call
      actions
    end

    def do_action action, sum = 0
      return nil if @game == :off
      place = @places[@turn]
      if action == :fold
        place.fold
      else
        available = actions[action]
        if !avaible.nil? && available.cover?(sum)
          place.bet(sum)
        else
          return nil
        end
      end
      next_turn
    end

    private

    def recycle cards
      @cards = cards + @cards
    end

    def start
      if @game == :off && busy_places > 1
        @cards.shuffle!
        init_bank
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
        @round = 0
        @game = :on
      end
    end

    def init_bank
        @bank, @wins = 0, []
        @bank_for = Array.new(@places.size, 0)
    end

    def next_turn
      turn, @turn = @turn, next_after(@turn)
      finish if turn == @turn
      @wait_to = nil if @turn == @wait_to
      next_round and return 0 if @wait_to.nil? && equal_amounts
      next_turn if @places[@turn].stack == 0
    end

    def next_round
      @round += 1
      update_bank
      case @round
      when 1
        @public_cards = @cards.pop(3)
      when 2..3
        @public_cards = @cards.pop(1)
      else
        finish
      end
      @turn = next_after @dealer if @round < 4
    end

    # TODO: конец партии - справедливая раздача выигрыша
    # TODO: рефакторинг

    def next_after index
      @places.index( @places.rotate(-index - 1).find{ |place| place.play? } )
    end

    def max_amount
      @places.max_by{ |place| place.amount }.amount
    end

    def equal_amounts
      max = max_amount
      @places.find do |place|
        place.play? && place.amount < max && place.stack > 0
      end.empty?
    end

    def update_bank
      acc = 0
      @places.map { |place| place.amount }.unique.sort.each do |amount|
        count = @places.count{ |place| place.amount >= amount }
        sum, acc = amount - acc, amount
        @places.each_with_index do |place, index|
          @bank_for[index] += sum * count if place.amount >= amount
        end
      end
      @places.each { |place| @bank += place.trush_amount }
    end

    def finish
      if @game == :on
        @game = :win
        update_bank
        groups = @places.select{ |place| place.play? }.
          sort_by{ |place| place.hand }.reverse.group_by{ |place| place.hand }
        groups.first do |group, places|
          size = places.size
          places.shuffle.each_with_index do |place, index|
            sum = @bank / (size - index)
            @bank -= sum
            @wins << [place, sum]
            place.win(sum)
          end
        end
        @places.each{ |place| recycle(place.remove_cards) }
        @dealer = @turn = nil
      end
      # delay for 20 seconds
      # TODO: new thread
      sleep 20
      start
    end

  end

end
