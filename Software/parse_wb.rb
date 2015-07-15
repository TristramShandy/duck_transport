
require 'nokogiri'
require 'yaml'
require 'gruff'

DataDirectory = "../Data"
WikipediaPageFilename = File.join(DataDirectory, "carl_barks_story_list_wikipedia.htm")
ReCB = /Carl Barks/

PlotSize = 800
PlotName = "barks_per_year.png"

class StoryInfo
  attr_reader :year, :name, :pages, :story_code

  def initialize(columns)
    date_str = columns[1].at_xpath("span[@class='sortkey']").content
    @year = date_str.sub(/^0*/, '').sub(/-.*/, '').to_i
    @name = columns[2].content
    @pages = columns[3].content.to_i
    @story_code = columns[7].content
  end
end

def parse_wb(filename, mode = :strict)
  result = []
  doc = Nokogiri::HTML(File.read(filename))
  lines = doc.xpath("//table/tr")
  lines[1..-1].each do |info|
    columns = info.xpath("td")
    is_art = columns[5].content =~ ReCB
    is_script = columns[6].content =~ ReCB
    case mode
    when :strict
      result << StoryInfo.new(columns) if is_art && is_script
    when :art
      result << StoryInfo.new(columns) if is_art
    when :script
      result << StoryInfo.new(columns) if is_script
    when :all
      result << StoryInfo.new(columns)
    end
  end
  result
end

def plot_counts(stories, min_nr_pages = 2)
  counts = {}
  stories.each do |story|
    if story.pages >= min_nr_pages
      counts[story.year] ||= 0
      counts[story.year] += 1
    end
  end
  min_year = counts.keys.min
  max_year = counts.keys.max

  heights = (min_year..max_year).map {|y| counts[y].to_i}
  labels = {}
  (min_year..max_year).each {|y| labels[y - min_year] = y.to_s if y % 5 == 0}

  g = Gruff::Bar.new(PlotSize)
  g.y_axis_increment = 5
  g.title = "Multipage stories per year"
  g.labels = labels
  g.data(:nr, heights)
  g.write(PlotName)
end

if $0 == __FILE__
  plot_counts parse_wb(WikipediaPageFilename, :strict)
  # stories.delete_if {|story| story.pages < 2}
  # puts stories.map {|s| s.year}.inspect
  # puts stories.size
end
