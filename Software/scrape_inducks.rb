
require 'open-uri'
require 'nokogiri'

DDSH = "http://coa.inducks.org/issue.php?c=de%2FTGDD++"

class ResultTable

end

def get_ddsh(nr)
  # agent = Mechanize.new
  #
  url = "#{DDSH}#{nr}"
  return url
  doc = Nokogiri::HTML(open(url))
  # doc = agent.get(url)
  found = false

  doc.search('table.boldtable > tr').each do |row|
    found = true
    cols = row.search("//td")
    puts cols.size
    if cols.size == 7
      puts cols[0].inspect
    end
  end

  unless found
    puts "Problem encountered"
    puts doc.inspect
  end

  found
end

if $0 == __FILE__
  puts get_ddsh(119).inspect
end


