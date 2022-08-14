# frozen_string_literal: true

require 'curses'
require 'time'

# Game singleton with all of the important vars and objects
class Game
  def initialize
    @win = Curses::Window.new(24, 80, 0, 0)
    @time = 0
    @last_time = (Time.now.to_f * 1000).to_i
    @digimon = Digimon.new('Agumon')
    @cur_char = ''
    @quit_game = false
  end

  attr_reader :quit_game
  attr_accessor :cur_char

  def update
    new_time = (Time.now.to_f * 1000).to_i
    diff_time = new_time - @last_time
    @time += diff_time
    @last_time = new_time

    c = Curses.get_char
    @cur_char = c if c

    @quit_game = true if %w[q Q].include? @cur_char
    @win.close if @quit_game

    @digimon.update diff_time, @cur_char
  end

  def draw_debug
    @win.setpos(21, 1)
    @win.addstr(@cur_char.rjust(78))
    @win.setpos(22, 1)
    @win.addstr(@time.to_s.rjust(78))
  end

  def draw_instructions
    @win.setpos(18, 2)
    @win.addstr('F: Feed')
    @win.setpos(19, 2)
    @win.addstr('S: Give vitamin')
    @win.setpos(20, 2)
    @win.addstr('P: Clean poop')
    @win.setpos(21, 2)
    @win.addstr('Q: Quit')
  end

  def draw_meters
    food = '♥' * @digimon.food
    strength = '♥' * @digimon.strength
    @win.setpos(4, 2)
    @win.addstr("#{@digimon.stage} - age: #{(@digimon.age / 10_000).to_i}")
    @win.setpos(5, 2)
    @win.addstr("food:  #{food.ljust(4, '○')}")
    @win.setpos(6, 2)
    @win.addstr("str:   #{strength.ljust(4, '○')}")
  end

  def draw_ui
    @win.addstr(@digimon.name)

    draw_meters

    if @digimon.food.zero? || @digimon.strength.zero?
      @win.setpos(7, 2)
      @win.attron Curses::A_STANDOUT
      @win.addstr('CARE')
      Curses.beep
      @win.attroff Curses::A_STANDOUT
    end
    nil
  end

  def draw_entities
    @digimon.poops.each do |poop|
      @win.setpos(poop.y, poop.x)
      @win.addstr('☁')
    end
    @win.setpos(@digimon.y, @digimon.x)
    @win.addstr('☺')
  end

  def draw
    @win.clear
    @win.box('|', '-')
    @win.setpos(2, 2)

    draw_ui

    draw_debug

    draw_instructions

    draw_entities

    @win.refresh
  end
end

# This is the guy!
class Digimon
  def initialize(name)
    @name = name
    @stage = 'child'
    @food = 4
    @strength = 4
    @x = 39
    @y = 11
    @poops = []

    @decision_timer = 500
    @food_timer = 5000
    @strength_timer = 4000
    @poop_timer = 2500
    @age = 0
  end

  def handle_input(cur_char)
    if %w[f F].include? cur_char
      @food = [@food + 1, 4].min
      @cur_char = ''
    end
    if %w[s S].include? cur_char
      @strength = [@strength + 1, 4].min
      @cur_char = ''
    end
    if %w[p P].include? cur_char
      @cur_char = ''
      @poops = []
    end
    nil
  end

  def make_decision(delta_t)
    @decision_timer -= delta_t
    if @decision_timer <= 0
      @decision_timer = 500
      roll = rand(5)
      case roll
      when 0
        @x = [@x + 1, 59].min
      when 1
        @x = [@x - 1, 9].max
      when 2
        @y = [@y + 1, 16].min
      when 3
        @y = [@y - 1, 6].max
      end
    end
    nil
  end

  def handle_timers(delta_t)
    make_decision delta_t

    @food_timer -= delta_t
    if @food_timer <= 0
      @food_timer = 5000
      @food -= 1
      @food = [@food, 0].max
    end

    @strength_timer -= delta_t
    if @strength_timer <= 0
      @strength_timer = 4000
      @strength -= 1
      @strength = [@strength, 0].max
    end

    @poop_timer -= delta_t
    if @poop_timer <= 0
      @poop_timer = 2500
      poop
    end
    nil
  end

  def update(delta_t, cur_char)
    @age += delta_t
    if @stage == 'child' && @age >= 50_000
      @stage = 'adult'
      @name = 'Greymon'
    end

    handle_timers delta_t

    handle_input cur_char
  end

  def poop
    new_poop = Poop.new(@y, @x - 1)
    @poops << new_poop
  end

  attr_accessor :name, :stage, :food, :strength, :x, :y
  attr_reader :age, :poops
end

# Little cloud of poop dropped periodically
class Poop
  def initialize(y_pos, x_pos)
    @y = y_pos
    @x = x_pos
  end

  attr_accessor :y, :x
end

Curses.init_screen
Curses.timeout = 0
Curses.curs_set(0)

game = Game.new

loop do
  game.update
  break if game.quit_game

  game.draw
  game.cur_char = ''
end

Curses.close_screen
