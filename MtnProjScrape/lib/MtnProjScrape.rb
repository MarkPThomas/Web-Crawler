require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'net/https'
require 'fileutils'

# See: http://ruby.bastardsbook.com/chapters/html-parsing/
# See: http://ruby.bastardsbook.com/chapters/web-crawling/

# Testing method:
read_route_page('http://www.mountainproject.com/v/cassin-ridge/105954372')

DATA_DIR = 'data-hold/mountainProject'
FileUtils::mkdir_p(DATA_DIR) unless File.exists?(DATA_DIR)

BASE_URL = 'http://www.mountainproject.com'
PROFILE_URL = '/u/mark-p-thomas//106560803'

# Page 1 is used as a starting point for getting the pagination range
TICKS_URL = '?action=ticks&&page='
URL_PAGE = '1'
LIST_URL = BASE_URL + PROFILE_URL + TICKS_URL + URL_PAGE

# Get the last page number from the second arrow button in the table navigation links in the first page
page = Nokogiri::HTML(open(LIST_URL))
last_page_number = page.css('a.smallMedium')[1]['href'].match(/page=(\d+)/)[1].to_i

##### Ticks Page #####
# Get basic route data from route ticks
URL_ROUTES = []
puts 'Scraping Ticks Page'
puts "Iterating from 1 to #{last_page_number}"
(1..last_page_number).each { |pg_number|
  puts "Getting #{pg_number}"

  LIST_URL = BASE_URL + PROFILE_URL + TICKS_URL + pg_number
  route_ticks = read_route_ticks(LIST_URL)

  # TODO
  # Print to file. Later this is to be swapped to insert to database
  local_fname = "#{DATA_DIR}/tick_list.txt"
  route_ticks.keys.each { |route_tick|  append_hash(local_fname, route_tick)}

  route_ticks.keys.each { |route_tick|  URL_ROUTES.push(BASE_URL + route_tick[:route_url]).compact.uniq}
} # done: pg_numbers.each

# Read route pages to get stars and rating
puts 'Getting ticked route overwrites'
URL_ROUTES.each { |url|
  my_route_overwrites = read_route_overwrites(url)
  my_route_overwrites[:route_url] = url

  # TODO
  # Print to file. Later this is to be swapped to insert to database
  local_fname = "#{DATA_DIR}/route_overwrites.txt"
  append_hash(local_fname, my_route_overwrites)
}

##### To-Do List Page #####
# Get additional routes from TODOS
puts 'Scraping To-Do Page'
TODO_URL = '?action=todos&'

LIST_URL = BASE_URL + PROFILE_URL + TODO_URL
routes_todo = read_routes_todo(LIST_URL)

# TODO
# Print to file. Later this is to be swapped to insert to database
local_fname = "#{DATA_DIR}/todo_list.txt"
routes_todo.keys.each { |route_todo|  append_hash(local_fname, route_todo)}

routes_todo.keys.each { |route_todo|  URL_ROUTES.push(BASE_URL + route_todo[:route_url]).compact.uniq}

##### Routes Page #####
# Scrape remaining data from route pages
URL_PARENTS = []
routes = {}
puts 'Iterating over route pages.'
URL_ROUTES.each do |url|
  route = read_route_page(url)
  routes[url] = route

  # TODO
  # Print to file. Later this is to be swapped to insert to database
  local_fname = "#{DATA_DIR}/routes.txt"
  append_hash(local_fname, route)

  url_parent = BASE_URL + route[:parent_url]
  URL_PARENTS.push(url_parent).compact.uniq unless URL_ROUTES.include? url_parent
end # done: URL_ROUTES

# Save complete URLs in case list needs to be regenerated - ideally from the backup file
# TODO
# Print to file. Later this is to be swapped to insert to database
local_fname = "#{DATA_DIR}/url_parents.txt"
append_hash(local_fname, URL_PARENTS)

##### Area Pages #####
puts 'Iterating over first parents.'
parents = {}
URL_PARENTS_PARENT = []
URL_PARENTS.each do |url|
  area = read_area_page(url)
  parents[url] = area

  # TODO
  # Print to file. Later this is to be swapped to insert to database
  local_fname = "#{DATA_DIR}/areas.txt"
  append_hash(local_fname, area)

  ###########
  # For all parents up the tree
  parent_urls = read_parent_area_urls(url)

  # Add to total list of parents
  parent_urls.each { |parent_url|
    url_parent = BASE_URL + parent_url
    URL_PARENTS_PARENT.push(url_parent).compact.uniq unless URL_PARENTS.include? url_parent
  }
end # done: URL_PARENTS

# Save complete URLs in case list needs to be regenerated - ideally from the backup file
# TODO
# Print to file. Later this is to be swapped to insert to database
local_fname = "#{DATA_DIR}/url_parents_parent.txt"
append_hash(local_fname, URL_PARENTS_PARENT)


puts 'Iterating up route tree.'
URL_PARENTS_PARENT.each do |url|
  if parents.key?(url)
    next
  end

  area = read_area_page(url)
  parents[url] = area

  # TODO
  # Print to file. Later this is to be swapped to insert to database
  local_fname = "#{DATA_DIR}/areas.txt"
  append_hash(local_fname, area)
end # done: URL_PARENTS_TOTAL

##### Methods #####
# TODO: Put into separate module

def append_hash(local_fname, hash)
  hash.sort.each { |key, value|  File.open(local_fname, 'a'){|file| file.write(key + ': ' + value + "\n")}}
  File.open(local_fname, 'a'){|file| file.write("\n")}
end

def append_array(local_fname, array)
  array.sort.each { |item|  File.open(local_fname, 'a'){|file| file.write(item + "\n")}}
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
  my_stars = page.css('span#startext1 input')[0]['value'] - 1
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
  route_rating = read_route_rating(page.css('div.rspCol h3')[0])
  route_stars = page.css('span#starSummaryText meta[itemprop=average]')[0].content
  route_type = page.css('div.rspCol > table > tr')[0].css('td')[1].content
  route_rating_original = read_route_rating(page.css('div.rspCol table tr')[1].css('td')[1])
  route_description = nil
  route_description = page.css('div#rspCol800 > div')[0].content if page.css('h3.dkorange')[0].content.include? 'Description'

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
  end

  description = main_content_text(page, 'Description')
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

def main_content_text(page, key)
  div_headers = page.css('div#rspCol800 > h3.dkorange')
  index =  main_content_header_index(div_headers, key)
  if index > -1
    page.css('div#rspCol800 > div')[index].content
  else
    nil
  end
end

def main_content_header_index(div_headers, value)
  div_index = 0
  value_found = false
  div_headers.each { |header|
    if header[0].content.include? value
      value_found = true
      break
    end
    div_index += 1
  }

  value_found ? div_index : -1
end

def read_route_rating(rating)
  rating
  # TODO: Complete. Return rating as string
end

def read_parent_area(page)
  parent = page.css('div.navBox div[itemtype=http://data-vocabulary.org/Breadcrumb')
  # Note: If below fails, try parent[-1] to get last array item
  parent_name = parent.last.css('a span')[0].content
  parent_url = parent.last.css('a')[0]['href']

  {parent_name: parent_name,
   parent_url: parent_url}
end

def read_parent_area_urls(url)
  page = Nokogiri::HTML(open(url))
  parents = page.css('div.navBox div[itemtype=http://data-vocabulary.org/Breadcrumb')

  parent_urls = []
  parents.each { |parent|  parent_urls.push(parent.css('a')[0]['href'])}

  parent_urls
end