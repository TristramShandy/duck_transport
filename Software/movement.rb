require 'sqlite3'

class DuckMovement
  attr_reader :data

  ColumnNames = {
    :books => [:id, :name, :volume],
    :stories => [:id, :name],
    :stories_in_books => [:id, :story_id, :book_id, :page_start, :page_end],
    :movements => [:id, :movers, :origin_place, :origin_time, :destination_place, :destination_time, :movement_mode, :purpose, :comment, :story_id],
    :persons => [:id, :name],
    :person_movement => [:movement_id, :person_id]
  }

  def initialize(filename)
    @db = SQLite3::Database.new(filename)
    @data = {}
    ColumnNames.keys.each {|table| @data[table] = @db.execute "select * from #{table}"}
    @person_index = create_index(:persons, :name, :id)
  end

  def add(table, row)
    table_sym = table.to_sym
    cols = ColumnNames[table_sym].dup.delete_if {|x| x == :id}
    if cols
      sql = "insert into #{table_sym} (#{cols.join(', ')}) values (#{qm(cols.size)})"
      @db.execute sql, row
      # @db.execute "insert into #{table_sym} (#{cols.join(', ')}) values (#{qm(cols.size)})", row
      @data[table_sym] << row
    else
      raise "Unknown table name #{table}"
    end
  end

  def qm(nr)
    (["?"] * nr).join(', ')
  end

  def add_movement(movement, persons, story_index)
    movement << @data[:stories][story_index][0]
    add(:movements, movement)
    mid = @db.last_insert_row_id
    persons.each do |name|
      if @person_index[name]
        add(:person_movement, [mid, @person_index[name]])
      else
        raise "Unknown person name #{name}"
      end
    end
  end

  def create_index(table, key_col, id_col = :id)
    result = {}
    ix_key = ColumnNames[table].index(key_col)
    ix_value = ColumnNames[table].index(id_col)
    @data[table].each {|row| result[row[ix_key]] = row[ix_value]}
    result
  end
end

if $0 == __FILE__
  dm = DuckMovement.new "../Data/duck_movement.db"
  puts dm.inspect
end
