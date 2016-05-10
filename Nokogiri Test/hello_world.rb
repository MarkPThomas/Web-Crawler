require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'net/https'
require 'fileutils'

# See: http://ruby.bastardsbook.com/chapters/html-parsing/
# See: http://ruby.bastardsbook.com/chapters/web-crawling/

DATA_DIR = "data-hold/nobel"
FileUtils::mkdir_p(DATA_DIR) unless File.exists?(DATA_DIR)

BASE_WIKIPEDIA_URL = "https://en.wikipedia.org"
LIST_URL = "#{BASE_WIKIPEDIA_URL}/wiki/List_of_Nobel_laureates"

HEADERS_HASH = {"User-Agent" => "Ruby/#{RUBY_VERSION}"}

page = Nokogiri::HTML(open(LIST_URL,  :ssl_verify_mode => OpenSSL::SSL::VERIFY_NONE))
rows = page.css('div.mw-content-ltr table.wikitable tr')

rows[1..-2].each do |row|

  hrefs = row.css("td a").map{ |a|
    a['href'] if a['href'] =~ /^\/wiki\//
  }.compact.uniq

  hrefs.each do |href|
    remote_url = BASE_WIKIPEDIA_URL + href
    local_fname = "#{DATA_DIR}/#{File.basename(href)}.html"
    unless File.exists?(local_fname)
      puts "Fetching #{remote_url}..."
      begin
        #wiki_content = open(remote_url, HEADERS_HASH).read
        wiki_content = open(remote_url,  :ssl_verify_mode => OpenSSL::SSL::VERIFY_NONE).read
      rescue Exception=>e
        puts "Error: #{e}"
        sleep 5
      else
        File.open(local_fname, 'w'){|file| file.write(wiki_content)}
        puts "\t...Success, saved to #{local_fname}"
      ensure
        sleep 1.0 + rand
      end  # done: begin/rescue
    end # done: unless File.exists?

  end # done: hrefs.each
end # done: rows.each