require 'rubygems'
require 'mechanize'
require 'nokogiri'
require 'open-uri'
require 'fileutils'
require_relative '../../lib/LibFileReadWrite'

# See: http://ruby.bastardsbook.com/chapters/html-parsing/
# See: http://ruby.bastardsbook.com/chapters/web-crawling/

BASE_URL = 'http://www.summitpost.org'
ROUTE_SEARCH_URL = '/object_list.php'

# SummitPost star ratings are on a scale of 0-5
MAX_STAR_RATING = 5

# ================================
# Supporting Methods: Entry Points: Search Results
# ================================
def search_route_reference(search_term)
  puts "Searching for route: #{search_term}"
  search_reference(search_term, 'Routes')
end

def search_peak_reference(search_term)
  puts "Searching for peak: #{search_term}"
  search_reference(search_term, 'Mountains & Rocks')
end

def search_reference(search_term, search_type)
  search_results = {}

  case search_type
    when 'Routes'
      search_type_code = 2
    when 'Mountains & Rocks'
      search_type_code = 1
    else
      search_type_code = 0
  end

  a = Mechanize.new { |agent|
    # Redirects after submission
    agent.follow_meta_refresh = true
  }

  a.get(BASE_URL + ROUTE_SEARCH_URL) { |search_page|

    my_results = search_page.form_with(:name => 'object_list'){ |form|
      form.object_type = search_type_code
      form.object_name_0 = search_term
      form.object_name_1 = search_term
      form.object_name_2 = search_term
      # form.search_select_2 = name_only' #'Name Only'
      # form.map_2 = 'List Format' #'List Format'
      # form.continent_2 = 'All'
      # form.country_2 = 'All'
      # form.state_province_2 = 'All'
      # form.route_type_2 = 'All'
      # form.low_rock_difficulty_2 = 'All'
      # form.high_rock_difficulty_2 = 'All'
      # form.low_grade_2 = 'All'
      # form.high_grade_2 = 'All'
      # form.distance_2 = 'Any'
      # form.distance_type_2 = 'Miles'
      # form.distance_city_2 = 'City, State or US Zip'
      # form.distance_lat_2 = 'Latitude'
      # form.distance_lon_2 = 'Longitude'
      # form.within_last_2 = 'All'
      # form.sort_select_2 = 'object_name' # 'Object Title'
      # form.order_type_2 = 'DESC' # 'Descending'
    }.submit

    search_results = get_search_page_results(my_results, search_type)
  }
  search_results
end

# ================================
# Scraping all
# ================================
def scrape_all_new(existing_urls, base_url, username, password)
# TODO
end

def scrape_all(profile_url, data_dir)
  FileUtils::mkdir_p(data_dir) unless File.exists?(data_dir)

  puts 'Running full scrape'
  home_page = BASE_URL + profile_url

  tick_urls_array = scrape_all_logs(home_page)
  read_write_climber_logs(tick_urls_array, profile_url, data_dir)

  scrape_all_ticked_pages(tick_urls_array, profile_url, data_dir)

  scrape_all_personal_pages(home_page, data_dir)

  puts 'Website scrape complete.'
end

def scrape_all_logs(home_page)
  puts 'Scraping all climber logs ...'
  tick_urls_array = []
  tick_urls = get_tick_urls_from_profile(home_page)
  tick_urls.keys.each { |key|
    tick_urls_array[tick_urls_array.count] = "#{BASE_URL}#{tick_urls[key][:link_url]}"
  }

  tick_urls_array
end

def scrape_all_ticked_pages(tick_urls_array, profile_url, data_dir)
  puts 'Scraping all pages of ticked objects ...'
  read_write_pages_ticked(tick_urls_array, profile_url, data_dir)
end

def scrape_all_personal_pages(home_page, data_dir)
  puts 'Scraping all personal pages ...'
  personal_urls_array = []
  object_urls = get_object_urls_from_profile(home_page)
  object_urls.keys.each { |key|
    personal_urls_array[personal_urls_array.count] = "#{object_urls[key][:link_url]}"
  }
  read_write_pages_personal(personal_urls_array, data_dir)
end

# ================================
# Supporting Methods: Entry Points: Search Results
# ================================
def get_search_page_results(page, search_type)
  rows = page.parser.css('table.srch_results > tr')

  results = {}
  max_num = rows.count - 1
  if max_num > 0
    count = 1
    rows[1..-1].each { |row|
      puts "Reading results row #{count} of #{max_num}"
      row_nodes = row.css('> td')

      result = nil
      case search_type
        when 'Routes'
          result = get_row_route_results(row_nodes)
        when 'Mountains & Rocks'
          result = get_row_peak_results(row_nodes)
        else
          # No action
      end
      results[result[:result_url]] = result unless result.nil?

      count += 1
    }
  end

  results
end

def get_row_route_results(row_nodes)
  row_nodes.count > 0 ? node_element = row_nodes[0].css('img')[0] : node_element = nil
  !node_element.nil? ? img_url = node_element['src'] : img_url = nil

  row_nodes.count > 1 ? node_element = row_nodes[1].css('a')[0] : node_element = nil
  !node_element.nil? ? result_title = node_element.text : result_title = nil
  !node_element.nil? ? result_url = node_element['href'] : result_url = nil

  row_nodes.count > 2 ? node_element = row_nodes[2].css('a')[0] : node_element = nil
  !node_element.nil? ? parents = node_element.text : parents = nil
  !node_element.nil? ? parents_url = node_element['href'] : parents_url = nil

  row_nodes.count > 4 ? additional_info = row_nodes[4] : additional_info = nil

  {result_title: result_title,
   result_url: result_url,
   img_url: img_url,
   parents: parents,
   parents_url: parents_url,
   elevation: nil,
   additional_info: additional_info}
end

def get_row_peak_results(row_nodes)
  row_nodes.count > 0 ? node_element = row_nodes[0].css('img')[0] : node_element = nil
  !node_element.nil? ? img_url = node_element['src'] : img_url = nil

  row_nodes.count > 1 ? node_element = row_nodes[1].css('a')[0] : node_element = nil
  !node_element.nil? ? result_title = node_element.text : result_title = nil
  !node_element.nil? ? result_url = node_element['href'] : result_url = nil

  row_nodes.count > 2 ? node_element = row_nodes[2].css('a')[0] : node_element = nil
  !node_element.nil? ? parents = node_element.text : parents = nil
  !node_element.nil? ? parents_url = node_element['href'] : parents_url = nil

  row_nodes.count > 3 ? elevation = row_nodes[3].text : elevation = nil
  elevation = elevation.split(' ft')[0].strip!

  row_nodes.count > 5 ? additional_info = row_nodes[5] : additional_info = nil

  {result_title: result_title,
   result_url: result_url,
   img_url: img_url,
   parents: parents,
   parents_url: parents_url,
   elevation: elevation,
   additional_info: additional_info}
end

# ================================
# Supporting Methods
# ================================
def read_write_climber_logs(urls, profile_url, data_dir)
  climber_logs = read_climber_log_pages(urls, profile_url)

  puts 'Writing all climber logs to file'
  local_fname = "#{data_dir}/climber_logs.txt"
  File.delete(local_fname) if File.exist?(local_fname)
  sleep(0.2)
  climber_logs.keys.each { |log_page|
    climber_logs[log_page].each { |log|
      append_hash(log[1], local_fname)
    }
  }
end

def read_climber_log_pages(urls, profile_url)
  max_num = urls.count
  count = 1
  logs = {}
  urls.each { |url|
    puts "Reading climber log #{count} of #{max_num}"
    logs[url] = read_climbers_log_page(url, profile_url)
    count += 1
  }
  logs
end

def read_write_pages_personal(urls, data_dir)
  max_num = urls.count
  count = 1
  urls.each { |url|
    puts "Reading personal page #{count} of #{max_num}"
    page = Nokogiri::HTML(open(BASE_URL + url))
    read_write_page_by_type(page, url, data_dir, 'my_')
    count += 1
  }
end

def read_write_pages_ticked(tick_urls, profile_url, data_dir)
  max_num = tick_urls.count
  count = 1
  tick_urls.each { |tick_url|
    puts "Reading ticked page #{count} of #{max_num}"
    tick_page_url = get_ticked_page_url(tick_url, profile_url)
    page = Nokogiri::HTML(open(BASE_URL + tick_page_url))
    read_write_page_by_type(page, tick_page_url, data_dir)
    count += 1
  }
end

def get_ticked_page_url(tick_url, profile_url)
  logs = read_climbers_log_page(tick_url, profile_url)

  if logs.count > 0
    logs.values[0][:object_url]
  else
    nil
  end
end

def get_object_urls_from_profile(url)
  puts 'Getting URLs for object pages ...'
  page = Nokogiri::HTML(open(url))
  links = page.css('div.parent_search_list > a')

  object_link = {}
  links.each { |link|
    link_url = link['href']

    unless link_url.include? '/climbers-log/'
      link_name = link.text

      object_link[link_url] = {link_url: link_url,
                               link_name: link_name}
    end
  }
  object_link
end

def get_tick_urls_from_profile(url)
  puts 'Getting URLs for tick/log pages ...'
  page = Nokogiri::HTML(open(url))
  links = page.css('div.parent_search_list > a')

  tick_link = {}
  links.each { |link|
    link_url = link['href']

    if link_url.include? '/climbers-log/'
      link_name = link.text

      tick_link[link_url] = {link_url: link_url,
                             link_name: link_name}
    end
  }
  tick_link
end

def classify_page(page)
  puts 'Getting page classification ...'
  get_main_data_box_item(page,'Page Type: ')
end

def read_page_by_type(page, url)
  type = classify_page(page)

  puts "Reading page of type: #{type}"
  case type
    when 'Route', 'Mountain/Rock', 'Article', 'Trip Report', 'Area/Range', 'Trailhead', 'Canyon'
      read_page(page, url)
    else
      # Page is ignored
      nil
  end
end

def read_write_page_by_type(page, url, data_dir, prefix='')
  page_to_write = read_page_by_type(page, url)

  unless page_to_write.nil?
    type = page_to_write[:type]
    type.gsub!('/', '-')
    id = page_to_write[:id]
    puts "Writing page of type: #{type} for ID #{id}"
    overwrite_hash(page_to_write, "#{data_dir}/#{prefix}#{type}_#{id}.txt")
  end
end


def read_climbers_log_page(url, profile_url)
  puts "Reading climbers log page: #{url} \n  for climber #{profile_url}"
  page = Nokogiri::HTML(open(url))
  tables = page.css('table.messages')

  climber_log = {}
  tables.each { |table|
    user_tag = table.css('a.dis_user_lnk')
    user_tag.count > 0 ? user = user_tag[0]['href'] : user = nil

    if !user.nil? && user === profile_url
      climber_log[url] = read_climber_log(url, table)
    end
  }
  climber_log
end

def read_climber_log(url, table)
  puts 'Reading climber log'

  object_id = url.split('/climbers-log/')[1]
  object_id = object_id.split('/d-')[0]

  object_url = url.split('/climbers-log/')[0] + '/' + object_id
  object_url.sub!(BASE_URL,'')

  title = table.css('tr > td > b')[0].text
  route_name = get_route(title)
  date = get_date(table)
  success = get_success(table)
  message = table.css('tr')[1].css('td')[1].text

  {id: object_id,
   object_url: object_url,
   route_name: route_name,
   log_url: url.sub(BASE_URL,''),
   title: title,
   success: success,
   date: date,
   message: message}
end

def get_route(title)
  begin
    route_key = 'Route Climbed: '
    date_key = 'Date Climbed: '

    route = nil
    if title.include? date_key
      titles = title.split(date_key)
      titles.each { |split_title|
        route = split_title if split_title.include? route_key
      }
    else
      route = 'N/A'
    end

    if !route.nil? && (route.include? route_key)
      route.sub!(route_key, '')
    elsif title.include? route_key
      route = title.sub!(route_key, '')
    else
      route = nil
    end
  rescue
    route = nil
  end
  route
end

def get_date(table)
  begin
    # Some logs have the date in the title.
    # Other logs have a particular span element with the title.

    title = table.css('tr > td > b')[0].text
    date_key = 'Date Climbed: '
    date = nil
    if title.include? date_key
      titles = title.split(date_key)
      date = titles.last
    else
      date = table.css('tr > td > span')[0].text
      date.sub!(/^Date Climbed: /,'').strip!
    end
  rescue
    date = nil
  end
  date
end

def get_success(table)
  begin
    nk_element = table.css('a[title]')
    if nk_element.count > 0
      nk_element[0]['title']
    else
      'No'
    end
  rescue
    'Unknown'
  end
end

def read_page(page, url)
  begin
    puts "Reading page: #{url}"

    id = url.split('/').last
    name = get_main_data_box_item(page,'Object Title: ')
    type = classify_page(page)

    location = get_main_data_box_item(page,'Location: ')

    lat_long = get_main_data_box_item(page,'Lat/Lon: ')
    latitude = get_latitude(lat_long)
    longitude = get_longitude(lat_long)

    elevation = get_elevation(page)

    route_type = get_main_data_box_item(page,'Route Type: ')
    seasons = get_main_data_box_item(page,'Season: ')
    time_required = get_main_data_box_item(page,'Time Required: ')
    rock_difficulty = get_main_data_box_item(page,'Rock Difficulty: ')
    difficulty = get_main_data_box_item(page,'Difficulty: ')
    number_of_pitches = get_main_data_box_item(page,'Number of Pitches: ')
    grade = get_main_data_box_item(page,'Grade: ')

    route_quality = get_rating(page)
    my_route_quality = get_my_rating(page)

    activities = get_main_data_box_item(page,'Activities: ')
    date = get_main_data_box_item(page,'Date Climbed/Hiked: ')
    hits = get_main_data_box_item(page,'Hits: ')

    bread_crumbs = page.css('div.breadcrumb a')
    if !bread_crumbs.nil? && bread_crumbs.count > 0
      parent = bread_crumbs.last
      parent_name = parent.text
      parent_url = parent['href']
      parent_code = parent_url.split('/').last
    else
      parent_name = nil
      parent_url = nil
      parent_code = nil
    end

    content = page.css('article')

    {id: id,
     page_url: url.sub(BASE_URL,''),
     name: name,
     type: type,
     location: location,
     latitude: latitude,
     longitude: longitude,
     elevation: elevation,
     route_type: route_type,
     seasons: seasons,
     time_required: time_required,
     rock_difficulty: rock_difficulty,
     difficulty: difficulty,
     number_of_pitches: number_of_pitches,
     grade: grade,
     route_quality: route_quality,
     # Currently this always come back as nil because the scrawler isn't signed in
     my_route_quality: my_route_quality,
     activities: activities,
     date: date,
     hits: hits,
     parent_name: parent_name,
     parent_url: parent_url,
     parent_code: parent_code,
     content: content}
  rescue
    puts 'Page read failed.'
    nil
  end
end

def get_latitude(lat_long)
  puts "Getting latitude: #{lat_long}"
  begin
    latitude_s = lat_long.split(' / ')[0]
    if latitude_s.include? 'N'
      latitude_s[0...-2].to_f
    else
      latitude_s[0...-2].to_f * -1
    end
  rescue
       nil
  end
end

def get_longitude(lat_long)
  puts "Getting longitude: #{lat_long}"

    longitude_s = lat_long.split(' / ')[1]
    if longitude_s.include? 'E'
      longitude_s[0...-2].to_f
    else
      longitude_s[0...-2].to_f * -1
    end
rescue
  nil
end

def get_rating(page)
  route_quality = nil
  star_check = page.css('li#current-rating')
  if star_check.count > 0
    puts 'Getting rating'
    stars = star_check[0]['style']
    route_quality = get_stars(stars)
    route_quality = route_quality / MAX_STAR_RATING unless route_quality.nil?
  end

  route_quality
end

def get_stars(star_width)
  begin
    star_width.sub!('px;','')
    star_width.sub!('width:','')

    # The stars are filled with a div of width # stars # 13 px
    # Rating is on a scale of 0-5
    (star_width.to_f / 13)
  rescue
    nil
  end
end

def get_my_rating(page)
  my_route_quality = nil
  my_stars_check = page.css('span#meta_vote_reg')
  if my_stars_check.count > 0
    puts 'Getting my rating'
    my_stars = my_stars_check[0]
    my_stars = my_stars.split('voted ')[1]
    my_stars = my_stars.split(' stars')[0].strip
    my_route_quality = my_stars.to_f / MAX_STAR_RATING
  end

  my_route_quality
end

def get_elevation(page)
  begin
    elevation = get_main_data_box_item(page, 'Elevation: ')
    puts 'Getting elevation'
    elevation.split(' ft / ')[0]
  rescue
    nil
  end
end

def get_main_data_box_item(page, key)
  entries = page.css('div#main_data_box tr > td > p')

  value = nil
  entries.each { |entry|
    value = entry.text
    if value.start_with? key
      value.sub!(key, '').strip!
      break
    else
      value = nil
    end
  }
  value
end


# ================================
# Testing methods
# ================================
def run_tests(profile_url, test_data_dir)
  FileUtils::mkdir_p(test_data_dir) unless File.exists?(test_data_dir)

  puts 'Running tests'
  home_page = BASE_URL + profile_url

#Clear and remake test data directory
  FileUtils::rm_rf(test_data_dir) if File.exists?(test_data_dir)
  sleep(0.2)
  FileUtils::mkdir_p(test_data_dir) unless File.exists?(test_data_dir)

  ### Basic Reading/Writing

  # URLs really tough to group a priori based on website layout
  # Easiest to just get all URLs from the lists, then classify them when visiting their pages.
  puts "Getting object URLs from profile page #{home_page}"
  object_urls = get_object_urls_from_profile(home_page)
  overwrite_sub_hashes(object_urls, "#{test_data_dir}/object_urls.txt")

  # Tick URLs can be classified on the fly as they have a predictable and unique substring in their URLs
  puts "Getting tick URLs from profile page #{home_page}"
  tick_urls = get_tick_urls_from_profile(home_page)
  overwrite_sub_hashes(tick_urls, "#{test_data_dir}/tick_urls.txt")

  # Read Climber Logs
  climber_log_url = 'http://www.summitpost.org/devil-s-golf-ball/climbers-log/247651/d-146721#146721'
  puts "Getting climber log from #{climber_log_url}"
  climber_logs = read_climbers_log_page(climber_log_url, profile_url)
  overwrite_sub_hashes(climber_logs, "#{test_data_dir}/climber_log.txt")

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

  ### Searches

  # 'east arete' = 8 results (routes)
  # 'east arete' = 11 results (all)
  route_results = search_route_reference('East Arete')
  overwrite_sub_hashes(route_results, "#{test_data_dir}/search_route_test.txt")

  # 'North Palisade' = 1 result (mountains & rocks)
  # 'North Palisade' = 5 results (all)
  peak_results = search_peak_reference('North Palisade')
  overwrite_sub_hashes(peak_results, "#{test_data_dir}/search_peak_test.txt")

  ### Getting Latest


  puts 'Test scrapes complete.'
end