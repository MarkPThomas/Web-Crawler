require 'rubygems'
require 'mechanize'
require 'nokogiri'
require 'open-uri'
require 'fileutils'
require_relative '../../lib/LibFileReadWrite'

# See: http://ruby.bastardsbook.com/chapters/html-parsing/
# See: http://ruby.bastardsbook.com/chapters/web-crawling/

BASE_URL = 'http://www.mountainproject.com'
TODO_URL = '?action=todos&'
TICKS_URL = '?action=ticks&&page='
ROUTE_SEARCH_URL = '/scripts/Search'

# MountainProject star ratings are on a scale of 0-4
MAX_STAR_RATING = 4

# ================================
# Supporting Methods: Entry Points: Search Results
# ================================
def search_route_reference(search_term)
  puts "Searching for route: #{search_term}"
  search_reference(search_term, 'ROUTES')
end

def search_area_reference(search_term)
  puts "Searching for peak: #{search_term}"
  search_reference(search_term, 'AREAS')
end

def search_reference(search_term, search_type)
  puts "Searching for route: #{search_term}"
  search_results = {}

  a = Mechanize.new { |agent|
    # Redirects after submission
    agent.follow_meta_refresh = true
  }

  a.get(BASE_URL + ROUTE_SEARCH_URL) { |search_page|

    my_results = search_page.form_with(:action => '/scripts/Search.php'){ |form|
      begin
        form.searchInput = search_term
      rescue
        form.query = search_term
      end
      form.SearchSet = search_type
    }.submit

    search_results = get_search_page_results(my_results, search_type)
  }
  search_results
end

def scrape_new(existing_urls, base_url, username, password)
# TODO
end

def scrape_all(profile_url, data_dir)
  FileUtils::mkdir_p(data_dir) unless File.exists?(data_dir)

  ##### Ticks Page #####
  routes_ticked = scrape_ticks_page(profile_url)
  #overwrite_sub_hashes(routes_ticked, "#{data_dir}/tick_list.txt")

  # Does nothing for now. Would work if done after signing in?
  #route_overwrites = scrape_route_overwrites(routes_ticked)
  #append_hash(route_overwrites, "#{data_dir}/route_overwrites.txt")

  ##### To-Do List Page #####
  routes_todo = scrape_to_do_page(profile_url)
  #overwrite_sub_hashes(routes_todo, "#{data_dir}/todo_list.txt")

  ##### Routes Pages #####
  puts 'Compiling total list of route URLs ...'
  url_routes_ticked = get_all_route_ticked_urls(routes_ticked)
  url_routes_todo = get_all_route_todo_urls(routes_todo)
  url_routes = url_routes_ticked | url_routes_todo

  routes = get_all_route_pages(url_routes)
  # routes.keys.each { |route|
  #   overwrite_hash(routes[route], "#{data_dir}/Route_#{routes[route][:id]}.txt")
  # }

  url_parents = get_all_route_areas_urls(routes)
  overwrite_array(url_parents, "#{data_dir}/url_area_routes.txt")

  ##### Route Area Pages #####
  areas = get_all_route_area_pages(url_parents)

  url_parents_parent = get_all_area_parents_urls(areas)
  overwrite_array(url_parents_parent, "#{data_dir}/url_parents_areas.txt")

  ##### Area Parent Pages #####
  areas_all = get_all_area_parents_pages(url_parents_parent, areas)
  areas_all.keys.each { |area|
    overwrite_hash(areas_all[area], "#{data_dir}/Area_#{areas_all[area][:id]}.txt")
  }
  #append_sub_hashes(areas_all, "#{data_dir}/areas.txt")

  puts 'Website scrape complete.'
end

# ================================
# Supporting Methods: Entry Points: Search Results
# ================================
def get_search_page_results(page, search_type)
  rows = page.parser.css('table.objectList > tr')

  results = {}
  max_num = rows.count
  count = 1
  if max_num > 2
    rows[2..-1].each { |row|
      puts "Reading results row #{count} of #{max_num}"
      row_nodes = row.css('> td')

      result = nil
      case search_type
        when 'ROUTES'
          result = get_row_route_results(row_nodes)
        when 'AREAS'
          result = get_row_area_results(row_nodes)
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
  row_nodes.count > 0 ? result_title = row_nodes[0].css('a')[0].text : result_title = nil
  row_nodes.count > 0 ? result_url = row_nodes[0].css('a')[0]['href'] : result_url = nil
  row_nodes.count > 1 ? route_rating = read_route_rating(row_nodes[1].css('p')[0]) : route_rating = nil
  row_nodes.count > 2 ? route_type = row_nodes[2].text : route_type = nil
  row_nodes.count > 3 ? result_formation = row_nodes[3].css('a').last.text : result_formation = nil
  row_nodes.count > 3 ? result_formation_url = row_nodes[3].css('a').last['href'] : result_formation_url = nil
  row_nodes.count > 3 ? result_location = row_nodes[3].text : result_location = nil

  {result_title: result_title,
   result_url: result_url,
   route_type: route_type,
   route_rating: route_rating,
   result_formation: result_formation,
   result_formation_url: result_formation_url,
   result_location: result_location}
end

def get_row_area_results(row_nodes)
  row_nodes.count > 0 ? result_title = row_nodes[0].css('a')[0].text : result_title = nil
  row_nodes.count > 0 ? result_url = row_nodes[0].css('a')[0]['href'] : result_url = nil
  row_nodes.count > 1 ? result_formation = row_nodes[1].css('a').last.text : result_formation = nil
  row_nodes.count > 1 ? result_formation_url = row_nodes[1].css('a').last['href'] : result_formation_url = nil
  row_nodes.count > 1 ? result_location = row_nodes[1].text : result_location = nil

  {result_title: result_title,
   result_url: result_url,
   route_type: nil,
   route_rating: nil,
   result_formation: result_formation,
   result_formation_url: result_formation_url,
   result_location: result_location}
end

# ================================
# Supporting Methods: Entry Points: Routes Ticked
# ================================

def scrape_ticks_page(profile_url)
  # Page 1 is used as a starting point for getting the pagination range
  last_page_number = 1
  list_url = BASE_URL + profile_url + TICKS_URL
  list_url_first = list_url + last_page_number.to_s

  puts 'Scraping Ticks pages ...'
  last_page_number = get_last_ticks_page_number(list_url_first)
  get_all_route_ticks(list_url, last_page_number)
end

def get_last_ticks_page_number(url)
  puts "Reading Route Tick page #{url}"
  page = Nokogiri::HTML(open(url))

  # Get the last page number from the second arrow button in the table navigation links in the first page
  page.css('a.smallMedium')[1]['href'].match(/page=(\d+)/)[1].to_i
end

def get_all_route_ticks(url, last_page_number)
  all_route_ticks = {}
  puts 'Scraping Ticks Page'
  puts "Iterating from 1 to #{last_page_number}"
  (1..last_page_number).each { |pg_number|
    puts "Getting web page #{pg_number} of #{last_page_number}"

    list_url = url + pg_number.to_s
    route_ticks = read_route_ticks(list_url)

    all_route_ticks.merge!(route_ticks)
  }

  all_route_ticks
end

def read_route_ticks(url)
  puts "Reading Route Tick page #{url}"
  page = Nokogiri::HTML(open(url))
  rows = page.css('table.objectList > tr')

  route_ticks = {}
  rows[1..-1].each { |row|   # starting at 1 skips the column header
    route_tick = read_route_tick(row)
    route_ticks[route_tick[:route_url]] = route_tick
  }

  route_ticks
end

def read_route_tick(row)
  route_name = row.css('td p')[0].content
  route_url = row.css('td p a')[0]['href']

  route_comments = row.css('td p.small')[1].content
  route_tick_date = row.css('td p.small')[2].content

  {route_name: route_name,
   route_url: route_url,
   route_comments: route_comments,
   route_tick_date: route_tick_date}
end

# ================================
# Supporting Methods: Entry Points: Routes To Do
# ================================
def scrape_to_do_page(profile_url)
  list_url = BASE_URL + profile_url + TODO_URL
  read_routes_todo(list_url)
end

def read_routes_todo(url)
  puts "Reading Routes To-Do page #{url}"
  page = Nokogiri::HTML(open(url))
  rows = page.css('table#todoListItems > tr')

  routes_todo = {}
  rows[1..-2].each { |row|   # starting at 1 skips the column header, ending at -2 skips an invisible row tr#hidden_todo
    route_todo = read_route_todo(row)
    routes_todo[route_todo[:route_url]] = route_todo
  }

  routes_todo
end

def read_route_todo(row)
  route_name = row.css('td a')[0].content
  route_url = row.css('td a')[0]['href']

  {route_name: route_name,
   route_url: route_url}
end


# ================================
# Supporting Methods: Route Overwrites
# ================================
def scrape_route_overwrites(route_ticks)
  puts 'Scraping route overwrites'
  url_routes = get_all_route_ticked_urls(route_ticks)

# Read route pages to get stars and rating
# Currently returns no ratings or overwrites since url is not for being signed in
  get_all_ticked_route_overwrites(url_routes)
end

def get_all_ticked_route_overwrites(url_routes)
  puts 'Getting ticked route overwrites'
  all_my_route_overwrites = {}
  route_num = 1
  route_max = url_routes.size
  url_routes.each { |url|
    puts "Reading route (#{route_num} of #{route_max}): #{BASE_URL + url}"
    my_route_overwrites = read_route_overwrite_pages(BASE_URL + url)
    my_route_overwrites[:route_url] = url.sub(BASE_URL,'')

    all_my_route_overwrites[:route_url] = my_route_overwrites
    route_num += 1
  }
  all_my_route_overwrites
end

def read_route_overwrite_pages(url)
  puts "Reading route page #{url}"
  page = Nokogiri::HTML(open(url))

  # MountainProject rates stars 1-5, with 1 being a bomb, so a 5 is a 4-star route
  # In my website, a bomb is -1 (or 0?), so this is adjusted
  # Stars cannot be read at that location because the non-closed img tags are interfering with the entire span.
  my_stars = nil #page.css('span#startext1 input')[0]['value'] - 1
  my_rating = page.css('span#personalRating')[0].content

  {my_stars: my_stars,
   my_rating: my_rating}
end


# ================================
# Supporting Methods: Route Pages
# ================================
def get_all_route_pages(url_routes)
  puts 'Iterating over route pages.'
  routes = {}
  route_num = 1
  route_max = url_routes.size
  url_routes.each {|url|
    puts "Reading route (#{route_num} of #{route_max})"
    route = read_route_page(BASE_URL + url)
    routes[url] = route
    route_num += 1
  }
  routes
end

def read_route_page(url)
  puts "Reading route page #{url}"
  page = Nokogiri::HTML(open(url))

  id = url.split('/').last
  route_name = page.css('h1.dkorange')[0].content
  route_rating = read_route_rating(page.css('div#rspCol800 div.rspCol h3')[0])
  route_stars = page.css('span#starSummaryText meta[itemprop=average]')[0]['content']
  !route_stars.nil? ? route_quality = route_stars.to_f / MAX_STAR_RATING : route_quality = nil

  rows = page.css('div#rspCol800 div.rspCol table > tr')
  route_type = rows_key_value_node(rows, 'Type').content
  route_rating_original = read_route_rating(rows_key_value_node(rows, 'Original'))
  route_rating_original = route_rating_original.split('[details]')[0].strip

  route_description = main_content_text(page, 'Description')
  if route_description.nil?
    route_description = main_content_text(page, 'Overview')
  end

  parent = read_parent_area(page)

  {route_name: route_name,
   route_url: url.sub(BASE_URL,''),
   id: id,
   route_rating: route_rating,
   route_quality: route_quality,
   route_type: route_type,
   route_rating_original: route_rating_original,
   route_description: route_description,
   parent_name: parent[:parent_name],
   parent_url: parent[:parent_url]}
end

def read_route_rating(rating)
  script_node = rating.css('script')

  # Take YDS 'unit' of rock rating, or Hueco system if bouldering
  is_yds = true
  rock_rating = rating.css('span.rateYDS')[0]
  if rock_rating.nil?
    is_yds = false
    rock_rating = rating.css('span.rateHueco')[0] if rock_rating.nil?
  end


  if rock_rating.nil?
    # There are no rock rating classes. Just get the text.
    other_rating = rating.text
    if !script_node.nil? && script_node.size > 0
      other_ratings = other_rating.split(script_node[0].content)
      other_ratings[0]
    else
      rating.text
    end
  else
    # All other ratings that are not rock ratings are listed after the last span.
    # This last span appears to always be of the rateBritish class
    other_rating = rating.text
    if is_yds
      split_rating = rating.css('span.rateBritish')[0].content
    else
      split_rating = rating.css('span.rateFont')[0].content
    end
    other_ratings = other_rating.split(split_rating)
    if other_ratings.size > 1
      if !script_node.nil? && script_node.size > 0
        other_ratings = other_ratings[1].split(script_node[0].content)
        rock_rating.text + other_ratings[0]
      else
        rock_rating.text + other_ratings[1]
      end
    else
      rock_rating.text
    end
  end
end


# ================================
# Supporting Methods: Area Pages
# ================================
def get_all_route_area_pages(url_parents)
  puts 'Iterating over first area parents.'
  parents = {}
  area_num = 1
  area_max = url_parents.size

  url_parents.each { |url|
    puts "Reading area (#{area_num} of #{area_max})"
    area = read_area_page(BASE_URL + url)
    parents[url] = area
    area_num += 1
  }

  parents
end

def get_all_area_parents_pages(url_parents_parent, parents)
  puts 'Iterating up areas hierarchy tree.'
  area_num = 1
  area_max = url_parents_parent.size

  url_parents_parent.each { |url|
    # Skip url if it is in the lower tier parents list
    if parents.key?(url)
      next
    end

    puts "Reading area parent (#{area_num} of #{area_max}): #{BASE_URL + url}"
    area = read_area_page(BASE_URL + url)

    parents[url] = area
    area_num += 1
  }

  parents
end

def read_area_page(url)
  puts "Reading area page #{url}"
  page = Nokogiri::HTML(open(url))

  id = url.split('/').last
  name = page.css('h1.dkorange')[0].content

  rows = page.css('div.rspCol > table > tr')
  location_node = rows_key_value_node(rows, 'Location')
  !location_node.nil? ? location = location_node.content : location = nil
  latitude = nil
  longitude = nil
  unless location.nil?
    latitude = location.split(',')[0]
    longitude = location.split(',')[1]
    longitude_items = longitude.split('View')
    if longitude_items.size >= 2
      longitude = longitude_items[0]
    end
  end

  description = main_content_text(page, 'Description')
  if description.nil?
    description = main_content_text(page, 'Overview')
  end
  getting_there = main_content_text(page, 'Getting There')

  parent = read_parent_area(page)

  {area_name: name,
   area_url: url.sub(BASE_URL,''),
   id: id,
   latitude: latitude,
   longitude: longitude,
   description: description,
   getting_there: getting_there,
   parent_name: parent[:parent_name],
   parent_url: parent[:parent_url]}
end

def read_parent_area(page)
  parent = page.css('div#navBox div[itemtype]')

  if parent.size === 0
    parent_name = nil
    parent_url = nil
  else
    parent_name = parent.last.css('a span')[0].content
    parent_url = parent.last.css('a')[0]['href']
  end

  {parent_name: parent_name,
   parent_url: parent_url}
end

# ================================
# Supporting Methods: URLs from Objects
# ================================
def get_all_route_ticked_urls(routes_ticked)
  puts 'Getting all URLs for routes ticked ...'
  url_routes = []
  routes_ticked.keys.each { |route_ticked|
    url_routes.push(routes_ticked[route_ticked][:route_url]).compact.uniq
  }
  url_routes
end


def get_all_route_todo_urls(routes_todo)
  puts 'Getting all URLs for routes to do ...'
  url_routes = []
  routes_todo.keys.each { |route_todo|
    url_routes.push(routes_todo[route_todo][:route_url]).compact.uniq
  }
  url_routes
end


def get_all_route_areas_urls(routes)
  puts 'Iterating over route pages.'
  url_parents = []
  route_num = 1
  route_max = routes.size

  routes.keys.each { |url|
    puts "Adding URL to areas URL list (#{route_num} of #{route_max}): #{url}"
    url_parent = routes[url][:parent_url]
    url_parents.push(url_parent).compact.uniq unless url_parents.include? url_parent
    route_num += 1
  }

  url_parents
end


def get_all_area_parents_urls(url_parents)
  url_parents_parent = []
  area_num = 1
  area_max = url_parents.size

  url_parents.keys.each { |url|
    # For all parents up the tree
    puts "Reading parents of route areas (#{area_num} of #{area_max})"
    parent_urls = read_parent_area_page_urls(BASE_URL + url)

    # Add to total list of parents
    parent_urls.each { |parent_url|
      unless (url_parents.include? parent_url) || (url_parents_parent.include? parent_url)
        url_parents_parent.push(parent_url).compact.uniq
      end
    }
    area_num += 1
  }

  url_parents_parent
end


def read_parent_area_page_urls(url)
  puts "Reading area page #{url}"
  page = Nokogiri::HTML(open(url))
  parents = page.css('div#navBox div[itemtype]')

  parent_urls = []
  parents.each { |parent|
    parent_url = parent.css('a')[0]['href']
    parent_url.sub!(BASE_URL,'')
    parent_urls.push(parent_url)
  }

  parent_urls
end

# ================================
# Supporting Methods: Tools
# ================================

def rows_key_value_node(rows, key)
  value = nil
  rows.each { |row|
    if row.css('td')[0].content.include? key
      value = row.css('td')[1]
      break
    end
  }

  value
end

def main_content_text(page, key)
  div_headers = page.css('div#rspCol800 > h3.dkorange')
  index =  main_content_header_index(div_headers, key)
  if index > -1
    page.css('div#rspCol800 > div')[index + 1].content
  else
    nil
  end
end

def main_content_header_index(div_headers, value)
  div_index = 0
  value_found = false

  div_headers.each { |header|
    if header.content.include? value
      value_found = true
      break
    end
    div_index += 1
  }

  value_found ? div_index : -1
end


# ================================
# Testing methods
# ================================
def run_tests(data_dir)
  puts 'Running tests'

  #Clear and remake test data directory
  FileUtils::rm_rf(data_dir) if File.exists?(data_dir)
  sleep(0.2)
  FileUtils::mkdir_p(data_dir) unless File.exists?(data_dir)

  ### Basic Reading/Writing
  page1_data = read_route_page('http://www.mountainproject.com/v/cassin-ridge/105954372')
  append_hash(page1_data, "#{data_dir}/page1_data.txt")

  page2_data = read_route_page('http://www.mountainproject.com/v/chrysler-crack/105887571')
  append_hash(page2_data, "#{data_dir}/page2_data.txt")

  page3_data = read_route_page('http://www.mountainproject.com/v/centennial/105715670')
  append_hash(page3_data, "#{data_dir}/page3_data.txt")

  page4_data = read_area_page('http://www.mountainproject.com/v/swan-slab/105841123')
  append_hash(page4_data, "#{data_dir}/page4_data.txt")

  page5_data = read_area_page('http://www.mountainproject.com/v/california/105708959')
  append_hash(page5_data, "#{data_dir}/page5_data.txt")

  page6_data = read_routes_todo('http://www.mountainproject.com/u/mark-p-thomas//106560803?action=todos&')
  append_hash(page6_data, "#{data_dir}/page6_data.txt")

  ### Searches
  results_route = search_route_reference('The Nose')
  overwrite_sub_hashes(results_route, "#{data_dir}/search_result_test.txt")

  results_area = search_area_reference('The Nose')
  overwrite_sub_hashes(results_area, "#{data_dir}/search_area_test.txt")


  ### Getting Latest


  puts 'Test scrapes complete.'
end
