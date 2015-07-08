# transfer book and story data from yaml to sqlite

require 'set'
require 'sqlite3'
require 'yaml'

# DbFile = "../Data/duck_movement.db"
DbFile = "../Data/duck_movement_test.db"

def usage
  puts "usage: ruby fill_stories.rb story_file.yml [story_file2.yml ...]"
  puts "  transfers the book and story information from the yaml files to the sqlite database"
end

def yaml_to_db(filename)
  db = SQLite3::Database.new(DbFile)
  yaml = YAML::load(File.read(filename))
  yaml.each do |book|
    db.execute("insert into books (name, volume) values (?, ?);", book[:name], book[:vol])
    book_id = db.last_insert_row_id
    book[:stories].each do |story|
      db.execute("insert into stories (name, year, name_de, inducks_id) values (?, ?, ?, ?);", story[:name], story[:year], story[:name_de], story[:inducks_id])
      story_id = db.last_insert_row_id
      db.execute("insert into stories_in_books (story_id, book_id) values (?, ?);", story_id, book_id)
    end
  end
end

if $0 == __FILE__
  if ARGV.empty?
    usage
    exit(0)
  end

  ARGV.each {|filename| yaml_to_db(filename)}
end
