require 'nokogiri'
require_relative '../lib/SummitPostScrape'
require_relative '../lib/LibFileReadWrite'

DATA_DIR = 'data-hold/summitPost'
FileUtils::mkdir_p(DATA_DIR) unless File.exists?(DATA_DIR)

BASE_URL = 'http://www.summitpost.org'
PROFILE_URL = '/users/pellucidwombat/12893'

HOME_PAGE = BASE_URL + PROFILE_URL
TEST_DIR = '/test-data'

# ================================
# Testing methods
# ================================
def run_tests
  puts 'Running tests'

  test_data_dir = "#{DATA_DIR}#{TEST_DIR}"

#Clear and remake test data directory
  FileUtils::rm_rf(test_data_dir) if File.exists?(test_data_dir)
  sleep(0.2)
  FileUtils::mkdir_p(test_data_dir) unless File.exists?(test_data_dir)

# URLs really tough to group a priori based on website layout
# Easiest to just get all URLs from the lists, then classify them when visiting their pages.
  puts "Getting object URLs from profile page #{HOME_PAGE}"
  object_urls = get_object_urls_from_profile(HOME_PAGE)
  object_urls.keys.each { |url|  append_hash("#{test_data_dir}/object_urls.txt", object_urls[url])}

# Tick URLs can be classified on the fly as they have a predictable and unique substring in their URLs
  puts "Getting tick URLs from profile page #{HOME_PAGE}"
  tick_urls = get_tick_urls_from_profile(HOME_PAGE)
  tick_urls.keys.each { |tick|  append_hash("#{test_data_dir}/tick_urls.txt", tick_urls[tick])}

# Read Climber Logs
  climber_log_url = 'http://www.summitpost.org/devil-s-golf-ball/climbers-log/247651/d-146721#146721'
  puts "Getting climber log from #{climber_log_url}"
  climber_logs = read_climbers_log_page(climber_log_url, PROFILE_URL)
  climber_logs.keys.each { |log|  append_hash("#{test_data_dir}/climber_log.txt", climber_logs[log])}

# Type: Mountain/Rock
  mountain_rock_url = 'http://www.summitpost.org/four-gables/153695'
  puts "Getting mountain/rock from #{mountain_rock_url}"
  page = Nokogiri::HTML(open(mountain_rock_url))
  read_write_page_by_type(page, mountain_rock_url, test_data_dir)

# Type: Route (rock)
  route_url = 'http://www.summitpost.org/selaginella/283772'
  puts "Getting rock route from #{route_url}"
  page = Nokogiri::HTML(open(route_url))
  read_write_page_by_type(page, route_url, test_data_dir)

# Type: Route (my rating)
  route_url = 'http://www.summitpost.org/green-butte-ridge/157170'
  puts "Getting route I rated from #{route_url}"
  page = Nokogiri::HTML(open(route_url))
  read_write_page_by_type(page, route_url, test_data_dir)


# Type: Article
  article_url = 'http://www.summitpost.org/glaciers/700719'
  puts "Getting article from #{article_url}"
  page = Nokogiri::HTML(open(article_url))
  read_write_page_by_type(page, article_url, test_data_dir)

# Type: Trip Report
  trip_report_url = 'http://www.summitpost.org/war-path-on-warbonnet-ne-face-left/843342'
  puts "Getting trip report from #{trip_report_url}"
  page = Nokogiri::HTML(open(trip_report_url))
  read_write_page_by_type(page, trip_report_url, test_data_dir)

# Type: Area/Range
  area_range_url = 'http://www.summitpost.org/ouray-ice-park-colorado/164486'
  puts "Getting area/range from #{area_range_url}"
  page = Nokogiri::HTML(open(area_range_url))
  read_write_page_by_type(page, area_range_url, test_data_dir)

# Type: Trailhead
  trip_report_url = 'http://www.summitpost.org/white-pine-trailhead/627226'
  puts "Getting trailhead from #{trip_report_url}"
  page = Nokogiri::HTML(open(trip_report_url))
  read_write_page_by_type(page, trip_report_url, test_data_dir)

# Type: Canyon
  canyon_url = 'http://www.summitpost.org/little-cottonwood-canyon/154313'
  puts "Getting canyon from #{canyon_url}"
  page = Nokogiri::HTML(open(canyon_url))
  read_write_page_by_type(page, canyon_url, test_data_dir)

# Type: Other
  nil_url = 'http://www.summitpost.org/my-list-o-climbs/660859'
  puts "Getting data from unsupported object from #{nil_url}"
  page = Nokogiri::HTML(open(nil_url))
  read_write_page_by_type(page, nil_url, test_data_dir)
end


# ================================
# Scraping all
# ================================
def scrape_all
  puts 'Running full scrape'

# Scrape all logs
  tick_urls_array = scrape_all_logs

# Scrape all ticked pages
  scrape_all_ticked_pages(tick_urls_array)

# Scrape all personal pages
  scrape_all_personal_pages
end

def scrape_all_logs
  puts 'Scraping all climber logs ...'
  tick_urls_array = []
  tick_urls = get_tick_urls_from_profile(HOME_PAGE)
  tick_urls.keys.each { |key|
    tick_urls_array[tick_urls_array.count] = "#{BASE_URL}#{tick_urls[key][:link_url]}"
  }
  read_write_climber_logs(tick_urls_array, PROFILE_URL, DATA_DIR)

  tick_urls_array
end

def scrape_all_ticked_pages(tick_urls_array)
  puts 'Scraping all pages of ticked objects ...'
  read_write_pages_ticked(tick_urls_array, PROFILE_URL, DATA_DIR)
end

def scrape_all_personal_pages
  puts 'Scraping all personal pages ...'
  personal_urls_array = []
  object_urls = get_object_urls_from_profile(HOME_PAGE)
  object_urls.keys.each { |key|
    personal_urls_array[personal_urls_array.count] = "#{BASE_URL}#{object_urls[key][:link_url]}"
  }
  read_write_pages_personal(personal_urls_array, DATA_DIR)
end



run_tests
scrape_all

puts 'Website scrape complete.'