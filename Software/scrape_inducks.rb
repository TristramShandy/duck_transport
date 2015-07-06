
require 'open-uri'
require 'nokogiri'

UrlPrefix = "http://coa.inducks.org/"
DDSH = "issue.php?c=de%2FTGDD++"
ReFindBarks = /Writing:.*Carl Barks.*Art:.*Carl Barks/

StoryData = Struct.new(:name, :year, :name_de, :inducks_id)

def get_story(url, story_id, name_de = nil)
  puts "  #{url}  -> #{story_id} #{name_de}"
  name = "???"
  year = "????"
  StoryData.new(name, year, name_de, story_id)
end

def get_ddsh(issue)
  # agent = Mechanize.new
  text = nil
  if Fixnum === issue
    text = open("#{UrlPrefix}#{DDSH}#{issue}")
  else
    text = File.open(issue)
  end
  doc = Nokogiri::HTML(text)
  # doc = agent.get(url)
  found = false
  result = []

  doc.search('table.boldtable').each do |table|
    table.search('tr').each do |row|
      found = true
      cols = row.search("td")
      if cols.size == 7
        if cols[3].content =~ ReFindBarks
          links = cols[0].search('a')
          if links.size > 1
            name_de = cols[1].search('i')[0].content
            story_url = UrlPrefix + links[1]["href"]
            story_id = links[1].content
            result << get_story(story_url, story_id, name_de)
          end
        end
      end
    end
  end

  unless found
    puts "Problem encountered"
    puts doc.inspect
    return nil
  end

  result
end

if $0 == __FILE__
  # puts get_ddsh(119).inspect
  puts get_ddsh("issue_test.html").inspect
end


