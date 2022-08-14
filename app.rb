require 'curses'
require 'time'
include Curses

class Digimon
    def initialize(name)
        @name = name
        @stage = "child"
        @food = 4
        @strength = 4
        @x = 39
        @y = 11

        @decision_timer = 500
        @food_timer = 5000
        @strength_timer = 4000
        @poop_timer = 2500
        @age = 0
    end

    def update(t)
        @age += t
        if @stage == 'child' && @age >= 50000
            @stage = 'adult'
            @name = 'Greymon'
        end
        @decision_timer -= t
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

        @food_timer -= t
        if @food_timer <= 0
            @food_timer = 5000
            @food -= 1
            @food = [@food, 0].max
        end

        @strength_timer -= t
        if @strength_timer <= 0
            @strength_timer = 5000
            @strength -= 1
            @strength = [@strength, 0].max
        end

        @poop_timer -= t
        if @poop_timer <= 0
            @poop_timer = 2500
            poop
        end

        if ['f', 'F'].include? $cur_char
            @food = [@food + 1, 4].min
            $cur_char = ''
        end
        if ['s', 'S'].include? $cur_char
            @strength = [@strength + 1, 4].min
            $cur_char = ''
        end
        if ['p', 'P'].include? $cur_char
            $cur_char = ''
            $poops = []
        end
    end

    def poop
        new_poop = Poop.new(@y, @x-1)
        $poops << new_poop
    end

    attr_accessor :name
    attr_accessor :stage
    attr_accessor :food
    attr_accessor :strength
    attr_accessor :x
    attr_accessor :y
    attr_reader :age
end

class Poop
    def initialize(y, x)
        @y = y
        @x = x
    end

    attr_accessor :y
    attr_accessor :x

    def draw
        $win.setpos(@y, @x)
        $win.addstr('☁')
    end
end

Curses.init_screen
Curses.timeout = 0

$win = Window.new(24, 80, 0, 0)
$time = 0
$last_time = (Time.now.to_f * 1000).to_i
$digimon = Digimon.new("Agumon")
$cur_char = ''
curs_set(0)
$poops = []
$quit_game = false


def update
    new_time = (Time.now.to_f * 1000).to_i
    diff_time = new_time - $last_time
    $time += diff_time
    $last_time = new_time

    c = get_char
    if c
        $cur_char = c
    end

    if ['q', 'Q'].include? $cur_char
        $quit_game = true
    end

    $digimon.update diff_time
end

def draw
    $win.clear
    $win.box('|', '-')
    $win.setpos(2, 2)
    $win.addstr($digimon.name)

    food = "♥" * $digimon.food
    strength = "♥" * $digimon.strength

    $win.setpos(4, 2)
    $win.addstr($digimon.stage + " - age: " + ($digimon.age / 10000).to_i.to_s)
    $win.setpos(5, 2)
    $win.addstr("food:  " + food.ljust(4, "○"))
    $win.setpos(6, 2)
    $win.addstr("str:   " + strength.ljust(4, "○"))
    if $digimon.food == 0 || $digimon.strength == 0
        $win.setpos(7, 2)
        $win.attron A_STANDOUT
        $win.addstr("CARE")
        beep
        $win.attroff A_STANDOUT
    end

    $win.setpos(21, 1)
    $win.addstr($cur_char.rjust(78))
    $win.setpos(22, 1)
    $win.addstr($time.to_s.rjust(78))

    $win.setpos(18, 2)
    $win.addstr("F: Feed")
    $win.setpos(19, 2)
    $win.addstr("S: Give vitamin")
    $win.setpos(20, 2)
    $win.addstr("P: Clean poop")
    $win.setpos(21, 2)
    $win.addstr("Q: Quit")

    $poops.each do |poop|
        poop.draw
    end
    $win.setpos($digimon.y, $digimon.x)
    $win.addstr('☺')

    $win.refresh
end




while true
    update
    if $quit_game
        break
    end
    draw
end

$win.close
close_screen