require 'Qt'
require './movement'

class DbList < Qt::ComboBox
  def initialize(db, table, display_indices, parent_info = nil)
    super()
    @db = db
    @table = table
    @display_indices = display_indices
    @parent_info = parent_info
    @ids = []
    update_list
  end

  def display_str(row)
    row.values_at(*@display_indices).join(", ")
  end

  def update_list(parent_id = nil)
    value_list = []
    clear
    if @parent_info
      if parent_id
        @ids = @db.get_all_with(@parent_info[:table], @parent_info[:id_column], @parent_info[:column], parent_id)
        @db.get_multiple(@table, @ids).each do |row|
          addItem(display_str(row))
        end
      end
    else
      @ids = []
      @db.get_all(@table).each do |row|
        @ids << row[0]
        addItem(display_str(row))
      end
    end
    if count > 0
      if currentIndex == 0
        emit currentIndexChanged(0)
      else
        setCurrentIndex(0)
      end
    end
  end

  def id_from_ix(ix)
    @ids[ix]
  end
end
