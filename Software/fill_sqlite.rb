# transfer data from csv to sqlite

require 'set'
require 'sqlite3'

DataFile = "WDCaSbCB"
DbFile = "duck_movement.db"

UseDataLines = /^[0-9]/
RecordSplit = ";"
VolLine = /^Vol (\d+)/

VolumeNames = "Walt Disney's Comics and Stories"

Movement = Struct.new(:movers, :origin_place, :origin_time, :destination_place, :destination_time, :movement_mode, :purpose, :comment) do
  def to_a
    [:movers, :origin_place, :origin_time, :destination_place, :destination_time, :movement_mode, :purpose, :comment].map {|sym| self[sym]}
  end
end

MovementIndices = [1, 2, 5, 3, 6, 4, 7, 8]

class DbInfo
  def initialize(filename)
    @filename = filename
    @stories = {}
    @movements = {}
  end

  def add(record)
    vol = record[:vol]
    sid = record[:data][0].to_i
    @stories[vol] ||= Set.new
    @stories[vol] << sid
    key = [vol, sid]
    @movements[key] ||= Array.new
    @movements[key] << Movement.new(* record[:data].values_at(*MovementIndices))
  end

  def commit
    db = SQLite3::Database.new(@filename)
    @stories.keys.each do |vol|
      db.execute("insert into books (id, name, volume) values(?, ?, ?)", [vol, VolumeNames, vol])
    end

    vi_to_id = {}
    story_key = 1
    @stories.each do |vol, story_indices|
      story_indices.each do |ix|
        db.execute("insert into stories (id) values (?)", [story_key])
        db.execute("insert into stories_in_books (book_id, story_id) values (?, ?)", [vol, story_key])
        vi_to_id[ [vol, ix] ] = story_key
        story_key += 1
      end
    end

    @movements.each do |key, moves|
      moves.each do |mov|
        db.execute("insert into movements (movers, origin_place, origin_time, destination_place, destination_time, movement_mode, purpose, comment, story_id) values (?, ?, ?, ?, ?, ?, ?, ?, ?)", mov.to_a + [vi_to_id[key]])
      end
    end
  end

  def to_s
    @movements.inspect
  end
end

def read_data(filename)
  vol = nil 
  File.read(filename).split("\n").each do |line|
    if line =~ VolLine
      vol = $1.to_i
    elsif line =~ UseDataLines
      yield({:vol => vol.to_i, :data => line.split(RecordSplit)})
    end
  end
end

if $0 == __FILE__
  info = DbInfo.new(DbFile)
  read_data(DataFile) {|record| info.add(record)}
  info.commit
end
