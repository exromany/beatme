module BeatMe

    CardValues = %w(2 3 4 5 6 7 8 9 10 J Q K A)
    CardSuits = %w(&#9824; &#9827; &#9829; &#9830;)

    class Card

        def initialize _value, _suit
            @value, @suit = _value, _suit
        end

        def to_s
            CardValues[@value] + CardSuits[@suit]
        end

    end

    class User

        def initialize * cards
            @cards = cards
        end

    end

    class Table

        def initialize
            @cards = []
            CardValues.each_index do |v|
                CardSuits.each_index do |s|
                    @cards << Card.new(v, s)
                end
            end
            shuffle
        end

        def shuffle
            @cards.shuffle!
        end

        def to_s
            @cards.join(', ')
        end

        def add_user
            @users << User.new(@cards.pop 2)
        end

    end

end
