require 'Qt'
require './movement'

Filename = "duck_movement.db"

class DuckEntry < Qt::Widget
  slots :create_duck, 'save_duck(int)'

  def initialize(filename)
    super()
    @filename = filename
    @movement = DuckMovement.new(@filename)
    setWindowTitle "Duck Entry"
    init_ui
    resize 400, 600
    show
  end

  def init_ui
    vbox = Qt::VBoxLayout.new self
    @all_ducks = Qt::VBoxLayout.new
    @edit_to_save = Qt::SignalMapper.new self
    set_ducks
    connect @edit_to_save, SIGNAL('mapped(int)'), self, SLOT('save_duck(int)')

    vbox.addLayout @all_ducks
    vbox.addStretch 1

    new_box = Qt::HBoxLayout.new
    @new_edit = Qt::LineEdit.new self
    new_box.addWidget @new_edit
    new_button = Qt::PushButton.new "Create", self
    new_box.addWidget new_button
    connect new_button, SIGNAL('clicked()'), self, SLOT('create_duck()')
    vbox.addLayout new_box

    hbox = Qt::HBoxLayout.new
    button_quit = Qt::PushButton.new 'Quit', self
    hbox.addWidget button_quit, 1, Qt::AlignLeft
    vbox.addLayout hbox

    connect button_quit, SIGNAL('clicked()'), $qApp, SLOT('quit()')
  end

  def set_ducks
    @edits = []
    @movement.data[:persons].each do |person|
      add_edit(person[1])
    end
  end

  def add_edit(name)
    nr_edits = @edits.size
    layout = Qt::HBoxLayout.new
    edit = Qt::LineEdit.new name, self
    @edits << edit
    layout.addWidget edit
    button = Qt::PushButton.new "Save", self
    layout.addWidget button
    connect button, SIGNAL('clicked()'), @edit_to_save, SLOT('map()')
    @edit_to_save.setMapping(button, nr_edits)
    @all_ducks.addLayout layout
  end

  def save_duck(ix)
    @movement.change_person(ix, @edits[ix].text)
  end

  def create_duck
    new_name = @new_edit.text
    if new_name && ! new_name.empty?
      @movement.add_person(@new_edit.text)
      add_edit(new_name)
    end
  end
end

app = Qt::Application.new ARGV
DuckEntry.new(Filename)
app.exec
