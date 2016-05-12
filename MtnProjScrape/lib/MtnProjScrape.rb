require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'net/https'
require 'fileutils'

# See: http://ruby.bastardsbook.com/chapters/html-parsing/
# See: http://ruby.bastardsbook.com/chapters/web-crawling/



##### Methods #####
# TODO: Put into separate module

def append_hash(local_fname, hash)
  hash.sort.each { |key, value|  File.open(local_fname, 'a'){|file| file.write("#{key}: #{value} \n")}}
  File.open(local_fname, 'a'){|file| file.write("\n")}
end

def append_array(local_fname, array)
  array.sort.each { |item|  File.open(local_fname, 'a'){|file| file.write("#{item} \n")}}
  File.open(local_fname, 'a'){|file| file.write("\n")}
end

##### Methods #####
# TODO: Put into separate module

def read_route_ticks(url)
  page = Nokogiri::HTML(open(url))
  rows = page.css('table.objectList > tr')

  route_ticks = {}
  rows[1..-2].each { |row|   # starting at 1 skips the column header
    route_tick = read_route_tick(row)
    route_ticks[route_tick[:route_url]] = route_tick
  } # done: rows.each

  route_ticks
end

def read_route_ticks_latest(url)
  page = Nokogiri::HTML(open(url))
  rows = page.css('table.objectList > tr')

  route_ticks = {}
  rows[1..-2].each { |row|   # starting at 1 skips the column header
    #TODO: Assess if the tick has already been recorded. Only do below if it is new.
    route_tick = read_route_tick(row)
    route_ticks[route_tick[:route_url]] = route_tick
  } # done: rows.each

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

def read_route_overwrites(url)
  page = Nokogiri::HTML(open(url))

  # MountainProject rates stars 1-5, with 1 being a bomb, so a 5 is a 4-star route
  # In my website, a bomb is -1 (or 0?), so this is adjusted
  # Stars cannot be read at that location because the non-closed img tags are interfering with the entire span.
  my_stars = nil #page.css('span#startext1 input')[0]['value'] - 1
  my_rating = page.css('span#personalRating')[0].content

  {my_stars: my_stars,
   my_rating: my_rating}
end

def read_routes_todo(url)
  page = Nokogiri::HTML(open(url))
  rows = page.css('table#todoListItems > tr')

  routes_todo = {}
  rows[1..-2].each { |row|   # starting at 1 skips the column header
    route_todo = read_route_todo(row)
    routes_todo[route_todo[:route_url]] = route_todo
  } # done: rows.each

  routes_todo
end

def read_routes_todo_latest(url)
  page = Nokogiri::HTML(open(url))
  rows = page.css('table#todoListItems > tr')

  routes_todo = {}
  rows[1..-2].each { |row|   # starting at 1 skips the column header
    #TODO: Assess if the todo has already been recorded. Only do below if it is new.

    route_todo = read_route_todo(row)
    routes_todo[route_todo[:route_url]] = route_todo
  } # done: rows.each

  routes_todo
end

def read_route_todo(row)
  route_name = row.css('td a')[0].content
  route_url = row.css('td a')[0]['href']

  {route_name: route_name,
   route_url: route_url}
end

def read_route_page(url)
  page = Nokogiri::HTML(open(url))

  route_name = page.css('h1.dkorange')[0].content
  route_rating = read_route_rating(page.css('div#rspCol800 div.rspCol h3')[0])
  route_stars = page.css('span#starSummaryText meta[itemprop=average]')[0]['content']

  rows = page.css('div#rspCol800 div.rspCol table > tr')
  route_type = rows_key_value(rows, 'Type')
  route_rating_original = read_route_rating(rows_key_value_elements(rows, 'Original'))#page.css('div.rspCol table tr')[1].css('td')[1])
  route_rating_original = route_rating_original.split('[details]')[0].strip

  route_description = main_content_text(page, 'Description')
  if route_description.nil?
    route_description = main_content_text(page, 'Overview')
  end

  parent = read_parent_area(page)

   {route_name: route_name,
    route_url: url,
    route_rating: route_rating,
    route_stars: route_stars,
    route_type: route_type,
    route_rating_original: route_rating_original,
    route_description: route_description,
    parent_name: parent[:parent_name],
    parent_url: parent[:parent_url]}
end

def read_area_page(url)
  page = Nokogiri::HTML(open(url))

  name = page.css('h1.dkorange')[0].content  # In debugging, see about stripping suffix, e.g. Rock Climbing

  rows = page.css('div.rspCol > table > tr')
  location = rows_key_value(rows, 'Location')
  latitude = nil
  longitude = nil
  unless location.nil?
    latitude = location.split(',')[0]
    longitude = location.split(',')[1]   # In debugging, see about stripping suffix, e.g. View Map
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
   area_url: url,
   latitude: latitude,
   longitude: longitude,
   description: description,
   getting_there: getting_there,
   parent_name: parent[:parent_name],
   parent_url: parent[:parent_url]}
end

def rows_key_value(rows, key)
  value = nil
  rows.each { |row|
    if row.css('td')[0].content.include? key
      value = row.css('td')[1].content
      break
    end
  }

  value
end

def rows_key_value_elements(rows, key)
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

def read_route_rating(rating)
   # Take YDS 'unit' of rock rating
  rock_rating = rating.css('span.rateYDS')[0]

  if rock_rating.nil?
    # There are no rock rating classes. Just get the text.
    rating.text
  else
    rock_rating = rock_rating.content.split(':')[1]

    # All other ratings that are not rock ratings are listed after the last span.
    # This last span appears to always be of the rateBritish class
    other_rating = rating.text
    split_rating = rating.css('span.rateBritish')[0].content
    other_ratings = other_rating.split(split_rating)
    if other_ratings.size >= 2
      rock_rating + other_ratings[1]
    else
      rock_rating
    end
  end
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

def read_parent_area_urls(url)
  page = Nokogiri::HTML(open(url))
  parents = page.css('div#navBox div[itemtype]')

  parent_urls = []
  parents.each { |parent|  parent_urls.push(parent.css('a')[0]['href'])}

  parent_urls
end


#============================
def get_all_route_ticks(url, last_page_number)
  all_route_ticks = {}
  puts 'Scraping Ticks Page'
  puts "Iterating from 1 to #{last_page_number}"
  (1..last_page_number).each { |pg_number|
    puts "Getting web page #{pg_number} of #{last_page_number}"

    list_url = url + pg_number.to_s
    puts "Reading Page: #{list_url}"
    route_ticks = read_route_ticks(list_url)

    # TODO
    # Print to file. Later this is to be swapped to insert to database
    local_fname = "#{DATA_DIR}/tick_list.txt"
    puts "Writing to file #{local_fname}"
    route_ticks.keys.each { |route_tick|  append_hash(local_fname, route_ticks[route_tick])}

    all_route_ticks.merge!(route_ticks)
  } # done: pg_numbers.each
  all_route_ticks
end

def get_all_route_tick_urls(route_ticks)
  url_routes = []
  route_ticks.keys.each { |route_tick|
    url_routes.push(BASE_URL + route_ticks[route_tick][:route_url]).compact.uniq
  }
  url_routes
end

def get_all_ticked_route_overwrites(url_routes)
  puts 'Getting ticked route overwrites'
  all_my_route_overwrites = {}
  route_num = 1
  route_max = url_routes.size
  url_routes.each { |url|
    puts "Reading route (#{route_num} of #{route_max}): #{url}"
    my_route_overwrites = read_route_overwrites(url)
    my_route_overwrites[:route_url] = url

    # TODO
    # Print to file. Later this is to be swapped to insert to database
    local_fname = "#{DATA_DIR}/route_overwrites.txt"
    puts "Writing to file #{local_fname}"
    append_hash(local_fname, my_route_overwrites)

    all_my_route_overwrites[:route_url] = my_route_overwrites
    route_num += 1
  }
  all_my_route_overwrites
end

def get_all_route_pages(url_routes)
  puts 'Iterating over route pages.'
  routes = {}
  route_num = 1
  route_max = url_routes.size
  url_routes.each do |url|
    puts "Reading route (#{route_num} of #{route_max}): #{url}"
    route = read_route_page(url)

    # TODO
    # Print to file. Later this is to be swapped to insert to database
    local_fname = "#{DATA_DIR}/routes.txt"
    puts "Writing to file #{local_fname}"
    append_hash(local_fname, route)

    routes[url] = route
    route_num += 1
  end # done: url_routes
  routes
end

def get_all_route_areas_urls(routes)
  puts 'Iterating over route pages.'
  url_parents = []
  route_num = 1
  route_max = routes.size

  routes.keys.each do |url|
    puts "Adding URL to areas URL list (#{route_num} of #{route_max}): #{url}"
    url_parent = BASE_URL + routes[url][:parent_url]
    url_parents.push(url_parent).compact.uniq unless url_parents.include? url_parent
    route_num += 1
  end # done: url_routes

  url_parents
end

def get_all_route_areas_pages(url_parents)
  puts 'Iterating over first area parents.'
  parents = {}
  area_num = 1
  area_max = url_parents.size

  url_parents.each do |url|
    puts "Reading area (#{area_num} of #{area_max}): #{url}"
    area = read_area_page(url)

    # TODO
    # Print to file. Later this is to be swapped to insert to database
    local_fname = "#{DATA_DIR}/areas.txt"
    puts "Writing to file #{local_fname}"
    append_hash(local_fname, area)

    parents[url] = area
    area_num += 1
  end # done: url_parents

  parents
end

def get_all_area_parents_urls(url_parents)
  url_parents_parent = []
  area_num = 1
  area_max = url_parents.size

  url_parents.keys.each do |url|
    ###########
    # For all parents up the tree
    puts "Reading parent of area (#{area_num} of #{area_max}): #{url}"
    parent_urls = read_parent_area_urls(url)

    # Add to total list of parents
    parent_urls.each { |parent_url|
      url_parent = BASE_URL + parent_url

      unless (url_parents.include? url_parent) || (url_parents_parent.include? url_parent)
        url_parents_parent.push(url_parent).compact.uniq
      end
    }
    area_num += 1
  end # done: url_parents

  url_parents_parent
end

def get_all_area_parents_pages(url_parents_parent, parents)
  puts 'Iterating up areas hierarchy tree.'
  area_num = 1
  area_max = url_parents_parent.size

  url_parents_parent.each do |url|
    if parents.key?(url)
      next
    end

    puts "Reading area (#{area_num} of #{area_max}): #{url}"
    area = read_area_page(url)

    # TODO
    # Print to file. Later this is to be swapped to insert to database
    local_fname = "#{DATA_DIR}/areas.txt"
    puts "Writing to file #{local_fname}"
    append_hash(local_fname, area)

    parents[url] = area
    area_num += 1
  end # done: URL_PARENTS_TOTAL

  parents
end

# Testing methods:
# page1_data = read_route_page('http://www.mountainproject.com/v/cassin-ridge/105954372')
# page2_data = read_route_page('http://www.mountainproject.com/v/chrysler-crack/105887571')
# page3_data = read_route_page('http://www.mountainproject.com/v/centennial/105715670')
# page4_data = read_area_page('http://www.mountainproject.com/v/swan-slab/105841123')
# page5_data = read_area_page('http://www.mountainproject.com/v/california/105708959')
# page6_data = read_routes_todo('http://www.mountainproject.com/u/mark-p-thomas//106560803?action=todos&')

# Running methods
DATA_DIR = 'data-hold/mountainProject'
FileUtils::mkdir_p(DATA_DIR) unless File.exists?(DATA_DIR)

BASE_URL = 'http://www.mountainproject.com'
PROFILE_URL = '/u/mark-p-thomas//106560803'

# Page 1 is used as a starting point for getting the pagination range
TICKS_URL = '?action=ticks&&page='
URL_PAGE = '1'
list_url = BASE_URL + PROFILE_URL + TICKS_URL + URL_PAGE

# Get the last page number from the second arrow button in the table navigation links in the first page
page = Nokogiri::HTML(open(list_url))
last_page_number = page.css('a.smallMedium')[1]['href'].match(/page=(\d+)/)[1].to_i

##### Ticks Page #####
# Get basic route data from route ticks
route_ticks = get_all_route_ticks(BASE_URL + PROFILE_URL + TICKS_URL, last_page_number)
url_routes = get_all_route_tick_urls(route_ticks)

# Read route pages to get stars and rating
get_all_ticked_route_overwrites(url_routes)

##### To-Do List Page #####
# Get additional routes from TODOS
puts 'Scraping To-Do Page'
TODO_URL = '?action=todos&'

list_url = BASE_URL + PROFILE_URL + TODO_URL
puts "Scraping: #{list_url}"
routes_todo = read_routes_todo(list_url)

# TODO
# Print to file. Later this is to be swapped to insert to database
local_fname = "#{DATA_DIR}/todo_list.txt"
puts "Writing to file #{local_fname}"
routes_todo.keys.each { |route_todo|  append_hash(local_fname, routes_todo[route_todo])}

puts 'Adding URLs to total routes URL list'
routes_todo.keys.each { |route_todo|  url_routes.push(BASE_URL + routes_todo[route_todo][:route_url]).compact.uniq}

##### Routes Page #####
# Scrape remaining data from route pages
routes = get_all_route_pages(url_routes)
url_parents = get_all_route_areas_urls(routes)

# Save complete URLs in case list needs to be regenerated - ideally from the backup file
# TODO
# Print to file. Later this is to be swapped to insert to database
local_fname = "#{DATA_DIR}/url_parents.txt"
puts "Writing to file #{local_fname}"
append_array(local_fname, url_parents)

##### Area Pages #####
areas = get_all_route_areas_pages(url_parents)
url_parents_parent = get_all_area_parents_urls(areas)

# Save complete URLs in case list needs to be regenerated - ideally from the backup file
# TODO
# Print to file. Later this is to be swapped to insert to database
local_fname = "#{DATA_DIR}/url_parents_parent.txt"
puts "Writing to file #{local_fname}"
append_array(local_fname, url_parents_parent)

get_all_area_parents_pages(url_parents_parent, areas)