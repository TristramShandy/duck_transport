require 'Qt'
require './movement'

class DbList < Qt::ComboBox
  def initialize(db, table, display_col, parent_table = nil, parent_table_column = "parent_id")
    super()
    @db = db
    @table = table
    @display_col = display_col
    @parent_table = parent_table
    @parent_table_column = parent_table_column
    @ids = []
    @selected = nil
    update_list
  end

  def update_list(parent_id = nil)
    value_list = []
    if parent_table
      if parent_id
        value_list = db.get_all_with(table, parent_table_column, parent_id)
      end
    else
      value_list = db.get_all(table)
    end
    @ids = value_list.map {|entry| entry[0]}
  end
end
