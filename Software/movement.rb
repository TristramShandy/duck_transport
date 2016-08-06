require 'sqlite3'

class DuckMovement
  ColumnNames = {
    :books => [:id, :name, :volume],
    :stories => [:id, :name, :year, :name_de, :inducks_id],
    :stories_in_books => [:id, :story_id, :book_id, :page_start, :page_end],
    :movements => [:id, :movers, :origin_place, :origin_time, :destination_place, :destination_time, :movement_mode, :purpose, :comment, :story_id, :trip_index],
    :persons => [:id, :name],
    :person_movement => [:movement_id, :person_id]
  }

  def initialize(filename)
    @db = SQLite3::Database.new(filename)
  end


  def add(table, row)
    table_sym = table.to_sym
    cols = ColumnNames[table_sym].dup.delete_if {|x| x == :id}
    if cols
      sql = "insert into #{table_sym} (#{cols.join(', ')}) values (#{qm(cols.size)})"
      @db.execute sql, row
      oid = @db.last_insert_row_id
    else
      raise "Unknown table name #{table}"
    end
  end

  def change(table, col_name, col_value, id)
    sql = "update #{table} set #{col_name} = ? where id = ?;"
    @db.execute sql, [col_value, id]
  end

  def get(table, id)
    sql = "select * from #{table} where id = ?"
    @db.execute(sql, [id])[0]
  end

  def get_multiple(table, ids)
    sql = "select * from #{table} where id in (#{qm(ids.size)})"
    @db.execute(sql, [ids])
  end

  def get_all(table)
    sql = "select * from #{table}"
    @db.execute(sql)
  end

  def get_all_with(table, id_column, column, condition)
    sql = "select #{id_column} from #{table} where #{column} = #{condition}"
    @db.execute(sql).flatten
  end

  def get_first(table)
    sql = "select * from #{table} limit 1"
    @db.execute(sql)[0]
  end

  def qm(nr)
    (["?"] * nr).join(', ')
  end

  def add_movement(movement_pre, persons, story_id)
    movement = movement_pre[0...-1] + [story_id, movement_pre[-1]]
    add(:movements, movement)
    @db.last_insert_row_id
  end

  def remove_person_movement(mid, pid)
    sql = "delete from person_movement where movement_id = ? and person_id = ?;"
    @db.execute sql, [mid, pid]
  end

  def add_person(name)
    sql = "insert into persons (name) values (?)"
    @db.execute sql, [name]
    @db.last_insert_row_id
  end

  def change_person(ix, new_name)
    sql = "update persons set name = ? where id = ?"
    @db.execute sql, [new_name, ix]
  end

  def movements_by_story(sid)
    sql = "select * from movements where story_id = ?"
    @db.execute(sql, [sid])
  end

  def persons_by_movement(mid)
    sql = "select person_id from person_movement where movement_id = ?"
    @db.execute(sql, [mid]).flatten
  end

  def story_ids_from_book(bid)
    sql = "select story_id from stories_in_books where book_id = ?"
    @db.execute(sql, [bid]).flatten
  end
end

if $0 == __FILE__
  dm = DuckMovement.new "../Data/duck_movement.db"
  puts dm.inspect
end
