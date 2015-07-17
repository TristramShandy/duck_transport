require 'Qt'
require './movement'

Filename = "../Data/duck_movement_test.db"

class DuckEntry < Qt::Widget
  slots :enter_movement, :set_moves, :sync, 'change_stories(int)'
  MovementEdits = [:origin_place, :origin_time, :destination_place, :destination_time, :movement_mode, :purpose, :comment]

  def initialize(filename)
    super()
    @filename = filename
    @movement = DuckMovement.new(@filename)
    @edits = {}
    setWindowTitle "Duck Movement"
    setToolTip "Enter Movement"
    init_ui
    resize 800, 600
    show
  end

  def init_ui
    vbox = Qt::VBoxLayout.new self
    hbox = Qt::HBoxLayout.new

    button_enter = Qt::PushButton.new 'Enter', self
    button_sync = Qt::PushButton.new 'Sync', self
    button_quit = Qt::PushButton.new 'Quit', self
    hbox.addWidget button_quit, 1, Qt::AlignLeft
    hbox.addStretch 1
    hbox.addWidget button_sync, 1, Qt::AlignLeft
    hbox.addStretch 1
    hbox.addWidget button_enter, 1, Qt::AlignLeft

    vbox.addWidget Qt::Label.new "Enter Movement"

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
    @current_who = []
    @movement.data[:persons].each do |person|
      who_check = Qt::CheckBox.new person[1], self
      who_box.addWidget who_check
      @current_who << who_check
    end
    vbox.addLayout who_box

    MovementEdits.each {|col| vbox.addLayout(text_entry(col))}

    move_box = Qt::HBoxLayout.new
    move_box.addWidget Qt::Label.new "Movements", self
    @current_moves = Qt::TextEdit.new self
    @current_moves.readOnly = true
    set_moves
    move_box.addWidget @current_moves
    vbox.addLayout move_box

    vbox.addStretch 1
    vbox.addLayout hbox

    connect button_quit, SIGNAL('clicked()'), $qApp, SLOT('quit()')
    connect button_sync, SIGNAL('clicked()'), self, SLOT('sync()')
    connect button_enter, SIGNAL('clicked()'), self, SLOT('enter_movement()')
    connect @current_book, SIGNAL('currentIndexChanged(int)'), self, SLOT('change_stories(int)')
    connect @current_story, SIGNAL('currentIndexChanged(int)'), self, SLOT('set_moves()')
  end

  def text_entry(name)
    hbox = Qt::HBoxLayout.new
    label = Qt::Label.new name.to_s, self
    edit = Qt::LineEdit.new self
    hbox.addWidget label, 1
    hbox.addWidget edit, 3
    @edits[name]= edit
    hbox
  end

  def enter_movement
    movement_row = MovementEdits.map {|col| @edits[col].displayText }
    person_row = []
    @current_who.each {|who| person_row << who.text if who.isChecked}
    movement_row.unshift person_row.join(', ')
    story_id = @story_list[@current_story.currentIndex][0]
    @movement.add_movement(movement_row, person_row, story_id)
    set_moves
  end

  def change_stories(ix)
    return if @block_book
    @selected_book = @movement.data[:books][ix]
    set_stories
  end

  def set_books
    if @selected_book
      @selected_book = @movement.get_book_by_id(@selected_book[0])
    else
      @selected_book = @movement.data[:books][0]
    end
    @block_book = true
    @current_book.clear
    ix = 0
    @movement.data[:books].each_with_index do |row, i|
      @current_book.addItem "#{row[1]} #{row[2]}"
      ix = i if @selected_book[0] == row[0]
    end
    @block_book = false
    @current_book.currentIndex = ix
    @current_book.currentIndexChanged(ix)
  end

  def set_stories
    @story_list = []
    @movement.data[:stories_in_books].each do |sib|
      @story_list << @movement.story_by_id(sib[1]) if sib[2] == @selected_book[0]
    end
    @story_block = true
    @current_story.clear
    ix = 0
    @story_list.each_with_index do |row|
      @current_story.addItem "#{row[1]} | #{row[3]}"
    end
    @story_block = false
    set_moves if @current_moves
  end

  def set_moves
    story_id = @story_list[@current_story.currentIndex][0]
    strs = []
    @movement.movements_by_story(story_id).each {|mov| strs << mov.join(" | ")}
    @current_moves.setText(strs.join("\n"))
  end

  def sync
    @movement = DuckMovement.new(@filename)
    set_books
  end
end

app = Qt::Application.new ARGV
DuckEntry.new(Filename)
app.exec
