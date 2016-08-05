require 'Qt'
require './movement'

Test = true

if Test
  Filename = "test_duck_movement.db"
else
  Filename = "duck_movement.db"
end

class DuckMovementEntry < Qt::Widget
  slots :enter_movement, :set_moves, :sync, :add_duck, 'change_stories(int)', 'edit_move(int)', 'set_story(int)'
  MovementEdits = [:origin_place, :origin_time, :destination_place, :destination_time, :movement_mode, :purpose, :comment, :trip_index]
  MovementIx = (2..8).to_a + [10]

  NrWhoCols = 5
  MaxNrMoves = 16

  def initialize(filename)
    super()
    @filename = filename
    @movement = DuckMovement.new(@filename)
    @edits = {}
    @duck_names = []
    @edit_mode = nil
    @story_id = @movement.get_first("stories")[0]
    setWindowTitle "Duck Movement"
    setToolTip "Enter Movement"
    init_ui
    resize 800, 800
    show
  end

  def init_ui
    @move_to_edit = Qt::SignalMapper.new self
    connect @move_to_edit, SIGNAL('mapped(int)'), self, SLOT('edit_move(int)')

    vbox = Qt::VBoxLayout.new self
    hbox = Qt::HBoxLayout.new

    @button_enter = Qt::PushButton.new 'Enter', self
    button_sync = Qt::PushButton.new 'Sync', self
    button_quit = Qt::PushButton.new 'Quit', self
    hbox.addWidget button_quit, 1, Qt::AlignLeft
    hbox.addStretch 1
    hbox.addWidget button_sync, 1, Qt::AlignLeft
    hbox.addStretch 1
    hbox.addWidget @button_enter, 1, Qt::AlignLeft

    book_box = Qt::HBoxLayout.new
    book_box.addWidget Qt::Label.new "Book", self
    @current_book = Qt::ComboBox.new self
    set_books
    book_box.addWidget @current_book
    vbox.addLayout book_box


    story_box = Qt::HBoxLayout.new
    story_box.addWidget Qt::Label.new "Story", self
    @current_story = Qt::ComboBox.new self
    set_stories
    story_box.addWidget @current_story
    vbox.addLayout story_box

    who_box = Qt::HBoxLayout.new
    who_box.addWidget Qt::Label.new "who", self
    @who_grid = Qt::GridLayout.new
    @who_grid.horizontalSpacing = 20
    set_ducks
    who_box.addLayout @who_grid
    vbox.addLayout who_box

    MovementEdits.each {|col| vbox.addLayout(text_entry(col))}

    @current_moves = Qt::VBoxLayout.new
    init_moves
    set_moves
    vbox.addLayout @current_moves

    vbox.addStretch 1
    vbox.addLayout hbox

    connect button_quit, SIGNAL('clicked()'), $qApp, SLOT('quit()')
    connect button_sync, SIGNAL('clicked()'), self, SLOT('sync()')
    connect @button_enter, SIGNAL('clicked()'), self, SLOT('enter_movement()')
    connect @current_book, SIGNAL('currentIndexChanged(int)'), self, SLOT('change_stories(int)')
    connect @current_story, SIGNAL('currentIndexChanged(int)'), self, SLOT('set_story(int)')
  end

  def text_entry(name)
    hbox = Qt::HBoxLayout.new
    label = Qt::Label.new name.to_s, self
    edit = Qt::LineEdit.new self
    edit.setInputMask("999") if name == :trip_index
    hbox.addWidget label, 1
    hbox.addWidget edit, 3
    @edits[name]= edit
    hbox
  end

  def enter_movement
    person_row = []
    person_ids = []
    @current_who.each_with_index do |who, ix|
      if who.isChecked
        person_row << who.text 
        person_ids << @duck_ids[ix]
      end
    end
    person_ids.sort!

    if @edit_mode
      mov = @movement.get("movements", @edit_mode)
      move_id = @edit_mode
      MovementEdits.each_with_index do |col, ix|
        txt = @edits[col].displayText
        txt = txt.to_i if col == :trip_index
        if txt != mov[MovementIx[ix]]
          @movement.change(:movements, col, txt, move_id)
        end
      end

      old_person_ids = @movement.persons_by_movement(move_id).sort
      if person_ids != old_person_ids
        @movement.change(:movements, :movers, person_row.join(', '), move_id)
        (person_ids - old_person_ids).each do |new_persons|
          @movement.add(:person_movement, [move_id, new_persons])
        end
        (old_person_ids - person_ids).each do |old_persons|
          @movement.remove_person_movement(move_id, old_persons)
        end
      end
      @edit_mode = nil
      @button_enter.text = "Enter"
      set_moves
    else
      movement_row = MovementEdits.map {|col| @edits[col].displayText }
      movement_row.unshift person_row.join(', ')
      @movement.add_movement(movement_row, person_row, @story_id)
      set_moves
    end
  end

  def change_stories(ix)
    return if @block_book
    @selected_book = @movement.get("books", ix)
    set_stories
  end

  def set_books
    if @selected_book
      @selected_book = @movement.get("books", @selected_book[0])
    else
      @selected_book = @movement.get_first("books")
    end
    @block_book = true
    @current_book.clear
    ix = 0
    @movement.get_all("books").each_with_index do |row, i|
      @current_book.addItem "#{row[1]} #{row[2]}"
      ix = i if @selected_book[0] == row[0]
    end
    @block_book = false
    @current_book.currentIndex = ix
    @current_book.currentIndexChanged(ix)
  end

  def set_stories(new_set = false)
    @story_list = []
    @movement.get_all("stories_in_books").each do |sib|
      @story_list << @movement.get("stories", sib[1]) if sib[2] == @selected_book[0]
    end
    @story_id = @story_list[0][0] if new_set
    @block_story = true
    @current_story.clear
    ix = 0
    @story_list.each_with_index do |row, i|
      @current_story.addItem "#{row[1]} | #{row[3]}"
      ix = i if @story_id == row[0]
    end
    @current_story.currentIndex = ix
    @block_story = false
    set_moves if @current_moves
  end

  def init_moves
    @move_edits = []
    @move_buttons = []
    MaxNrMoves.times do |mov|
      layout = Qt::HBoxLayout.new
      mov_edit = Qt::Label.new self
      layout.addWidget mov_edit
      @move_edits << mov_edit
      layout.addStretch 1
      mov_button = Qt::PushButton.new "Edit", self
      layout.addWidget mov_button
      @move_buttons << mov_button
      connect mov_button, SIGNAL('clicked()'), @move_to_edit, SLOT('map()')
      @move_to_edit.setMapping(mov_button, mov)
      @current_moves.addLayout layout
    end
  end

  def set_story(ix)
    unless @block_story
      @story_id = @story_list[ix][0]
      set_moves
    end
  end

  def set_moves
    @display_movs = @movement.movements_by_story(@story_id)
    @display_movs = @display_movs[-MaxNrMoves .. -1] if @display_movs.size > MaxNrMoves
    nr_movs = @display_movs.size
    MaxNrMoves.times do |i_mov|
      if i_mov < nr_movs
        @move_edits[i_mov].text = @display_movs[i_mov].values_at(1, *MovementIx).join(" | ")
        @move_buttons[i_mov].setEnabled(true)
      else
        @move_edits[i_mov].text = ""
        @move_buttons[i_mov].setEnabled(false)
      end
    end
  end

  def set_ducks
    @current_who ||= []
    nr_ducks = @duck_names.size
    @duck_ids = []
    @movement.get_all("persons").each_with_index do |person, i|
      @duck_ids << person[0]
      if i < nr_ducks
        @duck_names[i].text = person[1]
      else
        who_check = Qt::CheckBox.new person[1], self
        @duck_names << who_check
        @who_grid.addWidget(who_check, i / NrWhoCols, i % NrWhoCols)
        @current_who << who_check
      end
    end
  end

  def sync
    @movement = DuckMovement.new(@filename)
    set_books
    set_ducks
  end

  def edit_move(move_ix)
    move_id = @display_movs[move_ix][0]
    @edit_mode = move_id
    @button_enter.text = "Change"
    mov = @movement.get("movements", move_id)
    MovementEdits.each_with_index do |name, i|
      @edits[name].text = mov[MovementIx[i]]
    end

    pids = @movement.persons_by_movement(move_id)
    @movement.get_all("persons").each_with_index do |per, i|
      @duck_names[i].setChecked(pids.include?(per[0]))
    end
  end
end

if $0 == __FILE__
  app = Qt::Application.new ARGV
  DuckMovementEntry.new(Filename)
  app.exec
end
