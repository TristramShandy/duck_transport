
require 'open-uri'
require 'nokogiri'
require 'yaml'

UrlPrefix = "http://www.barksbase.de/deutsch/"
DataDirectory = "../Data"
Bookname = "Die tollsten Geschichten von Donald Duck"
DDName = "Donald Duck Sonderheft"

StoryData = Struct.new(:name, :year, :name_de, :inducks_id)

TargetIssues = "../Data/dds.txt"

class DuckException < RuntimeError
end

def dd_list_filename(issue)
  page = case issue
         when 1..49
           "bbttgdd1.htm"
         when 50..109
           "bbttgdd2.htm"
         when 110..Float::INFINITY
           "bbttgdd3.htm"
         else
           raise DuckException.new("Unknown issue #{issue}")
         end
  File.join(DataDirectory, page)
end

def get_id_tag(url)
  if url =~ /(.*)#(.*)/
    $2
  end
end

def url_to_inducks_id(url)
  url.split('/')[-1].gsub(/\++/, " ")
end

def parse_infoline(line)
  if line =~ /E: (\d\d\d\d)/
    $1.to_i
  else
    raise DuckException.new("Unable to parse infoline #{line}")
  end
end

def get_story(url, name_de = nil)
  text = open("#{UrlPrefix}#{url}")

  # # DEBUG
  # return {} unless url =~ /us_39/
  # text = File.read(File.join(DataDirectory, "us39.htm"))

  doc = Nokogiri::HTML(text)
  tag = get_id_tag(url)
  info = doc.xpath("//a[@name='#{tag}']/../..")
  raise DuckException.new("Bad info for url #{url}") if info.empty?
  name = info.search("span")[0].content
  inducks_id = url_to_inducks_id(info.xpath("a[@target='inducks']")[0]["href"])

  infoline = info.xpath("../div[@class='bbcinfo']")[0].content
  year = parse_infoline(infoline)
  StoryData.new(name, year, name_de, inducks_id).to_h
end

def get_ddsh(issue)
  $stderr.puts ".. #{issue}"
  doc = Nokogiri::HTML(File.read(dd_list_filename(issue)))
  x_table = doc.xpath("//th[a='#{Bookname} #{issue}']/../..")
  if x_table.empty?
    $stderr.puts "Warning: empty x_table for issue #{issue}"
    return []
  end
  result = []
  x_table[0].next_element.xpath("tr/td/table/tbody/tr").each do |node|
    begin
      cols = node.search("td")
      raise DuckException.new("Malformed columns") if cols.size != 6
      unless cols[2].content =~ /Cover/
        name_de = cols[1].content
        links = cols[5].search('a')
        url = links[0]["href"]
        result << get_story(url, name_de)
      end
    rescue DuckException => msg
      $stderr.puts "Warning for issue #{issue}"
      $stderr.puts "  #{msg}"
    end
  end
  raise DuckException.new("Did not find issue #{issue}") if result.empty?
  result
end

def all_issues(filename)
  issues = File.read(filename).split("\n").map {|str| str.to_i}.uniq
  issues.map {|issue| {:name => DDName, :vol => issue, :stories => get_ddsh(issue)}}
end

if $0 == __FILE__
  puts all_issues(TargetIssues).to_yaml
  # puts get_ddsh(50).inspect
end

