# encoding: ISO-8859-1

require 'open-uri'
require 'nokogiri'
require 'yaml'

# TargetSymbols = [:cbl_usa, :cbl_dda, :cbl_ggcf, :cbl_ddcg, :cbl_uscop, :cbl_wdcs, :bcs]
TargetSymbols = [:bcs]
TitleInfo = Struct.new(:symbol, :name, :bookname, :issues)

DdsTitles = [
50, 51, 57, 58, 64, 66, 66, 67, 68, 70, 71, 74, 75, 76, 77, 78, 79, 80, 81, 82,
83, 85, 86, 87, 89, 90, 90, 91, 92, 92, 93, 94, 95, 95, 96, 97, 100, 103, 106,
106, 107, 107, 109, 112, 113, 116, 116, 117, 117, 118, 118, 119, 119, 120, 120,
121, 121, 122, 122, 123, 124, 124, 127, 129, 130, 130, 132, 132, 133, 134, 137,
139, 142, 144, 160, 169, 219, 234, ]

DdsName = "Donald Duck Sonderheft"
DdsBookname = "Die tollsten Geschichten von Donald Duck"
KlassikName = "Die besten Geschichten mit Donald Duck - Klassik Album"
IodName = "Ich Onkel Dagobert"
IddName = "Ich Donald Duck"
CblUsaName = "The Carl Barks Library in Color - Uncle Scrooge Adventures"
CblUsaBookname = "CBLC-USA"
CblDdaName = "The Carl Barks Library in Color - Donald Duck Adventures"
CblDdaBookname = "CBLC-DDA"
CblGgcfName = "The Carl Barks Library in Color - Gyro Gearlose Comics and Fillers"
CblGgcfBookname = "CBLC-GG"
CblDdcgName = "The Carl Barks Library in Color - Donald Duck Christmas Giveaways"
CblDdcgBookname = "CBLC-FCG"
CblUscopName = "The Carl Barks Library in Color - Uncle Scrooge Comics One Pagers"
CblUscopBookname = "CBLC-USOP"
CblWdcsName = "The Carl Barks Library in Color - Walt Disney's Comics and Stories"
CblWdcsBookname = "CBLC-WDC"
BcsName = "Barks Comics & Stories"
BcsBookname = "Barks Comics & Stories"

Titles = [
  TitleInfo.new(:dds, DdsName, DdsBookname, DdsTitles),
  TitleInfo.new(:klassik, KlassikName, KlassikName, (1..20).to_a),
  TitleInfo.new(:idd, IddName, IddName, [1]),
  TitleInfo.new(:iod, IodName, IodName, [1]),
  TitleInfo.new(:cbl_usa, CblUsaName, CblUsaBookname, [1]),
  TitleInfo.new(:cbl_dda, CblDdaName, CblDdaBookname, [1]),
  TitleInfo.new(:cbl_ggcf, CblGgcfName, CblGgcfBookname, [1]),
  TitleInfo.new(:cbl_ddcg, CblDdcgName, CblDdcgBookname, [1]),
  TitleInfo.new(:cbl_uscop, CblUscopName, CblUscopBookname, [1, 2]),
  TitleInfo.new(:cbl_wdcs, CblWdcsName, CblWdcsBookname, [1]),
  TitleInfo.new(:bcs, BcsName, BcsBookname, [2, 4, 6, 7, 9, 10]),
]

UrlPrefix = "http://www.barksbase.de/deutsch/"
DataDirectory = "../Data"

StoryData = Struct.new(:name, :year, :name_de, :inducks_id)

ReCBLTitel = /CBL-Titel[^a-zA-Z]*([a-zA-Z"' ]*)/

class DuckException < RuntimeError
end

def dd_list_filename(symbol, issue)
  case symbol
  when :dds
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
  when :klassik
    page = "bbtka.htm"
  when :idd
    page = "idd.htm"
  when :iod
    page = "iod.htm"
  when :cbl_usa, :cbl_dda, :cbl_ggcf, :cbl_ddcg, :cbl_uscop, :cbl_wdcs, :bcs
    page = "#{symbol}.htm"
  else
    raise DuckException.new("Unknown symbol #{symbol}")
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
  elsif line =~ /V: (\d\d\d\d)/
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

  name = nil
  info[0].xpath("../div[@class='bbccomment']").each do |node|
    if node.content =~ ReCBLTitel
      name = $1
    end
  end
  name = info.search("span")[0].content unless name
  inducks_id = url_to_inducks_id(info.xpath("a[@target='inducks']")[0]["href"])

  infoline = info.xpath("../div[@class='bbcinfo']")[0].content
  year = parse_infoline(infoline)
  StoryData.new(name, year, name_de, inducks_id).to_h
end

def get_book_ddsh(doc, title_info, issue)
  x_table = doc.xpath("//th[a='#{title_info[:bookname]} #{issue}']/../..")
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

def get_cbl_ddsh(doc, title_info, issue)
  x_info = doc.xpath("//strong[a='#{title_info[:bookname]} #{issue}']/../../div[@class='bbipub']/a")
  if x_info.empty?
    $stderr.puts "Warning: empty x_info for issue #{issue}"
    return []
  end
  x_info.map {|info| get_story(info["href"])}
end

def get_ddsh(title_info, issue)
  symbol = title_info[:symbol]
  $stderr.puts ".. #{symbol} #{issue}"
  doc = Nokogiri::HTML(File.read(dd_list_filename(symbol, issue)))
  if symbol.to_s =~ /^cbl_/
    get_cbl_ddsh(doc, title_info, issue)
  else
    get_book_ddsh(doc, title_info, issue)
  end
end

def all_issues(symbols)
  result = []
  Titles.each do |title|
    if symbols.include? title[:symbol]
      symbol = title[:symbol]
      title[:issues].each do |issue|
        result << {:name => title[:name], :vol => issue, :stories => get_ddsh(title, issue)}
      end
    end
  end
  result
end

if $0 == __FILE__
  puts all_issues(TargetSymbols).to_yaml
end

