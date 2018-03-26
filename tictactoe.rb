module UI
  def clear_screen
    system('clear') || system('cls')
  end

  def ps(msg)
    puts "--> #{msg}"
  end

  def line_break
    puts ''
  end

  def line
    puts "----------------------------------"
  end

  def sleep_message(msg)
    if msg.length.positive?
      sleep 0.5
      ps msg
      sleep 1.5
    end
  end

  def joiner(array, char=', ', word='or')
    if array.size > 1
      last_part_string = " #{word} #{array.pop}"
      first_part_string = array.join(char)
      joined_string = first_part_string + last_part_string
    else
      joined_string = array[0].to_s
    end
    joined_string
  end
end

module Prompts
  def display_welcome_message
    clear_screen
    ps "Welcome to Tic, Tac Toe #{human.name}!"
    ps "Today you'll be facing #{computer.name}"
  end

  def display_goodbye_message
    ps "Thanks for playing Tic, Tac, Toe!"
  end

  def display_board
    ps "#{human.name} is a #{human.marker}. #{computer.name} is a #{computer.marker}"
    ps "Score - You're score: #{human.score}/#{TTTGame::WINNING_SCORE}. "\
       "Computer score: #{computer.score}/#{TTTGame::WINNING_SCORE}"
    puts ""
    board.draw
    puts ""
  end

  def clear_screen_and_display_board
    clear_screen
    display_board
  end

  def display_result
    clear_screen_and_display_board

    case board.winning_marker
    when human.marker
      ps "You Won This Round!"
    when computer.marker
      ps "Computer Won This Round!"
    else
      ps "It's a Tie This Round!"
    end
    display_game_winner
  end

  def display_game_winner
    ps "#{human.name} Won the Game!" if human.score == TTTGame::WINNING_SCORE
    ps "#{computer.name} Won the Game!" if computer.score == TTTGame::WINNING_SCORE
  end
end

class Board
  WINNING_LINES =  [[1, 2, 3], [4, 5, 6], [7, 8, 9]] +
                   [[1, 4, 7], [2, 5, 8], [3, 6, 9]] +
                   [[1, 5, 9], [3, 5, 7]]

  def initialize
    @squares = {}
    reset
  end

  # rubocop:disable Metrics/AbcSize
  def draw
    puts "     |     |"
    puts "  #{@squares[1]}  |  #{@squares[2]}  |  #{@squares[3]}"
    puts "     |     |"
    puts "-----+-----+-----"
    puts "     |     |"
    puts "  #{@squares[4]}  |  #{@squares[5]}  |  #{@squares[6]}"
    puts "     |     |"
    puts "-----+-----+-----"
    puts "     |     |"
    puts "  #{@squares[7]}  |  #{@squares[8]}  |  #{@squares[9]}"
    puts "     |     |"
  end
  # rubocop:enable Metrics/AbcSize

  def []=(key, marker)
    @squares[key].marker = marker
  end

  def unmarked_keys
    @squares.keys.select { |key| @squares[key].unmarked? }
  end

  def full?
    unmarked_keys.empty?
  end

  def someone_won_round?
    !!winning_marker
  end

  def find_at_risk_square(marker)
    initial_marker = Square::INTIIAL_MARKER
    WINNING_LINES.each do |line|
      squares = @squares.values_at(*line)
      squares.map!(&:marker)
      next unless squares.count(marker) == 2 &&
                  squares.count(initial_marker) == 1
      temp_array = line.select do |sq|
        @squares[sq].marker == initial_marker
      end
      return temp_array.join.to_i
    end
    nil
  end

  def winning_marker
    WINNING_LINES.each do |line|
      squares = @squares.values_at(*line)
      if three_identical_markers?(squares)
        return squares.first.marker
      end
    end
    nil
  end

  def reset
    (1..9).each { |key| @squares[key] = Square.new }
  end

  private

  def three_identical_markers?(squares)
    markers = squares.select(&:marked?).collect(&:marker)
    return false if markers.size != 3
    markers.min == markers.max
  end
end

class Square
  INTIIAL_MARKER = " ".freeze

  attr_accessor :marker

  def initialize(marker=INTIIAL_MARKER)
    @marker = marker
  end

  def to_s
    @marker
  end

  def marked?
    marker != INTIIAL_MARKER
  end

  def unmarked?
    marker == INTIIAL_MARKER
  end
end

class Player
  attr_reader :marker
  attr_accessor :name, :score

  def initialize(name, marker)
    @name = name
    @marker = marker
    @score = 0
  end
end

class TTTGame
  include Prompts, UI

  COMPUTER_MARKER = 'O'
  WINNING_SCORE = 5

  attr_reader :board, :human, :computer

  def initialize
    clear_screen
    @board = Board.new
    set_player_name_and_marker
    @computer = Player.new('Hal', COMPUTER_MARKER)
    @current_marker = human.marker
  end

  def play
    display_welcome_message
    loop do
      display_board
      one_round
      reset_round

      if someone_won_game?
        break unless play_again?
        reset_game
      end
    end
    display_goodbye_message
  end

  private

  def set_player_name_and_marker
    name = ''
    marker = ''

    loop do
      ps "What's your name?"
      name = gets.chomp.strip
      break unless name.empty?
      ps "Whoops! you must have a name!"
    end

    loop do
      ps "Choose a marker!"
      marker = gets.chomp.strip
      break if marker.length == 1
      ps "Whoops! You're marker must be only one character."
    end
    @human = Player.new(name, marker)
  end

  def someone_won_game?
    human.score == WINNING_SCORE || computer.score == WINNING_SCORE
  end

  def one_round
    loop do
      current_player_moves
      break if board.someone_won_round? || board.full?
      clear_screen_and_display_board
    end
    adjust_score
    display_result
    sleep 1
  end

  def human_turn?
    @current_marker == human.marker
  end

  def current_player_moves
    if human_turn?
      human_moves
      @current_marker = COMPUTER_MARKER
    else
      computer_moves
      @current_marker = human.marker
    end
  end

  def human_moves
    ps "Choose a square #{joiner(board.unmarked_keys)}: "
    square = nil
    loop do
      square = gets.chomp.to_i
      break if board.unmarked_keys.include?(square)
      ps "Sorry, not a valid choice"
    end

    board[square] = human.marker
  end

  def computer_move_square
    square = board.find_at_risk_square(COMPUTER_MARKER)
    return square if !square.nil?
    square = board.find_at_risk_square(human.marker)
    return square if !square.nil?
    board.unmarked_keys.sample
  end

  def computer_moves
    board[computer_move_square] = computer.marker
  end

  def adjust_score
    human.score += 1 if board.winning_marker == human.marker
    computer.score += 1 if board.winning_marker == COMPUTER_MARKER
  end

  def play_again?
    answer = nil
    loop do
      ps "Would you like to play again? (y/n)"
      answer = gets.chomp.downcase
      break if %w(y n).include? answer
      ps "Sorry must be y or n"
    end

    answer == 'y'
  end

  def reset_round
    board.reset
    clear_screen
    @current_marker = human.marker
  end

  def reset_game
    reset_round
    human.score = 0
    computer.score = 0
  end
end

game = TTTGame.new
game.play
