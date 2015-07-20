require 'sqlite3'

class DuckMovement
  attr_reader :data

  ColumnNames = {
    :books => [:id, :name, :volume],
    :stories => [:id, :name, :year, :name_de, :inducks_id],
    :stories_in_books => [:id, :story_id, :book_id, :page_start, :page_end],
    :movements => [:id, :movers, :origin_place, :origin_time, :destination_place, :destination_time, :movement_mode, :purpose, :comment, :story_id],
    :persons => [:id, :name],
    :person_movement => [:movement_id, :person_id]
  }

  def initialize(filename)
    @db = SQLite3::Database.new(filename)
    @data = {}
    ColumnNames.keys.each {|table| @data[table] = @db.execute "select * from #{table}"}
    update_index
  end

  def update_index(changed = :all)
    @person_index = create_index(:persons, :name, :id) if changed == :all || changed == :persons
    @story_index = create_id_index(:stories) if changed == :all || changed == :stories
  end

  def add(table, row)
    table_sym = table.to_sym
    cols = ColumnNames[table_sym].dup.delete_if {|x| x == :id}
    if cols
      sql = "insert into #{table_sym} (#{cols.join(', ')}) values (#{qm(cols.size)})"
      @db.execute sql, row
      # @db.execute "insert into #{table_sym} (#{cols.join(', ')}) values (#{qm(cols.size)})", row
      oid = @db.last_insert_row_id
      @data[table_sym] << (oid ? [oid] + row : row)
      update_index(table_sym)
    else
      raise "Unknown table name #{table}"
    end
  end

  def change(table, col_name, col_value, id)
    sql = "update #{table} set #{col_name} = ? where id = ?;"
    @db.execute sql, [col_value, id]
  end

  def qm(nr)
    (["?"] * nr).join(', ')
  end

  def add_movement(movement, persons, story_id)
    movement << story_id
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

  def remove_person_movement(mid, pid)
    sql = "delete from person_movement where movement_id = ? and person_id = ?;"
    @data[:person_movement].delete_if {|pm| pm[0] == mid && pm[1] == pid}
    @db.execute sql, [mid, pid]
  end

  def add_person(name)
    add(:persons, [name])
    pid = @db.last_insert_row_id
    data[:person] << [pid, name]
  end

  def change_person(ix, new_name)
    item = @data[:persons][ix]
    if item[1] != new_name
      item[1] = new_name
      change(:persons, :name, new_name, item[0])
    end
  end

  def create_index(table, key_col, id_col = :id)
    result = {}
    ix_key = ColumnNames[table].index(key_col)
    ix_value = ColumnNames[table].index(id_col)
    @data[table].each {|row| result[row[ix_key]] = row[ix_value]}
    result
  end

  def create_id_index(table, id_col = :id)
    result = {}
    id_key = ColumnNames[table].index(id_col)
    @data[table].each {|row| result[row[id_key]] = row}
    result
  end

  def story_by_id(sid)
    @story_index[sid]
  end

  def movements_by_story(sid)
    result = []
    @data[:movements].each {|mov| result << mov if mov[9] == sid}
    result
  end

  def persons_by_movement(mid)
    result = []
    @data[:person_movement].each {|pm| result << pm[1] if pm[0] == mid}
    result
  end

  def movement_by_id(mid)
    @data[:movements].each {|mov| return mov if mov[0] == mid}
    nil
  end

  def get_book_by_id(bid)
    @data[:books].each {|b| return b if b[0] == bid}
  end
end

if $0 == __FILE__
  dm = DuckMovement.new "../Data/duck_movement.db"
  puts dm.inspect
end
