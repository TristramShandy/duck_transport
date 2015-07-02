require 'Qt'
require './movement'

Filename = "duck_movement_test.db"

class DuckEntry < Qt::Widget
  slots :enter_movement
  MovementEdits = [:origin_place, :origin_time, :destination_place, :destination_time, :movement_mode, :purpose, :comment]

  def initialize(filename)
    super()
    @movement = DuckMovement.new(filename)
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

    enter = Qt::PushButton.new 'Enter', self
    quit = Qt::PushButton.new 'Quit', self
    hbox.addWidget quit, 1, Qt::AlignLeft
    hbox.addStretch 1
    hbox.addWidget enter, 1, Qt::AlignLeft

    vbox.addWidget Qt::Label.new "Enter Movement"

    story_box = Qt::HBoxLayout.new
    story_box.addWidget Qt::Label.new "Story", self
    @current_story = Qt::ComboBox.new self
    @movement.data[:stories].each {|row| @current_story.addItem row[1]}
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
    vbox.addStretch 1
    vbox.addLayout hbox

    connect quit, SIGNAL('clicked()'), $qApp, SLOT('quit()')
    connect enter, SIGNAL('clicked()'), self, SLOT('enter_movement()')
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
    story_index = @current_story.currentIndex
    @movement.add_movement(movement_row, person_row, story_index)
  end
end

app = Qt::Application.new ARGV
DuckEntry.new(Filename)
app.exec
