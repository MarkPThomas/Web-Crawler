require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'net/https'
require 'fileutils'

# See: http://ruby.bastardsbook.com/chapters/html-parsing/
# See: http://ruby.bastardsbook.com/chapters/web-crawling/

DATA_DIR = "data-hold/sumimtPost"
FileUtils::mkdir_p(DATA_DIR) unless File.exists?(DATA_DIR)

BASE_URL = "http://www.summitpost.org/"
LIST_URL = "#{BASE_URL}/users/pellucidwombat/12893"  #Works
#LIST_URL = "http://www.summitpost.org/west-ridge/640956"  #Works

page = Nokogiri::HTML(open(LIST_URL,  :ssl_verify_mode => OpenSSL::SSL::VERIFY_NONE))
rows = page.css('table.objectList tr')